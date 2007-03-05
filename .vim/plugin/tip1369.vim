" preserve noeol (missing trailing eol) when saving file
" in order to preserve missing-trailing-eol, we need
" to temporarily 'set binary' for the duration of file writing.
" Thanks to Aaron and A.Mechelynck for motivation and hints
" leading to this solution.

aug automatic_noeol
au!

au BufWritePre  * :call <SID>TempSetBinaryForNoeol()
au BufWritePost * :let &l:binary=g:save_binary

fun! <SID>TempSetBinaryForNoeol()
  let g:save_binary = &binary
  " the purpose is to save file without eol if it was read in as noeol.
  if ! &eol
    setlocal binary
  endif
endfun

aug END
