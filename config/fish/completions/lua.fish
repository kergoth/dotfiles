
complete -c lua -s e -d "execute string 'stat'"
complete -c lua -s l -d "require library 'name'"
complete -c lua -s i -d "enter interactive mode after executing 'script'"
complete -c lua -s v -d "show version information"
complete -c lua -o - -d "stop handling options"

complete -c lua -f -a "(/usr/bin/find *.lua -type f)"

