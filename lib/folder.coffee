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

  setParserStatusCallback: (@parserStatusCallback) ->

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

    # ignore non-go-files
    names = _.filter(names, (x) -> x.endsWith '.go')

    files = []
    promises = []
    @parserStatusCallback(names, [], [])

    doneFiles = new Set()
    failedFiles = new Set()
    for name in names
      result = @parseFile(name)

      if result?
        f = (n) =>
          result.then((code)=>
            if code == 0
              doneFiles.add(n)
            else
              failedFiles.add(n)
            @parserStatusCallback(names, doneFiles, failedFiles)
            )
          promises.push(result)
        f(name)
      else
        # if the result was no promise, the file was ignored
        # meaning it was not updated or different type, so we count a success
        doneFiles.add(name)

    Promise.all(promises).then(=>
      @parserStatusCallback(names, doneFiles, failedFiles)
      for pkgName, pkg of @packages
        pkg.sortChildren()
      @updateCallback(@)
    )

  parseFile: (name) ->

    # check stats of file, load symlinks etc.
    fullPath = path.join(@path, name)
    stat = fs.statSync(fullPath)
    stat = fs.lstatSync(fullPath) if stat.isSymbolicLink?()
    if stat.isDirectory?() or !stat.isFile?()
      return null

    # file stats exist, and file is not newer -> has not changed
    if fullPath of @fileStats && @fileStats[fullPath].mtime.getTime() >= stat.mtime.getTime()
        return null

    @fileStats[fullPath] = stat

    return @reparseFile(fullPath)

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
        c.handle()
      )

      return proc
    ).then (code) =>
      return code unless code is 0

      try
        @updatePackage(out.join("\n"))
      catch error
        console.log "Error creating outline from parser-output", error, out
      finally
        return code

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
