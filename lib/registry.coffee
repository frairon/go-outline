path = require 'path'
_ = require 'underscore-plus'
# {CompositeDisposable, Emitter} = require 'event-kit'

#PathWatcher = require 'pathwatcher'
#File = require './file'
# {repoForPath} = require './helpers'
#realpathCache = {}

EntryView = require './entry-view'
Package = require './package'
helpers = require './helpers'
module.exports =
class Registry
  constructor:(@container) ->

    @packageViews = {}

    @currentPackageDir = null;

  refreshFile: (filePath)->
    console.log "refreshing file"
    # get dir for file
    pkgDir = helpers.dirname(filePath)

    file = helpers.basename(filePath)

    # invalid
    if !pkgDir.length || !file.length
      console.log "invalid file location provided", filePath, "..ignoring"
      return

    # no package exists (i.e. hasn't been displayed yet), ignore it.
    if !@packageViews[pkgDir]?
      return
    @packageViews[pkgDir].refreshFile(file)

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

    # if package for folder does not exist, create it
    if !@packageViews[pkgDir]?
      pkgView = new EntryView()
      pkg = new Package(pkgDir)
      pkgView.initialize(pkg)

      @packageViews[pkgDir] = pkgView

    # if the package has changed (or nothing displayed yet)
    if !@currentPackageDir? || @currentPackageDir != pkgDir

      # remove old displayed package if existed
      if @currentPackageDir?
        @container.removeChild(list.childNodes[0])

      # set current, and display it.
      @currentPackageDir = pkgDir
      @container.appendChild(@packageViews[pkgDir])
