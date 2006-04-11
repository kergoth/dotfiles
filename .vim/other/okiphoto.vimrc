" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
  finish
endif

set nocompatible		" set non-compatible with vi
color vcbc			" load ~/.vim/colors/vcbc.vim
set isk+=_,$,@,%,#,-		" characters that do not separate words
set shortmess=atAI		" shorten various messages
set report=0			" threshold for reporting changes
set noerrorbells		" disable error bells
set vb t_vb=			" disable visual bells
set showmatch			" show matching brackets
set mat=10			" how long to show matching brackets
set nohlsearch			" no search highlighting
set incsearch			" show search results while typing
set tabstop=8			" tabstop - do not modify this value
set softtabstop=4		" number of spaces used for tab 
set shiftwidth=4		" number of spaces for auto indent and shifting
set noexpandtab			" do not substitute spaces for tabs
set nowrap			" do not wrap lines
set smarttab			" use shiftwidth and tabstop
set foldenable			" allow the code to be folded
set foldmethod=indent		" automatically create folds on indentation
set foldopen-=search		" open folds when searching 
set foldopen-=undo		" open folds during undo operations
set history=50			" keep 50 lines of command line history
set ruler			" show the cursor position all the time
set showcmd			" display incomplete commands
set incsearch			" do incremental searching
set backspace=indent,eol,start	" allow backspacing over everything in insert mode

let g:pydoc_cmd = "/Library/Frameworks/Python.framework/Versions/2.4/lib/python2.4/pydoc.py"
let g:explVertical=1	" split window vertically
let g:explWinSize=35	" set explorer window size
let mapleader = ","		" set <leader> default is backslash
let SVNCommandEdit='split'

" path to ctags installation directory
let Tlist_Ctags_Cmd = "/usr/local/bin/ctags"
let Tlist_Sort_Type = "order"	    " sort chronologically
let Tlist_Close_On_Select = 1	    " close buffer when tag is selected
let Tlist_Display_Tag_Scope = 1	    " display tag scope in list
let Tlist_Close_On_Select = 1	    " close when selecting a tag
let Tlist_Use_Horiz_Window = 1	    " use horizontal window split
let Tlist_Compact_Format = 1	    " use small menu format
let Tlist_Exit_OnlyWindow = 1	    " if you are the last, kill yourself
let Tlist_File_Fold_Auto_Close = 0  " do not close tags for other files
let Tlist_Enable_Fold_Column = 0    " do not show folding tree

map <buffer> <silent> <F3> :TlistOpen <CR>
map Q gq				" Don't use Ex mode, use Q for formatting

if has("autocmd")
  filetype plugin indent on
  autocmd FileType python set complete+=k~/.vim/plugin/pydiction iskeyword+=.,(
  autocmd FileType python compiler pylint
  autocmd FileType python map <buffer> <silent> <F8> :!python % <CR>
  autocmd FileType python map <buffer> <silent> <F2> zc <CR>
  autocmd BufReadPost quickfix map <buffer> <silent> <CR> :.cc <CR> :ccl <CR>
  autocmd BufEnter * :lcd %:p:h
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
else
  set autoindent		    " always set autoindenting on
endif " has("autocmd")

if &t_Co > 2 || has("gui_running")
  syntax on                         " Switch syntax highlighting on
  set hlsearch			    " highlight the last used search pattern.
endif
