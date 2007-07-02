" Vim color file
" baycomb v2.4
" http://www.vim.org/scripts/script.php?script_id=1454
" 
" Maintainer:	Shawn Axsom <axs221@gmail.com>
"
"   * Place :colo baycomb in your VimRC/GVimRC file
"   * Also add :set background=dark  or :setbackground=light
"     depending on your preference.
"
"   - Thanks to Desert and OceanDeep for their color scheme 
"     file layouts
"   - Thanks to Raimon Grau and Bob Lied for their feedback

if version > 580
    " no guarantees for version 5.8 and below, but this makes it stop
    " complaining
    hi clear
    if exists("syntax_on")
        syntax reset
    endif
endif

let g:colors_name="baycomb"

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

if &background == "dark"
    if has('gui_running')
        BetterHi Normal       fg=0xA0B4E0 bg=0x11121A
    else
        BetterHi Normal       fg=0xA0B4E0
    endif

    " BetterHi Comment    fg=0x349D58   bg=bg
    BetterHi Comment      fg=0x8B8B
    BetterHi Constant     fg=0x5C78F0
    BetterHi Cursor       fg=0xAA     bg=0xCAD5C0
    BetterHi CursorColumn bg=0x354070
    BetterHi CursorLine   bg=0x354070
    BetterHi DiffAdd      bg=0xA4B8C
    BetterHi DiffChange   bg=0x685B5C
    BetterHi DiffDelete   fg=0x300845 bg=0x200845
    BetterHi DiffText     bg=0x4335
    BetterHi Directory    fg=0xBBD0DF
    BetterHi Error        bg=0xB03452
    BetterHi ErrorMsg     bg=0xFF4545
    BetterHi FoldColumn   fg=0xDBCAA5 bg=0xA0A18
    BetterHi Folded       fg=0xBEBEBE bg=0x232235
    BetterHi Function     fg=0xBAB588 attr=BOLD
    BetterHi Identifier   fg=0x5094C4
    BetterHi Ignore       fg=0x666666
    BetterHi IncSearch    fg=0xBABEAA bg=0x3A4520
    BetterHi LineNr       fg=0x206AA9 bg=0x101124
    BetterHi MatchParen   fg=0x1122   bg=0x7B5A55
    BetterHi ModeMsg      fg=0xAACC
    BetterHi MoreMsg      fg=0x2E8B57
    BetterHi NonText      fg=0x382920
    BetterHi Number       fg=0x4580B4
    BetterHi Pmenu        fg=0x9AADD5 bg=0x3A6595
    BetterHi PmenuSel     fg=0xB0D0F0 bg=0x4A85BA
    BetterHi PreProc      fg=0xBA75CF
    BetterHi Question     fg=0xAABBCC
    " BetterHi Search     fg=0x0      bg=darkye
    BetterHi Special      fg=0xAAAACA
    " BetterHi SpecialKey fg=0x90DCB0
    BetterHi SpecialKey   fg=0x424242
    " BetterHi Statement  fg=0xFCA8AD
    BetterHi Statement    fg=0xDCA8AD attr=NONE
    BetterHi StatusLine   fg=0x6880EA bg=0x354070
    BetterHi StatusLineNC fg=0x5C6DBE bg=0x2C3054
    BetterHi tabline      fg=0x5B7098 bg=0x4D4D5F
    BetterHi tablinefill  fg=0xAAAAAA bg=0x2D2D3F
    BetterHi tablinesel   fg=0x50AAE5 bg=0x515A71
    BetterHi Title        fg=0xE5E5CA
    BetterHi Todo         fg=0x8B8B  bg=0xEEEE0
    BetterHi Type         fg=0x490E8  attr=BOLD
    BetterHi Underlined   fg=0xBAC5BA
    BetterHi VertSplit    fg=0x223355 bg=0x22253C
    BetterHi Visual       fg=0x102030 bg=0x80A0F0
    BetterHi VisualNOS    fg=0x201A30 bg=0xA3A5FF
    BetterHi WarningMsg   fg=0xFA8072
elseif &background == "light"
    if has('gui_running')
        BetterHi Normal       fg=0x3255   bg=0xE8EBF0
    else
        BetterHi Normal       fg=0x3255
    endif
    " BetterHi Comment    fg=darkyellow   bg=0x207ADA
    BetterHi Constant     fg=0x3A40AA
    BetterHi Cursor       fg=0xE8EBF0   bg=0x8FBF
    " BetterHi Cursor       fg=0x5293D  bg=0xCADACA
    BetterHi CursorColumn bg=0x20B5FD
    BetterHi CursorLine   bg=0x20B5FD
    BetterHi Directory    fg=0xBBD0DF
    BetterHi Error        bg=0xB03452
    BetterHi ErrorMsg     bg=0xFF4545
    BetterHi FoldColumn   fg=0xA9A9A9 bg=0x409AE0
    BetterHi Folded       fg=0xBBDDCC bg=0x252F5D
    BetterHi Function     fg=0xD06D50 attr=NONE
    BetterHi Identifier   fg=0x856075
    BetterHi Ignore       fg=0x666666
    BetterHi IncSearch    fg=0xDADECA bg=0x3A4520
    BetterHi LineNr       fg=0x8B     bg=0x409AE0 attr=BOLD
    BetterHi ModeMsg      fg=0xAACC
    BetterHi MoreMsg      fg=0x2E8B57
    BetterHi NonText      fg=0x382920 bg=0x152555
    BetterHi Number       fg=0x6BCD
    BetterHi Pmenu        fg=0x9AADD5 bg=0x3A6595
    BetterHi PmenuSel     fg=0xB0D0F0 bg=0x4A85BA
    BetterHi PreProc      fg=0x9570B5
    BetterHi Question     fg=0xAABBCC
    BetterHi Search       fg=0x3A4520 bg=0xBABDAD
    BetterHi Special      fg=0x652A7A
    BetterHi SpecialKey   fg=0x308C70
    BetterHi Statement    fg=0xDA302A
    BetterHi StatusLine   fg=0xA150D  bg=0x20B5FD
    BetterHi StatusLineNC fg=0x302D34 bg=0x580DA
    BetterHi Title        fg=0x857540
    BetterHi Todo         fg=0xFF450  bg=0xEEEE0
    BetterHi Type         fg=0x307ACA
    BetterHi Underlined   fg=0x8A758A
    BetterHi VertSplit    fg=0x7F7F7F bg=0x525F95
    BetterHi Visual       fg=0x8FBF   bg=0x33DFEF
    BetterHi WarningMsg   fg=0xFA8072
else
    echoerr "Unrecognized value for 'background'"
endif

" vim: sw=4 sts=4 et fdm=marker fdl=0:
