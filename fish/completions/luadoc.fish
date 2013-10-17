
complete -c luadoc -s d -d "output directory 'path'"
complete -c luadoc -s t -d "template directory 'path'"
complete -c luadoc -s h -l help -d "print help and exit"
complete -c luadoc -l noindexpage -d "do not generate global index page"
complete -c luadoc -l nofiles -d "do not generate documentation for files"
complete -c luadoc -l nomodules -d "do not generate documentation for modules"
complete -c luadoc -l doclet -d "doclet module to generate output"
complete -c luadoc -l taglet -d "taglet module to parse input code"
complete -c luadoc -s q -l quiet -d "suppress all normal output"
complete -c luadoc -o v -l version -d "print version information"

