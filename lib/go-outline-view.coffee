$ = $$ = fs = _s = Q = _ = null

{$, View, TextEditorView} = require 'atom-space-pen-views'

helpers = require './helpers'
d3 = require 'd3'
path = require 'path'
_ = require 'underscore-plus'

Folder = require './folder'

{EventsDelegation} = require 'atom-utils'
LocalStorage = window.localStorage
module.exports =
class GoOutlineView extends View
  EventsDelegation.includeInto(this)

  @content: ->
    @div class: 'go-outline-tree-resizer tool-panel', 'data-show-on-right-side': atom.config.get('go-outline.showOnRightSide'), =>
      @nav class: 'go-outline-navbar', =>
        @div =>
          @span outlet: 'bdgErrors'
        @div class: "btn-group", =>
          @div class: "icon icon-mention", title: "show variables", outlet: 'btnShowVariables'
          @div class: "icon icon-gist-secret", title: "show private symbols", outlet: 'btnShowPrivate'
          @div class: "icon icon-bug", title: "show test functions", outlet: 'btnShowTests'
          @div class: "icon", " "
          @div class: "icon icon-gist-fork", title: "show tree go-outline", outlet: 'btnShowTree'
          @div class: "icon icon-link", title: "link go-outline with tree view", outlet: 'btnLinkFile'
          @div class: "icon icon-chevron-up", title: "collapse all", outlet: 'btnCollapse'
          @div class: "icon icon-chevron-down", title: "expand all", outlet: 'btnExpand'
        @div class: "go-outline-search", =>
          @subview 'searchField', new TextEditorView({mini: true, placeholderText:"filter"})
          @div class: "icon icon-x", outlet: 'btnResetFilter'
      @div class: 'go-outline-tree-scroller order--center', outlet: 'scroller', =>
        @ol class: 'go-outline-tree full-menu list-tree has-collapsable-children focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'go-outline-tree-resize-handle', outlet: 'resizeHandle'

  setSelected: (element, selected) ->
    if selected
      $(element).addClass("selected")
    else
      $(element).removeClass("selected")

  initialize: (serializeState) ->

    @showOnRightSide = atom.config.get('go-outline.showOnRightSide')
    atom.config.onDidChange 'go-outline.showOnRightSide', ({newValue}) =>
      @onSideToggled(newValue)

    atom.commands.add 'atom-workspace', 'go-outline:toggle', => @toggle()
    atom.commands.add 'atom-workspace', 'go-outline:focus-filter', => @focusFilter()
    atom.workspace.onDidChangeActivePaneItem (item) =>
      @onActivePaneChange(item)

    @folders = {}

    @currentDir = null;
    @container = @list[0]

    @parserStatus=
      isDone:true
      failedFiles:[]

    @filterTimeout = null
    @initializeButtons()
    @handleEvents()

  setParserStatus: (allFiles=[], doneFiles=[], failedFiles=[]) =>
    # updates the parser status indicator badge
    # @param all: list/set of all files being parsed
    # @param doneFiles: list/set of all files where parsing is done
    # @param status: busy, success, failure
    # @param failedFiles: list of strings of files where parser failed
    allFiles = new Set(allFiles)
    doneFiles = new Set(doneFiles)
    failedFiles = new Set(failedFiles)

    isDone = (failedFiles.size + doneFiles.size) >= allFiles.size

    element = $(@bdgErrors)
    element.removeClass()
    if failedFiles.size > 0
      element.addClass('text-error')
      element.text(failedFiles.size + ' error(s)')
    else
      if !isDone
        element.text('processing...')
      else
        element.text('')

    @parserStatus.failedFiles = Array.from(failedFiles)
    @parserStatus.failedFiles.sort()
    @parserStatus.isDone=isDone


  parserStatusTooltip: =>
    if @parserStatus.failedFiles.length > 0
      start =  "<div class='tooltip-arrow'></div>
    <div class='tooltip-inner'>"
      end = "</div>"

      return start + @parserStatus.failedFiles.map((l) -> 'Parsing failed for '+l).join('<br>') + end

  initializeButtons: ->
    @showTests = atom.config.get('go-outline.showTests')
    @showPrivate = atom.config.get('go-outline.showPrivates')
    @showVariables = atom.config.get('go-outline.showVariables')
    @showTree = atom.config.get('go-outline.showTree')
    @linkFile = atom.config.get('go-outline.linkFile')

    @setSelected(@btnShowVariables, @showVariables)
    @setSelected(@btnShowTests, @showTests)
    @setSelected(@btnShowPrivate, @showPrivate)
    @setSelected(@btnShowTree, @showTree)
    @setSelected(@btnCollapse, @showTree)
    @setSelected(@btnExpand, @showTree)
    @setSelected(@btnLinkFile, @linkFile)

    atom.tooltips.add(@bdgErrors, {title:@parserStatusTooltip})

    @subscribeTo(@btnShowTree[0], { 'click': (e) =>
      @showTree = !@showTree
      @setSelected(@btnShowTree, @showTree)
      @setSelected(@btnCollapse, @showTree)
      @setSelected(@btnExpand, @showTree)
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@btnShowPrivate[0], { 'click': (e) =>
      @showPrivate = !@showPrivate
      @setSelected(@btnShowPrivate, @showPrivate)
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@btnShowTests[0], { 'click': (e) =>
      @showTests = !@showTests
      @setSelected(@btnShowTests, @showTests)
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@btnShowVariables[0], { 'click': (e) =>
      @showVariables = !@showVariables
      @setSelected(@btnShowVariables, @showVariables)
      @updateSymbolList(@currentFolder())
    })

    @subscribeTo(@btnCollapse[0], {'click':(e) =>
      folder = @currentFolder()
      if folder?
        folder.collapsePackages()
        @updateSymbolList(folder)
    })

    @subscribeTo(@btnExpand[0], {'click':(e) =>
      folder = @currentFolder()
      if folder?
        folder.expandPackages()
        @updateSymbolList(folder)
    })

    @subscribeTo(@btnLinkFile[0], { 'click': (e) =>
      @linkFile = !@linkFile
      @setSelected(@btnLinkFile, @linkFile)
      if @linkFile
        @onActivePaneChange(atom.workspace.getActiveTextEditor())
    })

    @subscribeTo(@btnResetFilter[0], {'click': (e) =>@resetFilter()})


    @filterText = null;

    @searchBuffer().onDidChange(@applyFilter)

    editorView = atom.views.getView(@searchField)
    editorView.addEventListener 'keydown', (e) =>
      if e.keyCode == 13 # pressed enter
        hits = d3.select(@list[0]).select("li ol li").data()
        if hits.length>0 and hits[0]?
          @jumpToEntry(hits[0])
          @resetFilter()
      else if e.keyCode == 27 # pressed ESC
        @resetFilter()

    editorView.addEventListener 'focus', (e) =>
      @searchField.getModel().selectAll()


  searchBuffer: =>
    @searchField.getModel().getBuffer()

  resetFilter: =>
    @searchBuffer().setText("")
    @applyFilter()
    @searchField.blur()

  focusFilter: =>
    @searchField.focus()

  applyFilter: =>
    @filterText = @searchBuffer().getText()
    if !@filterText?.length
      @filterText = null
    @scheduleTimeout()

  flatOutline: ->
    return !@showTree or @filterText?

  scheduleTimeout: ->
    clearTimeout(@filterTimeout)
    refreshPackage = => @updateSymbolList(@currentFolder())
    @filterTimeout = setTimeout(refreshPackage, 50)

  handleEvents: ->
    @on 'dblclick', '.go-outline-tree-resize-handle', =>
      @resizeToFitContent()
    @on 'mousedown', '.go-outline-tree-resize-handle', (e) => @resizeStarted(e)

  resizeToFitContent: ->
    @width(1) # Shrink to measure the minimum width of list
    @width(@contentElement()?.outerWidth())

  destroy: ->

    atom.config.set 'go-outline.showTests', @showTests
    atom.config.set 'go-outline.showPrivates', @showPrivate
    atom.config.set 'go-outline.showTree', @showTree
    atom.config.set 'go-outline.showVariables', @showVariables
    atom.config.set 'go-outline.linkFile', @linkFile

    @detach()

  toggle: ->
    if @isVisible()
      @detach()
    else
      @show()

  show: ->
    return if _.isEmpty(atom.project.getPaths())
    @panel ?=
      if @showOnRightSide
        atom.workspace.addRightPanel(item: this)
      else
        atom.workspace.addLeftPanel(item: this)

    @onActivePaneChange(atom.workspace.getActiveTextEditor())

  detach: ->
    @panel.destroy()
    @panel = null


  onActivePaneChange: (item) ->
    return unless @linkFile
    return unless @isVisible()
    return unless @getPath()?.endsWith(".go")

    @showPkgsForPath(@getPath())


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

    if atom.config.get('go-outline.showOnRightSide')
      width = @outerWidth() + @offset().left - pageX
    else
      width = pageX - @offset().left
    @width(width)

  contentElement: ->
    return $(@scroller[0].firstChild)


  showPkgsForPath:(filePath) ->

    folderPath = helpers.dirname(filePath)
    file = helpers.basename(filePath)

    return unless folderPath != @currentDir


    # invalid
    if !folderPath.length || !file.length
      console.log "invalid file location provided", filePath, "..ignoring"
      return

    if !file.endsWith '.go'
      console.log "ignoring non-go-files", filePath
      return

    # if package for folder does not exist, create it
    if !@folders[folderPath]?
      folder = new Folder(folderPath)
      folder.setUpdateCallback(@updateSymbolList)
      folder.setParserStatusCallback(@setParserStatus)

      @folders[folderPath] = folder

      folder.fullReparse()
    else
      @updateSymbolList(@folders[folderPath])

    @currentDir = folderPath

  jumpToEntry: (item) ->
    return false unless item.fileName?
    options =
      searchAllPanes: true
      initialLine: (item.fileLine-1) if item?.fileLine
      initialColumn:  (item.fileColumn-1) if item?.fileColumn
    if item?.fileName
      atom.workspace.open(item.fileName, options).then (editor) =>
        if options.initialLine?
          editor.scrollToBufferPosition([options.initialLine, options.initialColumn], {center:true}) #markBufferRange(
          @flash(editor, [[options.initialLine, 0], [options.initialLine, 100]])


  flash: (editor, range) ->
    marker = editor.markBufferRange range,
      invalidate: 'never'
      persistent: false
      maintainHistory: false

    # set flashy class to marker.
    editor.decorateMarker marker,
      type: 'line'
      class: 'go-outline-highlight-line'

    # after timeout, remove the marker
    setTimeout ->
      marker.destroy()
    , 300


  currentFolder: ->
    if @currentDir?
      return @folders[@currentDir]
    else
      return null

  setEntryIcon: (liItem) ->
    expanderIcon = liItem.append("span")

    entryStyleClasses =
      package:"icon icon-file-directory"
      variable:"icon icon-mention variable"
      type: "icon name type go icon-link entity"
      func: "icon icon-primitive-square entity name function"

    for entryType, styleClasses of entryStyleClasses
      expanderIcon.filter((d)-> d.type is entryType).classed(styleClasses, true)

    expanderIcon.text((d)=>
      if @flatOutline()
        d.getIdentifier()
      else
        d.name
    )
    expanderIcon.on("mouseup", (d)=>
      if @jumpToEntry(d)
        d3.event.stopPropagation()


    )

  filterChildren: (children) =>

    return _.filter(children, (c) =>

      searcher = (c) -> true

      if @filterText?
        needles = @filterText.toLowerCase().split(" ")
        searcher = (c) ->
          lowName = c.name.toLowerCase()
          return _.every(needles, (n) ->
            lowName.indexOf(n) > -1
            )

      return (
            (@showVariables or c.type isnt "variable") and
            (@showTests or c.type isnt "func" or not c.name.startsWith("Test")) and
            (@showPrivate or c.isPublic) and
            (!@filterText or searcher(c))
          )
    )

  showFilteredList: (pkg) =>
    if !pkg?
      console.log "Provided null as package to display. This should not happen"
      return


  updateSymbolList: (folder) =>

    outlineView = @

    updateExpanderIcon = (d)->
      classed =
        'collapsed': !d.expanded
      d3.select(this).classed(classed).attr("title", d.getTitle())


    createChildren = (selection, recurse) ->
      item = selection.append('li')
      item.on("mouseup", (d)->
        d.expanded = !d.expanded
        d3.event.stopPropagation()
        updateExpanderIcon.apply(this, [d])
        updateExpand()
      )
      # apply initially
      item.each(updateExpanderIcon)


      if !outlineView.flatOutline() or recurse == 0
        nonLeafs = item.filter((d) -> d.children.length > 0)
        nonLeafs.classed("list-nested-item", true)
        nonLeafContent = nonLeafs.append("div").attr({class:"list-item"})
        outlineView.setEntryIcon(nonLeafContent)

        leafs = item.filter((d) -> d.children.length == 0)
        leafs.classed("list-item", true)
        outlineView.setEntryIcon(leafs)

        nonLeafs.each((d) ->
          childList = d3.select(this).append("ol")
          childList.attr({class:'list-tree'})
          data = if outlineView.flatOutline() then outlineView.filterChildren(d.getChildrenFlat()) else outlineView.filterChildren(d.children)
          childSelection = childList.selectAll("li").data(data)
          childSelection.enter().call((s) -> createChildren(s, recurse+1))
        )
      else
        item.classed("list-item", true)
        outlineView.setEntryIcon(item)

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
    packageRoots = d3.select(@container).selectAll('li').data(folder.getPackages(), (d)->d.name)
    packageRoots.enter().call((c) -> createChildren(c, 0))
