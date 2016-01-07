{BufferedProcess} = require 'atom'


path = require 'path'
fs = require 'fs'
_ = require 'underscore-plus'
PathWatcher = require 'pathwatcher'

helpers = require './helpers'
{CompositeDisposable, Emitter} = require 'event-kit'

Entry = require './entry'

module.exports = class Package extends Entry
  constructor: (@packagepath)->
    super("Unkown")
    @updateEntry({ElemType:"package"})

    @fileStats = {}

    # create watches for the directory
    # and rescan if anything changes.
    @watch()

  setUpdateCallback: (@updateCallback) ->

  watch: ->
    try
      @watchSubscription ?= PathWatcher.watch @packagepath, (event, path) =>
        switch event
          when 'change' then @fullReparse()

  fullReparse: () ->
    try
      names = fs.readdirSync(@packagepath)
    catch error
      console.log "error reading directory", error
      names = []

    files = []
    for name in names
      # ignore non-go-files
      continue if !name.endsWith '.go'

      # check stats of file, load symlinks etc.
      fullPath = path.join(@packagepath, name)
      stat = fs.statSync(fullPath)
      stat = fs.lstatSync(fullPath) if stat.isSymbolicLink?()
      continue if stat.isDirectory?()
      continue if !stat.isFile?()

      # file stats exist, and file is not newer -> has not changed
      if fullPath of @fileStats && @fileStats[fullPath].mtime.getTime() >= stat.mtime.getTime()
          continue

      @fileStats[fullPath] = stat
      @reparseFile(fullPath)

  reparseFile: (filePath)->
    out = []
    promise = new Promise((resolve, reject) =>
      new BufferedProcess({
        command: '/home/franz/work/outline/outline-parser/outline-parser',
        args: ['-f', filePath],
        stdout: (data) =>
          out.push(data)

        exit: (code) =>
          resolve(code)
        })).then (code) =>
          @makeOutlineTree(out.join("\n"))
          @updateCallback(this)

  makeOutlineTree: (parserOutput) ->
    parsed = JSON.parse parserOutput
    file = parsed.Filename


    @updateEntry({Name:parsed.Packagename})

    for name, symbol of parsed.Entries
      symbol.FileName = file
      @updateChild(symbol)

    @removeRemainingChildren(file, _.keys(parsed.Entries))

  destroy: ->
    @unwatch
    @emitter.emit("did-destroy")

  unwatch: ->
    if @watchSubscription?
      @watchSubscription.close()
      @watchSubscription = null
