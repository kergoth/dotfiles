" aftersyntax.vim:
"   Author: 	Charles E. Campbell, Jr.
"   Date:		Apr 07, 2005
"   Version:	2a	ASTRO-ONLY
"
"   1. Just rename this file (to something like c.vim)
"   2. Put it into .vim/after/syntax
"   3. Then any *.vim files in the subdirectory
"      .vim/after/syntax/name-of-file/
"      will be sourced
"
" GetLatestVimScripts: 1023 1 aftersyntax.vim

" ---------------------------------------------------------------------
"  Initialize: {{{1
let s:keepcpo= &cpo
set cpo&vim
let g:loaded_aftersyntax= "v2a"

" ---------------------------------------------------------------------
" Source in all files in the after/syntax/c directory {{{1
let ft       = expand("<sfile>:t:r")
let s:synlist= glob(expand("<sfile>:h")."/".ft."/*.vim")
"call Decho("ft<".ft."> synlist<".s:synlist.">")

while s:synlist != ""
 if s:synlist =~ '\n'
  let s:synfile = substitute(s:synlist,'\n.*$','','e')
  let s:synlist = substitute(s:synlist,'^.\{-}\n\(.*\)$','\1','e')
  else
  let s:synfile = s:synlist
  let s:synlist = ""
 endif

" call Decho("sourcing <".s:synfile.">")
 exe "so ".s:synfile
endwhile

" cleanup
unlet s:synlist
if exists("s:synfile")
 unlet s:synfile
endif

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo

" vim: ts=4 fdm=marker
