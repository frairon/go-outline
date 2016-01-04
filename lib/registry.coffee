path = require 'path'
_ = require 'underscore-plus'

EntryView = require './entry-view'
Package = require './package'
helpers = require './helpers'
d3 = require 'd3'

module.exports =
class Registry
  constructor:(@container) ->

    @packages = []

    @currentPackageDir = null;

  showPkgForFile:(filePath) ->

    pkgDir = helpers.dirname(filePath)
    file = helpers.basename(filePath)

    # invalid
    if !pkgDir.length || !file.length
      console.log "invalid file location provided", filePath, "..ignoring"
      return

    if !file.endsWith '.go'
      console.log "ignoring non-go-files", filePath
      return

    # if package for folder does not exist, create i
    existing = _.find(@packages, (p)->p.packagepath == pkgDir)
    if !existing?
      #pkgView = new EntryView()
      pkg = new Package(pkgDir)
      #pkgView.initialize(pkg)

      pkg.fullReparse()

      @packages.push(pkg)

      data = d3.select(@container).append('ol')
              .attr({class:'entries list-tree'})
              .selectAll('li')
              .attr({class:'entry list-nested-item outline-tree'}).data(@packages)

      entries = data.enter().append("li").attr({class:'entry list-nested-item outline-tree'})
      entries.append("span").attr({class:'name icon icon-plus'}).text (el)->
        console.log el
        return el.name

    # if the package has changed (or nothing displayed yet)
    # if !@currentPackageDir? || @currentPackageDir != pkgDir
    #
    #   # remove old displayed package if existed
    #   if @currentPackageDir?
    #     @container.removeChild(@container.childNodes[0])
    #
    #   # set current, and display it.
    #   @currentPackageDir = pkgDir
    #   @container.appendChild(@packageViews[pkgDir])
