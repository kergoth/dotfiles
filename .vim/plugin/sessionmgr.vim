" File: sessionmgr.vim
" Author: Jason Heddings (vim at heddway dot com)
" Version: 1.1
" Last Modified: 20 October, 2005
"
if exists('g:SessionMgr_Loaded')
  finish
endif
let g:SessionMgr_Loaded = 1


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" used for my debugging - adapted from the taglist plugin
let g:SessionMgr_DebugLog = ""
if !exists("g:SessionMgr_Debug")
  let g:SessionMgr_Debug = 0
endif

command! -nargs=0 SMLog call confirm("__SessionMgr Log__\n\n" . g:SessionMgr_DebugLog)
function! SessionMgr_Debug(msg)
  if g:SessionMgr_Debug
    let l:len = strlen(g:SessionMgr_DebugLog)
    if l:len > 4096
      let g:SessionMgr_DebugLog = strpart(g:SessionMgr_DebugLog, l:len - 4096)
    endif
    let l:msg = strftime('%H:%M:%S') . ': ' .  a:msg
    let g:SessionMgr_DebugLog = g:SessionMgr_DebugLog . l:msg . "\n"
  endif
endfunction
call SessionMgr_Debug("BEGIN LOADING")


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" set the default options for the plugin
if !exists("g:SessionMgr_AutoManage")
  let g:SessionMgr_AutoManage = 1
endif
call SessionMgr_Debug("_AutoManage: " . g:SessionMgr_AutoManage)

if !exists("g:SessionMgr_DefaultSession")
  let g:SessionMgr_DefaultSession = "session"
endif
call SessionMgr_Debug("_DefaultSession: " . g:SessionMgr_DefaultSession)

if !exists("g:SessionMgr_Dir") || !isdirectory(g:SessionMgr_Dir)
  " try to use the first instance of "sessions" in runtime path
  let dirsearch = globpath(&runtimepath, "sessions/")
  if strlen(dirsearch) > 0
    let g:SessionMgr_Dir = substitute(dirsearch, "\n.*", "", "g")
  else
    let g:SessionMgr_Dir = "."
  endif

