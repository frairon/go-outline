{CompositeDisposable, Emitter} = require 'event-kit'

_ = require 'underscore-plus'
module.exports = class Entry

  constructor: (@name)->
    @parentIndex = -> 100
    @children = []

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
    return _.some(@children, (child)=>child.name==name)

  getChild: (name) ->
    return _.find(@children, (child) => child.name == name)

  addChild: (name, child) ->
    @children.push child
    child.parentIndex = =>
      _.findIndex(@children, (child) => child.name == name)
    @children = _.sortBy(@children, (child) => child.name.toLowerCase())

  removeChild: (name) ->
    index = _.findIndex(@children, (child) => child.name == name)
    @children.splice(index, 1)

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
