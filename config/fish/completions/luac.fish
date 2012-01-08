
complete -c luac -s l -d "list"
complete -c luac -s o -d "output to file 'name' (default: luac.out)"
complete -c luac -s p -d "parse only"
complete -c luac -s s -d "strip debug information"
complete -c luac -s v -d "show version information"
complete -c luac -o - -d "stop handling options"

complete -c luac -f -a "(/usr/bin/find *.lua -type f)"

