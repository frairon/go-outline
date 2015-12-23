path = require 'path'
fs = require 'fs'
_ = require 'underscore-plus'

{CompositeDisposable} = require 'event-kit'
{BufferedProcess} = require 'atom'

PathWatcher = require 'pathwatcher'

helpers = require './helpers'

class EntryView extends HTMLElement

  initialize: (@entry) ->
    @subscriptions = new CompositeDisposable()
    @subscribeToEntry()

    @entry.name
    @classList.add('entry',  'list-tree', 'outline-tree', 'collapsed')#,  'collapsed')
    @header = document.createElement('div')
    @nameElem = document.createElement('span')
    @nameElem.classList.add('name', 'icon')
    @nameElem.title = @entry.name
    @nameTextNode = document.createTextNode(@entry.name)
    @nameElem.appendChild(@nameTextNode)
    @header.appendChild(@nameElem)

    @appendChild(@header)

    @entries = document.createElement('ol')
    @entries.classList.add('entries', 'list-tree')
    @appendChild(@entries)


  subscribeToEntry: ->

    @subscriptions.add @entry.onDidDestroy => @subscriptions.dispose()
    @subscriptions.add @entrx.onDidChange(@onChanged)
    @subscriptions.add @entry.onDidAddChildren(@onChildrenAdded)
    @subscriptions.add @entry.onDidRemoveChildren(@onChildrenRemoved)


  onChildrenRemoved: (removedChildren)->

  onChanged:->
    @nameTextNode.nodeValue = @entry.name
    @nameElem.title = @entry.name

  onChildrenAdded: (addedChildren) ->
    #return unless @isExpanded

    for entry in addedChildren
      numberOfEntries = @entries.children.length
      view = new EntryView()
      entry = new Entry(entry.name)
      view.initialize(entry)
      insertionIndex = entry.parentIndex()
      if insertionIndex < numberOfEntries
        @entries.insertBefore(view, @entries.children[insertionIndex])
      else
        @entries.appendChild(view)

module.exports = document.registerElement('outline-package', prototype: EntryView.prototype, extends: 'div')
