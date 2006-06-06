" AsNeeded: allows functions/maps to reside in .../.vim/AsNeeded/ directory
"           and will enable their loaded as needed
" Author:	Charles E. Campbell, Jr.
" Date:		Mar 14, 2006
" Version:	12
" Copyright:    Copyright (C) 2004-2005 Charles E. Campbell, Jr. {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               AsNeeded.vim is provided *as is* and comes with no warranty
"               of any kind, either expressed or implied. By using this
"               plugin, you agree that in no event will the copyright
"               holder be liable for any damages resulting from the use
"               of this software.
"
" Usage: {{{1
"
" Undefined functions will be caught and loaded automatically, although
" whatever invoked them will then need to be re-run
"
" Undefined maps and commands need to be processed first:
" 	:AsNeeded map         :AN map
" 	:AsNeeded command     :AN command
" will search for the map/command for *.vim files in the AsNeeded directory.
"
" To both find and execute a command or map, use
"   :ANX map
"   :ANX command
"
" To speed up the process, generate a ANtags file
"   :MakeANtags
"
" Isaiah 42:1 : Behold, my servant, whom I uphold; my chosen, in whom {{{1
" my soul delights: I have put my Spirit on him; he will bring forth
" justice to the Gentiles.
"
" GetLatestVimScripts: 915 1 :AutoInstall: AsNeeded.vim
" Load Once: {{{1
if exists("g:loaded_AsNeeded") || &cp
 finish
endif
let g:loaded_AsNeeded = "v12"
let s:keepcpo         = &cpo
set cpo&vim

" ---------------------------------------------------------------------
"  Public Interface:	{{{1
au FuncUndefined *       call AsNeeded(1,expand("<afile>"))
com! -nargs=1 AsNeeded   call AsNeeded(2,<q-args>)
com! -nargs=1 AN         call AsNeeded(2,<q-args>)
com! -nargs=1 ANX        call AsNeeded(3,<q-args>)
com! -nargs=0 MakeANtags call MakeANtags()
com! -nargs=0 MkAsNeeded call MakeANtags()

" ---------------------------------------------------------------------
"  AsNeeded: looks for maps in AsNeeded/*.vim using the runtimepath. {{{1
"            Returns 0=success
"                   -1=failure
fun! AsNeeded(type,cmdmap)
"  call Dfunc("AsNeeded(type=".a:type.",cmdmap<".a:cmdmap.">)")

  if a:type == 1 && a:cmdmap =~ '#'
   " don't consider function names with '#' embedded - ie. let Bram's
   " autoload try without interference
"   call Dret("AsNeeded 0")
   return 0
  endif

  " ------------------------------
  " save&set registers and options {{{2
  " ------------------------------
  call s:SaveSettings()

  " -------------------------------------------
  " initialize search for requested command/map {{{2
  " -------------------------------------------
  let keeplastbufnr= bufnr("$")
"  call Decho("keeplastbufnr=".keeplastbufnr)
  silent 1new! AsNeededBuffer
  let asneededbufnr= bufnr("%")
"  call Decho("asneededbufnr=".asneededbufnr)
  setlocal buftype=nofile noswapfile noro nobl

  " -----------------------
  "  check for / use ANtags {{{2
  " -----------------------
  let ANtags= globpath(&rtp,"AsNeeded/ANtags")
  if ANtags != ""
   %d
   exe "silent 0r ".ANtags

   if     a:type == 1
    let srch= search("^f\t".a:cmdmap)
   elseif a:type >= 2
    let srchstring= substitute(a:cmdmap,' .*$','','e')
