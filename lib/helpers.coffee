p = require('path')

module.exports = {
  basename: (path) ->
    return p.basename(path)

  dirname: (path) ->
    return p.dirname(path)
}
