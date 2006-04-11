" vim: set et sw=2 sts=2 fdm=marker fdl=0:
"
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
" GetLatestVimScripts:
"   :GLVS - Checks to see if any vim scripts have new versions available,
"           and if so, downloads them (and installs in some cases).
" VIM core:
"   K - look up current word via 'man' (by default)
"   ^X ^O - Omni completion
"   * - search for teh current word in the document
"   % - jump between begin/end of blocks
"   ggqgG - reformat entire file
"   gg=G - reindent entire file
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

" Functions {{{
let colorterm = $COLORTERM

function! <SID>PropogateNumberState()
  windo
        \ if (winwidth(0) >= 80) && (s:numdisabled == 0) |
        \   set number |
        \ else |
        \   set nonumber |
        \ endif
endfunction

function! SetNumberingState(s)
  if (a:s == 0) || (a:s == 1)
    let l:newstate=a:s
  else
    let l:newstate=s:numdisabled==0?1:0
  endif

  let s:numdisabled=l:newstate
  call <SID>PropogateNumberState()
endfunction

function! <SID>Min(a, b)
  if a:a <= a:b
    return a:a
  else
    return a:b
  endif
endfunction

function! <SID>Max(a, b)
  if a:a >= a:b
    return a:a
  else
    return a:b
  endif
endfunction
" }}}

" Keymaps {{{
map ,is :!ispell %<C-M>          " ISpell !

map ,del :g/^\s*$/d<C-M>         " Delete Empty Lines
map ,ddql :%s/^>\s*>.*//g<C-M>   " Delete Double Quoted Lines
map ,ddr :s/\.\+\s*/. /g<C-M>    " Delete Dot Runs
map ,dsr :s/\s\s\+/ /g<C-M>      " Delete Space Runs
map ,dtw :%s/\s\+$//g<C-M>       " Delete Trailing Whitespace

nmap <leader>sh :runtime vimsh/vimsh.vim<C-M>
nmap <leader>a :A<CR>            " Switch between .c/cpp and .h (a.vim)
nmap <leader>n :call SetNumberingState(-1)<CR>  " Toggle Line Numbering

" Reformat paragraph
noremap <Leader>gp gqap

" Reformat everything
noremap <Leader>gq gggqG

" Select everything
noremap <Leader>gg ggVG

" Make <space> in normal mode go down a page rather than left a
" character
noremap <space> <C-f>

" Mappings to edit/reload the .vimrc
if has("win32")
  nmap ,s :source $HOME/_vimrc<CR>
  nmap <silent> ,v :e $HOME/_vimrc<CR>
else
  nmap ,s :source $HOME/.vimrc<CR>
  nmap <silent> ,v :e $HOME/.vimrc<CR>
endif

" quickfix things
nmap <Leader>cwc :cclose<CR>
nmap <Leader>cwo :botright copen 5<CR><C-w>p
nmap <Leader>ccn :cnext<CR>

" show the highlighting group(s) for the text under the cursor
nmap <Leader>i :echo "hi<" .
      \ synIDattr(synID(line("."),col("."),1),"name") . '> trans<' .
      \ synIDattr(synID(line("."),col("."),0),"name") ."> lo<" .
      \ synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") .
      \ ">"<CR>

" scrollwheel = intelligent # of lines to scroll based on window height
if has("autocmd")
  au BufWinEnter * exec "map <buffer> <MouseDown> " . <SID>Max(winheight("%")/8, 1) . ""
  au BufWinEnter * exec "map <buffer> <MouseUp> " . <SID>Max(winheight("%")/8, 1) . ""
endif

map <MouseDown> 3
map <MouseUp> 3

" meta (alt)+scrollwheel = scroll one line at a time
map <M-MouseDown> 
map <M-MouseUp> 

" ctrl+scrollwheel = scroll half a page
map <C-MouseDown> 
map <C-MouseUp> 

" shift+scrollwheel = unmapped
"unmap <S-MouseDown>
"unmap <S-MouseUp>

