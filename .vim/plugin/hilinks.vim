" hilinks.vim: the source herein generates a trace of what
"             highlighting groups link to what highlighting groups
"
"  Author:		Charles E. Campbell, Jr. <charles.e.campbell.1@gsfc.nasa.gov>
"  Date:		Apr 17, 2006
"  Version:		4a	ASTRO-ONLY
"
"  NOTE:        This script requires Vim 6.0 (or later)
"
"  Usage: {{{1
"
"  \hlt   : will reveal a linked list of highlighting from the top-level down
"           to the bottom level.
"           You may redefine the leading character using "let mapleader= ..."
"           in your <.vimrc>.
"
"  History: {{{1
"   3 04/07/05 :	* cpo&vim supported
"   2 07/14/04 :	* register a is used as before but now its original contents are restored
"   				* bugfix: redraw taken before echo to fix message display
"   				* debugging code installed
"  	1 08/01/01 :	* the first release
" ---------------------------------------------------------------------
"  Load Once: {{{1
if exists("g:loaded_hilinks") || &cp
  finish
endif
let s:keepcpo= &cpo
set cpo&vim
let g:loaded_hilinks= "v4a"

" ---------------------------------------------------------------------
" Public Interface: {{{1
if !hasmapto('<Plug>HiLinkTrace')
  map <s-F10>  <Leader>hlt
  map <unique> <Leader>hlt <Plug>HiLinkTrace
endif
map <script> <Plug>HiLinkTrace :call <SID>HiLinkTrace()<CR>

" ---------------------------------------------------------------------

" HiLinkTrace: this function traces the highlighting group names {{{1
"             from transparent/top level through to the bottom
fun! <SID>HiLinkTrace()
"  call Dfunc("HiLinkTrace()")

  " save register a
  let keep_rega= @a

  " get highlighting linkages into register "a"
  redir @a
   silent! hi
  redir END
"  call Decho("reg-A now has :hi output")

  " initialize with top-level highlighting
  let firstlink = synIDattr(synID(line("."),col("."),1),"name")
  let lastlink  = synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
  let translink = synIDattr(synID(line("."),col("."),0),"name")
"  call Decho("firstlink<".firstlink."> lastlink<".lastlink."> translink<".translink.">")

  " if transparent link isn't the same as the top highlighting link,
  " then indicate it with a leading "T:"
  if firstlink != translink
   let hilink= "T:".translink." -> ".firstlink
"   call Decho("firstlink!=translink<".hilink.">")
  else
   let hilink= firstlink
"   call Decho("firstlink==translink<".hilink.">")
  endif

  " trace through the linkages
  if firstlink != lastlink
   let no_overflow= 0
   let curlink    = firstlink
"   call Decho("loop#".no_overflow.": hilink<".hilink.">")
   while curlink != lastlink && no_overflow < 10
   	let nxtlink     = substitute(@a,'^.*\<'.curlink.'\s\+xxx links to \(\a\+\).*$','\1','')
"    call Decho("loop#".no_overflow.": curlink<".curlink."> nxtlink<".nxtlink."> hilink<".hilink.">")
   	let hilink      = hilink ." -> ". nxtlink
   	let curlink     = nxtlink
   	let no_overflow = no_overflow + 1
   endwhile
"   call Decho("endloop: hilink<".hilink.">")
  endif
  redraw
  echo hilink

  " restore register a
  let @a= keep_rega

"  call Dret("HiLinkTrace : hilink<".hilink.">")
endfun

let &cpo= s:keepcpo
" ---------------------------------------------------------------------
" vim: fdm=marker
