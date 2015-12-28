{CompositeDisposable, Emitter} = require 'event-kit'

EntryView = require './entry-view'

module.exports = class Entry

  constructor: (@name)->
    @emitter = new Emitter()
    @subscriptions = new CompositeDisposable()
    @parentIndex = -> 100
    @children = []
    @childNames = []

    @type ="unkown"
    @fileName = "unknown"
    @fileLine = -1
    @isPublic = false


  updateChild: (child) ->

    # if entry has a receiver
    if child?.Receiver?
      console.log "updating child", child.Name, child.Receiver
      @getOrCreateChild(child.Receiver).getOrCreateChild(child.Name).updateEntry(child)
    else
      @getOrCreateChild(child.Name).updateEntry(child)

  getOrCreateChild: (name) ->
    console.log "get or create child", name, "at", @name, @childNames
    if !@hasChild(name)
      @addChild(name, new Entry(name))

    @getChild(name)

  hasChild: (name) ->
    return name in @childNames

  getChild: (name) ->
    if @hasChild name
      return @children[@childNames.indexOf name]

  addChild: (name, child) ->
    console.log "add child", name, "to", @name
    @children.push child
    @childNames.push name
    child.parentIndex = =>
      @childNames.indexOf child.name

    @emitter.emit('did-add-children', [child])

  setView: (@view) ->

  removeChild: (childName) ->
    index = @childNames.indexOf childName
    child = @children[index]

    @children.splice(index)
    @childNames.splice(index)
    #@emitter.emit('did-remove-children', [child])
    child.view.remove()

  updateEntry: (data)->

    @name = data?.Name
    @fileName = data?.FileName
    @fileLine = data?.Line
    @isPublic = data?.Public
    @type = data?.ElemType
    @emitter.emit("did-change")

  removeRemainingChildren: (fileName, existingChildNames) ->
    console.log "remove remaining", fileName, existingChildNames, @childNames
    removed = 0
    i=0
    while i < @children.length
      child = @children[i]
      r = child.removeRemainingChildren(fileName, existingChildNames)

      # child is of the file, the child's name is not in the new list and it does not have any children itself
      # so we'll remove it.
      if child.fileName == fileName and child.name not in existingChildNames and child.children.length == 0
        @removeChild(child.name)
        console.log "removing child", child.name, "as it is not in the exsting child names list"
        removed += 1
        continue

      i+= 1
    return removed


  onDidDestroy: (callback)->
    @emitter.on('did-destroy', callback)

  onDidChange: (callback) ->
    @emitter.on('did-change', callback)

  onDidRemoveChildren: (callback)->
    @emitter.on('did-remove-children', callback)

  onDidAddChildren: (callback)->
    @emitter.on('did-add-children', callback)

  onDidRemoveChildren: (callback) ->
    @emitter.on('did-remove-children', callback)
