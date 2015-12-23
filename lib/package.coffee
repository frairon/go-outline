path = require 'path'
fs = require 'fs'
_ = require 'underscore-plus'

{BufferedProcess} = require 'atom'

# {CompositeDisposable, Emitter} = require 'event-kit'

#PathWatcher = require 'pathwatcher'
#File = require './file'
# {repoForPath} = require './helpers'
#realpathCache = {}
PathWatcher = require 'pathwatcher'

helpers = require './helpers'

EntryElement = require './entry'

#module.exports =
class Package extends HTMLElement

  initialize: (@packagepath) ->

    #@name = @path.replace(/^.*[\\\/]/, '')

    @initialPackageName = "parsing package..."
    @classList.add('entry',  'list-tree', 'outline-tree', 'collapsed')#,  'collapsed')
    @header = document.createElement('div')
    @packageNameElem = document.createElement('span')
    @packageNameElem.classList.add('name', 'icon', 'icon-file-directory')
    @packageNameElem.title= @initialPackageName
    @packageNameTextNode = document.createTextNode(@initialPackageName)
    @packageNameElem.appendChild(@packageNameTextNode)
    @header.appendChild(@packageNameElem)

    @appendChild(@header)

    @entries = document.createElement('ol')
    @entries.classList.add('entries', 'list-tree')
    @appendChild(@entries)

    @children = {}

    @fileStats = {}

    console.log "creating Package, watching path", @packagepath
    # create watches for the directory
    # and rescan if anything changes.
    @watch()

    @fullReparse()

  watch: ->
    console.log "watched paths", PathWatcher.getWatchedPaths()
    try
      @watchSubscription ?= PathWatcher.watch @packagepath, (event, path) =>
        switch event
          when 'change' then @fullReparse()

  refreshFile: (file) ->
    console.log "refreshing file", file

  dirChanged: (oldPath, newPath) ->
    console.log "file has been created or deleted", oldPath, newPath

  fullReparse: ->
    console.log "reparsing directory", @packagepath
    try
      names = fs.readdirSync(@packagepath)
    catch error
      console.log "error reading directory", error
      names = []

    console.log "found names in directory", names
    files = []
    for name in names

      continue if !name.endsWith '.go'

      fullPath = path.join(@packagepath, name)
      stat = fs.statSync(fullPath)
      stat = fs.lstatSync(fullPath) if stat.isSymbolicLink?()
      continue if stat.isDirectory?()
      continue if !stat.isFile?()

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
      })
    ).then (code) =>
      #console.log "parser finished", code
      outlineTree = @makeOutlineTree(out.join("\n"))

  makeOutlineTree: (parserOutput) ->
    #console.log "making outline from", parserOutput
    parsed = JSON.parse parserOutput
    file = parsed.Filename

    if @packageNameTextNode.nodeValue == @initialPackageName
      @packageNameTextNode.nodeValue = parsed.Packagename
      @packageNameElem.title = parsed.Packagename
    else
      @packageNameTextNode.nodeValue ?= parsed.Packagename
      @packageNameElem.title ?= parsed.Packagename


    entriesToRemove = _.pick(@children, (value, key, object) ->
      return value.FileName == fileName && key not in _.keys(@entries)
    )


    for name, symbol of parsed.Entries
      symbol.FileName = file

      @updateChild(symbol)

    @removeForFile(file, _.keys(entriesToRemove))

  removeForFile: (fileName, removeNames) ->
    console.log @children
    for name, child of @children
      console.log child
      child.removeForFile(fileName, removeNames)

      if child.FileName == fileName && name in removeNames
        child.remove()
        delete @children[name]

  updateChild: (entry) ->
    # if entry has a receiver
    if entry?.Receiver?
      @getOrCreateChild(entry.Receiver).updateChild(entry)
    else
      @getOrCreateChild(entry.Name).updateEntry(entry)

  getOrCreateChild: (name) ->
    if !@children[name]?
      child = new EntryElement().initialize(name)
      console.log child.removeForFile("asdf", "asdf")
      @children[name] = child
      @entries.appendChild(child)
    else
      child = @children[name]

    child

    # set package name if not set yet

  updateFileEntries: (fileName, entries) ->

    for entryName, entryValues of entries
      console.log entryName, entryValues
      if !@children[entryName]?
        child = new EntryElement().initialize(entryName)
        @children[entryName] = child
        @entries.appendChild(child)
      console.log entryValues.children
      @children[entryName].updateFileEntries(fileName, entryValues?.Children)

    for entryName, entryValue of entriesToRemove
      console.log "removing item", entryName, entryValue
      @children[entryName].destroy()
      delete @children[entryName]
  unwatch: ->
    if @watchSubscription?
      @watchSubscription.close()
      @watchSubscription = null
      console.log "cancelling path subscription"
  destroy: ->
    @unwatch


PackageElement = document.registerElement('outline-package', prototype: Package.prototype, extends: 'div')
module.exports = PackageElement
