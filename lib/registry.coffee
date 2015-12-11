path = require 'path'
_ = require 'underscore-plus'
# {CompositeDisposable, Emitter} = require 'event-kit'

#PathWatcher = require 'pathwatcher'
#File = require './file'
# {repoForPath} = require './helpers'
#realpathCache = {}

PackageElement = require './package'

module.exports =
class Registry
  constructor:(@container) ->

    @entries = {}

    @currentPackage = null;

  packageForName:(name) ->
    if !@entries[name]?
      pkg = new PackageElement()
      pkg.initialize(name)
      @entries[name] = pkg

    return @entries[name]

  displayPackage:(name)->

    if @currentPackage?.packageName != name
      if @currentPackage?
        @container.removeChild(@currentPackage)
      @currentPackage = @packageForName(name)

      @container.appendChild(@currentPackage)
