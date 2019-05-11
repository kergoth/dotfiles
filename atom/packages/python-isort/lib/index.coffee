PythonIsort = require './python-isort'

module.exports =
  config:
    isortPath:
      type: 'string'
      default: 'isort'
    sortOnSave:
      type: 'boolean'
      default: false
    checkOnSave:
      type: 'boolean'
      default: true

  activate: ->
    pi = new PythonIsort()

    atom.commands.add 'atom-workspace', 'pane:active-item-changed', ->
      pi.removeStatusbarItem()

    atom.commands.add 'atom-workspace', 'python-isort:sortImports', ->
      pi.sortImports()

    atom.commands.add 'atom-workspace', 'python-isort:checkImports', ->
      pi.checkImports()

    atom.config.observe 'python-isort.sortOnSave', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if value == true
          editor._isortSort = editor.onDidSave -> pi.sortImports()
        else
          editor._isortSort?.dispose()

    atom.config.observe 'python-isort.checkOnSave', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if value == true
          editor._isortCheck = editor.onDidSave -> pi.checkImports()
        else
          editor._isortCheck?.dispose()
