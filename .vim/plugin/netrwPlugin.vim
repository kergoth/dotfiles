" netrwPlugin.vim: Handles file transfer and remote directory listing across a network
"            PLUGIN SECTION
" Date:		Jan 05, 2007
" Maintainer:	Charles E Campbell, Jr <NdrOchip@ScampbellPfamily.AbizM-NOSPAM>
" GetLatestVimScripts: 1075 1 :AutoInstall: netrw.vim
" Copyright:    Copyright (C) 1999-2005 Charles E. Campbell, Jr. {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               netrw.vim, netrwPlugin.vim, and netrwSettings.vim are provided
"               *as is* and comes with no warranty of any kind, either
"               expressed or implied. By using this plugin, you agree that
"               in no event will the copyright holder be liable for any damages
"               resulting from the use of this software.
"
"  But be doers of the Word, and not only hearers, deluding your own selves {{{1
"  (James 1:22 RSV)
" =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_netrwPlugin")
 finish
endif
let g:loaded_netrwPlugin = 1
let s:keepcpo            = &cpo
if v:version < 700
 echohl WarningMsg | echo "***netrw*** you need vim version 7.0 for this version of netrw" | echohl None
 finish
endif
let s:keepcpo= &cpo
set cpo&vim

" ---------------------------------------------------------------------
" Public Interface: {{{1

" Local Browsing: {{{2
augroup FileExplorer
 au!
 au BufEnter * silent! call s:LocalBrowse(expand("<amatch>"))
 if has("win32") || has("win95") || has("win64") || has("win16")
  au BufEnter .* silent! call s:LocalBrowse(expand("<amatch>"))
 endif
augroup END

" Network Browsing Reading Writing: {{{2
augroup Network
 au!
 if has("win32") || has("win95") || has("win64") || has("win16")
  au BufReadCmd  file://*		exe "silent doau BufReadPre ".netrw#RFC2396(expand("<amatch>"))|exe 'e '.substitute(netrw#RFC2396(expand("<amatch>")),'file://\(.*\)','\1',"")|exe "silent doau BufReadPost ".netrw#RFC2396(expand("<amatch>"))
 else
  au BufReadCmd  file://*		exe "silent doau BufReadPre ".netrw#RFC2396(expand("<amatch>"))|exe 'e '.substitute(netrw#RFC2396(expand("<amatch>")),'file://\(.*\)','\1',"")|exe "silent doau BufReadPost ".netrw#RFC2396(expand("<amatch>"))
  au BufReadCmd  file://localhost/*	exe "silent doau BufReadPre ".netrw#RFC2396(expand("<amatch>"))|exe 'e '.substitute(netrw#RFC2396(expand("<amatch>")),'file://localhost/\(.*\)','\1',"")|exe "silent doau BufReadPost ".netrw#RFC2396(expand("<amatch>"))
 endif
 au BufReadCmd   ftp://*,rcp://*,scp://*,http://*,dav://*,rsync://*,sftp://*	exe "silent doau BufReadPre ".expand("<amatch>")|exe '2Nread "'.expand("<amatch>").'"'|exe "silent doau BufReadPost ".expand("<amatch>")
 au FileReadCmd  ftp://*,rcp://*,scp://*,http://*,dav://*,rsync://*,sftp://*	exe "silent doau FileReadPre ".expand("<amatch>")|exe 'Nread "'   .expand("<amatch>").'"'|exe "silent doau FileReadPost ".expand("<amatch>")
 au BufWriteCmd  ftp://*,rcp://*,scp://*,dav://*,rsync://*,sftp://*		exe "silent doau BufWritePre ".expand("<amatch>")|exe 'Nwrite "' .expand("<amatch>").'"'|exe "silent doau BufWritePost ".expand("<amatch>")
 au FileWriteCmd ftp://*,rcp://*,scp://*,dav://*,rsync://*,sftp://*		exe "silent doau FileWritePre ".expand("<amatch>")|exe "'[,']".'Nwrite "' .expand("<amatch>").'"'|exe "silent doau FileWritePost ".expand("<amatch>")
 try
  au SourceCmd    ftp://*,rcp://*,scp://*,http://*,dav://*,rsync://*,sftp://*	exe 'Nsource "'.expand("<amatch>").'"'
 catch /^Vim\%((\a\+)\)\=:E216/
  au SourcePre    ftp://*,rcp://*,scp://*,http://*,dav://*,rsync://*,sftp://*	exe 'Nsource "'.expand("<amatch>").'"'
 endtry
augroup END

" Commands: :Nread, :Nwrite, :NetUserPass {{{2
com! -count=1 -nargs=*	Nread		call netrw#NetSavePosn()<bar>call netrw#NetRead(<count>,<f-args>)<bar>call netrw#NetRestorePosn()
com! -range=% -nargs=*	Nwrite		call netrw#NetSavePosn()<bar><line1>,<line2>call netrw#NetWrite(<f-args>)<bar>call netrw#NetRestorePosn()
com! -nargs=*		NetUserPass	call NetUserPass(<f-args>)
com! -nargs=+           Ncopy           call netrw#NetObtain(<f-args>)
com! -nargs=*	        Nsource		call netrw#NetSavePosn()<bar>call netrw#NetSource(<f-args>)<bar>call netrw#NetRestorePosn()

