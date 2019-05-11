# from atom/terminal to reduce cpu usage
pty = require 'pty.js'

module.exports = (ptyCwd, args) ->
  callback = @async()
  # if sh
  #     shell = sh
  # else
  #     if process.platform is 'win32'
  #       path = require 'path'
  #       shell = path.resolve(process.env.SystemRoot, 'WindowsPowerShell', 'v1.0', 'powershell.exe')
  #     else
  shell = process.env.SHELL

  cols = 80
  rows = 30

  ptyProcess = pty.fork shell, args,
    name: 'xterm-256color'
    cols: cols
    rows: rows
    cwd: ptyCwd
    env: process.env

  ptyProcess.on 'data', (data) -> emit('iex:data', data)
  ptyProcess.on 'exit', ->
    emit('iex:exit')
    callback()

  process.on 'message', ({event, cols, rows, text}={}) ->
    switch event
      when 'resize' then ptyProcess.resize(cols, rows)
      when 'input' then ptyProcess.write(text)
