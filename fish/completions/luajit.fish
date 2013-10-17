
complete -c luajit -s e -d "execute string 'chunk'"
complete -c luajit -s l -d "require library 'name'"
complete -c luajit -s j -d "perform luajit control 'command'"
complete -c luajit -s O -d "control luajit optimizations"
complete -c luajit -s i -d "enter interactive mode after executing 'script'"
complete -c luajit -s v -d "show version information"
complete -c luajit -o - -d "stop handling options"

complete -c luajit -f -a "(/usr/bin/find *.lua -type f)"

