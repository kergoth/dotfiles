let colortrans = {}
for line in readfile("/home/clarson/.vimtodircolors")
  if line =~ '^#' || line =~ '^ *$'
    continue
  endif
  let parts = split(line)
  let colortrans[parts[0]] = parts[1]
endfor

"set nocp
"colo baycomb
"set background=dark
so /home/clarson/.vim/plugin/ColorschemeDegrade.vim

let g:highlights = ""
redir => g:highlights
" Normal must be set 1st for ctermfg=bg, etc, and resetting it doesn't hurt
silent highlight Normal
silent highlight
redir END

let hilines = split(g:highlights, '\n')
call filter(hilines, 'v:val !~ "links to" && v:val !~ "cleared"')

let i = 0
let end = len(hilines)

let out = []
while i < end
  let line = hilines[i]
  let i += 1
  while i < end && hilines[i] !~ '\<xxx\>'
    let line .= hilines[i]
    let i += 1
  endwhile
  let line = substitute(line, '\<st\(art\|op\)=.\{-}\S\@!', '', 'g')
"   let line = substitute(line, '\<c\=term.\{-}=.\{-}\S\@!', '', 'g')
  let line = substitute(line, '\<gui.\{-}=.\{-}\S\@!', '', 'g')
  let line = substitute(line, '\<term.\{-}=.\{-}\S\@!', '', 'g')
  let line = substitute(line, '\<cterm=.\{-}\S\@!', '', 'g')
  let line = substitute(line, '\<ctermbg=.\{-}\S\@!', '', 'g')
  let line = substitute(line, '\<xxx\>', '', '')
"   let line = substitute(line, '\<gui', 'cterm', 'g')
  let line = substitute(line, '\s\+', ' ', 'g')

  let items = split(line, '\%(\s\zecterm\|font\)\|=')

  let higrp = items[0]
  for dircolor in keys(colortrans)
    if colortrans[dircolor] == higrp
      for j in range((len(items)-1)/2)
        " TODO Handle 16 color terminals?
        let var = items[2*j+1]
        let val = items[2*j+2]
        let val = substitute(val, '\s\+$', '', '')
        if var == "ctermfg"
"           echomsg higrp . " - " . var . "=" . val
          call add(out, dircolor . " " . "38;5;" . val)
        endif
      endfor
    endif
  endfor
endwhile

call writefile(out, "/home/clarson/.dir_colors")

unlet g:highlights
