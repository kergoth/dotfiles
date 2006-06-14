set background=light

hi clear
if exists("syntax_on")
  syntax reset
endif

let colors_name = "pyte"

" functions {{{
" returns an approximate grey index for the given grey level
fun s:grey_number(x)
    if &t_Co == 88
        if a:x < 23
            return 0
        elseif a:x < 69
            return 1
        elseif a:x < 103
            return 2
        elseif a:x < 127
            return 3
        elseif a:x < 150
            return 4
        elseif a:x < 173
            return 5
        elseif a:x < 196
            return 6
        elseif a:x < 219
            return 7
        elseif a:x < 243
            return 8
        else
            return 9
        endif
    else
        if a:x < 14
            return 0
        else
            let l:n = (a:x - 8) / 10
            let l:m = (a:x - 8) % 10
            if l:m < 5
                return l:n
            else
                return l:n + 1
            endif
        endif
    endif
endfun

" returns the actual grey level represented by the grey index
fun s:grey_level(n)
    if &t_Co == 88
        if a:n == 0
            return 0
        elseif a:n == 1
            return 46
        elseif a:n == 2
            return 92
        elseif a:n == 3
            return 115
        elseif a:n == 4
            return 139
        elseif a:n == 5
            return 162
        elseif a:n == 6
            return 185
        elseif a:n == 7
            return 208
        elseif a:n == 8
            return 231
        else
            return 255
        endif
    else
        if a:n == 0
            return 0
        else
            return 8 + (a:n * 10)
        endif
    endif
endfun

" returns the palette index for the given grey index
fun s:grey_color(n)
    if &t_Co == 88
        if a:n == 0
            return 16
        elseif a:n == 9
            return 79
        else
            return 79 + a:n
        endif
    else
        if a:n == 0
            return 16
        elseif a:n == 25
            return 231
        else
            return 231 + a:n
        endif
    endif
endfun

" returns an approximate color index for the given color level
fun s:rgb_number(x)
    if &t_Co == 88
        if a:x < 69
            return 0
        elseif a:x < 172
            return 1
        elseif a:x < 230
            return 2
        else
            return 3
        endif
    else
        if a:x < 75
            return 0
        else
            let l:n = (a:x - 55) / 40
            let l:m = (a:x - 55) % 40
            if l:m < 20
                return l:n
            else
                return l:n + 1
            endif
        endif
    endif
endfun

" returns the actual color level for the given color index
fun s:rgb_level(n)
    if &t_Co == 88
        if a:n == 0
            return 0
        elseif a:n == 1
            return 139
        elseif a:n == 2
            return 205
        else
            return 255
        endif
    else
        if a:n == 0
            return 0
        else
            return 55 + (a:n * 40)
        endif
    endif
endfun

" returns the palette index for the given R/G/B color indices
fun s:rgb_color(x, y, z)
    if &t_Co == 88
        return 16 + (a:x * 16) + (a:y * 4) + a:z
    else
        return 16 + (a:x * 36) + (a:y * 6) + a:z
    endif
endfun

" returns the palette index to approximate the given R/G/B color levels
fun s:color(r, g, b)
    " get the closest grey
    let l:gx = s:grey_number(a:r)
    let l:gy = s:grey_number(a:g)
    let l:gz = s:grey_number(a:b)

    " get the closest color
    let l:x = s:rgb_number(a:r)
    let l:y = s:rgb_number(a:g)
    let l:z = s:rgb_number(a:b)

    if l:gx == l:gy && l:gy == l:gz
        " there are two possibilities
        let l:dgr = s:grey_level(l:gx) - a:r
        let l:dgg = s:grey_level(l:gy) - a:g
        let l:dgb = s:grey_level(l:gz) - a:b
        let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
        let l:dr = s:rgb_level(l:gx) - a:r
        let l:dg = s:rgb_level(l:gy) - a:g
        let l:db = s:rgb_level(l:gz) - a:b
        let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
        if l:dgrey < l:drgb
            " use the grey
            return s:grey_color(l:gx)
        else
            " use the color
            return s:rgb_color(l:x, l:y, l:z)
        endif
    else
        " only one possibility
        return s:rgb_color(l:x, l:y, l:z)
    endif
endfun

" returns the palette index to approximate the 'rrggbb' hex string
fun s:rgb(rgb)
    let l:r = ('0x' . strpart(a:rgb, 0, 2)) + 0
    let l:g = ('0x' . strpart(a:rgb, 2, 2)) + 0
    let l:b = ('0x' . strpart(a:rgb, 4, 2)) + 0

    return s:color(l:r, l:g, l:b)
endfun

" sets the highlighting for the given group
fun! s:X(group, ...)
    let fg = ''
    let bg = ''
    let attr = ''
    for s in a:000
        let sp = split(s, '=')
        if len(sp) > 1
            if sp[0] == 'fg'
                let fg = sp[1]
            elseif sp[0] == 'bg'
                let bg = sp[1]
            elseif sp[0] == 'attr'
                let attr = sp[1]
            else
                exe 'echoerr Unknown option '.sp[0]
                return
            endif
        endif
    endfor

    if fg != ''
        if fg[0:1] != '0x'
            let ctermfg = fg
            exec printf('hi %s guifg=#%s', a:group, fg)
        else
            let fg = printf('%06X', str2nr(fg, 16))
            let ctermfg = s:rgb(fg)
            exec printf('hi %s guifg=#%s ctermfg=%s', a:group, fg, ctermfg)
        endif
    endif

    if bg != ''
        if bg[0:1] != '0x'
            let ctermbg = bg
            exec printf('hi %s guibg=#%s', a:group, bg)
        else
            let bg = printf('%06X', str2nr(bg, 16))
            let ctermbg = s:rgb(bg)
            exec printf('hi %s guibg=#%s ctermbg=%s', a:group, bg, ctermbg)
        endif
    endif

    if attr != ''
        exec printf('hi %s gui=%s cterm=%s', a:group, attr, attr)
    endif
endfun
" }}}

command! -nargs=+ -buffer BetterHi call s:X(<f-args>)

BetterHi Comment      fg=0xA0B0C0 attr=ITALIC
BetterHi Conditional  fg=0x4C8F2F attr=BOLD
BetterHi Constant     fg=0xA07040
BetterHi Cursor       bg=0xB0B4B8
BetterHi CursorColumn bg=0xEAEAEA
BetterHi CursorLine   bg=0xF6F6F6
BetterHi Define       fg=0x1060A0 attr=BOLD
BetterHi DiffAdd      bg=0xC0E0D0 attr=ITALIC,BOLD
BetterHi DiffChange   bg=0xE0E0E0 attr=ITALIC,BOLD
BetterHi DiffDelete   bg=0xF0E0B0 attr=ITALIC,BOLD
BetterHi DiffText     bg=0xF0C8C8 attr=ITALIC,BOLD
BetterHi Error        fg=0xFF00   bg=0xFFFFFF              attr=BOLD,UNDERLINE
BetterHi Float        fg=0x70A040
BetterHi Folded       fg=0x708090 bg=0xC0D0E0
BetterHi Function     fg=0x6287E  attr=ITALIC
BetterHi Identifier   fg=0x5B3674 attr=ITALIC
BetterHi lCursor      bg=0xFFFFFF
BetterHi LineNr       fg=0xFFFFFF bg=0xC0D0E0
BetterHi MatchParen   fg=0xFFFFFF bg=0x80A090              attr=BOLD
BetterHi NonText      fg=0xC0C0C0 bg=0xE0E0E0
BetterHi Normal       fg=0x202020 bg=0xF0F0F0
BetterHi Number       fg=0x40A070
BetterHi Operator     fg=0x408010
BetterHi Pmenu        fg=0xFFFFFF bg=0x808080
BetterHi PreProc      fg=0x1060A0 attr=NONE
BetterHi Repeat       fg=0x7FBF58 attr=BOLD
BetterHi Special      fg=0x70A0D0 attr=ITALIC
BetterHi SpecialKey   fg=0xD8A080 bg=0xE8E8E8              attr=ITALIC
BetterHi Statement    fg=0x7020   attr=BOLD
BetterHi StatusLine   fg=0xFFFFFF bg=0x8090A0              attr=BOLD,ITALIC
BetterHi StatusLineNC fg=0x506070 bg=0xA0B0C0              attr=ITALIC
BetterHi String       fg=0x4070A0
BetterHi Structure    fg=0x7020   attr=ITALIC
BetterHi TabLine      bg=0xB0B8C0 attr=ITALIC
BetterHi TabLineFill  fg=0x9098A0
BetterHi TabLineSel   bg=0xF0F0F0 attr=ITALIC,BOLD
BetterHi Title        fg=0x202020 attr=BOLD
BetterHi Todo         fg=0xA0B0C0 attr=ITALIC,BOLD,UNDERLINE
BetterHi Type         fg=0xE5A00D attr=ITALIC
BetterHi Underlined   fg=0x202020 attr=UNDERLINE
BetterHi VertSplit    fg=0xA0B0C0 bg=0xA0B0C0              attr=NONE

" vim: sw=4 sts=4 et fdm=marker fdl=0:
