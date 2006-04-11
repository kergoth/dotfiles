" Vim color file
" watermark v1.0
" http://www.vim.org/scripts/script.php?script_id=1454
" 
" Maintainer:	Shawn Axsom <axs221@gmail.com>
"
"   - This scheme is built from Baycomb v0.6b. The scheme
"     has changed dramatically since this version, so I decided
"     to upload it with a new name for those who preferred it.
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

let g:colors_name="watermark"

hi Normal       guifg=#b0c5e0 guibg=#1d2442
hi NonText      guifg=#382920 guibg=#111a2a

" syntax highlighting
hi Comment		guifg=#a8a0ff
hi Title		guifg=#ffffd0
hi Underlined   guifg=#d0dfc0

hi Statement    guifg=#ff8a70
hi Type			guifg=#309ae0
hi Constant		guifg=#4a60c5
hi PreProc      guifg=#9a558a
hi Identifier   guifg=#d0baa0   
                    """e09a4b
hi Special		guifg=#208db5
hi Ignore       guifg=grey40
hi Todo			guifg=orangered guibg=yellow2
hi Error        guibg=#b03452
"""""this section borrowed from OceanDeep/Midnight"""""
hi Number guifg=#205ab3
hi Function gui=None guifg=#70abaa guibg=bg
highlight Conditional gui=None guifg=#cf3530 guibg=bg
highlight Repeat gui=None guifg=#ee305a guibg=bg
"hi Label gui=None guifg=LightGreen guibg=bg
highlight Operator gui=None guifg=#fdda55 guibg=bg
highlight Keyword gui=bold guifg=grey guibg=bg
highlight Exception gui=bold guifg=#ee5534 guibg=bg
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"end syntax highlighting

" highlight groups
"hi CursorIM
hi Directory	guifg=#bbd0df
"hi DiffAdd
"hi DiffChange
"hi DiffDelete
"hi DiffText
hi ErrorMsg     guibg=#ff4545

hi Cursor       guibg=#cacdab guifg=#05293d

hi FoldColumn	guibg=#83a5cd guifg=#70459F
hi LineNr       guibg=#1e203a guifg=#80a0dA 
hi StatusLine	guibg=#407aba guifg=#102015 gui=none
hi StatusLineNC	guibg=#45609a guifg=#373334 gui=none

hi Search       guibg=#6a8d7d guifg=#3a4520
hi IncSearch	guifg=#8aad9d guibg=#3a4520 

hi VertSplit	guibg=#525f95 guifg=grey50 gui=none
hi Folded       guibg=#352f5d guifg=#BBDDCC
hi ModeMsg    	guifg=#00AACC
hi MoreMsg      guifg=SeaGreen
hi Question    	guifg=#AABBCC
hi SpecialKey	guifg=#b0dc90
hi Visual       guifg=#008FBF guibg=#33DFEF
"hi VisualNOS
hi WarningMsg	guifg=salmon
"hi WildMenu
"hi Menu
"hi Scrollbar  guibg=grey30 guifg=tan
"hi Tooltip


" color terminal definitions
hi Number ctermfg=darkgreen
highlight Operator ctermfg=yellow
highlight Conditional ctermfg=red
highlight Repeat ctermfg=red
hi Exception ctermfg=red
hi function ctermfg=darkyellow
hi SpecialKey	ctermfg=darkgreen
hi NonText	cterm=bold ctermfg=darkblue
hi Directory	ctermfg=darkcyan
hi ErrorMsg	cterm=bold ctermfg=7 ctermbg=1
hi IncSearch	cterm=NONE ctermfg=darkgreen ctermbg=lightgrey
hi Search	cterm=NONE ctermfg=lightgreen ctermbg=darkgrey
hi MoreMsg	ctermfg=darkgreen
hi ModeMsg	cterm=NONE ctermfg=brown
hi LineNr	ctermfg=darkcyan ctermbg=NONE
hi Question	ctermfg=green
hi StatusLine	cterm=bold,reverse
hi StatusLineNC cterm=reverse
hi VertSplit	cterm=reverse
hi Title	ctermfg=darkyellow
hi Visual	cterm=reverse
hi VisualNOS	cterm=bold,underline
hi WarningMsg	ctermfg=1
hi WildMenu	ctermfg=0 ctermbg=3
hi Folded	ctermfg=darkgrey ctermbg=NONE
hi FoldColumn	ctermfg=darkgrey ctermbg=darkgrey
hi DiffAdd	ctermbg=4
hi DiffChange	ctermbg=5
hi DiffDelete	cterm=bold ctermfg=4 ctermbg=6
hi DiffText	cterm=bold ctermbg=1
hi Comment	ctermfg=magenta
hi Constant	ctermfg=blue
hi Special	ctermfg=darkgreen
hi Identifier	ctermfg=darkyellow
hi Statement	ctermfg=darkred
hi PreProc	ctermfg=5
hi Type		ctermfg=lightcyan
hi Underlined	cterm=underline ctermfg=5
hi Ignore	cterm=bold ctermfg=7
hi Ignore	ctermfg=darkgrey
hi Error	cterm=bold ctermfg=7 ctermbg=1


"vim: sw=4


