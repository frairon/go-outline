path = require 'path'
_ = require 'underscore-plus'
# {CompositeDisposable, Emitter} = require 'event-kit'

#PathWatcher = require 'pathwatcher'
#File = require './file'
# {repoForPath} = require './helpers'
#realpathCache = {}

module.exports =
class Entry
  construct:({@data}) ->
    @entries = {}

  type: ->
    @data?.type