" Execute an appropriate interpeter for the current file
" If there is no #! line at the top of the file, it will
" fall back to g:interp_<filetype>.
let g:interp_lua="/usr/bin/env lua"
let g:interp_python="/usr/bin/env python"
let g:interp_make="/usr/bin/env make"
let g:interp_perl="/usr/bin/env perl"
let g:interp_m4="/usr/bin/env m4"
let g:interp_sh="/bin/sh"
function! RunInterp()
  let l:interp = ""
  let line = getline(1)

  if line =~ "^#\!"
    let l:interp = strpart(line, 2)
  else
    if exists("g:interp_" . &filetype)
      let l:interp = g:interp_{&filetype}
    endif
  endif
  if l:interp != ""
    exe "!" . l:interp . " %"
  endif
endfunction
nnoremap <silent> <F9> :call RunInterp()<CR>

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
set autoindent
set smartindent

set cinoptions=>s,e0,n0,f0,{0,}0,^0,:s,=s,l0,gs,hs,ps,ts,+s,c3,C0,(0,us,\U0,w0,m0,j0,)20,*30
set cinkeys=0{,0},0),:,0#,!^F,o,O,e

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

" Enable modelines for secure versions of vim
if v:version >= 604
  set modeline
  set modelines=5
else
  set nomodeline
endif

" Show 2 rows/cols of context when scrolling
set scrolloff=2
set sidescrolloff=2

set nohidden
"set path=.

" Allow setting window title for screen
if &term == "screen"
  set t_ts=k
  set t_fs=\
endif

" Nice window title
set title
if has('title') && (has('gui_running') || &title)
  set titlestring=
  set titlestring+=%f                    " file name
  set titlestring+=%(\ %h%m%r%w%)        " flags
  set titlestring+=\ -\ %{v:progname}    " program name
endif
set titleold=""

set ttyfast
set ttybuiltin
set lazyredraw

" No annoying beeps
set novisualbell
set noerrorbells
set vb t_vb=

" Default folding settings
if has("folding")
  set foldenable
  set foldcolumn=0
  set foldminlines=3
  set foldmethod=indent
  set foldlevel=5
endif

" Nifty completion menu
set wildmenu
set wildignore+=*.o,*~
set suffixes+=.in,.a,.lo,.o,.moc,.la,.closure

set whichwrap=<,>,h,l,[,]
set ruler
set showcmd
set textwidth=0
set nobackup
set isk+=_,$,@,%,#,-
set shortmess=atItToO

set history=500
set viminfo='1000,f1,:1000,/1000

set backspace=indent,eol,start
set noshowmatch
set formatoptions=crqtn

" Case insensitivity
set ignorecase
set infercase

" No incremental searches or search highlighting
set noincsearch
set nohlsearch

" Syntax for printing
set popt+=syntax:y

" Don't automatically write buffers on switch
set noautowrite

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
  set number
endif

" Allow editing of all types of files
if has("unix")
  set fileformats=unix,dos,mac
else
  set fileformats=dos,unix,mac
endif

if has("gui_running")
  " Hide the mouse cursor while typing
  set mh

  "set go=Acgtm
  set go=Acg
endif

" Wrap at column 78
set tw=78

" Filter expected errors from make
"if has("eval") && v:version >= 700
"    let &makeprg='nice make $* 2>&1 \| sed -u -n '
"    let &makeprg.='-e "/should fail/s/:\([0-9]\)/∶\1/g" '
"    let &makeprg.='-e "s/\([0-9]\{2\}\):\([0-9]\{2\}\):\([0-9]\{2\}\)/\1∶\2∶\3/g" '
"    let &makeprg.='-e "/^/p" '
"endif

" Status Line {{{
set laststatus=2
set statusline=
set statusline+=%-3.3n\                      " buffer number
set statusline+=%f\                          " filename
set statusline+=%h%m%r%w                     " status flags

function! StatusLine_Tlist_Info()
  if exists('g:loaded_taglist') &&
        \ g:loaded_taglist == 'available'
    return Tlist_Get_Tagname_By_Line()
  else
    return ''
  endif
