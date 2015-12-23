path = require 'path'
_ = require 'underscore-plus'
# {CompositeDisposable, Emitter} = require 'event-kit'

#PathWatcher = require 'pathwatcher'
#File = require './file'
# {repoForPath} = require './helpers'
#realpathCache = {}


class Entry extends HTMLElement
  initialize:(entryName) ->

    @header = document.createElement("div")
    @header.classList.add("header", "list-item")
    @textNode = document.createTextNode(entryName)
    content = document.createElement("span")
    content.classList.add("name", "icon")
    content.appendChild(@textNode)
    @header.appendChild(content)
    @appendChild(@header)

    @classList.add('entry', 'list-nested-item')

    @entries = document.createElement('ol')
    @entries.classList.add('entries', 'list-tree', 'collapsed')
    @appendChild(@entries)
    @children = {}

    @FileName = ""
    @Name = entryName

    this

  updateEntry:(entryData) ->
    @textNode.nodeValue = entryData.Name
    @Name = entryData.Name
    @FileName = entryData.FileName

  updateChild:(child)->
    @getOrCreateChild(child.Name).updateEntry(child)

  getOrCreateChild: (name) ->
    if !@children[name]?
      child = new EntryElement().initialize(name)
      @children[name] = child
      @entries.appendChild(child)
    else
      child = @children[name]

    child

  removeForFile: (fileName, removeNames) ->
    for name, child of @children
      child.removeForFile(fileName, removeNames)

      if child.FileName == fileName && name in removeNames && _.keys(child.children).length == 0
        child.remove()
        delete @children[name]

EntryElement = document.registerElement('outline-entry', prototype: Entry.prototype, extends: 'li')
module.exports = EntryElement
