" Initialization: {{{1
if &cp || exists("g:loaded_ftfold")
  finish
endif
let g:loaded_ftfold = 1
let s:keepcpo = &cpo
set cpo&vim
" }}}1

" Automatically load a filetype specific folding script, if one exists (useful
" for rather complex foldexpr's)
function <SID>LoadFoldScript(ft)
  let l:fn = globpath(&rtp, 'fold/'.a:ft.'.vim')
  if len(l:fn) > 0
    exe 'source '.l:fn
  endif
endfunction
 
au FileType * call <SID>LoadFoldScript(expand('<amatch>'))

" Restore Options: {{{1
let &cpo= s:keepcpo
"}}}1

" vim: sw=2 sts=2 et fdm=marker nowrap:
