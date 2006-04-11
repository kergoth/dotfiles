" cecscope.vim:
"  Author: Charles E. Campbell, Jr.
"  Date:   Jan 30, 2006
"  Version: 1
"  Usage:  :CS[!]  [cdefgist]
"          :CSl[!] [cdefgist]
"          :CSs[!] [cdefgist]
"          :CSh     (gives help)
" ---------------------------------------------------------------------

" ---------------------------------------------------------------------
" Load Once: {{{1
if !has("cscope") || &cp || exists("g:loaded_cecscope") || v:version < 700
 finish
endif
let g:loaded_cecscope= "v1"

" ---------------------------------------------------------------------
" Public Interface: {{{1
com!       -nargs=* CS  call s:Cscope(<bang>0,<f-args>) 
com!       -nargs=? CSh call s:CscopeHelp(<q-args>)
com! -bang -nargs=* CSl call s:Cscope(4+<bang>0,<f-args>) 
com! -bang -nargs=* CSs call s:Cscope(2+<bang>0,<f-args>) 

" ---------------------------------------------------------------------
"  Functions: {{{1

" ---------------------------------------------------------------------
" Cscope: {{{2
"   Usage: :CS[ls][!]  [sgctefid]
" !: use vertical split
"
" -----
" style
" -----
"  s    (symbol)   find all references to the token under cursor
"  g    (global)   find global definition(s) of the token under cursor
"  c    (calls)    find all calls to the function name under cursor
"  t    (text)     find all instances of the text under cursor
"  e    (egrep)    egrep search for the word under cursor
"  f    (file)     open the filename under cursor
"  i    (includes) find files that include the filename under cursor
"  d    (called)   find functions that function under cursor calls
fun! s:Cscope(mode,...)
"  call Dfunc("Cscope(mode=".a:mode.") a:0=".a:0)
  if a:0 >= 1
   let style= a:1
"   call Decho("style=".style)
  endif
  if !&cscopetag
   " use cscope and ctags for ctrl-], :ta, etc
   " check cscope for symbol definitions before using ctags
   set cscopetag csto=0

   " specify cscope database in current directory
   " or use whatever the CSCOPE_DB environment variable says to
   if filereadable("cscope.out")
   	cs add cscope.out
   elseif $CSCOPE_DB != "" && filereadable($CSCOPE_DB)
   	cs add $CSCOPE_DB
   else
   	if executable("cscope")
	 call system("cscope ".expand("%"))
     if !filereadable("cscope.out")
      echohl WarningMsg | echoerr "(Cscope) can't find cscope database" | echohl None
     endif
	endif
   endif
   if !executable("cscope")
    echohl Error | echoerr "can't execute cscope!" | echohl None
"    call Dret("Cscope : can't execute cscope")
    return
   endif

   " show message whenver any cscope database added
   set cscopeverbose
  endif

  " decide if cs/scs and vertical/horizontal
  if a:mode == 0
   let mode= "cs"
  elseif a:mode == 1
   let a:mode= "vert cs"
  elseif a:mode == 2
   let mode= "scs"
  elseif a:mode == 3
   let mode= "vert scs"
  elseif a:mode == 4
   let mode= "silent cs"
   redir! > cscope.qf
  elseif a:mode == 5
   " restore previous efm
   if exists("b:cscope_efm")
    let &efm= b:cscope_efm
    unlet b:cscope_efm
   endif
"   call Dret("Cscope")
   return
  else
   echohl Error | echoerr "(Cscope) mode=".a:mode." not supported" | echohl None
"   call Dret("Cscope")
   return
  endif

  if a:0 == 2
   let word= a:2
  elseif style =~ '[fi]'
   let word= expand("<cfile>")
  else
   let word= expand("<cword>")
  endif

  if style == 'f'
"   call Decho("exe ".mode." find f ".word)
   exe mode." find f ".word
  elseif style == 'i'
"   call Decho("exe ".mode." find i ^".word."$")
   exe mode." find i ^".word."$"
  else
"   call Decho("exe ".mode." find ".style." ".word)
   exe mode." find ".style." ".word
  endif

  if a:mode == 4
   redir END
   if !exists("b:cscope_efm")
    let b:cscope_efm= &efm
    setlocal efm=%C\ \ \ \ \ \ \ \ \ \ \ \ \ %m
    setlocal efm+=%I\ %#%\\d%\\+\ %#%l\ %#%f\ %m
    setlocal efm+=%-GChoice\ number\ %.%#
    setlocal efm+=%-G%.%#line\ \ filename\ /\ context\ /\ line
    setlocal efm+=%-G%.%#Cscope\ tag:\ %.%#
    setlocal efm+=%-G
   endif
   lg cscope.qf
   silent! lope 5
   if has("menu") && has("gui_running") && &go =~ 'm'
    exe 'silent! unmenu '.g:DrChipTopLvlMenu.'Cscope.Restore\ Error\ Format'
    exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Restore\ Error\ Format	:CSl!'."<cr>"
   endif
  endif
