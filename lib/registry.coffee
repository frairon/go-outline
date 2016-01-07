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
      options =
        searchAllPanes: true
        initialLine: (item.fileLine-1) if item?.fileLine
        initialColumn:  (item.fileColumn-1) if item?.fileColumn

      if item?.fileName
        atom.workspace.open(item.fileName, options)

    makeChildren = (parentLists) ->
      item = parentLists.append('li').attr({class:"entry list-nested-item outline-tree"})
      parentLists.on("click", (d)->
        d3.event.stopPropagation()
        jumpToSymbol(d)
        )
      header = item.append("div")
      header.append("span").attr({class: "name icon icon-plus"})
      header.append("span").text((d)->d.name)

      children = item.selectAll('ol')
          .data(((d)->d.children), (d)->d.name)
            .enter().append('ol').attr({class:'entries list-tree'})

      if !children.empty()
        makeChildren(children)

    roots = d3.select(@container).selectAll('ol').data([pkg], (d)->d.packagepath).enter().append("ol").attr({class:'entries list-tree'})
    makeChildren(roots)
    # remove superfluous package trees
    d3.select(@container).select('ol').data([pkg], (d)->d.packagepath).exit().remove()
