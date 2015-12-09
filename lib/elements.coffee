path = require 'path'
_ = require 'underscore-plus'
{CompositeDisposable, Emitter} = require 'event-kit'

PathWatcher = require 'pathwatcher'
{repoForPath} = require './helpers'
realpathCache = {}

module.exports =
class Directory
