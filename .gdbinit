set history expansion
#set history filename ~/.gdb_history
set history file ~/.gdb_history
#set history file .gdb_history
set history save on
set history size 10000

set print array
set print asm-demangle
set print null-stop
set print object
set print pretty
set print vtbl

#handle SIGPWR nostop noprint
#handle SIGXCPU nostop noprint
#handle SIG32 nostop noprint pass
#handle SIG33 nostop noprint pass
#sharedlibrary libpthread
