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
      @nav class: 'outline-navbar', =>
        @div class: "btn-group", =>
          @div class: "icon icon-gist-fork", title: "show tree outline", outlet: 'btnShowTree'
          @div class: "icon icon-bug", title: "show test functions", outlet: 'btnShowTests'
          @div class: "icon icon-mention", title: "show variables", outlet: 'btnShowVariables'
          @div class: "icon icon-gist-secret", title: "show private symbols", outlet: 'btnShowPrivate'
          @div class: "icon icon-chevron-up", title: "collapse all", outlet: 'btnCollapse'
          @div class: "icon icon-chevron-down", title: "expand all", outlet: 'btnExpand'
        @div class: "outline-search native-key-bindings", =>
          @input outlet: 'searchField', placeholder:'filter'
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
    @showTree = LocalStorage.getItem("outline:show-tree") ? true

    if @showTests
      $(@btnShowTests).addClass("selected")
    if @showPrivate
      $(@btnShowPrivate).addClass("selected")
    if @showTree
      $(@btnShowTree).addClass("selected")

    @handleEvents()

    if LocalStorage.getItem('outline:outline-visible') == 'true'
      @show()

    @onActivePaneChange(atom.workspace.getActiveTextEditor())

    @subscribeTo(@btnShowTree[0], { 'click': (e) =>
      @showTree = !@showTree
      @setSelected(@btnShowTree, @showTree)
      @updatePackageList(@currentPackage())
    })

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

    @filterText = null;
    @subscribeTo(@searchField[0], {"input": (e) =>
      @filterText = @searchField[0].value
      if !@filterText?.length
        @filterText = null
      @scheduleTimeout()
    })

    @filterTimeout = null


  flatOutline: ->
    return !@showTree or @filterText?

  scheduleTimeout: ->
    clearTimeout(@filterTimeout)
    refreshPackage = => @updatePackageList(@currentPackage())
    @filterTimeout = setTimeout(refreshPackage, 250)

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

  destroy: ->
    @detach()

  toggle: ->
    if @isVisible()
      @detach()
    else
      @show()

    LocalStorage.setItem 'outline:outline-visible', @isVisible()
    LocalStorage.setItem 'outline:show-tests', @showTests
    LocalStorage.setItem 'outline:show-private', @showPrivate
    LocalStorage.setItem 'outline:show-tree', @showTree

  show: ->
    @attach()
    @focus()

  focus: ->
    @contentElement()?.focus()

  detach: ->
    @panel.destroy()
    @panel = null



  attach: ->
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

    console.log("Refreshing package list")
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
      d3.select(this).classed(classed).attr("title", d.getTitle())

    addEntryIcon = (liItem) ->
      expanderIcon = liItem.append("span")
      expanderIcon.classed("icon", true)
      expanderIcon.classed("icon-file-directory", (d) -> d.type is "package")
      expanderIcon.classed("icon-primitive-square" , (d) -> d.type is "func")
      expanderIcon.classed("icon-link" , (d) -> d.type is "type")
      #expanderIcon.classed("icon-mention" , (d) -> d.type is "variable")
      expanderIcon.classed("status-modified" , (d) -> d.type is "type")
      expanderIcon.classed("status-renamed" , (d) -> d.type is "func")
      expanderIcon.text((d)->
        if outView.flatOutline()
          d.getIdentifier()
        else
          d.name
      )

      expanderIcon.on("click", (d)->
        d3.event.stopPropagation()
        jumpToSymbol(d)

      )

    filterChildren =  (children) =>

      return _.filter(children, (c) =>
        if @filterText?
          filterPattern = new RegExp(@filterText.toLowerCase().split("").reduce( (a,b) -> a+'[^'+b+']*'+b ))

        return (
              (@showTests or c.type is not "func" or not c.name.startsWith("Test")) and
              (@showPrivate or c.name[0].toLowerCase() != c.name[0]) and
              (!@filterText or filterPattern.test(c.name.toLowerCase()))
            )
      )



    createChildren = (selection, recurse) ->
      item = selection.append('li')
      item.on("click", (d)->
        d.expanded = !d.expanded
        d3.event.stopPropagation()
        updateIcon.apply(this, [d])
        updateExpand()
      )
      # apply initially
      item.each(updateIcon)


      if !outView.flatOutline() or recurse == 0
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
          data = if outView.flatOutline then filterChildren(d.getChildrenFlat()) else filterChildren(d.children)
          childSelection = childList.selectAll("li").data(data)
          childSelection.enter().call((s) -> createChildren(s, recurse+1))
        )
      else
        item.classed("list-item", true)
        addEntryIcon(item)

      updateExpand = ->
        item.each((d)->
          ol = d3.select(this).select("ol")
          classed =
            hidden : !d.expanded
          ol.classed(classed)
        )

    # remove all existing
    d3.select(@container).selectAll("li").remove()

    # add all again
    packageRoots = d3.select(@container).selectAll('li').data([pkg], (d)->d.packagepath)
    packageRoots.enter().call((c) -> createChildren(c, 0))
