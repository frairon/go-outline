

module.exports = {
  basename: (path) ->
    return path.replace(/^.*\//, '')

  dirname: (path) ->
    return path.replace(/[^\/]+$/, '')
}
