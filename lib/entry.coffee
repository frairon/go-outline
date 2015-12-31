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
      @getOrCreateChild(child.Receiver).getOrCreateChild(child.Name).updateEntry(child)
    else
      @getOrCreateChild(child.Name).updateEntry(child)

  getOrCreateChild: (name) ->
    if !@hasChild(name)
      @addChild(name, new Entry(name))

    @getChild(name)

  hasChild: (name) ->
    return name in @childNames

  getChild: (name) ->
    if @hasChild name
      return @children[@childNames.indexOf name]

  addChild: (name, child) ->
    @children.push child
    @childNames.push name
    child.parentIndex = =>
      @childNames.indexOf child.name

    @emitter.emit('did-add-children', [child])

  setView: (@view) ->

  removeChild: (childName) ->
    index = @childNames.indexOf childName
    child = @children[index]

    @children.splice(index, 1)
    @childNames.splice(index, 1)
    child?.view?.remove()

  updateEntry: (data)->

    @name = data?.Name
    @fileName = data?.FileName
    @fileLine = data?.Line
    @fileColumn = data?.Column
    @isPublic = data?.Public
    @type = data?.ElemType
    @emitter.emit("did-change")

  removeRemainingChildren: (fileName, existingChildNames) ->
    i=0
    while i < @children.length
      child = @children[i]
      r = child.removeRemainingChildren(fileName, existingChildNames)

      # child is of the file, the child's name is not in the new list and it does not have any children itself
      # so we'll remove it.
      if child.fileName == fileName and child.name not in existingChildNames and child.children.length == 0
        @removeChild(child.name)
        continue
      i+= 1

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
