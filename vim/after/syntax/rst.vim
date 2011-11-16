" From http://www.georgevreilly.com/blog/CategoryView,category,reStructuredText.aspx
" Altered by me to kill the bits I don't need, move to an after/syntax/ file,
" and re-apply the rstBold/rstItalic when the color scheme changes

function! s:SynFgColor(hlgrp)
    return synIDattr(synIDtrans(hlID(a:hlgrp)), 'fg')
endfun

function! <SID>SetupBoldItalic()
    exec 'hi rstBold    term=bold cterm=bold gui=bold guifg=' . s:SynFgColor('PreProc')
    exec 'hi rstItalic  term=italic cterm=italic gui=italic guifg=' . s:SynFgColor('Statement')
endfunction

augroup ReST
    au!
    au ColorScheme * call <SID>SetupBoldItalic()
augroup END

call <SID>SetupBoldItalic()

syn match rstEnumeratedList /^\s*[0-9#]\{1,3}\.\s/
syn match rstBulletedList /^\s*[+*-]\s/

hi link rstEnumeratedList Operator
hi link rstBulletedList   Operator
hi! link rstEmphasis       rstItalic
hi! link rstStrongEmphasis rstBold
execute 'syn region rstComment contained' .
      \ ' start=/.*/'
      \ ' end=/^\s\@!/ contains=rstTodo,vimModeline'
