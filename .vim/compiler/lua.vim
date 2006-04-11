" vim compiler file
" Compiler:		Lua
" Maintainer:   Chris Larson <kergoth-at-handhelds-dot-org>
" Last Change:  15 Mar 2006

if exists("current_compiler")
  finish
endif

let s:cpo_save = &cpo
set cpo-=C

" let current_compiler = "lua"
" let &l:makeprg = current_compiler . ' "%"'
" let &l:errorformat = current_compiler . ': %f:%l:\ %m,%-Astack traceback:,%-C	%.%#,%-Z%.%#'

let current_compiler = "luac"
let &l:makeprg = current_compiler . ' -p "%"'
let &l:errorformat = current_compiler . ': %f:%l: %p'

let &cpo = s:cpo_save
unlet s:cpo_save

"vim: ft=vim
