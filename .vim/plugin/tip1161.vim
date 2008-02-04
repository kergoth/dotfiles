com! -nargs=+ -complete=command Windo call tip1161#WinDo(<q-args>)

if v:version >= 700
  " Just like Windo except that it disables all autocommands for super fast processing.
  com! -nargs=+ -complete=command Windofast noau call tip1161#WinDo(<q-args>)
else
  com! -nargs=+ -complete=command Windofast let l:ei = &eventignore | let &eventignore = 'all' | call tip1161#WinDo(<q-args>) | let &eventignore = l:ei
endif

com! -nargs=+ -complete=command Bufdo call BufDo(<q-args>)
