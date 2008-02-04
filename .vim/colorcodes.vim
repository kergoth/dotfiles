so $HOME/.vim/plugin/ColorschemeDegrade.vim

let g:highlights = ""
redir => g:highlights
" Normal must be set 1st for ctermfg=bg, etc, and resetting it doesn't hurt
silent highlight Normal
silent highlight
redir END

let hilines = split(g:highlights, '\n')
call filter(hilines, 'v:val !~ "cleared"')
" call filter(hilines, 'v:val !~ "links to" && v:val !~ "cleared"')

fun s:GetCode(...)
  if a:0 == 1
    if a:1 == "bold"
      return printf("%d", 1)
    elseif a:1 == "italic"
      return printf("%d", 3)
    elseif a:1 == "underline"
      return printf("%d", 4)
    elseif a:1 == "reverse" || a:1 == "inverse"
      return printf("%d", 7)
    endif
  elseif a:0 == 2
    if &t_Co == 8
      if a:1 == "fg"
        return printf("%d", 30 + a:2)
      elseif a:1 == "bg"
        return printf("%d", 40 + a:2)
      end
    elseif &t_Co == 16
      if a:2 < 8
        if a:1 == "fg"
          return printf("%d", 30 + a:2)
        elseif a:1 == "bg"
          return printf("%d", 40 + a:2)
        endif
      else
        if a:1 == "fg"
          return printf("%d", 90 + a:2 - 8)
        elseif a:1 == "bg"
          return printf("%d", 100 + a:2 - 8)
        endif
      endif
    elseif &t_Co == 88
      if a:1 == "fg"
        return printf("38;5;%d", a:2)
      elseif a:1 == "bg"
        return printf("48;5;%d", a:2)
      endif
    elseif &t_Co == 256
      if a:1 == "fg"
        return printf("38;5;%d", a:2)
      elseif a:1 == "bg"
        return printf("48;5;%d", a:2)
      endif
    endif
  endif
endfun

let links = {}

let i = 0
let end = len(hilines)

let out = {}
while i < end
  let line = hilines[i]
  let i += 1
  while i < end && hilines[i] !~ '\<xxx\>'
    let line .= hilines[i]
    let i += 1
  endwhile

  let line = substitute(line, '\<xxx\>', '', '')
  let line = substitute(line, '\s\+', ' ', 'g')

  if line =~ "links to"
    let line = substitute(line, ' links to ', ' ', '')
    let parts = split(line, ' ')
    let links[parts[0]] = parts[1]
    continue
  endif

  let line = substitute(line, '\<st\(art\|op\)=.\{-}\S\@!', '', 'g')
"   let line = substitute(line, '\<c\=term.\{-}=.\{-}\S\@!', '', 'g')
  let line = substitute(line, '\<gui.\{-}=.\{-}\S\@!', '', 'g')
  let line = substitute(line, '\<term.\{-}=.\{-}\S\@!', '', 'g')
"   let line = substitute(line, '\<gui', 'cterm', 'g')

  let items = split(line, '\%(\s\zecterm\|font\)\|=')

  let higrp = substitute(items[0], '\s\+$', '', '')
  if get(out, higrp) != 0
    continue
  end
  for j in range((len(items)-1)/2)
    let var = items[2*j+1]
    let val = items[2*j+2]
    let val = substitute(val, '\s\+$', '', '')
    let code = ""
    if var == "ctermfg"
      let code = s:GetCode('fg', str2nr(val))
    elseif var == "ctermbg"
      let code = s:GetCode('bg', str2nr(val))
    elseif var == "cterm"
      let val = tolower(val)
      let code = s:GetCode(val)
    endif
    if code != ""
      if ! get(out, higrp)
        let out[higrp] = code
      else
        let out[higrp] = out[higrp] . ";" . code
      endif
    endif
  endfor
endwhile

for higrp in keys(links)
  let linkedto = links[higrp]
  let code = get(out, linkedto)
  if code != 0
    let out[higrp] = code
  endif
endfor

let outlist = []
for higrp in keys(out)
  call add(outlist, higrp . " " . out[higrp])
endfor
call writefile(outlist, $HOME."/.vimcolors")

unlet g:highlights
