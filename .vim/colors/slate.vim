hi clear Normal
set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let colors_name = "slate"

hi Cursor guibg=#c6e2ff guifg=#000000 gui=bold
hi Directory guibg=#181b1f guifg=#1e90ff gui=none
hi ErrorMsg guibg=#ee2c2c guifg=#ffffff gui=bold
hi DiffAdd guibg=#008b00 guifg=#d0d0d0 gui=none
hi DiffChange guibg=#00008b guifg=#d0d0d0 gui=none
hi DiffDelete guibg=#8b0000 guifg=#d0d0d0 gui=none
hi DiffText guibg=#00008b guifg=#d0d0d0 gui=bold
hi FoldColumn guibg=#363d45 guifg=#d0d0d0 gui=none
hi Folded guibg=#48525d guifg=#d0d0d0 gui=none
hi IncSearch guibg=#e7e7e7 guifg=#000000 gui=bold
hi LineNr guibg=#24292e guifg=#a7a7a7 gui=none
hi ModeMsg guibg=#181b1f guifg=#d0d0d0 gui=bold
hi MoreMsg guibg=#181b1f guifg=#d0d097 gui=bold
hi NonText ctermfg=8 guibg=#090a0b guifg=#878787 gui=bold
hi Normal ctermbg=0 ctermfg=15 guibg=#181b1f guifg=#d0d0d0 gui=none
hi Question guibg=#181b1f guifg=#e0c07e gui=bold
hi Search guibg=#d0d097 guifg=#000000 gui=bold
hi SignColumn guibg=#363d45 guifg=#d0d0d0 gui=none
hi SpecialKey guibg=#181b1f guifg=#a28b5b gui=none
hi StatusLine guibg=#9fb6cd guifg=#000000 gui=bold
hi StatusLineNC guibg=#6c7b8b guifg=#000000 gui=bold
hi Title guibg=#181b1f guifg=#e7e7e7 gui=bold
hi VertSplit guibg=#6c7b8b guifg=#000000 gui=bold
hi Visual ctermbg=7 ctermfg=0 guibg=#8598ac guifg=#000000 gui=bold
hi VisualNOS guibg=#181b1f guifg=#8598ac gui=bold,underline
hi WarningMsg guibg=#181b1f guifg=#ee2c2c gui=bold
hi WildMenu guibg=#e7e7e7 guifg=#000000 gui=bold

hi Comment guibg=#181b1f guifg=#bbbb87 gui=none
hi Constant guibg=#181b1f guifg=#8fe779 gui=none
hi Error guibg=#181b1f guifg=#ee2c2c gui=none
hi Identifier guibg=#181b1f guifg=#7ee0ce gui=none
hi Ignore guibg=#181b1f guifg=#373737 gui=none
hi lCursor guibg=#d0d0d0 guifg=#181b1f gui=bold
hi PreProc guibg=#181b1f guifg=#d7a0d7 gui=none
hi Special guibg=#181b1f guifg=#e0c07e gui=none
hi Statement guibg=#181b1f guifg=#7ec0ee gui=none
hi Todo guibg=#181b1f guifg=#d0d097 gui=bold,underline
hi Type guibg=#181b1f guifg=#f09479 gui=none
hi Underlined guibg=#181b1f guifg=#1e90ff gui=underline

hi htmlBold guibg=#181b1f guifg=#d0d0d0 gui=bold
hi htmlItalic guibg=#181b1f guifg=#d0d0d0 gui=italic
hi htmlUnderline guibg=#181b1f guifg=#d0d0d0 gui=underline
hi htmlBoldItalic guibg=#181b1f guifg=#d0d0d0 gui=bold,italic
hi htmlBoldUnderline guibg=#181b1f guifg=#d0d0d0 gui=bold,underline
hi htmlBoldUnderlineItalic guibg=#181b1f guifg=#d0d0d0 gui=bold,underline,italic
hi htmlUnderlineItalic guibg=#181b1f guifg=#d0d0d0 gui=underline,italic
