{BufferedProcess} = require 'atom'
{View, $$} = require 'atom-space-pen-views'
AnsiFilter = require 'ansi-to-html'
ansiFilter = new AnsiFilter
fs = require 'fs'

elixirModule = /^((?:[A-Z][a-zA-Z0-9_-]*)(?:\.[A-Z][a-zA-Z0-9_-]*)*)$/
elixirModuleFunction = /^((?:[A-Z][a-zA-Z0-9_-]*)(?:\.[A-Z][a-zA-Z0-9_-]*)*)\.([a-z][a-zA-Z0-9_-]*)$/
kernelFunction = /^([a-z][a-zA-Z0-9_-]*)/

filelike = /((?:\w*\/)*\w*\.exs?(?::\d+))/
filesplit = /((?:\w*\/)*\w*\.exs?)(?::(\d+))/

# Functions for escaping and unescaping strings to/from HTML interpolation.
# List of HTML entities for escaping.
escape = (() ->
  escaping =
    "&": "&amp;"
    "<": "&lt;"
    ">": "&gt;"
    "\"": "&quot;"
    "'": "&#x27;"
    "`": "&#x60;"
  replacer= (match) -> escaping[match]
  reString = "(?:" + (for k of escaping then k).join("|") + ")"
  reTest = RegExp(reString)
  reMatch = RegExp(reString, "g")
  return (string) ->
    string = (if not string? then "" else "" + string)
    if reTest.test(string)
      string.replace(reMatch, replacer)
    else string)()

fileResolve = (filename) ->
  file = atom.project.getDirectories()[0]?.resolve(filename)
  if fs.existsSync(file)
    return file

# Runs a portion of a script through an interpreter and displays it line by line
module.exports =
class ElixirCmdView extends View
  @bufferedProcess: null

  @content: ->
    @div =>
      css = 'tool-panel panel panel-bottom padding elixir-cmd-view
        native-key-bindings'
      @div class: css, outlet: 'script', tabindex: -1, =>
        @div
          click: 'gotoFile'
          class: 'panel-body padded output', outlet: 'output'

  initialize: (serializeState, @runOptions) ->
    atom.commands.add 'atom-workspace',
      'elixir-cmd:build': => @buildProject()
      'elixir-cmd:test': => @testProject()
      'elixir-cmd:doc': => @keywordDocumentation()
      'elixir-cmd:kill-process': => @stop()

  gotoFile: ({target: target}) ->
    return unless file=target.getAttribute("file")
    atom.workspace.open(file).then (editor) ->
      return unless (lineno = target.getAttribute("lineno"))
      editor.moveToTop()
      editor.moveDown(lineno-1)

  serialize: ->

  buildProject: ->
    @resetView()
    @saveAll()
    @run 'mix', ['compile']

  testProject: ->
    @resetView()
    @saveAll()
    @run 'mix', ['test']

  keywordDocumentation: ->
    return unless (kw=@keywordGet())?
    args = ['-S', 'mix', 'run', '-e']
    switch
      when matches=kw.match elixirModule
        [_matching, moduleName] = matches
        @resetView()
        args.push "require IEx\nApplication.put_env(:iex, :colors, [enabled: true])\nIEx.Introspection.h(#{moduleName})"
      when matches=kw.match elixirModuleFunction
        [_matching, moduleName, functionName] = matches
        @resetView()
        args.push "require IEx\nApplication.put_env(:iex, :colors, [enabled: true])\nIEx.Introspection.h(#{moduleName}, :#{functionName})"
      when matches=kw.match kernelFunction
        [_matching, functionName] = matches
        @resetView()
        args.push "require IEx\nApplication.put_env(:iex, :colors, [enabled: true])\nIEx.Introspection.h(Kernel, :#{functionName})"
      else return
    @run 'elixir', args

  keywordGet:  ->
    editor    = atom.workspace.getActiveEditor()
    selection = editor.getSelection().getText()

    return selection if selection

    scopes       = editor.getCursorScopes()
    currentScope = scopes[scopes.length - 1]

    # Use the current cursor scope if available. If the current scope is a
    # string, comment or not available, get the current word under the cursor.
    # Ignore: comment (any), string (any), meta (html), markup (md).
    if scopes.length > 1 && !/^(?:comment|string|meta|markup)(?:\.|$)/.test(currentScope)
      range = editor.bufferRangeForScopeAtCursor(currentScope)
    else
      range = editor.getCursor().getCurrentWordBufferRange()
    start = range.start.column
    range.start.column = 0
    text = editor.getTextInBufferRange(range)
    validNameChars = /[a-zA-Z]/
    while start>1 and text.charAt(start-1) == "." and validNameChars.test(text.charAt(start-2))
      start-=1
      while start > 0 and validNameChars.test(text.charAt(start-1)) then start-=1
    text.slice(start, range.end.column)

  keywordExtendLeft: (range) ->



  resetView: (title = 'Loading...') ->
    # Display window and load message

    # First run, create view
    atom.workspace.addBottomPanel {item: this} unless @hasParent()

    # Close any existing process and start a new one
    @stop()

    # Get script view ready
    @output.empty()

  saveAll: ->
    atom.project.buffers.forEach (buffer) -> buffer.save() if buffer.isModified() and buffer.file?

  close: ->
    # Stop any running process and dismiss window
    @stop()
    @detach() if @hasParent()

  handleError: (err) ->
    # Display error and kill process
    @output.append err
    @stop()

  run: (command, args, stdout = (output) => @display 'stdout', output) ->
#    atom.emit 'achievement:unlock', msg: 'Homestar Runner'

    # Default to where the user opened atom
    options =
      cwd: @getCwd()
      env: process.env

    stderr = (output) => @display 'stderr', output
    exit = (returnCode) =>
      @output.append $$ ->
        @small "-- exit #{returnCode} --"

    # Run process
    @bufferedProcess = new BufferedProcess({
      command, args, options, stdout, stderr, exit
    })

    @bufferedProcess.process.on 'error', (nodeError) =>
      @output.append $$ ->
        @h1 'Unable to run'
        @pre escape command
        @h2 'Is it on your path?'
        @pre "PATH: #{escape process.env.PATH}"

  getCwd: ->
    atom.project.getPaths()[0]

  stop: ->
    # Kill existing process if available
    if @bufferedProcess? and @bufferedProcess.process?
      @display 'stdout', '^C'
      @bufferedProcess.kill()

  display: (css, line) ->
    @output.append $$ ->
      @pre class: "line #{css}", =>
        if filelike.test(line)
          bits = line.split(filelike)
          for bit in bits
            if matching = bit.match(filesplit)
              [matchstring, filename, lineno] = matching
              if filename and (file=fileResolve(filename)) and fs.existsSync(file)
                @a
                  style: 'color: #428bca;'
                  file: file
                  lineno: lineno if lineno
                  bit
              else
                @span bit
            else
              @span bit
        else
          line = escape(line)
          line = ansiFilter.toHtml(line)
          @raw line
