setlocal foldmethod=syntax
setlocal commentstring=--\ %s

let b:match_words =
    \ '\<\%(function\|do\|if\)\>:' .
    \ '\<\%(else\|elseif\)\>:' .
    \ '\<end\>,' .
    \ '\<repeat\>:\<until\>'
