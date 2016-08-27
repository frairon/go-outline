{basename} = require './helpers'
_ = require 'underscore-plus'
module.exports = class Entry

  constructor: (@name)->
    @children = []

    @type =null
    @fileDef = null
    @filesUsage = new Set()
    @fileLine = -1
    @fileColumn = -1
    @isPublic = false

    @expanded = true

    @parent = null


  getNameAsParent: ->
    return @name

  getIdentifier: ->

    identifier = @name
    parentName = @parent?.getNameAsParent()
    if parentName? and @parent.type != 'package'
      identifier = parentName + "::" + identifier

    return identifier


  getTitle: ->
    if @fileDef? and @fileLine?
      basename(@fileDef)+":"+@fileLine

    if @isImplicitParent()
      @name + " (definition not found)"
    else
      @name

  updateChild: (child) ->

    # if entry has a receiver
    if child?.Receiver?
      receiver = @getOrCreateChild(child.Receiver)
      receiver.getOrCreateChild(child.Name).updateEntry(child)
    else
      @getOrCreateChild(child.Name).updateEntry(child)

  getOrCreateChild: (name) ->
    child = @getChild(name)
    if !child?
      child = @addChild(name, new Entry(name))

    return child

  sorter:(children) ->
    sortedChildren = children.slice(0)

    sortedChildren.sort((l,r) ->
      typeDiff = l.getTypeRank() - r.getTypeRank()
      if typeDiff isnt 0
        return typeDiff

      return l.name.localeCompare(r.name)
    )

    return sortedChildren

  isTestEntry: ->
    suffix = 'test.go'
    return @fileDef? and @fileDef.length != suffix.length and @fileDef.endsWith('test.go')

  sortChildren: ->
    @children = @sorter(@children)

    _.each(@children, (c) -> c.sortChildren(true))


  # returns all children recursively.
  getChildrenFlat: ->
    flatChildren = _.flatten([@children, _.map(@children, (c) -> c.getChildrenFlat())])
    return @sorter(flatChildren)

  hasChild: (name) ->
    return _.some(@children, (child) => child.name is name)

  getChild: (name) ->
    return _.find(@children, (child) => child.name is name)

  addChild: (name, child) ->
    @children.push child
    child.parent = @

    return child

  hasChildren: ->
    return @children.length > 0

  removeChild: (name) ->
    @children = _.filter(@children, (c) -> c.name isnt name)

  expandAll: (expanded) ->
    @expanded = expanded
    _.each(@children, (c) -> c.expandAll(expanded))

  updateEntry: (data)->
    if data.Name?
      @name = data.Name
    if data.FileName?
      @fileDef = data.FileName
    if data.Line?
      @fileLine = data.Line
    if data.Column?
      @fileColumn = data.Column
    if data.Public?
      @isPublic = data.Public
    if data.Elemtype?
      @type = data.Elemtype

  getTypeRank: ->
    switch @type
      when "variable" then 0
      when "type" then 1
      when "func" then 2

  usageFiles: ->
    return _.pluck(@children, "fileDef").length

  removeRemainingChildren: (fileName, existingChildren) ->
    i=0

    # filter the existing children for the children that are assigned to me.
    # I don't have a parent, that means I'm a package
    if !@parent?
      # so my children don't have a receiver
      myChildFilter = (c) => !c.Receiver? and c.FileName == fileName
    else
      # otherwise I must be their receiver
      myChildFilter = (c) => c.Receiver == @name and c.FileName == fileName

    myChildren = _.pluck(_.filter(existingChildren, myChildFilter), 'Name')

    while i < @children.length
      child = @children[i]
      child.removeRemainingChildren(fileName, existingChildren)

      # the child was defined in this file, but is not anymore and doesn't have any children.
      if child.fileDef==fileName and child.name not in myChildren
        if !child.hasChildren()
          @removeChild(child.name)
          continue
        else # it still has children, so let's remove the definition
          # since we couldn't delete it we'll remove the fileDef
          child.fileDef = null

      # in case it was an implicit parent (e.g. after renaming), but now all the children are gone,
      # finally remove it now too.
      if !child.fileDef? and child.children.length == 0
        @removeChild(child.name)
        continue

      i+= 1

  isImplicitParent: ->
    @hasChildren() and !@fileDef?
