" This scheme was created by CSApproxSnapshot
" on Tue, 15 Nov 2011

hi clear
if exists("syntax_on")
    syntax reset
endif

if v:version < 700
    let g:colors_name = expand("<sfile>:t:r")
    command! -nargs=+ CSAHi exe "hi" substitute(substitute(<q-args>, "undercurl", "underline", "g"), "guisp\\S\\+", "", "g")
else
    let g:colors_name = expand("<sfile>:t:r")
    command! -nargs=+ CSAHi exe "hi" <q-args>
endif

if has('gui_running')
    CSAHi ColorColumn guibg=#8b0000 guifg=fg
    CSAHi Comment guibg=bg guifg=#008b8b
    CSAHi Conditional guibg=#11121a guifg=#d0688d
    CSAHi Constant guibg=bg guifg=#5c78f0
    CSAHi Cursor guibg=#cad5c0 guifg=#0000aa
    CSAHi CursorColumn guibg=#354070 guifg=fg
    CSAHi CursorLine guibg=#354070 guifg=fg
    CSAHi DiffAdd guibg=#003000 guifg=fg
    CSAHi DiffChange guibg=#000040 guifg=fg
    CSAHi DiffDelete gui=bold guibg=#300000 guifg=#0000ff
    CSAHi DiffText gui=bold guibg=#0e0e0e guifg=fg
    CSAHi Directory guibg=bg guifg=#bbd0df
    CSAHi Error guibg=#b03452 guifg=#ffffff
    CSAHi ErrorMsg guibg=#ff4545 guifg=#ffffff
    CSAHi Exception gui=bold guibg=#11121a guifg=#d0a8ad
    CSAHi FoldColumn guibg=#0a0a18 guifg=#dbcaa5
    CSAHi Folded guibg=#232235 guifg=#bebebe
    CSAHi Function gui=bold guibg=bg guifg=#bab588
    CSAHi Identifier guibg=bg guifg=#5094c4
    CSAHi Ignore guibg=#11121a guifg=#11121a
    CSAHi IncSearch gui=reverse guibg=#3a4520 guifg=#babeaa
    CSAHi Keyword gui=bold guibg=#11121a guifg=#bebebe
    CSAHi LineNr guibg=#101124 guifg=#206aa9
    CSAHi MatchParen guibg=#7b5a55 guifg=#001122
    CSAHi ModeMsg gui=bold guibg=bg guifg=#00aacc
    CSAHi MoreMsg gui=bold guibg=bg guifg=#2e8b57
    CSAHi NONE guibg=bg guifg=fg
    CSAHi NonText gui=bold guibg=bg guifg=#382920
    CSAHi Normal guibg=#11121a guifg=#a0b4e0
    CSAHi Number guibg=bg guifg=#4580b4
    CSAHi Operator guibg=#11121a guifg=#e8cdc0
    CSAHi Pmenu guibg=#3a6595 guifg=#9aadd5
    CSAHi PmenuSbar guibg=#bebebe guifg=fg
    CSAHi PmenuSel guibg=#4a85ba guifg=#b0d0f0
    CSAHi PmenuThumb gui=reverse guibg=bg guifg=fg
    CSAHi PreProc guibg=bg guifg=#ba75cf
    CSAHi Question gui=bold guibg=bg guifg=#aabbcc
    CSAHi Repeat guibg=#11121a guifg=#e06070
    CSAHi Search guibg=#ffff00 guifg=#000000
    CSAHi SignColumn guibg=#bebebe guifg=#00ffff
    CSAHi Special guibg=bg guifg=#aaaaca
    CSAHi SpecialKey guibg=bg guifg=#424242
    CSAHi SpellBad gui=undercurl guibg=bg guifg=fg guisp=#ff0000
    CSAHi SpellCap gui=undercurl guibg=bg guifg=fg guisp=#0000ff
    CSAHi SpellLocal gui=undercurl guibg=bg guifg=fg guisp=#00ffff
    CSAHi SpellRare gui=undercurl guibg=bg guifg=fg guisp=#ff00ff
    CSAHi Statement guibg=bg guifg=#dca8ad
    CSAHi StatusLine gui=reverse,bold guibg=#354070 guifg=#6880ea
    CSAHi StatusLineNC gui=reverse guibg=#2c3054 guifg=#5c6dbe
    CSAHi TabLine gui=underline guibg=#4d4d5f guifg=#5b7098
    CSAHi TabLineFill gui=reverse guibg=#2d2d3f guifg=#aaaaaa
    CSAHi TabLineSel gui=bold guibg=#515a71 guifg=#50aae5
    CSAHi Title gui=bold guibg=bg guifg=#e5e5ca
    CSAHi Todo guibg=#0eeee0 guifg=#008b8b
    CSAHi Type gui=bold guibg=bg guifg=#0490e8
    CSAHi Underlined gui=underline guibg=bg guifg=#bac5ba
    CSAHi VertSplit gui=reverse guibg=#22253c guifg=#223355
    CSAHi VimSynMtchCchar guibg=bg guifg=fg
    CSAHi Visual guibg=#80a0f0 guifg=#102030
    CSAHi VisualNOS gui=bold,underline guibg=#a3a5ff guifg=#201a30
    CSAHi WarningMsg guibg=bg guifg=#fa8072
    CSAHi WildMenu guibg=#ffff00 guifg=#000000
