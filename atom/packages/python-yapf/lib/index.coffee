module.exports =
  config:
    yapfPath:
      type: 'string'
      default: 'yapf'
    yapfStyle:
      type: 'string'
      default: ''
    formatOnSave:
      type: 'boolean'
      default: false
    checkOnSave:
      type: 'boolean'
      default: true

  status: null
  subs: null

  activate: ->
    PythonYAPF = require './python-yapf'
    pi = new PythonYAPF()

    {CompositeDisposable} = require 'atom'
    @subs = new CompositeDisposable

    @subs.add atom.commands.add 'atom-workspace', 'pane:active-item-changed', ->
      pi.removeStatusbarItem()

    @subs.add atom.commands.add 'atom-workspace', 'python-yapf:formatCode', ->
      pi.formatCode()

    @subs.add atom.commands.add 'atom-workspace', 'python-yapf:checkCode', ->
      pi.checkCode()

    @subs.add atom.config.observe 'python-yapf.formatOnSave', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if value
          editor._yapfFormat = editor.onDidSave -> pi.formatCode()
        else
          editor._yapfFormat?.dispose()

    @subs.add atom.config.observe 'python-yapf.checkOnSave', (value) ->
      atom.workspace.observeTextEditors (editor) ->
        if value
          editor._yapfCheck = editor.onDidSave -> pi.checkCode()
        else
          editor._yapfCheck?.dispose()

    StatusDialog = require './status-dialog'
    @status = new StatusDialog pi
    pi.setStatusDialog(@status)

  deactivate: ->
    @subs?.dispose()
    @subs = null
    @status?.dispose()
    @status = null

  consumeStatusBar: (statusBar) ->
    @status.attach statusBar
