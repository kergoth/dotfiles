" Decho.vim:   Debugging support for VimL
" Maintainer:  Charles E. Campbell, Jr. PhD <cec@NgrOyphSon.gPsfAc.nMasa.gov>
" Date:        Sep 05, 2006
" Version:     18
"
" Usage: {{{1
"   Decho "a string"
"   call Decho("another string")
"   let g:decho_bufname = "ANewDBGBufName"
"   let g:decho_bufenter= 1    " tells Decho to ignore BufEnter, WinEnter,
"                              " WinLeave events while Decho is working
"   call Decho("one","thing","after","another")
"   DechoOn     : removes any first-column '"' from lines containing Decho
"   DechoOff    : inserts a '"' into the first-column in lines containing Decho
"   DechoMsgOn  : use echomsg instead of DBG buffer
"   DechoMsgOff : turn debugging off
"   DechoRemOn  : turn remote Decho messaging on
"   DechoRemOff : turn remote Decho messaging off
"   DechoVarOn [varname] : use variable to write debugging messages to
"   DechoVarOff : turn debugging off
"   DechoTabOn  : turn debugging on (uses a separate tab)
"   DechoTabOff : turn debugging off
"
" GetLatestVimScripts: 642 1 :AutoInstall: Decho.vim
" GetLatestVimScripts: 1066 1 :AutoInstall: cecutil.vim

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_Decho") || &cp
 finish
endif
let g:loaded_Decho = "v18"
let s:keepcpo      = &cpo
set cpo&vim

" ---------------------------------------------------------------------
"  Default Values For Variables: {{{1
if !exists("g:decho_bufname")
 let g:decho_bufname= "DBG"
endif
if !exists("s:decho_depth")
 let s:decho_depth  = 0
endif
if !exists("g:decho_winheight")
 let g:decho_winheight= 5
endif
if !exists("g:decho_bufenter")
 let g:decho_bufenter= 0
endif
if !exists("g:dechomode")
 let s:DECHOWIN = 1
 let s:DECHOMSG = 2
 let s:DECHOVAR = 3
 let s:DECHOREM = 4
 let s:DECHOTAB = 5
 let g:dechomode= s:DECHOWIN
endif
if !exists("g:dechovarname")
 let g:dechovarname = "g:dechovar"
endif

" ---------------------------------------------------------------------
"  User Interface: {{{1
com! -nargs=+ -complete=expression Decho	call Decho(<q-args>)
com! -nargs=+ -complete=expression Dredir	call Dredir(<q-args>)
com! -nargs=0 -range=% DechoOn				call DechoOn(<line1>,<line2>)
com! -nargs=0 -range=% DechoOff				call DechoOff(<line1>,<line2>)
com! -nargs=0 Dhide    						call s:Dhide(1)
com! -nargs=0 Dshow    						call s:Dhide(0)
com! -nargs=0 DechoMsgOn					let  g:dechomode= s:DECHOMSG
com! -nargs=0 DechoMsgOff					let  g:dechomode= s:DECHOWIN
if has("clientserver") && executable("gvim")
 com! -nargs=0 DechoRemOn					call s:DechoRemote(1)
 com! -nargs=0 DechoRemOff					call s:DechoRemote(0)
endif
com! -nargs=? DechoVarOn					call s:DechoVarOn(<args>)
com! -nargs=0 DechoVarOff					call s:DechoVarOff()
if v:version >= 700
 com! -nargs=? DechoTabOn                   set lz|call s:DechoTab(1)|set nolz
 com! -nargs=? DechoTabOff                  set lz|call s:DechoTab(0)|set nolz
endif

