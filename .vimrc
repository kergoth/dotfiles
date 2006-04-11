" vim: set et sw=2 sts=2 fdm=marker fdl=0:

" Command quick reference {{{
" Align/AlignMaps:
"   \adec - align C declarations
"   \acom - align comments
"   \afnc - align ansi-style C function input arguments
"   \Htd  - align html tables
" NERD commenter:
"   \cs - apply "sexy" comment to line(s)
"   \c<space> - toggle commenting on line(s)
"   \cc - comment block as a whole (doesnt obey space_delim)
"   \ci - comment individually
"   \cu - uncomment individually
" modelines inserter:
"   \im - insert modelines based on current settings
" Line highlighter:
"   \hcli - enable highlighting of the current line
"   \hcls - disable highlighting of the current line
" winmanager (if enabled):
"   ^W^T - toggle
"   ^W^F - top left window
"   ^W^B - bottom left window
"   ^N (in the file explorer window) - toggle file explorer / tag list
" taglist (if not using winmanager):
"   F8 - toggle
" VIM core:
"   K - look up current word via 'man' (by default)
"   ^X ^O - Omni completion
" }}}

if v:version < 600
  echo "ERROR: vim version too old.  Upgrade to vim 6.0 or later."
  finish
endif

if has("win32")
  "set runtimepath=~/.vim,~/vimfiles,$VIM/vimfiles,$VIMRUNTIME
  behave mswin
  source $VIMRUNTIME/mswin.vim
else
  behave xterm
endif

" Keymaps {{{
map ,is :!ispell %<C-M>          " ISpell !

map ,del :g/^\s*$/d<C-M>         " Delete Empty Lines
map ,ddql :%s/^>\s*>.*//g<C-M>   " Delete Double Quoted Lines
map ,ddr :s/\.\+\s*/. /g<C-M>    " Delete Dot Runs
map ,dsr :s/\s\s\+/ /g<C-M>      " Delete Space Runs
map ,dtw :%s/\s\+$//g<C-M>       " Delete Trailing Whitespace

nmap <leader>sh :runtime vimsh/vimsh.vim<C-M>
nmap <leader>a :A<CR>            " Switch between .c/cpp and .h (a.vim)
nmap <leader>n :set number!<CR>  " Toggle Line Numbering

if has("win32")
  nmap ,s :source $HOME/_vimrc<CR>
  nmap <silent> ,v :e $HOME/_vimrc<CR>
else
  nmap ,s :source $HOME/.vimrc<CR>
  nmap <silent> ,v :e $HOME/.vimrc<CR>
endif


" Buffer Switching {{{
if has("gui_running")
  noremap <M-1> :b1<CR>:<BS>
  noremap <M-2> :b2<CR>:<BS>
  noremap <M-3> :b3<CR>:<BS>
  noremap <M-4> :b4<CR>:<BS>
  noremap <M-5> :b5<CR>:<BS>
  noremap <M-6> :b6<CR>:<BS>
  noremap <M-7> :b7<CR>:<BS>
  noremap <M-8> :b8<CR>:<BS>
  noremap <M-9> :b9<CR>:<BS>
  noremap <M-0> :b10<CR>:<BS>
  inoremap <M-1> :b1<CR>:<BS>
  inoremap <M-2> :b2<CR>:<BS>
  inoremap <M-3> :b3<CR>:<BS>
  inoremap <M-4> :b4<CR>:<BS>
  inoremap <M-5> :b5<CR>:<BS>
  inoremap <M-6> :b6<CR>:<BS>
  inoremap <M-7> :b7<CR>:<BS>
  inoremap <M-8> :b8<CR>:<BS>
  inoremap <M-9> :b9<CR>:<BS>
  inoremap <M-0> :b10<CR>:<BS>
