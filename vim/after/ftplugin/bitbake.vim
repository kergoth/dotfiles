set commentstring=#\ %s

set suffixesadd+=.bbclass
setlocal path+=;
setlocal path+=./classes;

if exists('$BBPATH')
    for dir in split($BBPATH, ":")
        let &l:path += dir
        let &l:path += dir . "/classes"
    endfor
endif