" ---------------------------------------------------------------------
" Decho: the primary debugging function: splits the screen as necessary and {{{1
"        writes messages to a small window (g:decho_winheight lines)
"        on the bottom of the screen
fun! Decho(...)
 
  " make sure that SaveWinPosn() and RestoreWinPosn() are available
  if !exists("g:loaded_cecutil")
   runtime plugin/cecutil.vim
   if !exists("g:loaded_cecutil") && exists("g:loaded_asneeded")
   	AN SaveWinPosn
   endif
   if !exists("g:loaded_cecutil")
   	echoerr "***Decho*** need to load <cecutil.vim>"
	return
   endif
  endif

  " open DBG window (if dechomode is dechowin)
  if g:dechomode == s:DECHOWIN
   let swp   = SaveWinPosn(0)
   let curbuf= bufnr("%")
   if g:decho_bufenter
    let eikeep= &ei
	let eakeep= &ea
    set ei=BufEnter,WinEnter,WinLeave noea
   endif
 
   " As needed, create/switch-to the DBG buffer
   if !bufexists(g:decho_bufname) && bufnr("*/".g:decho_bufname."$") == -1
    " if requested DBG-buffer doesn't exist, create a new one
    " at the bottom of the screen.
    exe "keepjumps silent bot ".g:decho_winheight."new ".g:decho_bufname
    setlocal noswf
	keepjumps silent! %d
 
   elseif bufwinnr(g:decho_bufname) > 0
    " if requested DBG-buffer exists in a window,
    " go to that window (by window number)
    exe "keepjumps ".bufwinnr(g:decho_bufname)."wincmd W"
    exe "res ".g:decho_winheight
 
   else
    " user must have closed the DBG-buffer window.
    " create a new one at the bottom of the screen.
    exe "keepjumps silent bot ".g:decho_winheight."new"
    setlocal noswf
    exe "keepjumps b ".bufnr(g:decho_bufname)
   endif
 
   set ft=Decho
   setlocal noswapfile noro nobl
 
   "  make sure DBG window is on the bottom
   wincmd J
  endif

  " Build Message
  let i  = 1
  let msg= ""
  while i <= a:0
   try
    exe "let msg=msg.a:".i
   catch /^Vim\%((\a\+)\)\=:E730/
       " looks like a:i is a list
    exe "let msg=msg.string(a:".i.")"
   endtry
   if i < a:0
    let msg=msg." "
   endif
   let i=i+1
  endwhile

  " Initialize message
  let smsg   = ""
  let idepth = 0
  while idepth < s:decho_depth
   let smsg   = "|".smsg
   let idepth = idepth + 1
  endwhile

  " Handle special characters (\t \r \n)
  let i    = 1
  while msg != ""
   let chr  = strpart(msg,0,1)
   let msg  = strpart(msg,1)
   if char2nr(chr) < 32
   	let smsg = smsg.'^'.nr2char(64+char2nr(chr))
   else
    let smsg = smsg.chr
   endif
  endwhile

"  echomsg "g:dechomode=".g:dechomode
  if g:dechomode == s:DECHOMSG
   " display message with echomsg
   exe "echomsg '".substitute(smsg,"'","'.\"'\".'","ge")."'"

  elseif g:dechomode == s:DECHOVAR
   " "display" message by appending to variable named by g:dechovarname
   let smsg= substitute(smsg,"'","''","ge")
   if exists(g:dechovarname)
    exe "let ".g:dechovarname."= ".g:dechovarname.".'\n".smsg."'"
   else
    exe "let ".g:dechovarname."= '".smsg."'"
   endif

  elseif g:dechomode == s:DECHOREM
   " display message by appending it to remote DECHOREMOTE vim server
   let smsg= substitute(smsg,"\<esc>","\<c-v>\<esc>","ge")
   call remote_send("DECHOREMOTE",':set ma'."\<cr>".'Go'.smsg."\<esc>".':set noma nomod'."\<cr>")

  elseif g:dechomode == s:DECHOTAB
   " display message by appending it to the debugging tab window
   let eikeep= &ei
   set ei=all
   let dechotabcur = tabpagenr()
   exe "tabn ".g:dechotabnr
   setlocal ma
   call setline(line("$")+1,smsg)
   setlocal noma nomod
   exe "tabn ".dechotabcur
   let &ei= eikeep

  else
   " Write Message to DBG buffer
   setlocal ma
   keepjumps $
   keepjumps let res= append("$",smsg)
   setlocal nomod
 
   " Put cursor at bottom of DBG window, then return to original window
   exe "res ".g:decho_winheight
   keepjumps norm! G
   if exists("g:decho_hide") && g:decho_hide > 0
    setlocal hidden
    q
   endif
   keepjumps wincmd p
   if exists("swp")
    call RestoreWinPosn(swp)
   endif
 
   if g:decho_bufenter
    let &ei= eikeep
	let &ea= eakeep
   endif
  endif
endfun

