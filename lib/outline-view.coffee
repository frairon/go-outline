$ = $$ = fs = _s = Q = _ = null

{$, View} = require 'atom-space-pen-views'
Registry = require './registry'
{EventsDelegation} = require 'atom-utils'
LocalStorage = window.localStorage
module.exports =
class OutlineView extends View
  EventsDelegation.includeInto(this)

  @content: ->
    @div class: 'outline-tree-resizer tool-panel', 'data-show-on-right-side': atom.config.get('outline.showOnRightSide'), =>
      @div class: 'outline-tree-scroller order--center', outlet: 'scroller', =>
        @div class: 'block', =>
          @div class: 'btn-group', =>
            @div class: "btn icon icon-broadcast inline-block-tight", title: "Show test functions", outlet: 'btnShowTests'
            @div class: "btn icon icon-mirror-private inline-block-tight", title: "Show private symbols", outlet: 'btnShowPrivate'
        @ol class: 'outline-tree full-menu list-tree has-collapsable-children focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'outline-tree-resize-handle', outlet: 'resizeHandle'

  initialize: (serializeState) ->

    @showOnRightSide = atom.config.get('outline.showOnRightSide')
    atom.config.onDidChange 'outline.showOnRightSide', ({newValue}) =>
      @onSideToggled(newValue)

    atom.commands.add 'atom-workspace', 'outline:toggle', => @toggle()
    atom.workspace.onDidChangeActivePaneItem (item) =>
      @onActivePaneChange(item)


    @eventView = atom.views.getView(atom.workspace)

    @handleEvents()
    @registry = new Registry(@list[0])

    if LocalStorage.getItem('outline:outline-visible') == 'true'
      @show()

    @onActivePaneChange(atom.workspace.getActiveTextEditor())

    @debug = false

    @subscribeTo(@btnShowTests[0], { 'click': (e) ->
      console.log "show tests button clicked"
    })

    @subscribeTo(@btnShowPrivate[0], { 'click': (e) ->
      console.log "show private button clicked"
    })

  handleEvents: ->
    @on 'dblclick', '.outline-tree-resize-handle', =>
      @resizeToFitContent()
    @on 'mousedown', '.entry', (e) =>
      @onMouseDown(e)
    @on 'mousedown', '.outline-tree-resize-handle', (e) => @resizeStarted(e)

  onMouseDown: (e) ->
    e.stopPropagation()

  resizeToFitContent: ->
    @width(1) # Shrink to measure the minimum width of list
    @width(@contentElement()?.outerWidth())

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
    console.log "toggling", @isVisible
    console.log "my style", this[0].style
    if @isVisible()
      @detach()
    else
      @show()
      console.log "It's visible now", @isVisible()

    LocalStorage.setItem 'outline:outline-visible', @isVisible()

  show: ->
    @attach()
    @focus()

  focus: ->
    @contentElement()?.focus()

  detach: ->
    @panel.destroy()
    @panel = null



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
    return unless @isVisible()
    return unless @getPath()?.endsWith(".go")

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
    @width(@contentElement()?.outerWidth())

  contentElement: ->
    return $(@scroller[0].firstChild)
