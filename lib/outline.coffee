OutlineView = require './outline-view'

module.exports =
  config:
    showOnRightSide:
      type: 'boolean'
      default: true

  outlineView: null

  activate: (state) ->
    @outlineView = new OutlineView \
      state.outlineViewState

  deactivate: ->
    @outlineView.destroy()

  serialize: ->
    outlineViewState: @outlineView.serialize()
