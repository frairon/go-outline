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
    text = document.createTextNode(entryName)
    content = document.createElement("span")
    content.classList.add("name", "icon")
    content.appendChild(text)
    @header.appendChild(content)
    @appendChild(@header)

    @classList.add('entry', 'list-nested-item')

    @entries = document.createElement('ol')
    @entries.classList.add('entries', 'list-tree', 'collapsed')
    @appendChild(@entries)
    @children = {}

    this

  updateFileEntries:(fileName, entryData) ->

    for entryName, entryValues of entryData

      if !@children[entryName]?
        child = new EntryElement().initialize(entryName)
        @children[entryName] = child
        @entries.appendChild(child)

      @children[entryName].updateFileEntries(fileName, entryValues?.children)


EntryElement = document.registerElement('outline-entry', prototype: Entry.prototype, extends: 'li')
module.exports = EntryElement
