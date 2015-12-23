OutlineView = require './outline-view'

module.exports =
  config:
    showOnRightSide:
      type: 'boolean'
      default: true

  outlineView: null

  activate: (state) ->
    @createView()

  createView: ->
    unless @outlineView?
      @outlineView = new OutlineView(@state)
    @outlineView

  deactivate: ->
    @outlineView.destroy()

  serialize: ->
    outlineViewState: @outlineView.serialize()
