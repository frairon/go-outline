$ = $$ = fs = _s = Q = _ = null
ResizableView = require './resizable-view'
#TagGenerator = require './tag-generator'

Registry = require './registry'

module.exports =
class OutlineView extends ResizableView
  #@innerContent: ->
  #  @div id: 'outline', class: 'padded', =>
  #    @div outlet: 'tree'

  @content: ->
    @div class: 'tree-view-resizer tool-panel', 'data-show-on-right-side': atom.config.get('tree-view.showOnRightSide'), =>
      @div class: 'tree-view-scroller order--center', outlet: 'scroller', =>
        @div class: '', outlet: 'list'
        #@ol class: 'tree-view full-menu list-tree has-collapsable-children focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'tree-view-resize-handle', outlet: 'resizeHandle'

  initialize: (serializeState) ->
    super serializeState

    @showOnRightSide = atom.config.get('outline.showOnRightSide')
    atom.config.onDidChange 'outline.showOnRightSide', ({newValue}) =>
      @onSideToggled(newValue)

    atom.commands.add 'atom-workspace', 'outline:toggle', => @toggle()
    atom.workspace.onDidChangeActivePaneItem (item) =>
      @onActivePaneChange(item)

    @registry = new Registry(@list[0])

    @visible = localStorage.getItem('outlineStatus') == 'true'
    if @visible
      @show()

    @onActivePaneChange(atom.workspace.getActiveTextEditor())

    @debug = false


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