elseif has("gui_running") || (&t_Co == 256 && (&term ==# "xterm" || &term =~# "^screen") && exists("g:CSApprox_konsole") && g:CSApprox_konsole) || &term =~? "^konsole"
    CSAHi ColorColumn term=reverse cterm=NONE ctermbg=124 ctermfg=fg
    CSAHi Comment term=bold cterm=NONE ctermbg=bg ctermfg=37
    CSAHi Conditional term=NONE cterm=NONE ctermbg=17 ctermfg=175
    CSAHi Constant term=underline cterm=NONE ctermbg=bg ctermfg=105
    CSAHi Cursor term=NONE cterm=NONE ctermbg=188 ctermfg=19
    CSAHi CursorColumn term=reverse cterm=NONE ctermbg=60 ctermfg=fg
    CSAHi CursorLine term=underline cterm=NONE ctermbg=60 ctermfg=fg
    CSAHi DiffAdd term=bold cterm=NONE ctermbg=22 ctermfg=fg
    CSAHi DiffChange term=bold cterm=NONE ctermbg=17 ctermfg=fg
    CSAHi DiffDelete term=bold cterm=bold ctermbg=52 ctermfg=21
    CSAHi DiffText term=reverse cterm=bold ctermbg=233 ctermfg=fg
    CSAHi Directory term=bold cterm=NONE ctermbg=bg ctermfg=188
    CSAHi Error term=reverse cterm=NONE ctermbg=132 ctermfg=231
    CSAHi ErrorMsg term=NONE cterm=NONE ctermbg=203 ctermfg=231
    CSAHi Exception term=NONE cterm=bold ctermbg=17 ctermfg=181
    CSAHi FoldColumn term=NONE cterm=NONE ctermbg=16 ctermfg=187
    CSAHi Folded term=NONE cterm=NONE ctermbg=59 ctermfg=250
    CSAHi Function term=NONE cterm=bold ctermbg=bg ctermfg=187
    CSAHi Identifier term=underline cterm=NONE ctermbg=bg ctermfg=110
    CSAHi Ignore term=NONE cterm=NONE ctermbg=17 ctermfg=17
    CSAHi IncSearch term=reverse cterm=NONE ctermbg=187 ctermfg=59
    CSAHi Keyword term=NONE cterm=bold ctermbg=17 ctermfg=250
    CSAHi LineNr term=underline cterm=NONE ctermbg=17 ctermfg=67
    CSAHi MatchParen term=reverse cterm=NONE ctermbg=102 ctermfg=17
    CSAHi ModeMsg term=bold cterm=bold ctermbg=bg ctermfg=38
    CSAHi MoreMsg term=bold cterm=bold ctermbg=bg ctermfg=72
    CSAHi NONE term=NONE cterm=NONE ctermbg=bg ctermfg=fg
    CSAHi NonText term=bold cterm=bold ctermbg=bg ctermfg=59
    CSAHi Normal term=NONE cterm=NONE ctermbg=17 ctermfg=152
    CSAHi Number term=NONE cterm=NONE ctermbg=bg ctermfg=74
    CSAHi Operator term=NONE cterm=NONE ctermbg=17 ctermfg=224
    CSAHi Pmenu term=NONE cterm=NONE ctermbg=67 ctermfg=146
    CSAHi PmenuSbar term=NONE cterm=NONE ctermbg=250 ctermfg=fg
    CSAHi PmenuSel term=NONE cterm=NONE ctermbg=74 ctermfg=153
    CSAHi PmenuThumb term=NONE cterm=NONE ctermbg=152 ctermfg=17
    CSAHi PreProc term=underline cterm=NONE ctermbg=bg ctermfg=176
    CSAHi Question term=NONE cterm=bold ctermbg=bg ctermfg=152
    CSAHi Repeat term=NONE cterm=NONE ctermbg=17 ctermfg=174
    CSAHi Search term=reverse cterm=NONE ctermbg=226 ctermfg=16
    CSAHi SignColumn term=NONE cterm=NONE ctermbg=250 ctermfg=51
    CSAHi Special term=bold cterm=NONE ctermbg=bg ctermfg=146
    CSAHi SpecialKey term=bold cterm=NONE ctermbg=bg ctermfg=238
    CSAHi SpellBad term=reverse cterm=undercurl ctermbg=bg ctermfg=196
    CSAHi SpellCap term=reverse cterm=undercurl ctermbg=bg ctermfg=21
    CSAHi SpellLocal term=underline cterm=undercurl ctermbg=bg ctermfg=51
    CSAHi SpellRare term=reverse cterm=undercurl ctermbg=bg ctermfg=201
    CSAHi Statement term=bold cterm=NONE ctermbg=bg ctermfg=181
    CSAHi StatusLine term=reverse,bold cterm=bold ctermbg=111 ctermfg=60
    CSAHi StatusLineNC term=reverse cterm=NONE ctermbg=104 ctermfg=60
    CSAHi TabLine term=underline cterm=underline ctermbg=102 ctermfg=103
    CSAHi TabLineFill term=reverse cterm=NONE ctermbg=248 ctermfg=59
    CSAHi TabLineSel term=bold cterm=bold ctermbg=102 ctermfg=110
    CSAHi Title term=bold cterm=bold ctermbg=bg ctermfg=188
    CSAHi Todo term=NONE cterm=NONE ctermbg=50 ctermfg=37
    CSAHi Type term=underline cterm=bold ctermbg=bg ctermfg=39
    CSAHi Underlined term=underline cterm=underline ctermbg=bg ctermfg=188
    CSAHi VertSplit term=reverse cterm=NONE ctermbg=60 ctermfg=59
    CSAHi VimSynMtchCchar term=NONE cterm=NONE ctermbg=bg ctermfg=fg
    CSAHi Visual term=reverse cterm=NONE ctermbg=147 ctermfg=23
    CSAHi VisualNOS term=bold,underline cterm=bold,underline ctermbg=147 ctermfg=59
    CSAHi WarningMsg term=NONE cterm=NONE ctermbg=bg ctermfg=216
    CSAHi WildMenu term=NONE cterm=NONE ctermbg=226 ctermfg=16
elseif has("gui_running") || (&t_Co == 256 && (&term ==# "xterm" || &term =~# "^screen") && exists("g:CSApprox_eterm") && g:CSApprox_eterm) || &term =~? "^eterm"
    CSAHi Normal term=NONE cterm=NONE ctermbg=17 ctermfg=189
    CSAHi SpecialKey term=bold cterm=NONE ctermbg=bg ctermfg=238
    CSAHi NonText term=bold cterm=bold ctermbg=bg ctermfg=59
    CSAHi Directory term=bold cterm=NONE ctermbg=bg ctermfg=195
    CSAHi ErrorMsg term=NONE cterm=NONE ctermbg=210 ctermfg=255
    CSAHi IncSearch term=reverse cterm=NONE ctermbg=188 ctermfg=65
    CSAHi Search term=reverse cterm=NONE ctermbg=226 ctermfg=16
    CSAHi MoreMsg term=bold cterm=bold ctermbg=bg ctermfg=72
    CSAHi ModeMsg term=bold cterm=bold ctermbg=bg ctermfg=45
    CSAHi LineNr term=underline cterm=NONE ctermbg=17 ctermfg=68
    CSAHi VimSynMtchCchar term=NONE cterm=NONE ctermbg=bg ctermfg=fg
    CSAHi SpellLocal term=underline cterm=undercurl ctermbg=bg ctermfg=51
    CSAHi PmenuSel term=NONE cterm=NONE ctermbg=110 ctermfg=195
    CSAHi PmenuSbar term=NONE cterm=NONE ctermbg=250 ctermfg=fg
    CSAHi PmenuThumb term=NONE cterm=NONE ctermbg=189 ctermfg=17
    CSAHi TabLine term=underline cterm=underline ctermbg=102 ctermfg=110
    CSAHi TabLineSel term=bold cterm=bold ctermbg=103 ctermfg=117
    CSAHi TabLineFill term=reverse cterm=NONE ctermbg=188 ctermfg=59
    CSAHi CursorColumn term=reverse cterm=NONE ctermbg=67 ctermfg=fg
    CSAHi CursorLine term=underline cterm=NONE ctermbg=67 ctermfg=fg
    CSAHi Cursor term=NONE cterm=NONE ctermbg=231 ctermfg=20
    CSAHi MatchParen term=reverse cterm=NONE ctermbg=138 ctermfg=17
    CSAHi Comment term=bold cterm=NONE ctermbg=bg ctermfg=37
    CSAHi Constant term=underline cterm=NONE ctermbg=bg ctermfg=111
    CSAHi Special term=bold cterm=NONE ctermbg=bg ctermfg=189
    CSAHi Identifier term=underline cterm=NONE ctermbg=bg ctermfg=111
    CSAHi Statement term=bold cterm=NONE ctermbg=bg ctermfg=224
    CSAHi Function term=NONE cterm=bold ctermbg=bg ctermfg=187
    CSAHi PreProc term=underline cterm=NONE ctermbg=bg ctermfg=183
    CSAHi Type term=underline cterm=bold ctermbg=bg ctermfg=39
    CSAHi Underlined term=underline cterm=underline ctermbg=bg ctermfg=194
    CSAHi Error term=reverse cterm=NONE ctermbg=168 ctermfg=255
    CSAHi Number term=NONE cterm=NONE ctermbg=bg ctermfg=110
    CSAHi Title term=bold cterm=bold ctermbg=bg ctermfg=231
    CSAHi Conditional term=NONE cterm=NONE ctermbg=17 ctermfg=211
    CSAHi Repeat term=NONE cterm=NONE ctermbg=17 ctermfg=211
    CSAHi Operator term=NONE cterm=NONE ctermbg=17 ctermfg=231
    CSAHi Keyword term=NONE cterm=bold ctermbg=17 ctermfg=250
    CSAHi Exception term=NONE cterm=bold ctermbg=17 ctermfg=224
    CSAHi NONE term=NONE cterm=NONE ctermbg=bg ctermfg=fg
    CSAHi ColorColumn term=reverse cterm=NONE ctermbg=124 ctermfg=fg
    CSAHi Pmenu term=NONE cterm=NONE ctermbg=68 ctermfg=189
    CSAHi Ignore term=NONE cterm=NONE ctermbg=17 ctermfg=17
    CSAHi Todo term=NONE cterm=NONE ctermbg=51 ctermfg=37
    CSAHi Question term=NONE cterm=bold ctermbg=bg ctermfg=189
    CSAHi StatusLine term=reverse,bold cterm=bold ctermbg=111 ctermfg=67
    CSAHi StatusLineNC term=reverse cterm=NONE ctermbg=110 ctermfg=60
    CSAHi VertSplit term=reverse cterm=NONE ctermbg=60 ctermfg=59
    CSAHi Visual term=reverse cterm=NONE ctermbg=153 ctermfg=23
    CSAHi VisualNOS term=bold,underline cterm=bold,underline ctermbg=189 ctermfg=59
    CSAHi WarningMsg term=NONE cterm=NONE ctermbg=bg ctermfg=217
    CSAHi WildMenu term=NONE cterm=NONE ctermbg=226 ctermfg=16
    CSAHi Folded term=NONE cterm=NONE ctermbg=59 ctermfg=250
    CSAHi FoldColumn term=NONE cterm=NONE ctermbg=17 ctermfg=230
    CSAHi DiffAdd term=bold cterm=NONE ctermbg=22 ctermfg=fg
    CSAHi DiffChange term=bold cterm=NONE ctermbg=18 ctermfg=fg
    CSAHi DiffDelete term=bold cterm=bold ctermbg=52 ctermfg=21
    CSAHi DiffText term=reverse cterm=bold ctermbg=233 ctermfg=fg
    CSAHi SignColumn term=NONE cterm=NONE ctermbg=250 ctermfg=51
    CSAHi SpellBad term=reverse cterm=undercurl ctermbg=bg ctermfg=196
    CSAHi SpellCap term=reverse cterm=undercurl ctermbg=bg ctermfg=21
    CSAHi SpellRare term=reverse cterm=undercurl ctermbg=bg ctermfg=201
elseif has("gui_running") || &t_Co == 256
    CSAHi Normal term=NONE cterm=NONE ctermbg=16 ctermfg=146
    CSAHi SpecialKey term=bold cterm=NONE ctermbg=bg ctermfg=238
    CSAHi NonText term=bold cterm=bold ctermbg=bg ctermfg=52
    CSAHi Directory term=bold cterm=NONE ctermbg=bg ctermfg=152
    CSAHi ErrorMsg term=NONE cterm=NONE ctermbg=203 ctermfg=231
    CSAHi IncSearch term=reverse cterm=NONE ctermbg=145 ctermfg=58
    CSAHi Search term=reverse cterm=NONE ctermbg=226 ctermfg=16
    CSAHi MoreMsg term=bold cterm=bold ctermbg=bg ctermfg=29
    CSAHi ModeMsg term=bold cterm=bold ctermbg=bg ctermfg=38
    CSAHi LineNr term=underline cterm=NONE ctermbg=16 ctermfg=25
    CSAHi VimSynMtchCchar term=NONE cterm=NONE ctermbg=bg ctermfg=fg
    CSAHi SpellLocal term=underline cterm=undercurl ctermbg=bg ctermfg=51
    CSAHi PmenuSel term=NONE cterm=NONE ctermbg=67 ctermfg=153
    CSAHi PmenuSbar term=NONE cterm=NONE ctermbg=250 ctermfg=fg
    CSAHi PmenuThumb term=NONE cterm=NONE ctermbg=146 ctermfg=16
    CSAHi TabLine term=underline cterm=underline ctermbg=59 ctermfg=60
    CSAHi TabLineSel term=bold cterm=bold ctermbg=59 ctermfg=74
    CSAHi TabLineFill term=reverse cterm=NONE ctermbg=248 ctermfg=17
    CSAHi CursorColumn term=reverse cterm=NONE ctermbg=59 ctermfg=fg
    CSAHi CursorLine term=underline cterm=NONE ctermbg=59 ctermfg=fg
    CSAHi Cursor term=NONE cterm=NONE ctermbg=187 ctermfg=19
    CSAHi MatchParen term=reverse cterm=NONE ctermbg=95 ctermfg=16
    CSAHi Comment term=bold cterm=NONE ctermbg=bg ctermfg=30
    CSAHi Constant term=underline cterm=NONE ctermbg=bg ctermfg=69
    CSAHi Special term=bold cterm=NONE ctermbg=bg ctermfg=146
    CSAHi Identifier term=underline cterm=NONE ctermbg=bg ctermfg=68
    CSAHi Statement term=bold cterm=NONE ctermbg=bg ctermfg=181
    CSAHi Function term=NONE cterm=bold ctermbg=bg ctermfg=144
    CSAHi PreProc term=underline cterm=NONE ctermbg=bg ctermfg=140
    CSAHi Type term=underline cterm=bold ctermbg=bg ctermfg=32
    CSAHi Underlined term=underline cterm=underline ctermbg=bg ctermfg=151
    CSAHi Error term=reverse cterm=NONE ctermbg=131 ctermfg=231
    CSAHi Number term=NONE cterm=NONE ctermbg=bg ctermfg=67
    CSAHi Title term=bold cterm=bold ctermbg=bg ctermfg=188
    CSAHi Conditional term=NONE cterm=NONE ctermbg=16 ctermfg=168
    CSAHi Repeat term=NONE cterm=NONE ctermbg=16 ctermfg=167
    CSAHi Operator term=NONE cterm=NONE ctermbg=16 ctermfg=187
    CSAHi Keyword term=NONE cterm=bold ctermbg=16 ctermfg=250
    CSAHi Exception term=NONE cterm=bold ctermbg=16 ctermfg=181
    CSAHi NONE term=NONE cterm=NONE ctermbg=bg ctermfg=fg
    CSAHi ColorColumn term=reverse cterm=NONE ctermbg=88 ctermfg=fg
    CSAHi Pmenu term=NONE cterm=NONE ctermbg=60 ctermfg=110
    CSAHi Ignore term=NONE cterm=NONE ctermbg=16 ctermfg=16
    CSAHi Todo term=NONE cterm=NONE ctermbg=50 ctermfg=30
    CSAHi Question term=NONE cterm=bold ctermbg=bg ctermfg=146
    CSAHi StatusLine term=reverse,bold cterm=bold ctermbg=68 ctermfg=59
    CSAHi StatusLineNC term=reverse cterm=NONE ctermbg=61 ctermfg=23
    CSAHi VertSplit term=reverse cterm=NONE ctermbg=23 ctermfg=17
    CSAHi Visual term=reverse cterm=NONE ctermbg=111 ctermfg=17
    CSAHi VisualNOS term=bold,underline cterm=bold,underline ctermbg=147 ctermfg=17
    CSAHi WarningMsg term=NONE cterm=NONE ctermbg=bg ctermfg=209
    CSAHi WildMenu term=NONE cterm=NONE ctermbg=226 ctermfg=16
    CSAHi Folded term=NONE cterm=NONE ctermbg=17 ctermfg=250
    CSAHi FoldColumn term=NONE cterm=NONE ctermbg=16 ctermfg=187
    CSAHi DiffAdd term=bold cterm=NONE ctermbg=22 ctermfg=fg
    CSAHi DiffChange term=bold cterm=NONE ctermbg=17 ctermfg=fg
    CSAHi DiffDelete term=bold cterm=bold ctermbg=52 ctermfg=21
    CSAHi DiffText term=reverse cterm=bold ctermbg=233 ctermfg=fg
    CSAHi SignColumn term=NONE cterm=NONE ctermbg=250 ctermfg=51
    CSAHi SpellBad term=reverse cterm=undercurl ctermbg=bg ctermfg=196
    CSAHi SpellCap term=reverse cterm=undercurl ctermbg=bg ctermfg=21
    CSAHi SpellRare term=reverse cterm=undercurl ctermbg=bg ctermfg=201
elseif has("gui_running") || &t_Co == 88
    CSAHi Normal term=NONE cterm=NONE ctermbg=16 ctermfg=42
    CSAHi SpecialKey term=bold cterm=NONE ctermbg=bg ctermfg=80
    CSAHi NonText term=bold cterm=bold ctermbg=bg ctermfg=80
    CSAHi Directory term=bold cterm=NONE ctermbg=bg ctermfg=58
    CSAHi ErrorMsg term=NONE cterm=NONE ctermbg=64 ctermfg=79
    CSAHi IncSearch term=reverse cterm=NONE ctermbg=57 ctermfg=80
    CSAHi Search term=reverse cterm=NONE ctermbg=76 ctermfg=16
    CSAHi MoreMsg term=bold cterm=bold ctermbg=bg ctermfg=21
    CSAHi ModeMsg term=bold cterm=bold ctermbg=bg ctermfg=22
    CSAHi LineNr term=underline cterm=NONE ctermbg=16 ctermfg=21
    CSAHi VimSynMtchCchar term=NONE cterm=NONE ctermbg=bg ctermfg=fg
    CSAHi SpellLocal term=underline cterm=undercurl ctermbg=bg ctermfg=31
    CSAHi PmenuSel term=NONE cterm=NONE ctermbg=38 ctermfg=59
    CSAHi PmenuSbar term=NONE cterm=NONE ctermbg=85 ctermfg=fg
    CSAHi PmenuThumb term=NONE cterm=NONE ctermbg=42 ctermfg=16
    CSAHi TabLine term=underline cterm=underline ctermbg=81 ctermfg=37
    CSAHi TabLineSel term=bold cterm=bold ctermbg=37 ctermfg=38
    CSAHi TabLineFill term=reverse cterm=NONE ctermbg=84 ctermfg=80
    CSAHi CursorColumn term=reverse cterm=NONE ctermbg=17 ctermfg=fg
    CSAHi CursorLine term=underline cterm=NONE ctermbg=17 ctermfg=fg
    CSAHi Cursor term=NONE cterm=NONE ctermbg=58 ctermfg=17
    CSAHi MatchParen term=reverse cterm=NONE ctermbg=37 ctermfg=16
    CSAHi Comment term=bold cterm=NONE ctermbg=bg ctermfg=21
    CSAHi Constant term=underline cterm=NONE ctermbg=bg ctermfg=39
    CSAHi Special term=bold cterm=NONE ctermbg=bg ctermfg=38
    CSAHi Identifier term=underline cterm=NONE ctermbg=bg ctermfg=38
    CSAHi Statement term=bold cterm=NONE ctermbg=bg ctermfg=54
    CSAHi Function term=NONE cterm=bold ctermbg=bg ctermfg=57
    CSAHi PreProc term=underline cterm=NONE ctermbg=bg ctermfg=54
    CSAHi Type term=underline cterm=bold ctermbg=bg ctermfg=23
    CSAHi Underlined term=underline cterm=underline ctermbg=bg ctermfg=58
    CSAHi Error term=reverse cterm=NONE ctermbg=49 ctermfg=79
    CSAHi Number term=NONE cterm=NONE ctermbg=bg ctermfg=22
    CSAHi Title term=bold cterm=bold ctermbg=bg ctermfg=58
    CSAHi Conditional term=NONE cterm=NONE ctermbg=16 ctermfg=53
    CSAHi Repeat term=NONE cterm=NONE ctermbg=16 ctermfg=53
    CSAHi Operator term=NONE cterm=NONE ctermbg=16 ctermfg=74
    CSAHi Keyword term=NONE cterm=bold ctermbg=16 ctermfg=85
    CSAHi Exception term=NONE cterm=bold ctermbg=16 ctermfg=54
    CSAHi NONE term=NONE cterm=NONE ctermbg=bg ctermfg=fg
    CSAHi ColorColumn term=reverse cterm=NONE ctermbg=32 ctermfg=fg
    CSAHi Pmenu term=NONE cterm=NONE ctermbg=21 ctermfg=42
    CSAHi Ignore term=NONE cterm=NONE ctermbg=16 ctermfg=16
    CSAHi Todo term=NONE cterm=NONE ctermbg=30 ctermfg=21
    CSAHi Question term=NONE cterm=bold ctermbg=bg ctermfg=42
    CSAHi StatusLine term=reverse,bold cterm=bold ctermbg=39 ctermfg=17
    CSAHi StatusLineNC term=reverse cterm=NONE ctermbg=38 ctermfg=17
    CSAHi VertSplit term=reverse cterm=NONE ctermbg=17 ctermfg=80
    CSAHi Visual term=reverse cterm=NONE ctermbg=39 ctermfg=16
    CSAHi VisualNOS term=bold,underline cterm=bold,underline ctermbg=39 ctermfg=80
    CSAHi WarningMsg term=NONE cterm=NONE ctermbg=bg ctermfg=69
    CSAHi WildMenu term=NONE cterm=NONE ctermbg=76 ctermfg=16
    CSAHi Folded term=NONE cterm=NONE ctermbg=80 ctermfg=85
    CSAHi FoldColumn term=NONE cterm=NONE ctermbg=16 ctermfg=57
    CSAHi DiffAdd term=bold cterm=NONE ctermbg=16 ctermfg=fg
    CSAHi DiffChange term=bold cterm=NONE ctermbg=16 ctermfg=fg
    CSAHi DiffDelete term=bold cterm=bold ctermbg=16 ctermfg=19
    CSAHi DiffText term=reverse cterm=bold ctermbg=16 ctermfg=fg
    CSAHi SignColumn term=NONE cterm=NONE ctermbg=85 ctermfg=31
    CSAHi SpellBad term=reverse cterm=undercurl ctermbg=bg ctermfg=64
    CSAHi SpellCap term=reverse cterm=undercurl ctermbg=bg ctermfg=19
    CSAHi SpellRare term=reverse cterm=undercurl ctermbg=bg ctermfg=67
endif

delcommand CSAHi