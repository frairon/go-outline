GoOutlineView = require './go-outline-view'

module.exports =
  config:
    showOnRightSide:
      type: 'boolean'
      default: true

  goOutlineView: null

  activate: (state) ->
    @createView()

  createView: ->
    unless @goOutlineView?
      @goOutlineView = new GoOutlineView(@state)
    @goOutlineView

  deactivate: ->
    @goOutlineView.destroy()