" ---------------------------------------------------------------------
"  Dfunc: just like Decho, except that it also bumps up the depth {{{1
"         It also appends a "{" to facilitate use of %
"         Usage:  call Dfunc("functionname([opt arglist])")
fun! Dfunc(...)
  " Build Message
  let i  = 1
  let msg= ""
  while i <= a:0
   exe "let msg=msg.a:".i
   if i < a:0
    let msg=msg." "
   endif
   let i=i+1
  endwhile
  let msg= msg." {"
  call Decho(msg)
  let s:decho_depth= s:decho_depth + 1
  let s:Dfunclist_{s:decho_depth}= substitute(msg,'[( \t].*$','','')
endfun

" ---------------------------------------------------------------------
"  Dret: just like Decho, except that it also bumps down the depth {{{1
"        It also appends a "}" to facilitate use of %
"         Usage:  call Dret("functionname [optional return] [: optional extra info]")
fun! Dret(...)
  " Build Message
  let i  = 1
  let msg= ""
  while i <= a:0
   exe "let msg=msg.a:".i
   if i < a:0
    let msg=msg." "
   endif
   let i=i+1
  endwhile
  let msg= msg." }"
  call Decho("return ".msg)
  if s:decho_depth > 0
   let retfunc= substitute(msg,'\s.*$','','e')
   if  retfunc != s:Dfunclist_{s:decho_depth}
   	echoerr "Dret: appears to be called by<".s:Dfunclist_{s:decho_depth}."> but returning from<".retfunc.">"
   endif
   unlet s:Dfunclist_{s:decho_depth}
   let s:decho_depth= s:decho_depth - 1
  endif
endfun

" ---------------------------------------------------------------------
" DechoOn: {{{1
fun! DechoOn(line1,line2)
  let ickeep= &ic
  set noic
  let swp=SaveWinPosn(0)
  exe "keepjumps ".a:line1.",".a:line2.'g/\<D\%(echo\|func\|redir\|ret\|echo\%(Msg\|Rem\|Tab\|Var\)O\%(n\|ff\)\)\>/s/^"\+//'
  call RestoreWinPosn(swp)
  let &ic= ickeep
endfun

" ---------------------------------------------------------------------
" DechoOff: {{{1
fun! DechoOff(line1,line2)
  let ickeep= &ic
  set noic
  let swp=SaveWinPosn(0)
  let swp= SaveWinPosn(0)
  exe "keepjumps ".a:line1.",".a:line2.'g/\<D\%(echo\|func\|redir\|ret\|echo\%(Msg\|Rem\|Tab\|Var\)O\%(n\|ff\)\)\>/s/^[^"]/"&/'
  call RestoreWinPosn(swp)
  let &ic= ickeep
endfun

" ---------------------------------------------------------------------

" DechoDepth: allow user to force depth value {{{1
fun! DechoDepth(depth)
  let s:decho_depth= a:depth
endfun

" ---------------------------------------------------------------------
" Dhide: (un)hide DBG buffer {{{1
fun! <SID>Dhide(hide)

  if !bufexists(g:decho_bufname) && bufnr("*/".g:decho_bufname."$") == -1
   " DBG-buffer doesn't exist, simply set g:decho_hide
   let g:decho_hide= a:hide

  elseif bufwinnr(g:decho_bufname) > 0
   " DBG-buffer exists in a window, so its not currently hidden
   if a:hide == 0
   	" already visible!
    let g:decho_hide= a:hide
   else
   	" need to hide window.  Goto window and make hidden
	let curwin = winnr()
	let dbgwin = bufwinnr(g:decho_bufname)
    exe bufwinnr(g:decho_bufname)."wincmd W"
	setlocal hidden
	q
	if dbgwin != curwin
	 " return to previous window
     exe curwin."wincmd W"
	endif
   endif

  else
   " The DBG-buffer window is currently hidden.
   if a:hide == 0
	let curwin= winnr()
    exe "silent bot ".g:decho_winheight."new"
    setlocal bh=wipe
    exe "b ".bufnr(g:decho_bufname)
    exe curwin."wincmd W"
   else
   	let g:decho_hide= a:hide
   endif
  endif
  let g:decho_hide= a:hide
endfun