endfunction
" let Tlist_Process_File_Always = 1
set statusline+=%((%{StatusLine_Tlist_Info()})\ %) " tag name

" set statusline+=\[%{strlen(&ft)?&ft:'none'}] " file type
set statusline+=%(\[%{&ft}]%)               " file type
set statusline+=%=                          " right align remainder
" set statusline+=0x%-8B                    " character value
set statusline+=%-14(%l,%c%V%)              " line, character
set statusline+=%<%P                        " file position

" special statusbar for special windows
" NOTE: only vim7+ supports a statusline local to a window
if has("autocmd") && v:version >= 700
  au FileType qf
        \ if &buftype == "quickfix" |
        \     setlocal statusline=%2*%-3.3n%0* |
        \     setlocal statusline+=\ \[Compiler\ Messages\] |
        \     setlocal statusline+=%=%2*\ %<%P |
        \ endif

  function! <SID>FixWindowTitles()
    if "-MiniBufExplorer-" == bufname("%")
      setlocal statusline=%2*%-3.3n%0*
      setlocal statusline+=\[Buffers\]
      setlocal statusline+=%=%2*\ %<%P
    endif

    if "__Tag_List__" == bufname("%")
      setlocal statusline=\[Tags\]
      setlocal statusline+=%=
      setlocal statusline+=%l
    endif
  endfunction

  au BufWinEnter *
        \ let oldwinnr=winnr() |
        \ windo call <SID>FixWindowTitles() |
        \ exec oldwinnr . " wincmd w"
endif
" }}}

" Encoding {{{
let &termencoding = &encoding
if has("multi_byte")
  set encoding=utf-8
  set fileencodings=utf-8,iso-8859-15
  " set fileencodings=ucs-bom,utf-8,iso-8859-15
  " set bomb
endif
" }}}

" Show nonprintable characters like hard tabs
"   NOTE: No longer showing trailing spaces this way, as those
"   are being highlighted in red, along with spaces before tabs.
set list

if (&termencoding == "utf-8") || has("gui_running")
  set listchars=tab:»·,extends:…

  if v:version >= 700
    set listchars+=nbsp:‗
  endif

  if (! has("gui_running")) && (&t_Co < 3)
    set listchars+=trail:·
  endif
else
  set listchars=tab:>-,extends:>

  if v:version >= 700
    set listchars+=nbsp:_
  endif

  if (! has("gui_running")) && (&t_Co < 3)
    set listchars+=trail:.
  endif
endif
" }}}

" Colors {{{
" Make sure the gui is initialized before setting up syntax and colors
if has("gui_running")
  gui
endif

if has("syntax")
  syntax on
endif

if colorterm == "gnome-terminal"
  set t_Co=16
elseif (colorterm == "rxvt-xpm") && (&term == "rxvt")
  "set colors correctly for mrxvt
  set t_Co=256
elseif colorterm == "putty"
  set t_Co=256
endif

if &t_Co > 2 || has("gui_running")
  "colors darkblack2
  "colors inkpot
  "colors darkblue3
  "let xterm16_colormap = 'soft'
  "let xterm16_brightness = '123'
  "colo xterm16

  if &t_Co >= 88 || has("gui_running")
    colors baycomb
  else
    colors desert256
  endif

  "Colors both trailing    
  "whitespace, and spaces  	before tabs
  hi RedundantWhitespace ctermbg=red guibg=red
  match RedundantWhitespace /\s\+$\| \+\ze\t/

  " Highlight vim modelines
  hi def link VimModelineLine comment
  hi def link VimModeline     special

  if has("syntax") && has("autocmd")
    autocmd Syntax *
          \ syn match VimModelineLine /^.\{-1,}vim:[^:]\{-1,}:.*/ contains=VimModeline |
          \ syn match VimModeline contained /vim:[^:]\{-1,}:/
  endif

  " Email signatures generally start with '-- '.  Adjust the
  " RedundantWhitespace match for the 'mail' filetype to not
  " highlight that particular trailing space in red.
  if has("autocmd")
    au FileType mail match RedundantWhitespace /\(^--\)\@<!\s\+$/
  endif

  " When using gnome-terminal, vim's color test script shows
  " dark gray on white correctly, but white on dark gray appears
  " as white on black.  This seemingly results in the cursor
  " vanishing when over a dark gray SpecialKey.  Dark blue works.
  if colorterm == "gnome-terminal"
    hi SpecialKey ctermfg=darkblue guifg=darkblue
  else
    hi SpecialKey ctermfg=darkgray guifg=darkgray
  endif
