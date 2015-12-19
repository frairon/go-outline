$ = $$ = fs = _s = Q = _ = null
ResizableView = require './resizable-view'
#TagGenerator = require './tag-generator'
{$, View} = require 'atom-space-pen-views'
Registry = require './registry'

module.exports =
class OutlineView extends ResizableView
  #@innerContent: ->
  #  @div id: 'outline', class: 'padded', =>
  #    @div outlet: 'tree'

  @content: ->
    @div class: 'outline-tree-resizer tool-panel', 'data-show-on-right-side': atom.config.get('outline.showOnRightSide'), =>
      @div class: 'outline-tree-scroller order--center', outlet: 'scroller', =>
        @div class: '', outlet: 'list'
        #@ol class: 'tree-view full-menu list-tree has-collapsable-children focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'outline-tree-resize-handle', outlet: 'resizeHandle'

  initialize: (serializeState) ->
    super serializeState

    @showOnRightSide = atom.config.get('outline.showOnRightSide')
    atom.config.onDidChange 'outline.showOnRightSide', ({newValue}) =>
      @onSideToggled(newValue)

    atom.commands.add 'atom-workspace', 'outline:toggle', => @toggle()
    atom.workspace.onDidChangeActivePaneItem (item) =>
      @onActivePaneChange(item)

    @handleEvents()

    @registry = new Registry(@list[0])

    @visible = localStorage.getItem('outlineStatus') == 'true'
    if @visible
      @show()

    @onActivePaneChange(atom.workspace.getActiveTextEditor())

    @debug = false

  handleEvents: ->
    @on 'dblclick', '.outline-tree-resize-handle', =>
      @resizeToFitContent()
    @on 'click', '.entry', (e) =>
      # This prevents accidental collapsing when a .entries element is the event target
      return if e.target.classList.contains('entries')

      @entryClicked(e) unless e.shiftKey or e.metaKey or e.ctrlKey
    @on 'mousedown', '.entry', (e) =>
      @onMouseDown(e)
    @on 'mousedown', '.outline-tree-resize-handle', (e) => @resizeStarted(e)
  #  @on 'dragstart', '.entry', (e) => @onDragStart(e)
    #@on 'dragenter', '.entry.directory > .header', (e) => @onDragEnter(e)
    #@on 'dragleave', '.entry.directory > .header', (e) => @onDragLeave(e)
    #@on 'dragover', '.entry', (e) => @onDragOver(e)
    #@on 'drop', '.entry', (e) => @onDrop(e)

  onMouseDown: (e) ->
    e.stopPropagation()

  entryClicked: (e) ->

  resizeToFitContent: ->
    @width(1) # Shrink to measure the minimum width of list
    @width(@list.outerWidth())

  serialize: ->

  destroy: ->
    @detach()
    @editorsSubscription.dispose()

  initEditorSubscriptions: ->
    @editorsSubscription = atom.workspace.observeTextEditors (editor) =>
    refreshFile = => @refreshFile(editor.getPath())
    #removeFile = => @removeCurrentFile(editor.getPath())
    editorSubscriptions = new CompositeDisposable()
    editorSubscriptions.add(editor.onDidSave(refreshFile))
    editorSubscriptions.add(editor.getBuffer().onDidReload(refreshFile))
    #editorSubscriptions.add(editor.getBuffer().onDidDestroy(removeCurrentFile))
    editor.onDidDestroy -> editorSubscriptions.dispose()

  toggle: ->
    if @isVisible()
      @detach()
    else
      @show()

    localStorage.setItem 'outlineStatus', @isVisible()

  show: ->
    @attach()
    @focus()

  attach: ->
    _ ?= require 'underscore-plus'
    return if _.isEmpty(atom.project.getPaths())

    @panel ?=
      if @showOnRightSide
        atom.workspace.addRightPanel(item: this)
      else
        atom.workspace.addLeftPanel(item: this)

  refreshFile: (filePath) ->
    @registry.refreshFile(filePath)

  onActivePaneChange: (item) ->
    if @isVisible()
      @registry.showPkgForFile(@getPath())


  onSideToggled: (newValue) ->
    @closest('.view-resizer')[0].dataset.showOnRightSide = newValue
    @showOnRightSide = newValue
    if @isVisible()
      @detach()
      @attach()


  getPath: ->
    # Get path for currently edited file
    atom.workspace.getActiveTextEditor()?.getPath()


  resizeStarted: =>
    $(document).on('mousemove', @resizeTreeView)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizeTreeView)
    $(document).off('mouseup', @resizeStopped)

  resizeTreeView: ({pageX, which}) =>
    return @resizeStopped() unless which is 1

    if atom.config.get('outline.showOnRightSide')
      width = @outerWidth() + @offset().left - pageX
    else
      width = pageX - @offset().left
    @width(width)

  resizeToFitContent: ->
    @width(1) # Shrink to measure the minimum width of list
    @width(@list.outerWidth())
