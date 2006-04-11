" Vim color file
" carvedwood v0.9
" Maintainer:	Shawn Axsom <axs221@gmail.com>
"               [axs221.1l.com]

" carvedwood -
"     a color scheme modified from my desertocean scheme into a brown
" and green scheme, easier on the eyes and optimized for more important syntax
" to stand out the most (eg comments and values are dark and dull while
" statements are bright).

" cool help screens
" :he group-name
" :he highlight-groups
" :he cterm-colors

set background=dark
if version > 580
    " no guarantees for version 5.8 and below, but this makes it stop
    " complaining
    hi clear
    if exists("syntax_on")
		syntax reset
    endif
endif

let g:colors_name="carvedwood"

hi Normal     guifg=#86808d guibg=#111715
hi NonText    guifg=#382920 guibg=#111128

" syntax highlighting
hi Comment	  guifg=#4a4048
hi Title	  guifg=#60a0da
hi Underlined guifg=#60a5cd
hi Statement  guifg=#fac5ba
hi Type		  guifg=#a57570
hi Constant	  guifg=#664448
hi PreProc    guifg=#c07a6a
hi Identifier guifg=#b06d69
hi Special	  guifg=#454D5A
hi Ignore     guifg=grey40
hi Todo		  guifg=orangered guibg=yellow2
hi Error      guibg=#e04462
"end syntax highlighting

" highlight groups
"hi CursorIM
hi Directory guifg=#bbd0df
"hi DiffAdd
"hi DiffChange
"hi DiffDelete
"hi DiffText
"hi ErrorMsg

hi Cursor       guibg=#2d394b guifg=#65899d

hi FoldColumn	guibg=#111122 guifg=#00CCFF
hi LineNr       guibg=#11111b guifg=#D0C0BA 
hi StatusLine	guibg=#cda995 guifg=#102015 gui=none
hi StatusLineNC	guibg=#a0897d guifg=#373334 gui=none

hi Search       guibg=#5a6d7d guifg=#bac5d0
hi IncSearch	guifg=#50606d guibg=#cddaf0

hi VertSplit	guibg=#c2bfa5 guifg=grey50 gui=none
hi Folded       guibg=#0a4f4d guifg=#BBDDCC
hi ModeMsg    	guifg=#00AACC
hi MoreMsg      guifg=SeaGreen
hi Question    	guifg=#AABBCC
hi SpecialKey	guifg=#90703B
hi Visual       guifg=#008FBF guibg=#33DFEF
"hi VisualNOS
hi WarningMsg	guifg=salmon
"hi WildMenu
"hi Menu
"hi Scrollbar  guibg=grey30 guifg=tan
"hi Tooltip


" color terminal definitions
hi SpecialKey	ctermfg=darkgreen
hi NonText	cterm=bold ctermfg=darkblue
hi Directory	ctermfg=darkcyan
hi ErrorMsg	cterm=bold ctermfg=7 ctermbg=1
hi IncSearch	cterm=NONE ctermfg=yellow ctermbg=green
hi Search	cterm=NONE ctermfg=grey ctermbg=blue
hi MoreMsg	ctermfg=darkgreen
hi ModeMsg	cterm=NONE ctermfg=brown
hi LineNr	ctermfg=3
hi Question	ctermfg=green
hi StatusLine	cterm=bold,reverse
hi StatusLineNC cterm=reverse
hi VertSplit	cterm=reverse
hi Title	ctermfg=5
hi Visual	cterm=reverse
hi VisualNOS	cterm=bold,underline
hi WarningMsg	ctermfg=1
hi WildMenu	ctermfg=0 ctermbg=3
hi Folded	ctermfg=darkgrey ctermbg=NONE
hi FoldColumn	ctermfg=darkgrey ctermbg=NONE
hi DiffAdd	ctermbg=4
hi DiffChange	ctermbg=5
hi DiffDelete	cterm=bold ctermfg=4 ctermbg=6
hi DiffText	cterm=bold ctermbg=1
hi Comment	ctermfg=darkcyan
hi Constant	ctermfg=brown
hi Special	ctermfg=5
hi Identifier	ctermfg=6
hi Statement	ctermfg=3
hi PreProc	ctermfg=5
hi Type		ctermfg=2
hi Underlined	cterm=underline ctermfg=5
hi Ignore	cterm=bold ctermfg=7
hi Ignore	ctermfg=darkgrey
hi Error	cterm=bold ctermfg=7 ctermbg=1


"vim: sw=4

