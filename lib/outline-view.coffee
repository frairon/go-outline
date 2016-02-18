$ = $$ = fs = _s = Q = _ = null

{$, View, TextEditorView} = require 'atom-space-pen-views'

helpers = require './helpers'
d3 = require 'd3'
path = require 'path'
_ = require 'underscore-plus'


Package = require './package'

{EventsDelegation} = require 'atom-utils'
LocalStorage = window.localStorage
module.exports =
class OutlineView extends View
  EventsDelegation.includeInto(this)

  @content: ->
    @div class: 'outline-tree-resizer tool-panel', 'data-show-on-right-side': atom.config.get('outline.showOnRightSide'), =>
      @div class: 'block', =>
        @div class: 'btn-group', =>
          @div class: "btn icon icon-broadcast inline-block-tight", title: "Show test functions", outlet: 'btnShowTests'
          @div class: "btn icon icon-mirror-private inline-block-tight", title: "Show private symbols", outlet: 'btnShowPrivate'
          @div class: "btn icon icon-alignment-align inline-block-tight", title: "Collapse", outlet: 'btnCollapse'
          @div class: "btn icon icon-alignment-aligned-to inline-block-tight", title: "Expand", outlet: 'btnExpand'
      @subview 'filterEditor', new TextEditorView(mini: true)
      @div class: 'outline-tree-scroller order--center', outlet: 'scroller', =>
        @ol class: 'outline-tree full-menu list-tree has-collapsable-children focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'outline-tree-resize-handle', outlet: 'resizeHandle'

  setSelected: (element, selected) ->
    if selected
      $(element).addClass("selected")
    else
      $(element).removeClass("selected")

  initialize: (serializeState) ->

    @showOnRightSide = atom.config.get('outline.showOnRightSide')
    atom.config.onDidChange 'outline.showOnRightSide', ({newValue}) =>
      @onSideToggled(newValue)

    atom.commands.add 'atom-workspace', 'outline:toggle', => @toggle()
    atom.workspace.onDidChangeActivePaneItem (item) =>
      @onActivePaneChange(item)

    @packages = {}

    @currentPackageDir = null;
    @container = @list[0]

    @showTests = LocalStorage.getItem('outline:show-tests') ? true
    @showPrivate = LocalStorage.getItem('outline:show-private') ? true

    if @showTests
      $(@btnShowTests).addClass("selected")

    if @showPrivate
      $(@btnShowPrivate).addClass("selected")

    @eventView = atom.views.getView(atom.workspace)

    @handleEvents()

    if LocalStorage.getItem('outline:outline-visible') == 'true'
      @show()

    @onActivePaneChange(atom.workspace.getActiveTextEditor())

    @debug = false

    @subscribeTo(@btnShowTests[0], { 'click': (e) =>
      @showTests = !@showTests
      @updatePackageList(@currentPackage())

    })

    @subscribeTo(@btnShowPrivate[0], { 'click': (e) =>
      @showPrivate = !@showPrivate
      @setSelected(@btnShowPrivate, @showPrivate)
      @updatePackageList(@currentPackage())
    })

    @subscribeTo(@btnShowTests[0], { 'click': (e) =>
      @showTests = !@showTests
      @setSelected(@btnShowTests, @showTests)
      @updatePackageList(@currentPackage())
    })

    @subscribeTo(@btnCollapse[0], {'click':(e) =>
      pkg = @currentPackage()
      pkg?.collapse()
      @updatePackageList(pkg)
    })

    @subscribeTo(@btnExpand[0], {'click':(e) =>
      pkg = @currentPackage()
      pkg?.expand()
      @updatePackageList(pkg)
    })

    @filterEditor.getModel().getBuffer().onDidChange =>
      @scheduleTimeout()

    @filterTimeout = null

  scheduleTimeout: ->
    clearTimeout(@filterTimeout)
    @filterTimeout = setTimeout(filterMethod , 250)

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
    removeFile = => @removeCurrentFile(editor.getPath())
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

    LocalStorage.setItem 'outline:outline-visible', @isVisible()
    LocalStorage.setItem 'outline:show-tests', @showTests
    LocalStorage.setItem 'outline:show-private', @showPrivate


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

  onActivePaneChange: (item) ->
    return unless @isVisible()
    return unless @getPath()?.endsWith(".go")

    @showPkgForFile(@getPath())


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


  showPkgForFile:(filePath, @packageUpdated) ->

    pkgDir = helpers.dirname(filePath)
    file = helpers.basename(filePath)

    return unless pkgDir != @currentPackageDir


    # invalid
    if !pkgDir.length || !file.length
      console.log "invalid file location provided", filePath, "..ignoring"
      return

    if !file.endsWith '.go'
      console.log "ignoring non-go-files", filePath
      return

    # if package for folder does not exist, create it
    if !@packages[pkgDir]?
      pkg = new Package(pkgDir)
      pkg.setUpdateCallback(@updatePackageList)

      @packages[pkgDir] = pkg

      pkg.fullReparse()
    else
      @updatePackageList(@packages[pkgDir])

    @currentPackageDir = pkgDir

  currentPackage: ->
    if @currentPackageDir?
      return @packages[@currentPackageDir]
    else
      return null


  updatePackageList: (pkg) =>
    if !pkg?
      console.log "Provided null as package to display. This should not happen"
      return

    outView = @

    jumpToSymbol = (item) ->
      return unless item.fileName?
      options =
        searchAllPanes: true
        initialLine: (item.fileLine-1) if item?.fileLine
        initialColumn:  (item.fileColumn-1) if item?.fileColumn

      if item?.fileName
        atom.workspace.open(item.fileName, options)

    updateIcon = (d)->
      classed =
        'collapsed': !d.expanded
      d3.select(this).classed(classed)

    addEntryIcon = (liItem) ->
      expanderIcon = liItem.append("span")
      expanderIcon.classed("icon", true)
      expanderIcon.classed("icon-file-directory", (d) -> d.type is "package")
      expanderIcon.classed("icon-primitive-square" , (d) -> d.type is "func")
      expanderIcon.classed("icon-link" , (d) -> d.type is "type")
      #expanderIcon.classed("icon-mention" , (d) -> d.type is "variable")
      expanderIcon.classed("status-modified" , (d) -> d.type is "type")
      expanderIcon.classed("status-renamed" , (d) -> d.type is "func")
      expanderIcon.text((d)->d.name)

      expanderIcon.on("click", (d)->
        d3.event.stopPropagation()
        jumpToSymbol(d)

      )

    filterChildren =  (children) =>
      return _.filter(children, (c) =>
        return ((@showTests or c.type is not "func" or not c.name.startsWith("Test")) and
            (@showPrivate or c.name[0].toLowerCase() != c.name[0]))
      )

    createChildren = (selection) ->
      #console.log "creating new children", selection
      item = selection.append('li')
      item.on("click", (d)->
        d.expanded = !d.expanded
        d3.event.stopPropagation()
        updateIcon.apply(this, [d])
        updateExpand()
      )
      # apply initially
      item.each(updateIcon)

      nonLeafs = item.filter((d) -> d.children.length > 0)
      nonLeafs.classed("list-nested-item", true)
      nonLeafContent = nonLeafs.append("div").attr({class:"list-item"})
      addEntryIcon(nonLeafContent)

      leafs = item.filter((d) -> d.children.length == 0)
      leafs.classed("list-item", true)
      addEntryIcon(leafs)


      nonLeafs.each((d) ->
        childList = d3.select(this).append("ol")
        childList.attr({class:'list-tree'})
        childList.selectAll("li").data(filterChildren(d.children), (d)->d.name).enter().call(createChildren)
      )

      updateExpand = ->
        item.each((d)->
          ol = d3.select(this).select("ol")
          classed =
            hidden : !d.expanded
          ol.classed(classed)
        )



    updateChildren = (selection) ->

      #console.log "updating children", selection
      #update text
      item = selection.select("li").select("div").select("span")
      item.text((d)->d.name)

      # select and create new children
      item.each((d)->
        if d.children.length > 0
          childList = d3.select(this).append("ol")
          childList.attr({class:'entries list-tree'})
          childList.selectAll("li").data((d.children), (d)->d.name).enter().call(createChildren)
      )

      # select and (recursively) update children
      children = item.select("ol").selectAll("li").data(((d)->d.children), (d)->d.name)
      if !children.empty()
        children.call(updateChildren)

      # remove superfluous children
      item.each((d)->
        d3.select(this).select("ol")
          .selectAll("li")
          .data((d.children), (d)->d.name).exit().remove()
      )

    # remove all existing
    d3.select(@container).selectAll("li").remove()

    # add all again
    packageRoots = d3.select(@container).selectAll('li').data([pkg], (d)->d.packagepath)
    packageRoots.enter().call(createChildren)
    #packageRoots.call(updateChildren)
    # remove superfluous package trees
    #d3.select(@container).select('li').data([pkg], (d)->d.packagepath).exit().remove()
