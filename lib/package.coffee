
Entry = require './entry'

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
