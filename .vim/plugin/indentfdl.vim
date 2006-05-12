" indentfdl.vim
"  Author:      Chris Larson <kergoth@handhelds.org>
"  Date:        2006-05-11
"  Description: Sets the foldlevel based on the shiftwidth and the window
"               width when using foldmethod=indent.

if exists('g:loaded_indentfdl') || &cp || ! has('autocmd') || v:version < 700
  if &verbose
    echo 'Not loading indentfdl.'
  endif
  finish
endif
let g:loaded_indentfdl = 1
let s:keepcpo = &cpo
set cpo&vim


if ! exists('g:indentfdl_threshold')
  let g:indentfdl_threshold = 50
endif

fun! <SID>AutoFDL()
  if &fdm != 'indent'
    return
  endif

  let l:winwidth = winwidth('%')
  let l:indentwidth = &sw

  if l:winwidth < g:indentfdl_threshold
    let &foldlevel = 0
    return
  endif

  let l:diff = l:winwidth - g:indentfdl_threshold
  let &foldlevel = (l:diff / l:indentwidth) + 1
  " echomsg 'Setting foldlevel to ' . &foldlevel
endfun


aug indentfdl
  au VimEnter,BufWinEnter,WinEnter,WinLeave * :call <SID>AutoFDL()
aug END

let &cpo= s:keepcpo

" vim: set fenc=utf-8 sts=2 sw=2 et:
