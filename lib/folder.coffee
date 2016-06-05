{BufferedProcess} = require 'atom'
path = require 'path'
fs = require 'fs'
_ = require 'underscore-plus'
PathWatcher = require 'pathwatcher'

Package = require './package'

helpers = require './helpers'
{CompositeDisposable, Emitter} = require 'event-kit'



module.exports = class Folder
  constructor: (@path) ->
    @packages = {}

    @fileStats = {}

    # create watches for the directory
    # and rescan if anything changes.
    @watch()

  setUpdateCallback: (@updateCallback) ->

  getPackages: ->
    return _.values(@packages)

  watch: ->
    try
      @watchSubscription ?= PathWatcher.watch @path, (event, path) =>
        switch event
          when 'change' then @fullReparse()

  fullReparse: () ->
    try
      names = fs.readdirSync(@path)
    catch error
      names = []

    files = []
    promises = []
    for name in names
      # ignore non-go-files
      continue if !name.endsWith '.go'

      # check stats of file, load symlinks etc.
      fullPath = path.join(@path, name)
      stat = fs.statSync(fullPath)
      stat = fs.lstatSync(fullPath) if stat.isSymbolicLink?()
      continue if stat.isDirectory?()
      continue if !stat.isFile?()

      # file stats exist, and file is not newer -> has not changed
      if fullPath of @fileStats && @fileStats[fullPath].mtime.getTime() >= stat.mtime.getTime()
          continue

      @fileStats[fullPath] = stat
      promises.push(@reparseFile(fullPath))

    Promise.all(promises).then(=>
      for pkgName, pkg of @packages
        pkg.sortChildren()
      @updateCallback(@)
      )


  reparseFile: (filePath)->
    out = []
    promise = new Promise((resolve, reject) =>
      proc = new BufferedProcess({
        command: 'go-outline-parser',
        args: ['-f', filePath],
        stdout: (data) =>
          out.push(data)

        exit: (code) =>
          resolve(code)
        })
      proc.onWillThrowError((c) ->
        console.log "Error executing go-parser-outline", c.error
        c.handle()
      )

      return proc
      ).then (code) =>
          return unless code is 0

          try
            @updatePackage(out.join("\n"))
          catch error
            console.log "Error creating outline from parser-output", error, out

      return promise

  updatePackage: (parserOutput) ->
    parsed = JSON.parse parserOutput
    file = parsed.Filename
    packageName = parsed.Packagename


    if packageName not of @packages
      @packages[packageName] = new Package(packageName)

    pkg = @packages[packageName]

    pkg.addFile(file)
    for name, p of @packages
      continue if p is pkg

      p.removeFile(file)

    for name in _.keys(@packages)
      if not @packages[name].hasFiles()
        delete @packages[name]


    for name, symbol of parsed.Entries
      symbol.FileName = file
      pkg.updateChild(symbol)

    pkg.removeRemainingChildren(file, _.keys(parsed.Entries))

  expandPackages: () ->
    for pkg in @getPackages()
      pkg.expand()

  collapsePackages: () ->
    for pkg in @getPackages()
      pkg.collapse()

  destroy: ->
    @unwatch
    @emitter.emit("did-destroy")

  unwatch: ->
    if @watchSubscription?
      @watchSubscription.close()
      @watchSubscription = null