"  call Dret("Cscope")
endfun

" ---------------------------------------------------------------------
" CscopeHelp: {{{2
fun! s:CscopeHelp(...)
"  call Dfunc("CscopeHelp() a:0=".a:0)
  if a:0 == 0 || a:1 == ""
   echo "CS     [cdefgist]   : cscope"
   echo "CSl[!] [cdefgist]   : locallist style (! restores efm)"
   echo "CSs[!] [cdefgist]   : split window and use cscope "
   let styles="!cdefgist"
   while styles != ""
"   	call Decho("styles<".styles.">")
   	call s:CscopeHelp(strpart(styles,0,1))
	let styles= strpart(styles,1)
   endwhile
"   call Dret("CscopeHelp : all")
   return
  elseif a:1 == '!' | echo "!            split vertically"
  elseif a:1 == 'c' | echo "c (calls)    find functions calling function under cursor"
  elseif a:1 == 'd' | echo "d (called)   find functions called by function under cursor"
  elseif a:1 == 'e' | echo "e (egrep)    egrep search for the word under cursor"
  elseif a:1 == 'f' | echo "f (file)     open the file named under cursor"
  elseif a:1 == 'g' | echo "g (global)   find global definition(s) of word under cursor"
  elseif a:1 == 'i' | echo "i (includes) find files that #include file named under cursor"
  elseif a:1 == 's' | echo "s (symbol)   find all references to the word under cursor"
  elseif a:1 == 't' | echo "t (text)     find all instances of the word under cursor"
  else              | echo a:1." not supported"
  endif

"  call Dret("CscopeHelp : on <".a:1.">")
endfun

" ---------------------------------------------------------------------
" CscopeMenu: {{{2
fun! CscopeMenu(type)
"  call Dfunc("CscopeMenu(type=".a:type.")")
  if !exists("g:DrChipTopLvlMenu")
   let g:DrChipTopLvlMenu= "DrChip."
  endif
  if !exists("s:installed_menus")
   exe "menu ".g:DrChipTopLvlMenu."Cscope.Help	:CSh\<cr>"
  endif
  if exists("s:installed_menus")
"   silent! unmenu DrChipCscope
   exe 'silent! unmenu '.g:DrChipTopLvlMenu.'Cscope.Use\ Messages\ Display'
   exe 'silent! unmenu '.g:DrChipTopLvlMenu.'Cscope.Use\ Horiz\ Split\ Display'
   exe 'silent! unmenu '.g:DrChipTopLvlMenu.'Cscope.Use\ Vert\ Split\ Display'
   exe 'silent! unmenu '.g:DrChipTopLvlMenu.'Cscope.Use\ Quickfix\ Display'
  endif
  if a:type == 1
   let cmd= "CS"
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Horiz\ Split\ Display 	:call CscopeMenu(2)'."<cr>"
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Vert\ Split\ Display	:call CscopeMenu(2)'."<cr>"
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Quickfix\ Display	:call CscopeMenu(2)'."<cr>"
  elseif a:type == 2
   let cmd= 'CSl'
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Messages\ Display	:call CscopeMenu(2)'."<cr>"
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Horiz\ Split\ Display	:call CscopeMenu(2)'."<cr>"
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Vert\ Split\ Display	:call CscopeMenu(2)'."<cr>"
  elseif a:type == 3
   let cmd= 'CSs'
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Messages\ Display	:call CscopeMenu(2)'."<cr>"
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Horiz\ Split\ Display	:call CscopeMenu(2)'."<cr>"
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Quickfix\ Display	:call CscopeMenu(2)'."<cr>"
  elseif a:type == 4
   let cmd= 'CSs!'
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Messages\ Display	:call CscopeMenu(2)'."<cr>"
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Horiz\ Split\ Display\  :call CscopeMenu(2)'."<cr>"
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Use\ Quickfix\ Display	:call CscopeMenu(2)'."<cr>"
  endif

  if exists("s:installed_menus")
   exe 'unmenu '.g:DrChipTopLvlMenu.'Cscope.Find\ functions\ which\ call\ word\ under\ cursor'
   exe 'unmenu '.g:DrChipTopLvlMenu.'Cscope.Find\ functions\ called\ by\ word\ under\ cursor'
   exe 'unmenu '.g:DrChipTopLvlMenu.'Cscope.Egrep\ search\ for\ word\ under\ cursor'
   exe 'unmenu '.g:DrChipTopLvlMenu.'Cscope.Open\ file\ under\ cursor'
   exe 'unmenu '.g:DrChipTopLvlMenu.'Cscope.Find\ globally\ word\ under\ cursor'
   exe 'unmenu '.g:DrChipTopLvlMenu.'Cscope.Find\ files\ that\ include\ word\ under\ cursor'
   exe 'unmenu '.g:DrChipTopLvlMenu.'Cscope.Find\ all\ references\ to\ symbol\ under\ cursor'
   exe 'unmenu '.g:DrChipTopLvlMenu.'Cscope.Find\ all\ instances\ of\ text\ under\ cursor'
   exe 'silent! unmenu '.g:DrChipTopLvlMenu.'Cscope.Restore\ Error\ Format'
  endif

  exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Find\ functions\ which\ call\ word\ under\ cursor	:'.cmd.'\ c'."<cr>"
  exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Find\ functions\ called\ by\ word\ under\ cursor	:'.cmd.'\ d'."<cr>"
  exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Egrep\ search\ for\ word\ under\ cursor	:'.cmd.'\ e'."<cr>"
  exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Open\ file\ under\ cursor	:'.cmd.'\ f'."<cr>"
  exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Find\ globally\ word\ under\ cursor	:'.cmd.'\ g'."<cr>"
  exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Find\ files\ that\ include\ word\ under\ cursor	:'.cmd.'\ i'."<cr>"
  exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Find\ all\ references\ to\ symbol\ under\ cursor	:'.cmd.'\ s'."<cr>"
  exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Find\ all\ instances\ of\ text\ under\ cursor	:'.cmd.'\ t'."<cr>"
  if exists("b:cscope_efm")
   exe 'menu '.g:DrChipTopLvlMenu.'Cscope.Restore\ Error\ Format	:CSl!'."<cr>"
  endif

  let s:installed_menus= 1
