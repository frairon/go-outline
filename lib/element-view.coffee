{CompositeDisposable} = require 'event-kit'


class ElementView extends HTMLElement
  initialize: (element) ->
    @subscriptions = new CompositeDisposable()
    @subscriptions.add @element.onDidDestroy => @subscriptions.dispose()
    @subscribeToDirectory()


    @classList.add('directory', 'entry',  'list-nested-item',  'collapsed')

    @header = document.createElement('div')
    @header.classList.add('header', 'list-item')

    @name = document.createElement('span')
    @name.classList.add('name', 'icon')

    @children = document.createElement('ol')
    @children.classList.add('entries', 'list-tree')

    @name.classList.add(iconClass)

    @package

    directoryNameTextNode = document.createTextNode(@directory.name)

    @appendChild(@header)
    @name.appendChild(directoryNameTextNode)
    @header.appendChild(@directoryName)
    @appendChild(@children)

    @expand() if @element.expansionState.isExpanded

  updateStatus: ->
    @classList.remove('status-ignored', 'status-modified', 'status-added')
    @classList.add("status-#{@directory.status}") if @directory.status?

  subscribeToDirectory: ->
    @subscriptions.add @directory.onDidAddEntries (addedEntries) =>
      return unless @isExpanded

      numberOfEntries = @entries.children.length

      for entry in addedEntries
        view = @createViewForEntry(entry)

        insertionIndex = entry.indexInParentDirectory
        if insertionIndex < numberOfEntries
          @entries.insertBefore(view, @entries.children[insertionIndex])
        else
          @entries.appendChild(view)

        numberOfEntries++

  getPath: ->
    @directory.path

  isPathEqual: (pathToCompare) ->
    @directory.isPathEqual(pathToCompare)

  createViewForEntry: (entry) ->
    if entry instanceof Directory
      view = new DirectoryElement()
    else
      view = new FileView()
    view.initialize(entry)

    subscription = @directory.onDidRemoveEntries (removedEntries) ->
      for removedName, removedEntry of removedEntries when entry is removedEntry
        view.remove()
        subscription.dispose()
        break
    @subscriptions.add(subscription)

    view

  reload: ->
    @directory.reload() if @isExpanded

  toggleExpansion: (isRecursive=false) ->
    if @isExpanded then @collapse(isRecursive) else @expand(isRecursive)

  expand: (isRecursive=false) ->
    unless @isExpanded
      @isExpanded = true
      @classList.add('expanded')
      @classList.remove('collapsed')
      @directory.expand()

    if isRecursive
      for entry in @entries.children when entry instanceof DirectoryView
        entry.expand(true)

    false

  collapse: (isRecursive=false) ->
    @isExpanded = false

    if isRecursive
      for entry in @entries.children when entry.isExpanded
        entry.collapse(true)

    @classList.remove('expanded')
    @classList.add('collapsed')
    @directory.collapse()
    @entries.innerHTML = ''

DirectoryElement = document.registerElement('tree-view-directory', prototype: DirectoryView.prototype, extends: 'li')
module.exports = DirectoryElement
