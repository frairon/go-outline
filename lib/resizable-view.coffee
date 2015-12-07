{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

module.exports =
class ResizableView extends View
  @content: ->
    @div class: 'view-resizer tool-panel', 'data-show-on-right-side': @showOnRightSide, =>
      @div class: 'view-scroller', outlet: 'scroller', =>
        @innerContent()
      @div class: 'view-resize-handle', outlet: 'resizeHandle'

  initialize: (state) ->
    @disposables = new CompositeDisposable

    @handleEvents()

  detached: ->
    @resizeStopped()

  deactivate: ->
    @disposables.dispose()

  handleEvents: ->
    @on 'dblclick', '.view-resize-handle', =>
      @resizeToFitContent()

    @on 'mousedown', '.view-resize-handle', (e) => @resizeStarted(e)

  resizeStarted: =>
    $(document).on('mousemove', @resizeView)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizeView)
    $(document).off('mouseup', @resizeStopped)

  resizeView: ({pageX, which}) =>
    return @resizeStopped() unless which is 1

    if @showOnRightSide
      width = $(document.body).width() - pageX
    else
      width = pageX
    @width(width)

  resizeToFitContent: ->
    @width(1) # Shrink to measure the minimum width of list
    @width(@scroller.find('>').outerWidth())