"  call Dret("CscopeMenu")
endfun

" ---------------------------------------------------------------------
"  Install Menus: {{{1
if !exists("s:installed_menus") && has("menu") && has("gui_running") && &go =~ 'm'
 call CscopeMenu(1)
endif

" ---------------------------------------------------------------------
" Modelines: {{{1
" vim: fdm=marker
" HelpExtractor:
"  Author:	Charles E. Campbell, Jr.
"  Version:	3
"  Date:	May 25, 2005
"
"  History:
"    v3 May 25, 2005 : requires placement of code in plugin directory
"                      cpo is standardized during extraction
"    v2 Nov 24, 2003 : On Linux/Unix, will make a document directory
"                      if it doesn't exist yet
"
" GetLatestVimScripts: 748 1 HelpExtractor.vim
" ---------------------------------------------------------------------
set lz
let s:HelpExtractor_keepcpo= &cpo
set cpo&vim
let docdir = expand("<sfile>:r").".txt"
if docdir =~ '\<plugin\>'
 let docdir = substitute(docdir,'\<plugin[/\\].*$','doc','')
else
 if has("win32")
  echoerr expand("<sfile>:t").' should first be placed in your vimfiles\plugin directory'
 else
  echoerr expand("<sfile>:t").' should first be placed in your .vim/plugin directory'
 endif
 finish
endif
if !isdirectory(docdir)
 if has("win32")
  echoerr 'Please make '.docdir.' directory first'
  unlet docdir
  finish
 elseif !has("mac")
  exe "!mkdir ".docdir
 endif
endif

let curfile = expand("<sfile>:t:r")
let docfile = substitute(expand("<sfile>:r").".txt",'\<plugin\>','doc','')
exe "silent! 1new ".docfile
silent! %d
exe "silent! 0r ".expand("<sfile>:p")
silent! 1,/^" HelpExtractorDoc:$/d
exe 'silent! %s/%FILE%/'.curfile.'/ge'
exe 'silent! %s/%DATE%/'.strftime("%b %d, %Y").'/ge'
norm! Gdd
silent! wq!
exe "helptags ".substitute(docfile,'^\(.*doc.\).*$','\1','e')

exe "silent! 1new ".expand("<sfile>:p")
1
silent! /^" HelpExtractor:$/,$g/.*/d
silent! wq!

set nolz
unlet docdir
unlet curfile
"unlet docfile
let &cpo= s:HelpExtractor_keepcpo
unlet s:HelpExtractor_keepcpo
finish

" ---------------------------------------------------------------------
" Put the help after the HelpExtractorDoc label...
" HelpExtractorDoc:
*cecscope.txt*	Charles E Campblell's Cscope Plugin		Jan 30, 2006

