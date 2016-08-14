GoOutlineView = require './go-outline-view'

module.exports =
  config:
    showTests:
      type: 'boolean'
      default: true
    showPrivates:
      type: 'boolean'
      default: true
    showVariables:
      type: 'boolean'
      default: true
    currentView:
      type: 'string'
      default: 'file'
    showTree:
      type: 'boolean'
      default: true
    showOnRightSide:
      type: 'boolean'
      default: true
    linkFile:
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
