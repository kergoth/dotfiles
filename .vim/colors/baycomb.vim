" baycomb v2.4 by Shawn Axsom <axs221@gmail.com>
"              modified by Chris Larson <clarson@kergoth.com>

if version > 580
    " no guarantees for version 5.8 and below, but this makes it stop
    " complaining
    hi clear

    if exists("syntax_on")
        syntax reset
    endif
endif

let g:colors_name="baycomb"

if &background == "dark"
    hi Normal guifg=#A0B4E0 guibg=#11121A

    hi Comment guifg=#008B8B
    hi Conditional gui=NONE guifg=#d0688d guibg=bg
    hi Constant guifg=#5C78F0
    hi Cursor guifg=#0000AA guibg=#CAD5C0
    hi CursorColumn guibg=#354070
    hi CursorLine guibg=#354070
    hi DiffAdd guibg=#003000
    hi DiffChange guibg=#000040
    hi DiffDelete guibg=#300000
    hi DiffText guibg=#0E0E0E
"     hi DiffAdd guibg=#0A4B8C
"     hi DiffChange guibg=#685B5C
"     hi DiffDelete guifg=#300845 guibg=#200845
"     hi DiffText guibg=#004335
    hi Directory guifg=#BBD0DF
    hi Error guibg=#B03452
    hi ErrorMsg guibg=#FF4545
    hi Exception gui=BOLD guifg=#d0a8ad guibg=bg
    hi FoldColumn guifg=#DBCAA5 guibg=#0A0A18
    hi Folded guifg=#BEBEBE guibg=#232235
    hi Function guifg=#BAB588 gui=BOLD
    hi Identifier guifg=#5094C4
    "hi Ignore guifg=#666666
    hi Ignore guifg=bg guibg=bg
    hi IncSearch guifg=#BABEAA guibg=#3A4520
    hi Keyword gui=BOLD guifg=grey guibg=bg
    hi LineNr guifg=#206AA9 guibg=#101124
    hi MatchParen guifg=#001122 guibg=#7B5A55
    hi ModeMsg guifg=#00AACC
    hi MoreMsg guifg=#2E8B57
    hi NonText guifg=#382920
    hi Number guifg=#4580B4
    hi Operator gui=NONE guifg=#e8cdc0 guibg=bg
    hi Pmenu guifg=#9AADD5 guibg=#3A6595
    hi PmenuSel guifg=#B0D0F0 guibg=#4A85BA
    hi PreProc guifg=#BA75CF
    hi Question guifg=#AABBCC
    hi Repeat gui=NONE guifg=#e06070 guibg=bg
    hi Special guifg=#AAAACA
    hi SpecialKey guifg=#424242
    hi Statement guifg=#DCA8AD gui=NONE
    hi StatusLine guifg=#6880EA guibg=#354070
    hi StatusLineNC guifg=#5C6DBE guibg=#2C3054
    hi tabline guifg=#5B7098 guibg=#4D4D5F
    hi tablinefill guifg=#AAAAAA guibg=#2D2D3F
    hi tablinesel guifg=#50AAE5 guibg=#515A71
    hi Title guifg=#E5E5CA
    hi Todo guifg=#008B8B guibg=#0EEEE0
    hi Type guifg=#0490E8 gui=BOLD
    hi Underlined guifg=#BAC5BA
    hi VertSplit guifg=#223355 guibg=#22253C
    hi Visual guifg=#102030 guibg=#80A0F0
    hi VisualNOS guifg=#201A30 guibg=#A3A5FF
    hi WarningMsg guifg=#FA8072

    hi Cursor ctermfg=black ctermbg=white
    hi Normal ctermfg=grey ctermbg=black
    hi Number ctermfg=darkgreen
    hi Operator ctermfg=yellow
    hi Conditional ctermfg=darkred
    hi Repeat ctermfg=darkred
    hi Exception ctermfg=darkred
    hi SpecialKey ctermfg=darkgreen
    hi NonText cterm=bold ctermfg=darkgrey
    hi Directory ctermfg=darkcyan
    hi ErrorMsg cterm=bold ctermfg=7 ctermbg=1
    hi IncSearch ctermfg=yellow ctermbg=darkyellow cterm=NONE
    hi Search ctermfg=black ctermbg=darkyellow cterm=NONE
    hi MoreMsg ctermfg=darkgreen
    hi ModeMsg cterm=NONE ctermfg=brown
    hi LineNr ctermfg=darkcyan ctermbg=black
    hi Question ctermfg=green
    hi StatusLine ctermfg=yellow ctermbg=darkblue cterm=NONE
    hi StatusLineNC ctermfg=grey ctermbg=darkblue cterm=NONE
    hi VertSplit ctermfg=black ctermbg=darkgrey cterm=NONE
    hi Title ctermfg=yellow cterm=NONE
    hi Visual ctermbg=grey ctermfg=blue cterm=NONE
    hi VisualNOS ctermbg=grey ctermfg=blue cterm=NONE
    hi WarningMsg ctermfg=1
    hi WildMenu ctermfg=0 ctermbg=3
    hi Folded ctermfg=white ctermbg=darkgrey cterm=NONE
    hi FoldColumn ctermfg=yellow ctermbg=black
    hi DiffAdd ctermbg=4
    hi DiffChange ctermbg=5
    hi DiffDelete cterm=bold ctermfg=4 ctermbg=6
    hi DiffText cterm=bold ctermbg=1
    hi Comment ctermfg=darkcyan ctermbg=black
    hi Identifier ctermfg=cyan
    "set comments to grey on non-Windows OS's to make sure
    "it is readable
    if &term == "builtin_gui" || &term == "win32"
        hi function ctermfg=grey
        hi Type ctermfg=darkyellow ctermbg=darkblue
        hi IncSearch ctermfg=black ctermbg=grey cterm=NONE
        hi Search ctermfg=black ctermbg=darkgrey cterm=NONE
    else
        hi function ctermfg=white
        hi Type ctermfg=grey
        hi IncSearch ctermfg=yellow ctermbg=darkyellow cterm=NONE
        hi Search ctermfg=black ctermbg=darkyellow cterm=NONE
    endif
    hi Constant ctermfg=blue
    hi Special ctermfg=white
    hi Statement ctermfg=yellow
    hi PreProc ctermfg=red
    hi Underlined ctermfg=cyan cterm=NONE
