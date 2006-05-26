" Vim compiler file
" Compiler: dmd - Digital Mars D language
" Maintainer: marc Michel
" Last Change: 2005/08/10

if exists("current_compiler")
finish
endif
let current_compiler = "dmd"

" A workable errorformat for the Digital Mars D compiler

setlocal errorformat=%f\(%l\)\:%m,%-Gdmd\ %m,%-G%.%#errorlevel\ %m,\%-G\\s%#

" default make
setlocal makeprg=make
