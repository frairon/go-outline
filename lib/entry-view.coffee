path = require 'path'
fs = require 'fs'
_ = require 'underscore-plus'

{CompositeDisposable} = require 'event-kit'
{BufferedProcess} = require 'atom'

PathWatcher = require 'pathwatcher'

helpers = require './helpers'

class EntryViewClass extends HTMLElement

  initialize: (@entry) ->
    @subscriptions = new CompositeDisposable()
    @subscribeToEntry()

    @classList.add('entry',  'list-nested-item', 'outline-tree', 'collapsed')#,  'collapsed')
    @header = document.createElement('div')
    @nameElem = document.createElement('span')
    @nameElem.classList.add('name', 'icon', 'icon-plus')
    @nameElem.title = @entry.name
    @nameTextNode = document.createTextNode(@entry.name)
    @nameElem.appendChild(@nameTextNode)
    @header.appendChild(@nameElem)

    @appendChild(@header)

    @entries = document.createElement('ol')
    @entries.classList.add('entries', 'list-tree')
    @appendChild(@entries)

    console.log "view initialized"
  subscribeToEntry: ->
    @subscriptions.add @entry.onDidDestroy => @subscriptions.dispose()
    @subscriptions.add @entry.onDidChange =>
      console.log "entry changed", @entry.name
      @nameTextNode.nodeValue = @entry.name
      @nameElem.title = @entry.name
    @subscriptions.add @entry.onDidAddChildren (addedChildren) =>
      #return unless @isExpanded
      for entry in addedChildren
        console.log "adding children", entry
        numberOfEntries = @entries.children.length
        view = new EntryView()
        view.initialize(entry)
        insertionIndex = entry.parentIndex()
        console.log "insert entry at index", insertionIndex
        if insertionIndex < numberOfEntries
          @entries.insertBefore(view, @entries.children[insertionIndex])
        else
          @entries.appendChild(view)

    @subscriptions.add @entry.onDidRemoveChildren (removedChildren)=>
      console.log "children removed"

EntryView = document.registerElement('outline-package', prototype: EntryViewClass.prototype, extends: 'li')
module.exports = EntryView