"    hi Ignore cterm=bold ctermfg=7
    hi Ignore ctermfg=bg ctermbg=bg
    hi Error cterm=bold ctermfg=7 ctermbg=1
    hi Pmenu ctermbg=darkblue ctermfg=lightgrey
    hi PmenuSel ctermbg=lightblue ctermfg=white
    hi tablinesel ctermfg=cyan ctermbg=blue
    hi tabline ctermfg=black ctermbg=blue
    hi tablinefill ctermfg=green ctermbg=darkblue
    hi MatchParen ctermfg=black ctermbg=green
elseif &background == "light"
    hi Normal guifg=#003255 guibg=#E8EBF0

    hi Constant guifg=#3A40AA
    hi Cursor guifg=#E8EBF0 guibg=#008FBF
    hi CursorColumn guibg=#20B5FD
    hi CursorLine guibg=#20B5FD
    hi Directory guifg=#BBD0DF
    "hi Error guibg=#B03452
    hi Error guibg=#D07082
    hi ErrorMsg guibg=#FF4545
    hi FoldColumn guifg=#A9A9A9 guibg=#409AE0
    hi Folded guifg=#BBDDCC guibg=#252F5D
    hi Function guifg=#D06D50 gui=NONE
    hi Identifier guifg=#856075
    hi Ignore guifg=#666666
    hi IncSearch guifg=#DADECA guibg=#3A4520
    hi LineNr guifg=#00008B guibg=#409AE0 gui=BOLD
    hi ModeMsg guifg=#00AACC
    hi MoreMsg guifg=#2E8B57
    hi NonText guifg=#382920 guibg=#152555
    hi Number guifg=#006BCD
    hi Pmenu guifg=#9AADD5 guibg=#3A6595
    hi PmenuSel guifg=#B0D0F0 guibg=#4A85BA
    hi PreProc guifg=#9570B5
    hi Question guifg=#AABBCC
    hi Search guifg=#3A4520 guibg=#BABDAD
    hi Special guifg=#652A7A
    hi SpecialKey guifg=#308C70
    hi Statement guifg=#DA302A
    hi StatusLine guifg=#0A150D guibg=#20B5FD
    hi StatusLineNC guifg=#302D34 guibg=#0580DA
    hi Title guifg=#857540
    hi Todo guifg=#0FF450 guibg=#0EEEE0
    hi Type guifg=#307ACA
    hi Underlined guifg=#8A758A
    hi VertSplit guifg=#7F7F7F guibg=#525F95
    hi Visual guifg=#008FBF guibg=#33DFEF
    hi WarningMsg guifg=#FA8072
else
    echoerr "Unrecognized value for 'background'"
endif


" vim: sw=4 sts=4 et:
