ElixirCmdView = require './elixir-cmd-view'
{CompositeDisposable} = require 'atom'
path = require 'path'
fs = require 'fs'

module.exports =
  elixirCmdView: null

  activate: (state) ->
    return unless fs.existsSync("#{atom.project.getPaths()[0]}/mix.exs")
    @elixirCmdView = new ElixirCmdView(state.elixirCmdViewState)
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace',
      'core:close': => @elixirCmdView?.close()
      'core:cancel': => @elixirCmdView?.close()

  deactivate: ->
    if @elixirCmdView
      @elixirCmdView.destroy()
      @disposables.dispose()

  serialize: ->
    elixirCmdViewState: @elixirCmdView?.serialize()
