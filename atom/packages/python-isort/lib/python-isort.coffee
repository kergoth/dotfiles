fs = require 'fs'
$ = require 'jquery'
process = require 'child_process'

module.exports =
class PythonIsort

  checkForPythonContext: ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor?
      return false
    return editor.getGrammar().name == 'Python'

  removeStatusbarItem: =>
    @statusBarTile?.destroy()
    @statusBarTile = null

  updateStatusbarText: (message, isError) =>
    if not @statusBarTile
      statusBar = document.querySelector("status-bar")
      return unless statusBar?
      @statusBarTile = statusBar
        .addLeftTile(
          item: $('<div id="status-bar-python-isort" class="inline-block">
                    <span style="font-weight: bold">Isort: </span>
                    <span id="python-isort-status-message"></span>
                  </div>'), priority: 100)

    statusBarElement = @statusBarTile.getItem()
      .find('#python-isort-status-message')

    if isError == true
      statusBarElement.addClass("text-error")
    else
      statusBarElement.removeClass("text-error")

    statusBarElement.text(message)

  getFilePath: ->
    editor = atom.workspace.getActiveTextEditor()
    return editor.getPath()

  checkImports: ->
    if not @checkForPythonContext()
      return

    params = [@getFilePath(), "-c", "-vb"]
    isortpath = atom.config.get "python-isort.isortPath"

    which = process.spawnSync('which', ['isort']).status
    if which == 1 and not fs.existsSync(isortpath)
      @updateStatusbarText("unable to open " + isortpath, false)
      return

    proc = process.spawn isortpath, params

    updateStatusbarText = @updateStatusbarText
    proc.on 'exit', (exit_code, signal) ->
      if exit_code == 0
        updateStatusbarText("√", false)
      else
        updateStatusbarText("x", true)

  sortImports: ->
    if not @checkForPythonContext()
      return

    params = [@getFilePath(), "-vb"]
    isortpath = atom.config.get "python-isort.isortPath"

    which = process.spawnSync('which', ['isort']).status
    if which == 1 and not fs.existsSync(isortpath)
      @updateStatusbarText("unable to open " + isortpath, false)
      return

    proc = process.spawn isortpath, params
    @updateStatusbarText("√", false)
    @reload
