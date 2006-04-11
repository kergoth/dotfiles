" Vim color file
" baycomb v0.8h
" http://www.vim.org/scripts/script.php?script_id=1454
"
" Maintainer:    Shawn Axsom <axs221@gmail.com>
"
"   - Thanks to Desert and OceanDeep for their color scheme
"     file layouts

set background=dark
if version > 580
    " no guarantees for version 5.8 and below, but this makes it stop
    " complaining
    hi clear
    if exists("syntax_on")
        syntax reset
    endif
endif

let g:colors_name="baycomb"

if has("gui_running") || &t_Co == 88 || &t_Co == 256
    " functions {{{
    " returns an approximate grey index for the given grey level
    fun <SID>grey_number(x)
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
    fun <SID>grey_level(n)
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
    fun <SID>grey_color(n)
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
    fun <SID>rgb_number(x)
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
    fun <SID>rgb_level(n)
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
    fun <SID>rgb_color(x, y, z)
        if &t_Co == 88
            return 16 + (a:x * 16) + (a:y * 4) + a:z
        else
            return 16 + (a:x * 36) + (a:y * 6) + a:z
        endif
    endfun

    " returns the palette index to approximate the given R/G/B color levels
    fun <SID>color(r, g, b)
        " get the closest grey
        let l:gx = <SID>grey_number(a:r)
        let l:gy = <SID>grey_number(a:g)
        let l:gz = <SID>grey_number(a:b)

        " get the closest color
        let l:x = <SID>rgb_number(a:r)
        let l:y = <SID>rgb_number(a:g)
        let l:z = <SID>rgb_number(a:b)

        if l:gx == l:gy && l:gy == l:gz
            " there are two possibilities
            let l:dgr = <SID>grey_level(l:gx) - a:r
            let l:dgg = <SID>grey_level(l:gy) - a:g
            let l:dgb = <SID>grey_level(l:gz) - a:b
            let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
            let l:dr = <SID>rgb_level(l:gx) - a:r
            let l:dg = <SID>rgb_level(l:gy) - a:g
            let l:db = <SID>rgb_level(l:gz) - a:b
            let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
            if l:dgrey < l:drgb
                " use the grey
                return <SID>grey_color(l:gx)
            else
                " use the color
                return <SID>rgb_color(l:x, l:y, l:z)
            endif
        else
            " only one possibility
            return <SID>rgb_color(l:x, l:y, l:z)
        endif
    endfun

    " returns the palette index to approximate the 'rrggbb' hex string
    fun <SID>rgb(rgb)
        let l:r = ("0x" . strpart(a:rgb, 0, 2)) + 0
        let l:g = ("0x" . strpart(a:rgb, 2, 2)) + 0
        let l:b = ("0x" . strpart(a:rgb, 4, 2)) + 0

        return <SID>color(l:r, l:g, l:b)
    endfun

    " sets the highlighting for the given group
    fun <SID>X(group, fg, bg, attr)
        if a:fg != ""
            exec "hi " . a:group . " guifg=#" . a:fg . " ctermfg=" . <SID>rgb(a:fg)
        endif
        if a:bg != ""
            exec "hi " . a:group . " guibg=#" . a:bg . " ctermbg=" . <SID>rgb(a:bg)
        endif
        if a:attr != ""
            exec "hi " . a:group . " gui=" . a:attr . " cterm=" . a:attr
        endif
    endfun
    " }}}

    call <SID>X("Normal", "b8d0f0", "131d33", "")
    call <SID>X("NonText", "382920", "151822", "")

    " syntax highlighting
    "hi Comment        guifg=#84ad88  "green
    call <SID>X("Comment", "d8ca4b", "", "")
    call <SID>X("Title", "f5f5c0", "", "none")
    call <SID>X("Underlined", "dae5da", "", "")

    call <SID>X("Statement", "ff756d", "", "none")
    call <SID>X("Type", "309ace", "", "")
    call <SID>X("Constant", "4568cd", "", "")
    call <SID>X("PreProc", "9570b5", "", "")
    call <SID>X("Identifier", "c5604a", "", "") " or blue 4075aa
                        """e09a4b
    call <SID>X("Special", "1ab5ba", "", "")
    call <SID>X("Ignore", "666666", "", "")
    call <SID>X("Todo", "ff4500", "eeee00", "")
    call <SID>X("Error", "", "b03452", "")
    """""this section borrowed from OceanDeep/Midnight"""""
    call <SID>X("Number", "0065bd", "", "")
    call <SID>X("Function", "f0ad80", "", "none")
    call <SID>X("Conditional", "d52a4a", "", "none")
    call <SID>X("Repeat", "e0455a", "", "none")
    call <SID>X("Label", "90ee90", "", "none")
    call <SID>X("Operator", "fdb055", "", "none")
    call <SID>X("Keyword", "bebebe", "", "bold")
    call <SID>X("Exception", "ea5460", "", "none")
    """""""""""""""""""""""""""""""""""""""""""""""""""""""
    "end syntax highlighting

    " highlight groups
    "hi CursorIM
    call <SID>X("Directory", "bbd0df", "", "")
    "hi DiffAdd
    "hi DiffChange
    "hi DiffDelete
    "hi DiffText
    call <SID>X("ErrorMsg", "ff4545", "", "")

    call <SID>X("Cursor", "05293d", "cad5c0", "")

    call <SID>X("FoldColumn", "70459f", "83a5cd", "")
    call <SID>X("LineNr", "90a5d5", "111a2d", "")
    call <SID>X("StatusLine", "0a150d", "4085bd", "none")
    call <SID>X("StatusLineNC", "302d34", "45609a", "none")

    call <SID>X("Search", "3a4520", "9a9d8d", "")
    call <SID>X("IncSearch", "caceba", "3a4520", "")

    call <SID>X("VertSplit", "7f7f7f", "525f95", "none")
    call <SID>X("Folded", "bbddcc", "352f5d", "")
    call <SID>X("ModeMsg", "00aacc", "", "")
    call <SID>X("MoreMsg", "2e8b57", "", "")
    call <SID>X("Question", "aabbcc", "", "")
    call <SID>X("SpecialKey", "90dcb0", "", "")
    call <SID>X("Visual", "008fbf", "33dfef", "")
    "hi VisualNOS
    call <SID>X("WarningMsg", "fa8072", "", "")
    "hi WildMenu
    "hi Menu
    "hi Scrollbar  guibg=grey30 guifg=tan
    "hi Tooltip


    " new Vim 7.0 items
    call <SID>X("Pmenu", "9aadd5", "3a6595", "")
    call <SID>X("PmenuSel", "b0d0f0", "4a85ba", "")
    " delete functions {{{
    delf <SID>X
    delf <SID>rgb
    delf <SID>color
    delf <SID>rgb_color
    delf <SID>rgb_level
    delf <SID>rgb_number
    delf <SID>grey_color
    delf <SID>grey_level
    delf <SID>grey_number
    " }}}
else
    " color terminal definitions
    hi Number ctermfg=darkgreen
    highlight Operator ctermfg=yellow
    highlight Conditional ctermfg=red
    highlight Repeat ctermfg=red
    hi Exception ctermfg=red
    hi function ctermfg=darkyellow
    hi SpecialKey    ctermfg=darkgreen
    hi NonText    cterm=bold ctermfg=darkblue
    hi Directory    ctermfg=darkcyan
    hi ErrorMsg    cterm=bold ctermfg=7 ctermbg=1
    hi IncSearch    cterm=NONE ctermfg=darkgreen ctermbg=lightgrey
    hi Search    cterm=NONE ctermfg=lightgreen ctermbg=darkgrey
    hi MoreMsg    ctermfg=darkgreen
    hi ModeMsg    cterm=NONE ctermfg=brown
    hi LineNr    ctermfg=darkcyan ctermbg=NONE
    hi Question    ctermfg=green
    hi StatusLine    cterm=bold,reverse
    hi StatusLineNC cterm=reverse
    hi VertSplit    cterm=reverse
    hi Title    ctermfg=darkyellow
    hi Visual    cterm=reverse
    hi VisualNOS    cterm=bold,underline
    hi WarningMsg    ctermfg=1
    hi WildMenu    ctermfg=0 ctermbg=3
    hi Folded    ctermfg=darkgrey ctermbg=NONE
    hi FoldColumn    ctermfg=darkgrey ctermbg=darkgrey
    hi DiffAdd    ctermbg=4
    hi DiffChange    ctermbg=5
    hi DiffDelete    cterm=bold ctermfg=4 ctermbg=6
    hi DiffText    cterm=bold ctermbg=1
    hi Comment    ctermfg=yellow
    hi Constant    ctermfg=blue
    hi Special    ctermfg=darkcyan
    hi Identifier    ctermfg=darkyellow
    hi Statement    ctermfg=darkred
    hi PreProc    ctermfg=5
    hi Type        ctermfg=lightcyan
    hi Underlined    cterm=underline ctermfg=5
    hi Ignore    cterm=bold ctermfg=7
    hi Ignore    ctermfg=darkgrey
    hi Error    cterm=bold ctermfg=7 ctermbg=1

    " new Vim 7.0 items
    hi Pmenu        ctermbg=darkblue ctermfg=lightgrey
    hi PmenuSel     ctermbg=lightblue ctermfg=white
endif

" vim: sw=4 sts=4 et fdm=marker fdl=0:
