" tabpagebuffers.vim: This exists to manage lists of buffers associated with a
" given tab page, primarily for the "tab page as a workspace" use case.
"
" It tracks any buffer which has ever been visible in a window in a given tab
" page, to be used in a minibufexpl or tabbar type buffer list display.
"
" Author:      Chris Larson <kergoth@handhelds.org>

if exists("g:loaded_tabpagebuffers") || &cp || ! has('autocmd') || v:version < 700
  finish
endif
let g:loaded_tabpagebuffers = 1

fun! TBufDo(command)
  let currBuff = bufnr('%')
  let l:currEi = &ei
  let ei = &ei . ',Syntax'
  for n in keys(g:tabpagebuffers[tabpagenr()])
    if exists('&buflisted')
      exe 'buffer ' . n
      try
        exe a:command
      catch
        break
      endtry
    endif
  endfor
  let &ei = l:currEi
  exe 'buffer ' . currBuff
endfun
com! -nargs=+ -complete=command TBufdo call TBufDo(<q-args>)

fun! <SID>Init()
  let l:tnr = tabpagenr()
  try
    let l:foo = g:tabpagebuffers[l:tnr]
  catch
    let g:tabpagebuffers[l:tnr] = {}
  endtry
  return l:tnr
endfun

let g:tabpagebuffers = {1: {}}
aug TabPageBuffers
  au!
  au TabEnter * call <SID>Init()
  " Argh, TabLeave isnt executed when a tab closes!  How the hell do we catch
  " removal of a tab?
  au TabLeave * let tcount = 0 | for i in tabpagebuflist() | let tcount = tcount + 1 | endfor | if tcount == 0 | try | call remove(g:tabpagebuffers, tabpagenr()) | catch | endtry | endif | unlet tcount
  au BufWinEnter * let g:tabpagebuffers[tabpagenr()][bufnr('%')] = 1
  au BufDelete * let afile = expand('<afile>') | if afile != '' | let bnr = bufnr(afile) | for n in keys(g:tabpagebuffers) | try | call remove(g:tabpagebuffers[n], bnr) | catch | endtry | endfor | unlet bnr | endif | unlet afile
  au VimEnter * let tnr = tabpagenr() | for i in tabpagebuflist() | let g:tabpagebuffers[tnr][i] = 1 | endfor | unlet tnr
aug END

" vim: set fenc=utf-8 sts=2 sw=2 et:
