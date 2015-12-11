path = require 'path'
_ = require 'underscore-plus'
# {CompositeDisposable, Emitter} = require 'event-kit'

#PathWatcher = require 'pathwatcher'
#File = require './file'
# {repoForPath} = require './helpers'
#realpathCache = {}


class Entry extends HTMLElement
  initialize:(entryName) ->
    text = document.createTextNode(entryName)
    content = document.createElement("span")
    content.appendChild(text)
    @appendChild(content)
    @classList.add('entry', 'list-item')

    @entries = document.createElement('ol')
    @entries.classList.add('entries', 'list-tree')
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
