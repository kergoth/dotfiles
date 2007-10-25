" eltab.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Aug 29, 2007
"   Version: 1a	NOT RELEASED
" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_ftplugin_eltab")
 finish
endif
let g:loaded_ftplugin_eltab = "v1a"
let s:keepcpo               = &cpo
set cpo&vim

" ---------------------------------------------------------------------
"  Align everything to single-space tabs
set ts=1
1ka
$
exe "AlignCtrl g \<Char-0xff>"
if !exists("g:mapleader")
 norm \tab
else
 exe "norm ".g:mapleader.'tab'
endif
AlignCtrl g

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
