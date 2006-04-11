" quilt.vim:
"
" Author:      Chris Larson <kergoth@handhelds.org>

if exists("g:loaded_quilt") || &cp
  finish
endif
let g:loaded_quilt = 1

fun! <SID>RunQuilt(...)
  " Store current compiler setting.
  if exists('current_compiler')
    let l:savedcompiler = current_compiler
  endif

  " Change compiler to quilt (write a compiler plugin to set the makeprg and
  " the error format for quilt).
  compiler quilt

  make

  " Set compiler back to previous value and return.
  if exists('l:savedcompiler')
    exe 'compiler ' . l:savedcompiler
  endif
endfun

" vim: set fenc=utf-8 sts=2 sw=2 et:
