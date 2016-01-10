path = require 'path'
_ = require 'underscore-plus'

Package = require './package'
helpers = require './helpers'
d3 = require 'd3'

module.exports =
class Registry
  constructor:(@container) ->

    @packages = {}

    @currentPackageDir = null;

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

      #@updatePackageList(pkg)
      pkg.fullReparse()
    else
      @updatePackageList(@packages[pkgDir])

    @currentPackageDir = pkgDir


  updatePackageList: (pkg) =>
    
    jumpToSymbol = (item) ->
      return unless item.fileName?
      options =
        searchAllPanes: true
        initialLine: (item.fileLine-1) if item?.fileLine
        initialColumn:  (item.fileColumn-1) if item?.fileColumn

      if item?.fileName
        atom.workspace.open(item.fileName, options)

    createChildren = (selection) ->
      #console.log "creating new children", selection
      item = selection.append('li').attr({class:"entry list-nested-item outline-tree"})
      item.on("click", (d)->
        d.expanded = !d.expanded
        d3.event.stopPropagation()
        updateIcon.apply(this, [d])
        updateExpand()
      )
      content = item.append("div").attr({class:"list-item"})

      updateIcon = (d)->
        classed =
          'collapsed': !d.expanded
        d3.select(this).classed(classed)

      expanderIcon = content.append("span")
      expanderIcon.classed("icon", true)
      expanderIcon.classed("icon-package", (d) -> d.type is "package")
      expanderIcon.classed("icon-code" , (d) -> d.type is "func")
      expanderIcon.classed("icon-list-unordered" , (d) -> d.type is "type")
      expanderIcon.classed("status-renamed" , (d) -> d.isPublic)
      expanderIcon.classed("status-modified" , (d) -> not d.isPublic)
      expanderIcon.text((d)->d.name)


      item.each((d)->
        if d.children.length > 0
          childList = d3.select(this).append("ol")
          childList.attr({class:'list-tree'})
          childList.selectAll("li").data((d.children), (d)->d.name).enter().call(createChildren)
      )

      updateExpand = ->
        item.each((d)->
          ol = d3.select(this).select("ol")
          classed =
            hidden : !d.expanded
          ol.classed(classed)
        )

      expanderIcon.on("click", (d)->
        d3.event.stopPropagation()
        jumpToSymbol(d)

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