Author:  Charles E. Campbell, Jr.  <NdrOchip@ScampbellPfamily.AbizM>
	 (remove NOSPAM from Campbell's email first)
Copyright: (c) 2004-2006 by Charles E. Campbell, Jr.	*cecscope-copyright*
           The VIM LICENSE applies to cecscope.vim and cecscope.txt
           (see |copyright|) except use "cecscope" instead of "Vim".
	   No warranty, express or implied.  Use At-Your-Own-Risk.
Note:    Required:
         * your :version of vim must have +cscope
         * vim 7.0aa snapshot#188 or later for the "quickfix" display

==============================================================================
1. Contents						*cecscope-contents*

  1. Contents............................: |cescope-contents|
  2. Installing cecscope.................: |cecscope-install|
  3. Cescope Manual......................: |cecscope-manual|
  3. Cescope Tutorial....................: |cecscope-tutorial|
  5. Cescope History.....................: |cecscope-history|
   	

==============================================================================
2. Installing cecscope					*cecscope-install*

    1. Move/copy cecscope.tar.gz to
        unix/linux: ~/.vim
        Windows   : ...\vimfiles
    2. gunzip cecscope.tar.gz
    3. tar -oxvf cecscope.tar
    4. vim    (this step enables the help)
       :helptags doc
       :q


==============================================================================
3. Cescope Manual					*cecscope-manual*
							*:CS* *:CSl* *CSs* *CSh*
    :CS     [cdefgist]   : cscope
    :CSl[!] [cdefgist]   : locallist style (! restores efm)
    :CSs[!] [cdefgist]   : split window and use cscope
    :CSh                 : give quick help

    !            split vertically
    c (calls)    find functions calling function under cursor
    d (called)   find functions called by function under cursor
    e (egrep)    egrep search for the word under cursor
    f (file)     open the file named under cursor
    g (global)   find global definition(s) of word under cursor
    i (includes) find files that #include file named under cursor
    s (symbol)   find all references to the word under cursor
    t (text)     find all instances of the word under cursor

    In addition, when using gvim, there is a menu interface under the
    "DrChip" label with all of the above options mentioned.  The first
    four items are taken from: 

        Help
        Use Messages Display
        Use Horiz Split Display
        Use Vert Split Display
        Use Quickfix Display

    The "Use" method that's currently active will not be present (initially,
    that's the "Use Messages Display").


==============================================================================
4. Cescope Tutorial					*cecscope-tutorial*

   GETTING STARTED
    To use this plugin you'll need to have vim 7.0aa, snapshot#188 or later,
    and your version should have +cscope.  To check that latter condition,
    either look for +cscope through the output of >
        :version
<   or type >
        :echo has("cscope")
<   You'll need to recompile your vim if you don't have +cscope.

    BUILDING CSCOPE DATABASE
    Once you have your cscope-enabled vim, then change directory to wherever
    you have some C code.  Type >
        cscope -b *.[ch]
<   and the cscope database will be generated (<cscope.out>).  If you don't
    have a cscope database, the file specified by the environment variable
    named >
        $CSCOPE_DB
<   will be used.  Sadly, otherwise cecscope.vim will issue a warning message.

    SELECTING A DISPLAY MODE

    Assuming you're using gvim: Select >
        DrChip:Cscope:Use Quickfix Display
<   This will make the information from cscope show up in a local quickfix
    window (see |lopen|).  The other modes allow one to see cscope messages
    as regular messages (which will shortly disappear) or in another window.

    USING THE QUICKFIX DISPLAY
    Place your cursor atop some function that you've written: >
        DrChip:Cscope:Find function which calls word under cursor
<   and you'll see a locallist window open up which tells you something like >
        xgrep.c|410 info| <<sprt>> Edbg(("xgrep(%s)",sprt(filename)));
<   To jump to that entry, type >
        :ll
<   To jump to the next entry, type >
        :lne
<   To jump to the previous entry, type >
        :lp
<   You can also switch windows (ex. <ctrl-w>j, see |window-move-cursor|)
    to the locallist window, move the cursor about normally, then hit the
    <cr> to jump to the selection.

    USING THE COMMAND LINE
    You could've done the above using the command line!  Again, just
    place your cursor atop some function that you've written, then type: >
        :CSl c
<   You may use the :ll, :lne, and :lp commands as before.

    HELP
    Just type >
        :CSh
<   for a quick help display.  Of course, you can always type : >
        :help CS
<   too.


==============================================================================
5. Cescope History					*cecscope-history*

   v1 Jan 30, 2006 : initial release

=====================================================================
vim:tw=78:ts=8:ft=help:sts=4:et:ai
