" Vim color file
" sift v1.2
" http://www.vim.org/scripts/script.php?script_id=1454
" 
" Maintainer:	Shawn Axsom <axs221@gmail.com>
"
"   * Place :colo sift in your VimRC/GVimRC file
"     * GvimRC if using GUI any
"
"   - Thanks to Desert and OceanDeep for their color scheme 
"     file layouts
"   - Thanks to Raimon Grau for his feedback

set background=dark
if version > 580
    " no guarantees for version 5.8 and below, but this makes it stop
    " complaining
    hi clear
    if exists("syntax_on")
		syntax reset
    endif
endif

let g:colors_name="sift"

hi Normal       guifg=#9bdcef guibg=#13081a
hi NonText      guifg=#382920 guibg=#140316

" syntax highlighting """"""""""""""""""""""""""""""""""""""""

hi Comment		guifg=#509080
hi Title		guifg=#5959f9  gui=none
hi Underlined   guifg=#0959f9 gui=none

hi Statement    guifg=#ffff80  gui=none
hi Type			guifg=#00e5bf  gui=none
hi Constant		guifg=#3acaf5
hi Number		guifg=#0afafa
hi PreProc      guifg=#f055c3
hi Identifier   guifg=#30a0f0
hi Special		guifg=#c0caa5
hi Operator		guifg=#905a60
"hi Keyword		guifg=green
"hi Error        guibg=#408452
hi Function     guifg=#c08a50 guibg=black gui=bold "or green 50b3b0 
hi Conditional	guifg=#f5305a guibg=bg
hi Repeat		guifg=#f5505a guibg=bg
hi Exception	guifg=#cfff00
"hi Ignore       guifg=grey40
"hi Todo			guifg=orangered guibg=yellow2
"""""this section borrowed from OceanDeep/Midnight"""""
"hi Label gui=None guifg=LightGreen guibg=bg
"highlight Operator gui=None guifg=#daca65 guibg=bg
"highlight Keyword gui=bold guifg=grey guibg=bg
"highlight Exception gui=none guifg=#ea5460 guibg=bg
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"end syntax highlighting """""""""""""""""""""""""""""""""""""

" highlight groups
"hi CursorIM
hi Directory	guifg=#bbd0df
"hi DiffAdd
"hi DiffChange
"hi DiffDelete
"hi DiffText
hi ErrorMsg     guibg=#ff4545

hi Cursor       guibg=#cad5c0 guifg=#05293d

hi Folded       guibg=#201328 guifg=#BBDDCC
hi FoldColumn	guibg=#130014 guifg=#dbcaa5
"hi FoldColumn	guibg=#83a5cd guifg=#70459F
hi LineNr       guibg=#130518 guifg=#8095d5 
"hi LineNr       guibg=#081c30 guifg=#80a0dA 
hi StatusLine	guibg=#6585c5 guifg=#0a150d gui=none
hi StatusLineNC	guibg=#55609a guifg=#302d34 gui=none

hi Search       guibg=#9a9d8d guifg=#3a4520
hi IncSearch	guifg=#caceba guibg=#3a4520 

hi VertSplit	guibg=#525f95 guifg=grey50 gui=none
hi ModeMsg    	guifg=#00AACC
hi MoreMsg      guifg=SeaGreen
hi Question    	guifg=#AABBCC
hi SpecialKey	guifg=#90dcb0
hi Visual       guifg=#4a2F3F guibg=#935FdF
"hi VisualNOS
hi WarningMsg	guifg=salmon
"hi WildMenu
"hi Menu
"hi Scrollbar  guibg=grey30 guifg=tan
"hi Tooltip


" new Vim 7.0 items
hi Pmenu        guibg=#3a6595 guifg=#9aadd5
hi PmenuSel     guibg=#4a85ba guifg=#b0d0f0                    





" color terminal definitions
hi Normal ctermfg=grey
hi Number ctermfg=blue
highlight Operator ctermfg=yellow
highlight Conditional ctermfg=darkred
highlight Repeat ctermfg=darkred
hi Exception ctermfg=red
hi function ctermfg=darkyellow
hi SpecialKey	ctermfg=darkgreen
hi NonText	cterm=bold ctermfg=darkgrey
hi Directory	ctermfg=darkcyan
hi ErrorMsg	cterm=bold ctermfg=7 ctermbg=1
hi IncSearch	ctermfg=yellow ctermbg=darkyellow cterm=NONE
hi Search	ctermfg=black ctermbg=darkyellow cterm=NONE
hi MoreMsg	ctermfg=darkgreen
hi ModeMsg	cterm=NONE ctermfg=brown
hi LineNr	ctermfg=darkcyan ctermbg=NONE
hi Question	ctermfg=green
hi StatusLine	ctermfg=blue ctermbg=grey cterm=NONE
hi StatusLineNC ctermfg=black ctermbg=grey cterm=NONE
hi VertSplit	ctermfg=black ctermbg=grey cterm=NONE
hi Title	ctermfg=Yellow cterm=NONE
hi Visual	ctermbg=darkcyan ctermfg=black cterm=NONE
hi VisualNOS	ctermbg=darkcyan ctermfg=black cterm=NONE
hi WarningMsg	ctermfg=1
hi WildMenu	ctermfg=0 ctermbg=3
hi Folded	ctermfg=darkgreen ctermbg=NONE cterm=NONE
hi FoldColumn	ctermfg=green ctermbg=black
hi DiffAdd	ctermbg=4
hi DiffChange	ctermbg=5
hi DiffDelete	cterm=bold ctermfg=4 ctermbg=6
hi DiffText	cterm=bold ctermbg=1
hi identifier   ctermfg=darkmagenta

"set comments to grey on non-Windows OS's to make sure
"it is readable
if &term == "builtin_gui" || &term == "win32"
	hi Comment		ctermfg=darkgrey  ctermbg=darkblue
	hi IncSearch	ctermfg=black ctermbg=grey cterm=NONE
	hi Search	ctermfg=black ctermbg=darkgrey cterm=NONE
else
	hi Comment		ctermfg=grey  ctermbg=darkblue
	hi IncSearch	ctermfg=yellow ctermbg=darkyellow cterm=NONE
	hi Search	ctermfg=black ctermbg=darkyellow cterm=NONE
endif
""""""""""""""""""""""""""""""""""""""""""""""""""""""

hi Constant	ctermfg=blue
hi Special	ctermfg=darkmagenta
hi Statement	ctermfg=red
hi PreProc	ctermfg=magenta
hi Type		ctermfg=darkblue " ctermbg=darkblue
hi Underlined	ctermfg=yellow cterm=NONE
hi Ignore	cterm=bold ctermfg=7
hi Ignore	ctermfg=darkgrey
hi Error	cterm=bold ctermfg=7 ctermbg=1

" new Vim 7.0 items
hi Pmenu        ctermbg=darkblue ctermfg=lightgrey
hi PmenuSel     ctermbg=lightblue ctermfg=white                    

"vim: sw=4