endif
call SessionMgr_Debug("_Dir: " . g:SessionMgr_Dir)


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" used to update the tag status
if g:SessionMgr_AutoManage
  augroup SessionMgr_AutoManage
    autocmd!
    autocmd VimEnter * call SessionMgr_OnEnter()
    autocmd VimLeavePre * call SessionMgr_OnLeave()
  augroup END
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" creates a new session with an optional name
command! -nargs=? -complete=custom,SessionMgr_Complete SS call SessionMgr_Save(<f-args>)
function! SessionMgr_Save(...)
  if a:0 > 0
    let l:name = a:1
  else
    let l:name = SessionMgr_GetCurrentSession()
  endif
  let l:session = g:SessionMgr_Dir . "/" . l:name . ".vim"
  let g:SessionMgr_CurrentSession = l:name
  call SessionMgr_Debug("Save(" . l:name . "): " . l:session)

  silent! execute "mksession! " . l:session
  echohl ModeMsg | echo "Session Saved: " . l:name | echohl None
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" loads a previously saved session, or the most recent session if not specified
command! -nargs=? -complete=custom,SessionMgr_Complete SR call SessionMgr_Restore(<f-args>)
function! SessionMgr_Restore(...)
  if a:0 > 0
    let l:name = a:1
  else
    let l:name = SessionMgr_GetCurrentSession()
  endif
  let l:session = g:SessionMgr_Dir . "/" . l:name . ".vim"
  call SessionMgr_Debug("Restore(" . l:name . "): " . l:session)

  if filereadable(l:session)
    silent! execute "source " . l:session
    echohl ModeMsg | echo "Session Restored: " . l:name | echohl None
    let g:SessionMgr_CurrentSession = l:name
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" deletes the specified session (or the active session)
command! -nargs=? -complete=custom,SessionMgr_Complete SD call SessionMgr_Delete(<f-args>)
function! SessionMgr_Delete(...)
  " use only either the specified name or active session (not the default name)
  if a:0 > 0
    let l:name = a:1
  else
    if exists("g:SessionMgr_CurrentSession")
      let l:name = g:SessionMgr_CurrentSession
    else
      call SessionMgr_Debug("Delete(): NO SESSION")
      echohl ErrorMsg | echo "No Active Session" | echohl None
      return
    endif
  endif
  call SessionMgr_Debug("Delete(" . l:name . ")")

  " end the session if it is the current one
  if exists("g:SessionMgr_CurrentSession") && l:name == g:SessionMgr_CurrentSession
    SQ
  endif

  " go ahead and delete it
  call delete(g:SessionMgr_Dir . "/" . l:name . ".vim")
  echohl ModeMsg | echo "Session Deleted: " . l:name | echohl None
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" quit recording the current session
command! -nargs=0 SQ call SessionMgr_Quit()
function! SessionMgr_Quit()
  call SessionMgr_Debug("Quit()")

  if exists("g:SessionMgr_CurrentSession")
    call SessionMgr_Debug("Quit(): " . g:SessionMgr_CurrentSession)
    unlet g:SessionMgr_CurrentSession
    echohl ModeMsg | echo "Session Ended: " . g:SessionMgr_CurrentSession | echohl None
  else
    call SessionMgr_Debug("Quit(): NO SESSION")
    echohl ErrorMsg | echo "No Active Session" | echohl None
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" prints a list of all stored sessions
command! -nargs=0 SL call SessionMgr_List()
function! SessionMgr_List()
  let l:sessions = SessionMgr_GetSessions()
  if strlen(l:sessions) == 0
    call SessionMgr_Debug("List(): NO SESSIONS")
    echohl ErrorMsg | echo "No Sessions" | echohl None
  else
    call SessionMgr_Debug("List()")
    echohl ModeMsg | echo "__Sessions__" | echohl None
    echohl SpecialKey | echo l:sessions | echohl None
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" returns the names of all available sessions (in session directory)
function! SessionMgr_GetSessions()
  if !isdirectory(g:SessionMgr_Dir)
    return ""
  endif

  let l:curdir = escape(getcwd(), "\" ()")
  execute "cd " . g:SessionMgr_Dir
  let l:dir = glob("*.vim")
  let l:sessions = substitute(l:dir, "\\.vim", "", "g") 
  let l:sessions = substitute(l:sessions, "\n$", "", "g") 
  execute "cd " . l:curdir
  return l:sessions
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" toggles the available sessions window
command! -nargs=0 SE call SessionMgr_Echo()
function! SessionMgr_Echo()
  if exists("g:SessionMgr_CurrentSession")
    echohl ModeMsg | echo "Current Session: " . SessionMgr_GetCurrentSession() | echohl None
  else
    echohl ErrorMsg | echo "No Active Session" | echohl None
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" returns the name of the current session, or the default
function! SessionMgr_GetCurrentSession()
  if exists("g:SessionMgr_CurrentSession")
    return g:SessionMgr_CurrentSession
  endif
  return g:SessionMgr_DefaultSession
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" used for auto-completing session names
function! SessionMgr_Complete(ArgLead, CmdLine, CursorPos)
  let l:sessions = SessionMgr_GetSessions()
  return l:sessions
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" called when vim starts up
function! SessionMgr_OnEnter()
  call SessionMgr_Debug("OnEnter [" . argc() . "]")

  if argc() == 0
    execute "SR " . SessionMgr_GetCurrentSession()
    let g:SessionMgr_CurrentSession = SessionMgr_GetCurrentSession()
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" called when vim is about to exit
function! SessionMgr_OnLeave()
  if exists("g:SessionMgr_CurrentSession")
    execute "SS " . SessionMgr_GetCurrentSession()
  endif
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" always be last
call SessionMgr_Debug("END LOADING")
