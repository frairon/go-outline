
Entry = require './entry'

module.exports = class Package extends Entry
  constructor: (name)->
    super(name)
    @updateEntry({Elemtype:"package"})


  collapse: ->
    # collapse all children, let me expanded
    @expandAll(false)
    @expanded = true

  expand: ->
    @expandAll(true)
