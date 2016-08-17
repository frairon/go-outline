
Entry = require './entry'

_ = require 'underscore-plus'

module.exports = class Package extends Entry
  constructor: (name)->
    super(name)
    @updateEntry({Elemtype:"package"})

    @containingFiles = new Set()

  addFile: (file) ->
    @containingFiles.add(file)

  removeFile: (file) ->
    @containingFiles.delete(file)

  hasFiles: ->
    return @containingFiles.size > 0

  collapse: ->
    # collapse all children, let me expanded
    @expandAll(false)
    @expanded = true

  expand: ->
    @expandAll(true)

  updateChildrenForFile: (children, file) ->
    for name, symbol of children
      symbol.FileName = file
      @updateChild(symbol)

    @removeRemainingChildren(file, children)
