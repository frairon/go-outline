{CompositeDisposable, Emitter} = require 'event-kit'

module.exports = class Entry

  constructor: (@name)->
    @parentIndex = -> 100
    @children = []
    @childNames = []

    @type =null
    @fileName = null
    @fileLine = -1
    @fileColumn = -1
    @isPublic = false

    @expanded = true


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

  removeChild: (childName) ->
    index = @childNames.indexOf childName
    child = @children[index]

    @children.splice(index, 1)
    @childNames.splice(index, 1)

  updateEntry: (data)->

    if data.Name?
      @name = data.Name
    if data.FileName?
      @fileName = data.FileName
    if data.Line?
      @fileLine = data.Line
    if data.Column?
      @fileColumn = data.Column
    if data.Public?
      @isPublic = data.Public
    if data.Elemtype?
      @type = data.Elemtype

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
