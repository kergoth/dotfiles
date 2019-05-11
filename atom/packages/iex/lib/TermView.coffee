util        = require 'util'
path        = require 'path'
os          = require 'os'
fs          = require 'fs-plus'
uuid        = require 'uuid'

Terminal    = require 'atom-iex-term.js'

keypather   = do require 'keypather'

{Task, CompositeDisposable} = require 'atom'
{$, View, ScrollView} = require 'atom-space-pen-views'

uuids = []

last = (str)-> str[str.length-1]

generateUUID = ()->
  new_id = uuid.v1().substring(0,4)
  while new_id in uuids
    new_id = uuid.v1().substring(0,4)
  uuids.push new_id
  new_id

getMixFilePath = ()->
  mixPath = null
  for projectPath in atom.project.getPaths()
    do (projectPath) ->
      if projectPath && fs.existsSync(path.join(projectPath, 'mix.exs'))
        mixPath = path.join(projectPath, 'mix.exs')
        return
  mixPath

renderTemplate = (template, data)->
  vars = Object.keys data
  vars.reduce (_template, key)->
    _template.split(///\{\{\s*#{key}\s*\}\}///)
      .join data[key]
  , template.toString()

class TermView extends View

  tabindex: -1

  @content: ->
    @div class: 'iex', click: 'click'

  constructor: (@opts={})->
    @opts.shell = process.env.SHELL or 'bash'
    @opts.shellArguments or= ''

    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    @opts.cwd = @opts.cwd or atom.project.getPaths()[0] or editorPath or process.env.HOME
    super

  applyStyle: ->
    # remove background color in favor of the atom background
    @term.element.style.background = null
    @term.element.style.fontFamily = (
      @opts.fontFamily or
      atom.config.get('editor.fontFamily') or
      # (Atom doesn't return a default value if there is none)
      # so we use a poor fallback
      "monospace"
    )
    # Atom returns a default for fontSize
    @term.element.style.fontSize = (
      @opts.fontSize or
      atom.config.get('editor.fontSize')
    ) + "px"

  forkPtyProcess: (args=[])->
    processPath = require.resolve './pty'
    projectPath = atom.project.getPaths()[0] ? '~'
    Task.once processPath, fs.absolute(projectPath), args
    # TODO - try switching back to pty.js to see if it fixes the backspace issue

  initialize: (@state)->
    @shell_stdout_history = []
    iexSrcPath = atom.packages.resolvePackagePath("iex") + "/elixir_src/iex.exs"
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, runCommand, colors, cursorBlink, scrollback} = @opts
    new_id = generateUUID()
    iexPath = atom.config.get('iex.iexExecutablePath')
    args = ["-l", "-c", iexPath + " --sname IEX-" + new_id + " -r " + iexSrcPath]
    mixPath = getMixFilePath()
    # assume mix file is at top level
    if mixPath
      file_str = fs.readFileSync(mixPath, {"encoding": "utf-8"})
      phoenix_str = ""
      if atom.config.get('iex.startPhoenixServer') && file_str.match(/applications.*:phoenix/g)
        phoenix_str = " phoenix.server"
      args = ["-l", "-c", iexPath + " --sname IEX-" + new_id + " -r " + iexSrcPath + " -S mix" + phoenix_str]

    @term = term = new Terminal {
      useStyle: no
      screenKeys: no
      colors: colorsArray
      cursorBlink, scrollback, cols, rows
    }

    @ptyProcess = @forkPtyProcess args
    # capture output from the child process (shell)
    @ptyProcess.on 'iex:data', (data) =>
      @shell_stdout_history.push data
      if @shell_stdout_history.length > 10
          @shell_stdout_history = @shell_stdout_history.slice(-10)
      @term.write data
    @ptyProcess.on 'iex:exit', (data) => @destroy()

    colorsArray = (colorCode for colorName, colorCode of colors)

    term.end = => @destroy()

    term.on "copy", (text)=> @copy(text)

    term.on "data", (data)=> @input data
    term.open this.get(0)

    @input "#{runCommand}#{os.EOL}" if runCommand
    term.focus()
    @applyStyle()
    @attachEvents()
    @resizeToPane()


  focus: ->
    @resizeToPane()
    @focusTerm()
    #super

  focusTerm: ->
    @term.element.focus()
    @term.focus()

  onActivePaneItemChanged: (activeItem) =>
    if (activeItem && activeItem.items.length == 1 && activeItem.items[0] == this)
      @focus()

  input: (data) ->
    @ptyProcess.send event: 'input', text: data

  resize: (cols, rows) ->
    try
      @ptyProcess.send {event: 'resize', rows, cols}
    catch error
      console.log error

  titleVars: ->
    bashName: last @opts.shell.split '/'
    hostName: os.hostname()
    platform: process.platform
    home    : process.env.HOME

  getTitle: ->
    @vars = @titleVars()
    titleTemplate = @opts.titleTemplate or "({{ bashName }})"
    renderTemplate titleTemplate, @vars

  getIconName: ->
    "terminal"

  attachEvents: ->
    @resizeToPane = @resizeToPane.bind this
    @attachResizeEvents()
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add '.iex', 'iex:paste': => @paste()
    @subscriptions.add atom.commands.add '.iex', 'iex:copy': => @copy()
    @subscriptions.add atom.workspace.onDidChangeActivePane(@onActivePaneItemChanged)
    #atom.workspace.onDidChangeActivePaneItem (item)=> @onActivePaneItemChanged(item)

  click: (evt, element) ->
    @focus()

  paste: ->
    try
      @input atom.clipboard.read()
    catch error

  copy: ->
    if @term._selected  # term.js visual mode selections
      textarea = @term.getCopyTextarea()
      text = @term.grabText(
        @term._selected.x1, @term._selected.x2,
        @term._selected.y1, @term._selected.y2)
    else # fallback to DOM-based selections
      text = @term.context.getSelection().toString()
      rawText = @term.context.getSelection().toString()
      rawLines = rawText.split(/\r?\n/g)
      lines = rawLines.map (line) ->
        line.replace(/\s/g, " ").trimRight()
      text = lines.join("\n")
    atom.clipboard.write text

  attachResizeEvents: ->
    setTimeout (=>  @resizeToPane()), 10
    @on 'focus', @focus
    $(window).on 'resize', => @resizeToPane()

  detachResizeEvents: ->
    @off 'focus', @focus
    $(window).off 'resize'

  resizeToPane: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @term
    return if @term.rows is rows and @term.cols is cols

    @resize cols, rows
    @term.resize cols, rows
    atom.views.getView(atom.workspace).style.overflow = 'visible'

  getDimensions: ->
    fakeRow = $("<div><span>&nbsp;</span></div>").css visibility: 'hidden'
    if @term
      @find('.terminal').append fakeRow
      fakeCol = fakeRow.children().first()
      cols = Math.floor (@width() / fakeCol.width()) or 9
      rows = Math.floor (@height() / fakeCol.height()) or 16
      fakeCol.remove()
    else
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 14

    cols = cols - 2
    {cols, rows}

  activate: ->
    @focus

  deactivate: ->
    @subscriptions.dispose()

  destroy: ->
    console.log "Destroying TermView"
    @input "\nSystem.halt\n\n"
    console.log "System halted"
    # this is cheesy and a race condition, but apparently I need a delay
    # before continuing so the IEx system can halt
    # FIXME - race condition
    count = 10000000
    while count -= 1
      ""

    @detachResizeEvents()

    @ptyProcess.send("exit")
    @ptyProcess.terminate()
    @term.destroy()
    parentPane = atom.workspace.getActivePane()
    if parentPane.activeItem is this
      parentPane.removeItem parentPane.activeItem
    @detach()

module.exports = TermView
