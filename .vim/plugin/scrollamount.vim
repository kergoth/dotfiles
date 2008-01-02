" Title:        ScrollAmount
" Description:  Adjust mouse wheel scroll amount based on window height.
" Maintainer:   Chris Larson <clarson@kergoth.com>
" Version:      1

if exists("g:loaded_scrollamount") || &cp || !has('autocmd')
  finish
endif
let g:loaded_scrollamount = 1

function! <SID>Max(a, b)
  if a:a >= a:b
    return a:a
  else
    return a:b
  endif
endfunction

if &ttymouse != '' ||
      \ (has('gui_running') && has('unix'))
  " scrollwheel = intelligent # of lines to scroll based on window height
  augroup KergothScrollWheel
    au!
    au WinEnter,VimEnter * let w:mousejump = <SID>Max(winheight(0)/8, 1)
    au WinEnter,VimEnter * exe 'map <MouseDown> ' . w:mousejump . ''
    au WinEnter,VimEnter * exe 'map <MouseUp> ' . w:mousejump . ''

    try
      au VimResized * let w:mousejump = <SID>Max(winheight(0)/8, 1)
      au VimResized * exe 'map <MouseDown> ' . w:mousejump . ''
      au VimResized * exe 'map <MouseUp> ' . w:mousejump . ''
    catch
    endtry
  augroup END
endif