else
  if has("win32")
    noremap ± :b1<CR>:<BS>
    noremap ² :b2<CR>:<BS>
    noremap ³ :b3<CR>:<BS>
    noremap Ž :b4<CR>:<BS>
    noremap µ :b5<CR>:<BS>
    noremap ¶ :b6<CR>:<BS>
    noremap · :b7<CR>:<BS>
    noremap ž :b8<CR>:<BS>
    inoremap ± :b1<CR>:<BS>
    inoremap ² :b2<CR>:<BS>
    inoremap ³ :b3<CR>:<BS>
    inoremap Ž :b4<CR>:<BS>
    inoremap µ :b5<CR>:<BS>
    inoremap ¶ :b6<CR>:<BS>
    inoremap · :b7<CR>:<BS>
    inoremap ž :b8<CR>:<BS>
  else
    noremap 1 :b1<CR>:<BS>
    noremap 2 :b2<CR>:<BS>
    noremap 3 :b3<CR>:<BS>
    noremap 4 :b4<CR>:<BS>
    noremap 5 :b5<CR>:<BS>
    noremap 6 :b6<CR>:<BS>
    noremap 7 :b7<CR>:<BS>
    noremap 8 :b8<CR>:<BS>
    noremap 9 :b9<CR>:<BS>
    noremap 0 :b10<CR>:<BS>
    inoremap 1 :b1<CR>:<BS>
    inoremap 2 :b2<CR>:<BS>
    inoremap 3 :b3<CR>:<BS>
    inoremap 4 :b4<CR>:<BS>
    inoremap 5 :b5<CR>:<BS>
    inoremap 6 :b6<CR>:<BS>
    inoremap 7 :b7<CR>:<BS>
    inoremap 8 :b8<CR>:<BS>
    inoremap 9 :b9<CR>:<BS>
    inoremap 0 :b10<CR>:<BS>
  endif
endif
" }}}
" }}}

" Fonts {{{
if has("win32")
  set guifont=Courier\ New:h10,Courier,Lucida\ Console,Letter\ Gothic,
   \Arial\ Alternative,Bitstream\ Vera\ Sans\ Mono,OCR\ A\ Extended
else
  set guifont=Bitstream\ Vera\ Sans\ Mono\ 9,
   \Courier\ New\ 10,Courier\ 10
endif
" }}}

" Indentation {{{
" BUG/Undocumented, Confusing Behavior:
"   When using smarttab with sts != 0, <tab> when not at beginning of
"   line works correctly, obeying sts, however <BS> obeys sw.  The docs
"   claim that smarttab only affects <tab> and <BS> at beginning of line.
"
"   Seen with:
"     Vim version 6.2 on a RedHat Enterprise Linux release 3 machine.
"     Vim version 6.3 on an Ubuntu Breezy machine.
"     Vim version 7.0188 on a Debian Unstable machine.
"
" NOTE: This bug was fixed in VIM 7 snapshot as of 02/02/06 or so.
"
" For now, keep smarttab disabled to avoid confusion.
set nosmarttab

" NOTE: The ctab plugin is incredibly useful, but behaves inconsistently
"       as compared to stock vim behavior (that is, its <tab>/<BS> key
"       behavior when not at start-of-line obeys 'sw' when it should be
"       obeying sts/ts).  Fix it.

"set expandtab      "Disable insertion of tabs as compression / indentation
set tabstop=4       "How many spaces a tab in the file counts for, and when
                    "not using sts, how many spaces the tab key counts for.
set shiftwidth=4    "Indentation width (affects indent plugins, indent based folding, etc, and when smarttab is on, is used instead of ts/sts for the indentation at beginning of line)
set softtabstop=0   "Number of spaces that the tab key counts for when editing
                    "Only really useful if different from ts, or if using et.

" Common indentation setups
"   No hard tabs, 2 space indent: set sw=2 sts=2 et
"   No hard tabs, 4 space indent: set sw=4 sts=4 et
"   All hard tabs, 8 space tabstops: set ts=8 sw=8 sts=0 noet
"   Hard tabs for indentation, 4 space tabstops: set ts=4 sw=4 sts=0 noet
"   Horrendous, 4 space indent, 8 space tabstops, hard tabs:
"      set ts=8 sw=4 sts=4 noet
" }}}

