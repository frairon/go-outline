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
    viewMode:
      type: 'string'
      default: 'file'
      description: "Display the whole package or just the current file"
      enum: ['package', 'file']
    showTree:
      type: 'boolean'
      default: true
    showOnRightSide:
      type: 'boolean'
      default: true
    linkFile:
      type: 'boolean'
      default: true
      description: 'When disabled, the outline is not synchronized with the active file'
    parserExecutable:
      type: 'string'
      default: 'go-outline-parser'

  goOutlineView: null

  activate: (state) ->
    @createView()

  createView: ->
    unless @goOutlineView?
      @goOutlineView = new GoOutlineView(@state)
    @goOutlineView

  deactivate: ->
    @goOutlineView.destroy()
    @goOutlineView = null
