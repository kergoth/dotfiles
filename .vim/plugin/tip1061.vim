" Vim tip #1061

if exists('g:loaded_tip1061') || &cp
  finish
endif
let g:loaded_tip1061 = 1

nmap <silent><Home>      :cal SmartHome("n")<CR>
nmap <silent><End>       :cal SmartEnd("n")<CR>
imap <silent><Home>     <C-r>=SmartHome("i")<CR>
imap <silent><End>      <C-r>=SmartEnd("i")<CR>
vmap <silent><Home> <Esc>:cal SmartHome("v")<CR>
vmap <silent><End>  <Esc>:cal SmartEnd("v")<CR>

""""""""""""""""""""
"smart home function
function SmartHome(mode)
  let curcol = col(".")

  "gravitate towards beginning for wrapped lines
  if curcol > indent(".") + 2
    call cursor(0, curcol - 1)
  endif

  if curcol == 1 || curcol > indent(".") + 1
    if &wrap
      normal g^
    else
      normal ^
    endif
  else
    if &wrap
      normal g0
    else
      normal 0
    endif
  endif

  if a:mode == "v"
    normal msgv`s
  endif

  return ""
endfunction

"""""""""""""""""""
"smart end function
function SmartEnd(mode)
  let curcol = col(".")
  let lastcol = a:mode == "i" ? col("$") : col("$") - 1

  "gravitate towards ending for wrapped lines
  if curcol < lastcol - 1
    call cursor(0, curcol + 1)
  endif

  if curcol < lastcol
    if &wrap
      normal g$
    else
      normal $
    endif
  else
    normal g_
  endif

  "correct edit mode cursor position, put after current character
  if a:mode == "i"
    call cursor(0, col(".") + 1)
  endif

  if a:mode == "v"
    normal msgv`s
  endif

  return ""
endfunction