" Settings {{{
filetype plugin indent on

set secure
set nocompatible
set nodigraph
set modeline
set modelines=5
"set scroll=1
set scrolloff=2
set nohidden
set nohlsearch
"set path=.
set suffixes+=.lo,.o,.moc,.la,.closure
set title
set titleold=""
set ttyfast
set ttybuiltin
set novisualbell
set noerrorbells
set foldcolumn=0
set foldminlines=3
set foldmethod=syntax
set foldlevel=5
set vb t_vb=
set whichwrap=<,>,h,l,[,]
set ruler
set showcmd
set textwidth=0
set nobackup
set history=50
set viminfo='20,\"50
set backspace=indent,eol,start
set noshowmatch
set ignorecase
set noincsearch
set noautowrite
set autoindent
set cinoptions=>s,e0,n0,f0,{0,}0,^0,:s,=s,l0,gs,hs,ps,ts,+s,c3,C0,(0,us,\U0,w0,m0,j0,)20,*30
set cinkeys=0{,0},0),:,0#,!^F,o,O,e

" Usage of the mouse
set mouse=a
if has("unix") &&
   \ has("mouse") &&
   \ ! has("gui_running")
  if &term == "xterm"
    set ttymouse=xterm2
  else
    set ttymouse=xterm
  endif
endif

" Line numbering
if v:version >= 700
  set numberwidth=2
  set number
endif

if has("unix")
   set fileformats=unix,dos,mac  " Allow editing of all types of files
else
   set fileformats=dos,unix,mac
endif

" Status Line {{{
set laststatus=2
set statusline=
set statusline+=%-3.3n\                      " buffer number
set statusline+=%f\                          " filename
set statusline+=%h%m%r%w                     " status flags

function StatusLine_Tlist_Info()
  if exists('g:loaded_taglist') &&
    \ g:loaded_taglist == 'available'
    return Tlist_Get_Tagname_By_Line()
  else
    return ''
  endif
endfunction
" let Tlist_Process_File_Always = 1
set statusline+=%((%{StatusLine_Tlist_Info()})\ %) " tag name

set statusline+=\[%{strlen(&ft)?&ft:'none'}] " file type
set statusline+=%=                           " right align remainder
" set statusline+=0x%-8B                       " character value
set statusline+=%-14(%l,%c%V%)               " line, character
set statusline+=%<%P                         " file position
" }}}

" Encoding {{{
if has("multi_byte")
  if (&encoding == "") || has("gui_running")
    set encoding=utf-8
  endif
  setglobal fileencoding=utf-8
  let &termencoding = &encoding
"  set fileencodings=ucs-bom,utf-8,iso-8859-15
  set fileencodings=utf-8,iso-8859-15

"  set bomb
endif
" }}}

if (&termencoding == "utf-8") || has("gui_running")
  if v:version >= 700
    set list listchars=tab:»·,trail:·,extends:…,nbsp:‗
  else
    set list listchars=tab:»·,trail:·,extends:…
  endif
else
  if v:version >= 700
    set list listchars=tab:>-,trail:.,extends:>,nbsp:_
  else
    set list listchars=tab:>-,trail:.,extends:>
  endif
endif

function! s:CHANGE_CURR_DIR()
    let _dir = expand("%:p:h")
    if _dir !~ '^/tmp'
      exec "cd " . _dir
    endif
    unlet _dir
endfunction

autocmd BufEnter * call s:CHANGE_CURR_DIR()
" }}}

" Colors {{{
" Make sure the gui is initialized before setting up syntax and colors
if has("gui_running")
  gui
endif
syntax enable