" Commands: :Explore, :Sexplore, Hexplore, Vexplore {{{2
com! -nargs=* -bar -bang -count=0 -complete=dir	Explore		call netrw#Explore(<count>,0,0+<bang>0,<q-args>)
com! -nargs=* -bar -bang -count=0 -complete=dir	Sexplore	call netrw#Explore(<count>,1,0+<bang>0,<q-args>)
com! -nargs=* -bar -bang -count=0 -complete=dir	Hexplore	call netrw#Explore(<count>,1,2+<bang>0,<q-args>)
com! -nargs=* -bar -bang -count=0 -complete=dir	Vexplore	call netrw#Explore(<count>,1,4+<bang>0,<q-args>)
com! -nargs=* -bar       -count=0 -complete=dir	Texplore	call netrw#Explore(<count>,0,6        ,<q-args>)
com! -nargs=* -bar -bang			Nexplore	call netrw#Explore(-1,0,0,<q-args>)
com! -nargs=* -bar -bang			Pexplore	call netrw#Explore(-2,0,0,<q-args>)

" Commands: NetrwSettings {{{2
com! -nargs=0 NetrwSettings :call netrwSettings#NetrwSettings()

" Maps:
if !exists("g:netrw_nogx") && maparg('g','n') == ""
 if !hasmapto('<Plug>NetrwBrowseX')
  nmap <unique> gx <Plug>NetrwBrowseX
 endif
 nno <silent> <Plug>NetrwBrowseX :call netrw#NetBrowseX(expand("<cWORD>"),0)<cr>
endif

" ---------------------------------------------------------------------
" LocalBrowse: {{{2
fun! s:LocalBrowse(dirname)
  " unfortunate interaction -- debugging calls can't be used here;
  " the BufEnter event causes triggering when attempts to write to
  " the DBG buffer are made.
"  echomsg "dirname<".a:dirname.">"
  if has("amiga")
   " The check against '' is made for the Amiga, where the empty
   " string is the current directory and not checking would break
   " things such as the help command.
   if a:dirname != '' && isdirectory(a:dirname)
    silent! call netrw#LocalBrowseCheck(a:dirname)
   endif
  elseif isdirectory(a:dirname)
"   echomsg "dirname<".dirname."> isdir"
   silent! call netrw#LocalBrowseCheck(a:dirname)
  endif
  " not a directory, ignore it
endfun

" ---------------------------------------------------------------------
" NetrwStatusLine: {{{1
fun! NetrwStatusLine()
"  let g:stlmsg= "Xbufnr=".w:netrw_explore_bufnr." bufnr=".bufnr("%")." Xline#".w:netrw_explore_line." line#".line(".")
  if !exists("w:netrw_explore_bufnr") || w:netrw_explore_bufnr != bufnr("%") || !exists("w:netrw_explore_line") || w:netrw_explore_line != line(".") || !exists("w:netrw_explore_list")
   let &stl= s:netrw_explore_stl
   if exists("w:netrw_explore_bufnr")|unlet w:netrw_explore_bufnr|endif
   if exists("w:netrw_explore_line")|unlet w:netrw_explore_line|endif
   return ""
  else
   return "Match ".w:netrw_explore_mtchcnt." of ".w:netrw_explore_listlen
  endif
endfun

" ------------------------------------------------------------------------
" NetUserPass: set username and password for subsequent ftp transfer {{{1
"   Usage:  :call NetUserPass()			-- will prompt for userid and password
"	    :call NetUserPass("uid")		-- will prompt for password
"	    :call NetUserPass("uid","password") -- sets global userid and password
fun! NetUserPass(...)

 " get/set userid
 if a:0 == 0
"  call Dfunc("NetUserPass(a:0<".a:0.">)")
  if !exists("g:netrw_uid") || g:netrw_uid == ""
   " via prompt
   let g:netrw_uid= input('Enter username: ')
  endif
 else	" from command line
"  call Dfunc("NetUserPass(a:1<".a:1.">) {")
  let g:netrw_uid= a:1
 endif

 " get password
 if a:0 <= 1 " via prompt
"  call Decho("a:0=".a:0." case <=1:")
  let g:netrw_passwd= inputsecret("Enter Password: ")
 else " from command line
"  call Decho("a:0=".a:0." case >1: a:2<".a:2.">")
  let g:netrw_passwd=a:2
 endif
"  call Dret("NetUserPass")
endfun

" ------------------------------------------------------------------------
" NetReadFixup: this sort of function is typically written by the user {{{1
"               to handle extra junk that their system's ftp dumps
"               into the transfer.  This function is provided as an
"               example and as a fix for a Windows 95 problem: in my
"               experience, win95's ftp always dumped four blank lines
"               at the end of the transfer.
if has("win95") && exists("g:netrw_win95ftp") && g:netrw_win95ftp
 fun! NetReadFixup(method, line1, line2)
"   call Dfunc("NetReadFixup(method<".a:method."> line1=".a:line1." line2=".a:line2.")")
   if method == 3   " ftp (no <.netrc>)
    let fourblanklines= line2 - 3
    silent fourblanklines.",".line2."g/^\s*/d"
   endif
"   call Dret("NetReadFixup")
 endfun
endif

" ------------------------------------------------------------------------
" Modelines And Restoration: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim:ts=8 fdm=marker
