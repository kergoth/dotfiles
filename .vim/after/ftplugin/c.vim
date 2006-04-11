" syn region myFold start="{" end="}" transparent fold
" syn sync fromstart
" set foldmethod=syntax

setlocal foldmethod=marker
setlocal foldmarker={,}

setlocal commentstring=/*\ %s\ */
