" DotFill: fills and aligns text separated by a user-selected fill character
" Author:  Charles E. Campbell, Jr.
" Date:    Apr 11, 2006
" Version: 1a ASTRO-ONLY
" Copyright:    Copyright (C) 2006 Charles E. Campbell, Jr. {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               DotFill.vim is provided *as is* and comes with no warranty
"               of any kind, either expressed or implied. By using this
"               plugin, you agree that in no event will the copyright
"               holder be liable for any damages resulting from the use
"               of this software.
" Usage:
"     :[range]DotFill .       Simply select a range of lines.  Any lines
"     :[range]DotFill -       which contain three or more contiguous copies
"     etc                     of the fill-character will be aligned and
"                             separated by the fill character.
" GetLatestVimScripts: 294  1 :AutoInstall: Align.vim
" GetLatestVimScripts: 1066 1 :AutoInstall: cecutil.vim

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_align") || &cp
 finish
endif
let g:loaded_DotFill = "v1a"
let s:keepcpo      = &cpo
set cpo&vim

" ---------------------------------------------------------------------
"  Public Interface: {{{1
com! -nargs=1 -range DotFill <line1>,<line2>call s:DotFill(<q-args>)

" ---------------------------------------------------------------------
" DotFill: requires at least three contiguous copies of fillchar: {{{1
"    * uses a substitute to surround (at least) three contiguous copies of fillchar with @s
"    * uses Align to align the @s
"    * does a substitute to change text inside @s to fillchar
"    * removes the @s
fun! s:DotFill(fillchar) range
"  call Dfunc("DotFill(fillchar<".a:fillchar.">) lines[".a:firstline.",".a:lastline."]")
  let fillchar= escape(strpart(a:fillchar,0,1),'[\*.[$]')
"  call Decho("fillchar<".fillchar."> (escaped)")
  AlignCtrl mp0P0
  exe "silent ".a:firstline.",".a:lastline.'s/'.fillchar.'\{3,}/@&@/'
  exe a:firstline.",".a:lastline.'Align @'
  exe "silent ".a:firstline.",".a:lastline.'s/ *@[ '.fillchar.']\+@ */\=substitute(submatch(0),"[^@]","'.fillchar.'","g")/'
  exe "silent ".a:firstline.",".a:lastline.'s/@//g'
"  call Dret("DotFill")
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