" ---------------------------------------------------------------------
" Dredir: this function performs a debugging redir by temporarily using {{{1
"         register a in a redir @a of the given command.  Register a's
"         original contents are restored.
fun! Dredir(...)
  if a:0 <= 0
   return
  endif
  let cmd  = a:1
  let icmd = 2
  while icmd <= a:0
   call Decho(a:{icmd})
   let icmd= icmd + 1
  endwhile

  " save register a, initialize
  let keep_rega = @a
  let v:errmsg  = ''

  " do the redir of the command to the register a
  try
   redir @a
    exe "keepjumps silent ".cmd
  catch /.*/
   let v:errmsg= substitute(v:exception,'^[^:]\+:','','e')
  finally
   redir END
   if v:errmsg == ''
   	let output= @a
   else
   	let output= v:errmsg
   endif
   let @a= keep_rega
  endtry

  " process output via Decho()
  while output != ""
   if output =~ "\n"
   	let redirline = substitute(output,'\n.*$','','e')
   	let output    = substitute(output,'^.\{-}\n\(.*$\)$','\1','e')
   else
   	let redirline = output
   	let output    = ""
   endif
   call Decho("redir<".cmd.">: ".redirline)
  endwhile
endfun

 " ---------------------------------------------------------------------
 " DechoRemote: supports sending debugging to a remote vim {{{1
if has("clientserver") && executable("gvim")
 fun! s:DechoRemote(mode)
   if a:mode == 0
    " turn remote debugging off
    if g:dechomode == s:DECHOREM
    	let g:dechomode= s:DECHOWIN
    endif
 
   elseif a:mode == 1
    " turn remote debugging on
    if g:dechomode != s:DECHOREM
 	let g:dechomode= s:DECHOREM
    endif
    if serverlist() !~ '\<DECHOREMOTE\>'
 "   " start up remote Decho server
 "   call Decho("start up DECHOREMOTE server")
     call system("gvim --servername DECHOREMOTE")
     while 1
      try
       call remote_send("DECHOREMOTE",':file [Decho\ Remote\ Server]'."\<cr>")
 	  call remote_send("DECHOREMOTE",":put ='-----------------------------'\<cr>")
 	  call remote_send("DECHOREMOTE",":put ='Remote Decho Debugging Window'\<cr>")
 	  call remote_send("DECHOREMOTE",":put ='-----------------------------'\<cr>")
 	  call remote_send("DECHOREMOTE","1GddG")
 	  call remote_send("DECHOREMOTE",':silent set noswf noma nomod nobl nonu ch=1'."\<cr>")
 	  call remote_send("DECHOREMOTE",':'."\<cr>")
 	  call remote_send("DECHOREMOTE",':set ft=Decho'."\<cr>")
 	  call remote_send("DECHOREMOTE",':syn on'."\<cr>")
 	  break
      catch /^Vim\%((\a\+)\)\=:E241/
 	  sleep 200m
      endtry
     endwhile
    endif
 
   else
    echohl Warning | echomsg "DechoRemote(".a:mode.") not supported" | echohl None
   endif
 
 endfun
endif

" ---------------------------------------------------------------------
"  DechoVarOn: turu debugging-to-a-variable on.  The variable is given {{{1
"  by the user;   DechoVarOn [varname]
fun! s:DechoVarOn(...)
  let g:dechomode= s:DECHOVAR
  
  if a:0 > 0
   if a:1 =~ '^g:'
    exe "let ".a:1.'= ""'
   else
    exe "let g:".a:1.'= ""'
   endif
  else
   let g:dechovarname= "g:dechovar"
  endif
endfun

" ---------------------------------------------------------------------
" DechoVarOff: {{{1
fun! s:DechoVarOff()
  if exists("g:dechovarname")
   if exists(g:dechovarname)
    exe "unlet ".g:dechovarname
   endif
  endif
  let g:dechomode= s:DECHOWIN
endfun

 " --------------------------------------------------------------------
 " DechoTab: {{{1
if v:version >= 700
 fun! s:DechoTab(mode)
 "  call Dfunc("DechoTab(mode=".a:mode.")")
 
   if a:mode
    let g:dechomode = s:DECHOTAB
    let dechotabcur = tabpagenr()
    if !exists("g:dechotabnr")
	 let eikeep= &ei
	 set ei=all
	 tabnew
	 file Decho\ Tab
	 setlocal ma
	 put ='---------'
	 put ='Decho Tab'
	 put ='---------'
	 norm! 1GddG
	 let g:dechotabnr = tabpagenr()
	 let &ei          = ""
	 set ft=Decho
	 set ei=all
	 setlocal noma nomod nobl noswf ch=1
	 exe "tabn ".dechotabcur
	 let &ei= eikeep
	endif
   else
    let g:dechomode= s:DECHOWIN
   endif
 
 "  call Dret("DechoTab")
 endfun
endif

" ---------------------------------------------------------------------
"  End Plugin: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" ---------------------------------------------------------------------
"  vim: ts=4 fdm=marker
