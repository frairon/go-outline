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


    @packages.push("hello")
    @packages.push("hello")
    @packages.push("hello")



  showPkgForFile:(filePath) ->


    console.log @packages, @container, d3

    container = document.getElementById('outlinecontainer')
    console.log typeof container

    d3.select(container).append("div").text("hello world")

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