"	call Decho("srchstring<".srchstring.">")
    if exists("g:mapleader") && match(srchstring,'^'.g:mapleader) == 0
	 let srchstring= substitute(escape(srchstring,'\'),'^.\(.*\)$','&\\|<[lL][eE][aA][dD][eE][rR]>\1','')
	endif
"	call Decho("srchstring<".srchstring.">")
	let result= search('^[mc]\t\<'.srchstring.'\>')
	if result == 0
     let srch= search('^[mc]\t'.srchstring)
	else
	 let srch= result
	endif
   endif
"   call Decho("using <ANtags>: srchstring<".srchstring."> srch=".srch)

   if srch != 0
   	let curline   = getline(".")
   	let vimfile   = substitute(curline,'^\%(.\+\t\)\{2}\(.*\)$','\1','')
	if curline !~ '^f'
   	 let mapstring = curline
	endif

"	call Decho("vimfile<".vimfile.">")
   endif

  else
"   call Decho("<ANtags> not found, using search")

   " --------------------
   " Set up search string {{{2
   " --------------------
   let srchstring= substitute(a:cmdmap,' .*$','','e')
   if     a:type == 1
    let srchstring= '\<fu\%[nction]!\=\s*\(<[sS][iI][dD]>\|[sS]:\)\='.srchstring.'\>'
   elseif a:type > 1
    if exists("g:mapleader") && match(srchstring,'^'.g:mapleader) == 0
     " allow srchstring to handle map...<Leader>modsrch
	 let  mlgt      = '[>'.escape(escape(g:mapleader,'\'),'\').']'
	 let  modsrch   = substitute(srchstring,g:mapleader,mlgt,'')
    else
     " support searching for maps or commands
	 let  mlgt      = '[>\\\\]'
	 let  modsrch   = substitute(srchstring,'^\\',mlgt,'')
    endif
"    call Decho("mlgt      <".mlgt.">")
"    call Decho("modsrch   <".modsrch.">")
    let srchstring= '\(map\|[nvoilc]m\%[ap]\|\([oilc]\=no\|[nv]n\)\%[remap]\|com\%[mand]\)!\=\s.*'.modsrch.'\s'
"    call Decho("srchstring<".srchstring.">")
   endif

   " --------------------------------
   " search for requested command/map {{{2
   " --------------------------------
   let vimfiles=substitute(globpath(&rtp,"AsNeeded/*.vim"),'\n',',',"ge")
   while vimfiles != ""
    let vimfile = substitute(vimfiles,',.*$','','e')
    let vimfiles= (vimfiles =~ ",")? substitute(vimfiles,'^[^,]*,\(.*\)$','\1','e') : ""
"    call Decho(".considering file<".vimfile.">")
    %d
    exe "silent 0r ".vimfile
    if bufnr("$") > asneededbufnr
"     call Decho("bwipe read-in buf#".bufnr("$")." (> asneededbufnr=".asneededbufnr.")")
     exe "silent! ".bufnr("$")."bwipe!"
    endif
    let srchresult= search(srchstring)
"	call Decho("srchresult=".srchresult)
    if srchresult != 0
     let mapstring = getline(srchresult)
"     call Decho("Found mapstring<".mapstring."> maparg<".maparg(mapstring,'n')."> line#".line(".")." col=".col(".")." <".getline(".").">")
     break
    endif
    let vimfile= ""
   endwhile
  endif
  q!

  " ---------------------------
  " source in the selected file {{{2
  " ---------------------------
  if exists("vimfile") && vimfile != ""
"   call Decho("success: sourcing ".vimfile)
   call s:RestoreSettings()
   exe "so ".vimfile
   call s:SaveSettings()
   if exists("g:AsNeededSuccess")
    let vimf=substitute(vimfile, $HOME, '\~', '')
	if exists("srchstring")
     echomsg "***success*** AsNeeded found <".srchstring."> in <".vimf.">; now loaded"
	else
     echomsg "***success*** AsNeeded found command in <".vimf.">; now loaded"
	endif
   endif
   " successfully sourced file containing srchstring
   if a:type == 3 && exists("mapstring")
    let maprhs= maparg(a:cmdmap,'n')
"    call Decho("type==".a:type.": maprhs<".maprhs."> mapstring<".mapstring.">")
    call s:RestoreSettings()
   	if maprhs == ""
	 " attempt to execute a:cmdmap as a command (with no arguments)
"	 call Decho("exe ".a:cmdmap)
   	 exe "silent! ".a:cmdmap
	else
	 " attempt to execute a:cmdmap as a normal command (ie. a map)
"	 call Decho("norm ".a:cmdmap)
   	 exe "norm ".a:cmdmap
	endif
   endif

   if asneededbufnr > keeplastbufnr
    call s:SaveSettings()
"    call Decho("bwipe asneeded buf#".asneededbufnr)
    exe "silent! ".asneededbufnr."bwipe!"
	call s:RestoreSettings()
   endif
"   call Dret("AsNeeded 0")
   return 0
  endif

  call s:RestoreSettings()

  " ----------------------------------------------------------------
  " failed to find srchstring in *.vim files in AsNeeded directories {{{2
  " ----------------------------------------------------------------
"  call Decho("***warning*** AsNeeded unable to find <".a:cmdmap."> in the (runtimepath)/AsNeeded directory")
  echohl WarningMsg
  echomsg "***warning*** AsNeeded unable to find <".a:cmdmap."> in the (runtimepath)/AsNeeded directory"
  echohl NONE
  if asneededbufnr > keeplastbufnr
"   	call Decho("bwipe asneeded buf#".asneededbufnr)
   exe "silent! ".asneededbufnr."bwipe!"
  endif
"  call Dret("AsNeeded -1")
  return -1
endfun

" ---------------------------------------------------------------------
" MakeANtags: makes the (optional) ANtags file {{{1
fun! MakeANtags()
"  call Dfunc("MakeANtags()")

  " ------------------------------
  " save&set registers and options {{{2
  " ------------------------------
  let keepa   = @a
  let keepei  = &ei
  let keeprep = &report
  set lz ei=all report=10000

  " --------------------------------------------------------
  " initialize search for all commands, maps, and functions: {{{2
  " --------------------------------------------------------
  let keeplastbufnr= bufnr("$")
"  call Decho("keeplastbufnr=".keeplastbufnr)
  silent 1new! AsNeededBuffer
  let asneededbufnr= bufnr("%")
"  call Decho("asneededbufnr=".asneededbufnr)
  setlocal noswapfile

  let fncsrch  = '\<fu\%[nction]!\=\s\+\%([sS]:\|<[sS][iI][dD]>\)\@<!\(\u\w*\)\s*('
  let mapsrch  = '\<\%(map\|[nvoilc]m\%[ap]\|[oic]\=no\%[remap]\|[nl]n\%[oremap]\)!\=\s\+\%(<\%([sS][iI][lL][eE][nN][tT]\|[uU][nN][iI][qQ][uU][eE]\|[bB][uU][fF][fF][eE][rR]\|[sS][cC][rR][iI][pP][tT]\)>\s\+\)*\(\S\+\)\s'
  let cmdsrch  = '\<com\%[mand]!\=\s.\{-}\(\u\w*\)\>'
  let fmcsrch  = fncsrch.'\|'.mapsrch.'\|'.cmdsrch
  let mapreject= '\<\%(map\|[nvoilc]m\%[ap]\|[oic]\=no\%[remap]\|[nl]n\%[oremap]\)!\=\s\+\%(<\%([sS][iI][lL][eE][nN][tT]\|[uU][nN][iI][qQ][uU][eE]\|[bB][uU][fF][fF][eE][rR]\|[sS][cC][rR][iI][pP][tT]\)>\s\+\)*<[pP][lL][uU][gG]>\(\u\w*\)\s'

  " remove any old <ANtags>
  if filereadable(globpath(&rtp,"AsNeeded/ANtags"))
"   call Decho("removing old <ANtags>")
   call delete(globpath(&rtp,"AsNeeded/ANtags"))
  endif

  " ---------------------------------------------
  " search for all commands, maps, and functions: {{{2
  " ---------------------------------------------
  let vimfiles= substitute(globpath(&rtp,"AsNeeded/*.vim"),'\n',',',"ge")
  let ANtags  = substitute(vimfiles,'AsNeeded.*','AsNeeded/ANtags','e')
  let first   = 1
"  call Decho("ANtags<".ANtags.">")

  while vimfiles != ""
   let vimfile = substitute(vimfiles,',.*$','','e')
   let vimfiles= (vimfiles =~ ",")? substitute(vimfiles,'^[^,]*,\(.*\)$','\1','e') : ""
"   call Decho("considering file<".vimfile.">")
   %d
   exe "silent 0r ".vimfile
   if bufnr("$") > asneededbufnr
"    call Decho(".bwipe read-in buf#".bufnr("$"))
    exe "silent! ".bufnr("$")."bwipe!"
   endif

   " clean out all non-map, non-command, non-function lines
   silent! g/^\s*"/d
   silent! g/\c<script>/d
   exe 'silent! %g@'.mapreject.'@d'
   silent! g/^\s*echo\(err\|msg\)\=\>/d
   silent! %s/^\s*exe\%[cute]\s\+['"]\(.*\)['"]/\1/e
   " remove anything that doesn't look like a map, command, or function
   exe "silent! v/".fmcsrch."/d"
"   call Decho("Before conversion to ANtags-style:")
"   call Dredir("%p")

   " convert remaining lines into ANtag-style search patterns
   exe 'silent! %s@^[ \t:]*'.fncsrch.'.*$@f\t\1\t'.escape(vimfile,'@ \').'@e'
   exe 'silent! %s@^.*'.mapsrch.'.*$@m\t\1\t'.escape(vimfile,'@ \').'@e'
   exe 'silent! %s@^[ \t:]*'.cmdsrch.'.*$@c\t\1\t'.escape(vimfile,'@ \').'@e'

   " clean up anything that snuck into <ANtags> that shouldn't be there.
   silent v/^[mfc]\t/d
   silent g/^m\t"\./d
   silent g/^m\t<[sS][iI][dD]>/d
   silent g/^m\t.*'\./d

   " record in <ANtags>
   if  line("$") <= 1 && col("$") <= 2
   	echoerr "***warning*** no tags found in file <".vimfile.">!"
"	call Decho("***warning*** no tags found in file <".vimfile.">!")
"	call Decho("line($)=".line("$")." col($)=".col("$"))
   else
    if first
"     call Decho(".write ".line("$")." tags to ANtags<".ANtags.">")
     exe "silent w! ".ANtags
 	let first= 0
    else
"     call Decho(".append ".line("$")." tags to ANtags<".ANtags.">")
     exe "silent w >>".ANtags
    endif
"	call Decho("After conversion to ANtags-style:")
"    call Dredir("%p")
   endif

   let vimfile= ""
  endwhile
  q!

  " ------------------------------
  " restore registers and settings {{{2
  " ------------------------------
  set nolz
  let @a      = keepa
  let &ei     = keepei
  let &report = keeprep

"  call Dret("MakeANtags")
endfun

" ---------------------------------------------------------------------
" SaveSettings: {{{1
fun! s:SaveSettings()
"  call Dfunc("SaveSettings()")
  let s:keeprep = &report
  let s:keepa   = @a
  let s:keepei  = &ei
  let s:keeplz  = &lz
  set lz ei=all report=10000
"  call Dret("SaveSettings")
endfun

" ---------------------------------------------------------------------
" s:RestoreSettings: {{{1
fun! s:RestoreSettings()
"  call Dfunc("s:RestoreSettings()")
  let @a      = s:keepa
  let &ei     = s:keepei
  let &lz     = s:keeplz
  let &report = s:keeprep
"  call Dret("s:RestoreSettings")
endfun

" ---------------------------------------------------------------------
"  Restore Cpo: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" ---------------------------------------------------------------------
"  Modelines: {{{1
" vim: ts=4 fdm=marker
