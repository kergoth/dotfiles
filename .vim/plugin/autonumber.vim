" Title:        autonumber
" Description:  Dynamically enable/disable the line number column based on
"               window width.
" Maintainer:   Chris Larson <clarson@kergoth.com>
" Version:      1
" Help:         Maps <leader>n to manually toggle the line number column.
"               Maps <leader>N to go back to dynamic for the current window.
" Variables:
"   g:autonumber_winthres - threshold below which line number column is
"                           disabled.
"   g:autonumber_nomaps   - disable creation of aforementioned maps
"   g:loaded_autonumber   - set to a non-empty value to prevent the plugin
"                           from loading.

if exists("g:loaded_autonumber") || &cp || !has('autocmd')
  finish
endif
let g:loaded_autonumber = 1

let g:autonumber_numstate = &number
if ! exists("g:autonumber_winthres")
  let g:autonumber_winthres = 80
endif

" Used to set sane default line numbering
" Obey the 'number' or 'nonumber' which the user set in their .vimrc
function! AutoNumberByWidth()
  Windofast
        \ let l:bufname = bufname('%') |
        \ if (! exists('w:numberoverride')) &&
        \    (&ma == 1) |
        \   if g:autonumber_numstate == 0 |
        \     set nonumber |
        \   else |
        \     if winwidth(0) >= g:autonumber_winthres |
        \       set number |
        \     else |
        \       set nonumber |
        \     endif |
        \   endif |
        \ endif
endfunction

function! SetNumbering(s)
  if a:s == 0
    let w:numberoverride = 1
    setlocal nonumber
  elseif a:s == 1
    let w:numberoverride = 1
    setlocal number
  elseif a:s == -1 " Toggle
    let w:numberoverride = 1
    setlocal number!
  else " Back to automatic
    if exists('w:numberoverride')
      unlet w:numberoverride
    endif
  endif
endfunction

if ! exists("autonumber_nomaps")
  if mapcheck("<leader>n", "n") == ""
    " Toggle line numbering for the current window (overrides automatic by width)
    nmap <leader>n :call SetNumbering(-1)<CR>
  endif

  if mapcheck("<leader>N", "n") == ""
    " Remove line number setting override, going back to automatic by win width
    nmap <leader>N :call SetNumbering(3)<CR>:call AutoNumberByWidth()<CR>
  end
endif

au VimEnter,BufWinEnter,WinEnter,WinLeave * :call AutoNumberByWidth()

if v:version >= 700
  au VimResized * :call AutoNumberByWidth()
endif
