" =============================================================================
"  Name Of File: rcs-menu.vim
"   Description: Interface to RCS Version Control.
"        Author: Jeff Lanzarotta
"           URL: http://lanzarott.tripod.com/vim.htm
"          Date: Saturday, February 3, 2001
"       Version: 6.0.2
"     Copyright: None.
"         Usage: These command and gui menu displays useful revision control 
"                system (rcs).
"                functions.
" Configuration: Your rcs executables must be in your path.
" =============================================================================
 
" Has this already been loaded?
if exists("loaded_rcs_menu")
  finish
endif

let loaded_rcs_menu = 1

if has("gui")
  amenu RCS.Initial\ Check\ In<Tab>,init :!ci -i -u %<CR>:e!<CR>
  amenu RCS.-SEP1-        <nul>
  amenu RCS.Check\ In<Tab>,ci :!ci -u %<CR>:e!<CR>
  amenu RCS.Check\ Out<Tab>,co :!co %<CR>:e!<CR>
  amenu RCS.Check\ Out\ (Locked)<Tab>,lock :!co -l %<CR>:e!<CR>
  amenu RCS.Revert\ to\ Last\ Version<Tab>,revert :!co -f %<CR>:e!<CR>
  amenu RCS.-SEP2-        <nul>
  amenu RCS.Show\ History<Tab>,log :call RCSShowLog("/rlog", "rlog")<CR><CR>
  amenu RCS.-SEP3-        <nul>
  amenu RCS.Show\ Differences<Tab>,diff :call RCSShowDiff("/rcsdiff", "rcsdiff")<CR><CR>
endif

" Mappings:
if(v:version >= 600)
  map <Leader>init  :!ci -i -u %<CR>:e!<CR>
  map <Leader>ci    :!ci -u %<CR>:e!<CR>
  map <Leader>co    :!co %<CR>:e!<CR>
  map <Leader>lock  :!co -l %<CR>:e!<CR>
  map <Leader>log   :call RCSShowLog("/rlog", "rlog")<CR><CR>
  map <Leader>diff  :call RCSShowDiff("/rcsdiff", "rcsdiff")<CR><CR>
else
  map ,init         :!ci -i -u %<CR>:e!<CR>
  map ,ci           :!ci -u %<CR>:e!<CR>
  map ,co           :!co %<CR>:e!<CR>
  map ,lock         :!co -l %<CR>:e!<CR>
  map ,log          :call RCSShowLog("/rlog", "rlog")<CR><CR>
  map ,diff         :call RCSShowDiff("/rcsdiff", "rcsdiff")<CR><CR>
endif

" RCSShowLog
" Show the log results of the current file with a revision control system.
function! RCSShowLog(bufferName, cmdName)
  call s:ReadCommandInBuffer(a:bufferName, a:cmdName)
endfunction

" ShowDiff
" Show the diffs of the current file with a revision control system.
function! RCSShowDiff(bufferName, cmdName)
  call s:ReadCommandInBuffer(a:bufferName, a:cmdName)
endfunction

" ReadCommandInBuffer
" - bufferName is the name which the new buffer with the command results
"   should have.
" - cmdName is the command to execute.
function! s:ReadCommandInBuffer(bufferName, cmdName)
  " Modify the shortmess option:
  " A  don't give the "ATTENTION" message when an existing swap file is
  "    found.
  set shortmess+=A

  " Get the name of the current buffer.
  let currentBuffer = bufname("%")

  " If a buffer with the name rlog exists, delete it.
  if bufexists(a:bufferName)
    execute 'bd! ' a:bufferName
  endif

  " Create a new buffer.
  execute 'new ' a:bufferName

  " Execute the command.
  execute 'r!' a:cmdName ' ' currentBuffer

  " Make is so that the file can't be edited.
  setlocal nomodified
  setlocal nomodifiable
  setlocal readonly

  " Go to the beginning of the buffer.
  execute "normal 1G"

  " Restore the shortmess option.
  set shortmess-=A
endfunction
