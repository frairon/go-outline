{BufferedProcess, Point} = require 'atom'
Q = require 'q'
path = require 'path'

module.exports =
class TagGenerator
  constructor: (@path, @scopeName) ->

  parseTagLine: (line) ->
    sections = line.split('\t')

    if sections.length > 4
      column = sections[2].match(/^\/\^(\s*)[\S]/)[1].length
      return {
        position: new Point(parseInt(sections[4].split(':')[1]) - 1, column)
        name: sections[0]
        kind: sections[3]
        identation: column
      }
    else
      null

  getLanguage: ->
    return 'Cson' if path.extname(@path) in ['.cson', '.gyp']

    switch @scopeName
      when 'source.c'        then 'C'
      when 'source.cpp'      then 'C++'
      when 'source.clojure'  then 'Lisp'
      when 'source.coffee'   then 'CoffeeScript'
      when 'source.css'      then 'Css'
      when 'source.css.less' then 'Css'
      when 'source.css.scss' then 'Css'
      when 'source.gfm'      then 'Markdown'
      when 'source.go'       then 'Go'
      when 'source.java'     then 'Java'
      when 'source.js'       then 'JavaScript'
      when 'source.json'     then 'Json'
      when 'source.makefile' then 'Make'
      when 'source.objc'     then 'C'
      when 'source.objcpp'   then 'C++'
      when 'source.python'   then 'Python'
      when 'source.ruby'     then 'Ruby'
      when 'source.sass'     then 'Sass'
      when 'source.yaml'     then 'Yaml'
      when 'text.html'       then 'Html'
      when 'text.html.php'   then 'Php'

      # For backward-compatibility with Atom versions < 0.166
      when 'source.c++'      then 'C++'
      when 'source.objc++'   then 'C++'

  getPackageRoot: ->
    packageRoot = path.resolve(__dirname, '..')
    {resourcePath} = atom.getLoadSettings()
    if path.extname(resourcePath) is '.asar'
      if packageRoot.indexOf(resourcePath) is 0
        packageRoot = path.join("#{resourcePath}.unpacked", 'node_modules', 'symbols-view')
    packageRoot

  generate: ->
    tags = {}
    packageRoot = @getPackageRoot()
    command = path.join(packageRoot, 'vendor', "ctags-#{process.platform}")
    defaultCtagsFile = path.join(packageRoot, 'lib', 'ctags-config')
    args = ["--options=#{defaultCtagsFile}", '--fields=+KS']

    if atom.config.get('symbols-view.useEditorGrammarAsCtagsLanguage')
      if language = @getLanguage()
        args.push("--language-force=#{language}")

    args.push('-nf', '-', @path)

    new Promise (resolve) =>
      new BufferedProcess({
        command: command,
        args: args,
        stdout: (lines) =>
          for line in lines.split('\n')
            if tag = @parseTagLine(line)
              tags[tag.position.row] ?= tag
        stderr: ->
        exit: ->
          tags = (tag for row, tag of tags)
          console.log "found tags", tags
          resolve(tags)
      })
