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
    console.log "get or create child", name, "at", @name
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


  updateEntry: (data)->

    @name = data?.Name
    @fileName = data?.FileName
    @fileLine = data?.Line
    @isPublic = data?.Public
    @type = data?.ElemType
    @emitter.emit("did-change")

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