if &t_Co > 2 || has("gui_running")
  "colors darkblack2
  colors darkblue3

  "Colors both trailing    
  "whitespace, and spaces  	before tabs
  hi RedundantWhitespace ctermbg=red guibg=red
  match RedundantWhitespace /\s\+$\| \+\ze\t/

  " .signature files generally start with '-- '.  Adjust the
  " RedundantWhitespace match when opening a .signature to not
  " highlight that particular trailing space in red.
  if has("autocmd")
    au BufReadPost .signature match RedundantWhitespace /\(^--\)\@<!\s\+$/
    au BufReadPost mutt-* match RedundantWhitespace /\(^--\)\@<!\s\+$/
  endif

  " When using gnome-terminal, vim's color test script shows
  " dark gray on white correctly, but white on dark gray appears
  " as white on black.  This seemingly results in the cursor
  " vanishing when over a dark gray SpecialKey.  Dark blue works.
  let colorterm = $COLORTERM
  if colorterm == "gnome-terminal"
    hi SpecialKey ctermfg=darkblue guifg=darkblue
  else
    hi SpecialKey ctermfg=darkgray guifg=darkgray
  endif
endif
" }}}

" Autocommands {{{
if has("autocmd")
  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  au BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  " Default to omni completion using the syntax highlighting files
  if v:version >= 700
    au BufReadPost *
      \ if (&ofu == "") |
      \   set ofu=syntaxcomplete#Complete |
      \ endif
  endif

  " Default textwidth is 0 for known filetypes
  " For unknown types, text, and mutt mails, it's 78.
  set tw=78
  au FileType * set tw=0
  au FileType text set tw=78
  au BufReadPost mutt-* set nocindent noautoindent tw=78

  " Sane settings for keywordprg
  au FileType vim set keywordprg=:help
  au FileType python set keywordprg=pydoc
  au FileType perl set keywordprg=perldoc\ -f

  " Disable moving to beginning of line when hitting ':',
  " as it behaves oddly when calling static methods in c++.
  au FileType cpp set cinkeys=0{,0},0),0#,!^F,o,O,e
endif " has("autocmd")
" }}}

" Plugin options {{{
"let g:xml_syntax_folding = 1
let g:NERD_shut_up=1
let g:NERD_comment_whole_lines_in_v_mode = 1
let g:NERD_left_align_regexp = ".*"
let g:NERD_right_align_regexp = ".*"
let g:NERD_space_delim_filetype_regexp = ".*"
let g:doxygen_enhanced_color = 1
let g:html_use_css = 1
let g:use_xhtml = 1
let g:perl_extended_vars = 1
let g:HL_HiCurLine = "Function"
" let g:perl_fold = 1
" let g:sh_fold_enabled= 1
" let g:sh_minlines = 500
" let g:xml_syntax_folding = 1
" }}}

" Explorer/Tags/Windows options {{{
let g:Tlist_Exit_OnlyWindow = 1
let g:Tlist_Show_Menu = 1


let s:using_winmanager = 0
if exists('s:using_winmanager') &&
      \ s:using_winmanager == 1
  let g:Tlist_Close_On_Select = 0
  " let g:winManagerWindowLayout = "FileExplorer,TagsExplorer|BufExplorer,TodoList"
  let g:winManagerWindowLayout = "FileExplorer,TagList|BufExplorer"
  let g:defaultExplorer = 0

  " Disable use of tabbar / minibufexpl
  " let Tb_loaded = 1
  let g:loaded_minibufexplorer = 1

  map <c-w><c-f> :FirstExplorerWindow<CR>
  map <c-w><c-b> :BottomExplorerWindow<CR>
  map <c-w><c-t> :WMToggle<CR>
else
  let g:Tlist_Close_On_Select = 1
  let g:loaded_winmanager = 1
  let g:loaded_winfileexplorer = 1
  let g:loaded_bufexplorer = 1
  nnoremap <silent> <F8> :Tlist<CR>
endif
" }}}
