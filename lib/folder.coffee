{BufferedProcess} = require 'atom'
path = require 'path'
fs = require 'fs'
_ = require 'underscore-plus'
PathWatcher = require 'pathwatcher'

Package = require './package'

helpers = require './helpers'
{CompositeDisposable, Emitter} = require 'event-kit'


module.exports = class Folder

  # static variable makes sure we only show the warning
  # about using an old browser only once
  @oldParserWarningShown: false
  @parserErrorShown: false

  constructor: (@path, @getParserExecutable) ->
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
    parserExecutable = @getParserExecutable()
    promise = new Promise((resolve, reject) =>
      proc = new BufferedProcess({
        command: parserExecutable,
        args: ['-f', filePath],
        stdout: (data) =>
          out.push(data)
        exit: (code) =>
          resolve(code)
        })

      proc.onWillThrowError((c) =>
        resolve(c)
        @showParserError(c.error)
        c.handle()
      )

      return proc
    ).then (code) =>
      return code unless code is 0

      try
        @updateFolder(out.join("\n"))

      catch error
        console.log "Error creating outline from parser-output", error, out
      finally
        return code

    return promise

  showParserError: (error) =>
    return if Folder.parserErrorShown

    atom.notifications.addError("Error executing go-outline-parser", {
      detail: error + "\nExecutable not found?",
      dismissable:true,
    })
    Folder.parserErrorShown=true

  updateFolder: (parserOutput) ->
    parsed = JSON.parse parserOutput
    console.log parsed.Entries, typeof parsed.Entries, parsed.Entries instanceof Array
    if parsed.Entries not instanceof Array and not Folder.oldParserWarningShown
      atom.notifications.addInfo("Update go-outline-parser",
                                    {detail: "It seems like you're using an outdated version of go-outline. Update to get more features/bugfixes.",
                                    dismissable: true})
      Folder.oldParserWarningShown = true
    file = parsed.Filename
    packageName = parsed.Packagename

    pkg = @updatePackage(file, packageName)

    pkg.updateChildrenForFile(parsed.Entries, file)

  updatePackage: (file, packageName) ->

    if packageName not of @packages
      @packages[packageName] = new Package(packageName)

    pkg = @packages[packageName]

    # add the parsed file to its package and remove it from all the other
    # packages. This covers the case when the package has been renamed.
    pkg.addFile(file)
    for name, p of @packages
      continue if p is pkg

      p.removeFile(file)

    # remove all packages that don't have any files
    for name in _.keys(@packages)
      if not @packages[name].hasFiles()
        delete @packages[name]

    return pkg

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
