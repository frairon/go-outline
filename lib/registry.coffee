path = require 'path'
_ = require 'underscore-plus'
# {CompositeDisposable, Emitter} = require 'event-kit'

#PathWatcher = require 'pathwatcher'
#File = require './file'
# {repoForPath} = require './helpers'
#realpathCache = {}

Package = require './package'

module.exports =
class Registry
  constructor:(@container) ->

    @entries = {}

    @currentPackage = null;

  packageForName:(name) ->
    if !@entries[name]?
      pkg = new Package()
      pkg.initialize(name)
      @entries[name] = pkg

    return @entries[name]

  displayPackage:(name)->
    # remove all children
    console.log @container


    if @currentPackage? && @currentPackage.packageName != name
      @currentPackage.destroy()
      @currentPackage = @packageForName(name)

      @container.appendChild(@currentPackage)
