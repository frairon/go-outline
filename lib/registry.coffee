path = require 'path'
_ = require 'underscore-plus'
# {CompositeDisposable, Emitter} = require 'event-kit'

#PathWatcher = require 'pathwatcher'
#File = require './file'
# {repoForPath} = require './helpers'
#realpathCache = {}

PackageElement = require './package'
helpers = require './helpers'
module.exports =
class Registry
  constructor:(@container) ->

    @entries = {}

    @currentPackage = null;

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
    if !@entries[pkgDir]?
      return
    @entries[pkgDir].refreshFile(file)

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
    if !@entries[pkgDir]?
      pkg = new PackageElement()
      pkg.initialize(pkgDir)
      @entries[pkgDir] = pkg

    # if the package has changed (or nothing displayed yet)
    if @currentPackage?.packageName != name

      # remove old displayed package if existed
      if @currentPackage?
        @container.removeChild(@currentPackage)

      # set current, and display it.
      @currentPackage = @entries[pkgDir]
      @container.appendChild(@currentPackage)
