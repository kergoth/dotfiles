" LargeFile: Sets up an autocmd to make editing large files work with celerity
"   Author:		Charles E. Campbell, Jr.
"   Date:		Jan 25, 2010
"   Version:	5d	ASTRO-ONLY
" GetLatestVimScripts: 1506 1 :AutoInstall: LargeFile.vim

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_LargeFile") || &cp
 finish
endif
let g:loaded_LargeFile = "v5d"
let s:keepcpo          = &cpo
set cpo&vim

" ---------------------------------------------------------------------
" Commands: {{{1
com! Unlarge			call s:Unlarge()
com! -bang Large		call s:LargeFile(<bang>0,expand("%"))

" ---------------------------------------------------------------------
"  Options: {{{1
if !exists("g:LargeFile")
 let g:LargeFile= 20	" in megabytes
endif

" ---------------------------------------------------------------------
"  LargeFile Autocmd: {{{1
" for large files: turns undo, syntax highlighting, undo off etc
" (based on vimtip#611)
augroup LargeFile
 au!
 au BufReadPre * call <SID>LargeFile(0,expand("<afile>"))
 au BufReadPost *
 \  if &ch < 2 && (getfsize(expand("<afile>")) >= g:LargeFile*1024*1024 || getfsize(expand("<afile>")) == -2)
 \|  echomsg "***note*** handling a large file"
 \| endif
augroup END

" ---------------------------------------------------------------------
" s:LargeFile: {{{2
fun! s:LargeFile(force,fname)
"  call Dfunc("s:LargeFile(force=".a:force." fname<".a:fname.">)")
  if a:force || getfsize(a:fname) >= g:LargeFile*1024*1024 || getfsize(a:fname) <= -2
   silent call s:ParenMatchOff()
   syn clear
   let b:bhkeep = &l:bh
   let b:eikeep = &ei
   let b:fdmkeep= &l:fdm
   let b:fenkeep= &l:fen
   let b:swfkeep= &l:swf
   let b:ulkeep = &ul
   let b:cptkeep= &cpt
   set ei=FileType
   setlocal noswf bh=unload fdm=manual ul=-1 nofen cpt-=w
   let fname=escape(substitute(a:fname,'\','/','g'),' ')
   exe "au LargeFile BufEnter ".fname." set ul=-1"
   exe "au LargeFile BufLeave ".fname." let &ul=".b:ulkeep."|set ei=".b:eikeep
   exe "au LargeFile BufUnload ".fname." au! LargeFile * ". fname
   echomsg "***note*** handling a large file"
  endif
"  call Dret("s:LargeFile")
endfun

" ---------------------------------------------------------------------
" s:ParenMatchOff: {{{2
fun! s:ParenMatchOff()
"  call Dfunc("s:ParenMatchOff()")
   redir => matchparen_enabled
    com NoMatchParen
   redir END
   if matchparen_enabled =~ 'g:loaded_matchparen'
	let b:nmpkeep= 1
	NoMatchParen
   endif
"  call Dret("s:ParenMatchOff")
endfun

" ---------------------------------------------------------------------
" s:Unlarge: this function will undo what the LargeFile autocmd does {{{2
fun! s:Unlarge()
"  call Dfunc("s:Unlarge()")
  if exists("b:bhkeep") |let &l:bh  = b:bhkeep |unlet b:bhkeep |endif
  if exists("b:fdmkeep")|let &l:fdm = b:fdmkeep|unlet b:fdmkeep|endif
  if exists("b:fenkeep")|let &l:fen = b:fenkeep|unlet b:fenkeep|endif
  if exists("b:swfkeep")|let &l:swf = b:swfkeep|unlet b:swfkeep|endif
  if exists("b:ulkeep") |let &ul    = b:ulkeep |unlet b:ulkeep |endif
  if exists("b:eikeep") |let &ei    = b:eikeep |unlet b:eikeep |endif
  if exists("b:cptkeep")|let &cpt   = b:cptkeep|unlet b:cptkeep|endif
  if exists("b:nmpkeep")
   DoMatchParen          
   unlet b:nmpkeep
  endif
  syn on
  doau FileType
  echomsg "***note*** stopped large-file handling"
"  call Dret("s:Unlarge")
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
