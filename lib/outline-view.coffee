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

    @fileWatcher = null


  serialize: ->

  destroy: ->
    @detach()
    @fileWatcher?.dispose()

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

  detach: ->
    @panel.destroy()
    @panel = null

  onSideToggled: (newValue) ->
    @closest('.view-resizer')[0].dataset.showOnRightSide = newValue
    @showOnRightSide = newValue
    if @isVisible()
      @detach()
      @attach()

  onActivePaneChange: (item) ->
    if @isVisible()
      @parseCurrentFile()
      @fileWatcher?.dispose()
      @fileWatcher = item?.onDidSave? =>
        @parseCurrentFile()

  getPath: ->
    # Get path for currently edited file
    atom.workspace.getActiveTextEditor()?.getPath()

  getScopeName: ->
    # Get grammar scope name
    atom.workspace.getActiveTextEditor()?.getGrammar()?.scopeName

  log: ->
    if @debug
      console.log arguments


  realParseCurrentFile: ->
    # packageRegex = /^[\s]*package[\s]+([\w-_]+)/
    # buffer = atom.workspace.getActiveTextEditor().getBuffer()
    #
    # for i in [0..buffer.getLineCount()]
    #   packageMatch = packageRegex.exec buffer.lineForRow(i)
    #   if packageMatch
    #     @registry.packageForName(@getPath())
    #     console.log(packageMatch)
    #     console.log("package is", packageMatch[1])
    #     break

    fileInfo =
      package: @getPath().replace(/^.*[\\\/]/, '')
      filePath: @getPath()
      entries:
        typeX:
          {}

    fileInfo

  parseCurrentFile: ->
    _s ?= require 'underscore.string'
    $ ?= require('atom-space-pen-views').$
    $$ ?= require('atom-space-pen-views').$$

    console.log "parsing new file", @getPath(),  @getScopeName()

    #pkg = @registry.packageForName("asdf", @getPath())

    fileInfo = @realParseCurrentFile()
    @registry.displayPackage(fileInfo["package"])
    @registry.packageForName(fileInfo["package"]).updateFileEntries(fileInfo)

    return

    scrollTop = @scroller.scrollTop()
    @tree.empty()

    if _s.endsWith(@getPath(), '.coffee')
      console.log "hello world"
      new TagGenerator(@getPath(), @getScopeName()).generate().done (tags) =>
        lastIdentation = -1
        for tag in tags
          if tag.identation > lastIdentation
            root = if @tree.find('li:last').length then @tree.find('li:last') else @tree
            root.append $$ ->
              @ul class: 'list-tree'
            root = root.find('ul:last')
          else if tag.identation == lastIdentation
            root = @tree.find('li:last')
          else
            root = @tree.find('li[data-identation='+tag.identation+']:last').parent()

          icon = ''
          switch tag.kind
            when 'function' then icon = 'icon-unbound'
            when 'function-bind' then icon = 'icon-bound'
            when 'class' then icon = 'icon-class'

          if _s.startsWith(tag.name, '@')
            tag.name = tag.name.slice(1)
            if tag.kind == 'function'
              icon += '-static'
          else if tag.name == 'module.exports'
            icon = 'icon-package'

          root.append $$ ->
              @li class: 'list-nested-item', 'data-identation': tag.identation, =>
                @div class: 'list-item', =>
                  @a
                    class: 'icon ' + icon
                    "data-line": tag.position.row
                    "data-column": tag.position.column, tag.name

          lastIdentation = tag.identation

        @scroller.scrollTop(scrollTop)


        @tree.find('a').on 'click', (el) ->
          line = parseInt($(@).attr 'data-line')
          column = parseInt($(@).attr 'data-column')
          editor = atom.workspace.getActiveTextEditor()

          editor.setCursorBufferPosition [line, column]
          firstRow = editor.getFirstVisibleScreenRow()
          editor.scrollToBufferPosition [line + (line - firstRow) - 1, column]

  onChange: =>
    @parseCurrentFile()