endif
" }}}

" Autocommands {{{
if has("autocmd")
  " Always do a full syntax refresh
  autocmd BufEnter * syntax sync fromstart

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  au BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif

  " m4 matchit support
  autocmd FileType m4 :let b:match_words="(:),`:',[:],{:}"

  " Default to omni completion using the syntax highlighting files
  if v:version >= 700
    au BufReadPost *
          \ if (&ofu == "") |
          \   setlocal ofu=syntaxcomplete#Complete |
          \ endif
  endif

  au FileType * if &fo =~ 't' | let &l:fo = substitute(&fo, '(.*)t(.*)', '\1\2', '') | endif
  au FileType text if &fo !~ 't' | let &l:fo = substitute(&fo, '$', 't', '') | endif
  au FileType mail if &fo !~ 't' | let &l:fo = substitute(&fo, '$', 't', '') | setlocal nocindent noautoindent | endif

  " Sane settings for keywordprg
  au FileType vim setlocal keywordprg=:help
  au FileType python setlocal keywordprg=pydoc
  au FileType perl setlocal keywordprg=perldoc\ -f

  " Disable moving to beginning of line when hitting ':',
  " as it behaves oddly when calling static methods in c++.
  au FileType cpp setlocal cinkeys-=:

  try
    " if we have a vim which supports QuickFixCmdPost (vim7),
    " give us an error window after running make, grep etc, but
    " only if results are available.
    autocmd QuickFixCmdPost * botright cwindow 5

    autocmd QuickFixCmdPre make
          \ let g:make_start_time=localtime()

    autocmd QuickFixCmdPost make
          \ let g:make_total_time=localtime() - g:make_start_time |
          \ echo printf("Time taken: %dm%2.2ds", g:make_total_time / 60,
          \     g:make_total_time % 60)
  catch
  endtry

  " Close out the quickfix window if it's the only open window
  function! <SID>QuickFixClose()
    " if the window is quickfix go on
    if &buftype=="quickfix"
      " if this window is last on screen quit without warning
      if winbufnr(2) == -1
        quit!
      endif
    endif
  endfunction
  au BufEnter * call <SID>QuickFixClose()

  " Change the current directory to the location of the
  " file being edited.
  autocmd BufEnter * :lcd %:p:h

  " Special less.sh and man modes {{{
  function! <SID>check_pager_mode()
    if exists("g:loaded_less") && g:loaded_less
      " we're in vimpager / less.sh / man mode
      set laststatus=0
      set ruler
      set foldmethod=manual
      set foldlevel=99
      set nolist
    endif
  endfunction
  autocmd VimEnter * :call <SID>check_pager_mode()

  " Intelligent enable/disable of the line number display
  au VimEnter * let s:numdisabled = &number==0?1:0
  au VimEnter,WinEnter,WinLeave * :call <SID>PropogateNumberState()
  " }}}
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
let g:HL_HiCurLine = "HL_HiCurLine"
" }}}

" Explorer/Tags/Windows options {{{
let g:Tlist_Exit_OnlyWindow = 1
let g:Tlist_Show_Menu = 1
let g:Tlist_Enable_Fold_Column = 0
let g:Tlist_WinWidth = 28
let g:Tlist_Compact_Format = 1
let g:Tlist_File_Fold_Auto_Close = 1
let g:Tlist_Use_Right_Window = 1
let g:Tlist_Sort_Type = "name"
let g:Tlist_Inc_Winwidth = 0

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
