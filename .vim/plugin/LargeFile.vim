" LargeFile: Sets up an autocmd to make editing large files work with celerity
"   Author:		Charles E. Campbell, Jr.
"   Date:		Mar 30, 2006
"   Version:	2
" GetLatestVimScripts: 1506 1 LargeFile.vim

" Load Once: {{{1
if exists("g:loaded_LargeFile") || &cp
 finish
endif
let g:loaded_LargeFile = "v2"
let s:keepcpo          = &cpo
set cpo&vim
" ---------------------------------------------------------------------
"  Options: {{{1
if !exists("g:LargeFile")
 let g:LargeFile= 100	" in megabytes
endif

" ---------------------------------------------------------------------
"  LargeFile Autocmd: {{{1
" for large files: turns undo, syntax highlighting, undo off etc
" (based on vimtip#611)
let s:LargeFile= g:LargeFile*1024*1024
augroup LargeFile
  au BufReadPre *
  \ let f=expand("<afile>") |
  \  if getfsize(f) >= s:LargeFile |
  \  let b:eikeep= &ei |
  \  let b:ulkeep= &ul |
  \  set ei=FileType |
  \  setlocal noswf bh=unload |
  \  let f=escape(substitute(f,'\','/','g'),' ') |
  \  exe "au LargeFile BufEnter ".f." set ul=-1" |
  \  exe "au LargeFile BufLeave ".f." let &ul=".b:ulkeep."|set ei=".b:eikeep |
  \  exe "au LargeFile BufUnload ".f." au! LargeFile * ". f |
  \  echomsg "***note*** handling a large file" |
  \ endif
augroup END

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
