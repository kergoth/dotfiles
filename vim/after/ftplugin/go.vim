if exists('$GOROOT')
  exec "set path+=" . $GOROOT . '/src/pkg'
endif
set suffixesadd+=.go

set nolist
set sw=4 ts=4 sts=0 noet
set comments=s1:/*,mb:*,ex:*/,://
set commentstring=//\ %s
set foldmethod=syntax
set fileencoding=utf-8

let g:go_highlight_space_tab_error = 0
let g:go_highlight_trailing_whitespace_error = 0

" 'make test' error format for Go:
set errorformat=gotest:\ parse\ error:\ %f:%l:%c:\ %m,&errorformat

if !executable("gofmt")
  finish
endif

let bindirs = split(globpath(&runtimepath, 'bin'), '\n')
let $PATH = $PATH . ':' . join(bindirs, ':')
if !executable("mygofmt")
  finish
endif
set equalprg=mygofmt

function! Goformat()
  let regel=line(".")
  silent %!mygofmt
  call cursor(regel, 1)
endfunction

command! Gofmt call Goformat()
