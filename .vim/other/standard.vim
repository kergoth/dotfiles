" Michael's standard settings
" Author: Michael Geddes
" Version: 0.1

" Smart tabbing / autoindenting
set undolevels=100
set nocompatible
set autoindent
set smarttab
" Allow backspace to back over lines
set backspace=2
set exrc
set shiftwidth=4
set tabstop=4
set cino=t0
" I like it writing automatically on swapping
set autowrite
set noshowcmd
if exists('&selection')
  set selection=exclusive
endif

if has("gui_running")
    " set the font to use
    set guifont=Courier_New:h10
    " Hide the mouse pointer while typing
    set mousehide
endif


"Special error formats that handles borland make, greps
"Error formats :
"   line = line number
"   file = file name
"   etype = error type ( a single character )
"   enumber = error number
"   column = column number
"   message = error message 
"   _ = space

"   file(line)_:_etype [^0-9] enumber:_message
"   [^"] "file" [^0-9] line:_message
"   file(line)_:_message
"   [^ ]_file_line:_message
"   file:line:message
"   etype [^ ]_file_line:_message
"   etype [^:]:__file(line,column):message    = Borland ??
"   file:line:message
"   etype[^_]file_line_column:_message
set efm=%*[^\ ]\ %t%n\ %f\ %l:\ %m,%\\s%#%f(%l)\ :\ %t%*[^0-9]%n:\ %m,%*[^\"]\"%f\"%*[^0-9]%l:\ %m,%\\s%#%f(%l)\ :\ %m,%*[^\ ]\ %f\ %l:\ %m,%f:%l:%m,%t%*[^\ ]\ %f\ %l:\ %m,%t%*[^:]:\ \ %f(%l\\,%c):%m,%f:%l:%m,%t%*[^\ ]\ %f\ %l\ %c:\ %m 
" This changes the status bar highlight slightly from the default
" " set highlight=8b,db,es,mb,Mn,nu,rs,ss,tb,vr,ws

"I like things quiet
set visualbell
" Give some room for errors
set cmdheight=2
" always show a status line
au VimEnter * set laststatus=2
set ruler
" Use a viminfo file
set viminfo='20,\"50
"set path=.,d:\wave,d:\wave\include,d:\wave\fdt
set textwidth=80        " always limit the width of text to 80
set backup              " keep a backup file
set backupext=.bak
" Like having history
set history=100

" Map Y do be analog of D
map Y y$
" Toggle paste 
map zp :set paste! paste?<CR>

" From the vimrc of 'Peppe'

  " So I can get to ,
  noremap g, ,
  " Go to old line + column
  noremap gf gf`"
  noremap <C-^> <C-^>`"


" Switch off search pattern highlighting.
set nohlsearch
"Toggle search pattern hilighting and display the value
if v:version >=600
  map <f7> :nohlsearch<CR>
else
  map <f7> :set hlsearch! hlsearch?<CR>
endif
imap <f7> <C-O><f7> 

"Ctags mapping for <alt n> and <alt p>
map <M-n> :cn<cr>z.:cc<CR>
map <M-p> :cp<cr>z.:cc<CR>
set shellpipe=2>&1\|tee
"set shellpipe=\|grep\ -v\ NOTE:\|tee

" Set nice colors
" background for normal text is light grey
" Text below the last line is darker grey
" Cursor is green
" Constants are not underlined but have a slightly lighter background
"  highlight Normal guibg=grey95
highlight Cursor guibg=Red guifg=NONE
highlight Visual guifg=Sys_HighlightText guibg=Sys_Highlight gui=NONE
"  highlight NonText guibg=grey90
"  highlight Constant gui=NONE guibg=grey95
"  highlight Special gui=NONE guibg=grey95

if has("gui_running")
"if &columns < 90 && &lines < 32
"   win 90 32 
    au GUIEnter * win 90 32 
"  endif
  " Make external commands work through a pipe instead of a pseudo-tty
  set noguipty
endif

" Map control-cr to goto new line without comment leader
imap <C-CR> <ESC>o

" Look at syntax attribute
nmap <F4> :echo synIDattr(synID(line("."), col("."), 1), "name")<CR>
nmap <S-F4> :echo synIDattr(synID(line("."), col("."), 0), "name")<CR>
" delete the swap file
nmap \\. :echo strpart("Error  Deleted",7*(0==delete(expand("%:p:h")."/.".expand("%:t").".swp")),7)<cr>

" delete prev word
imap <C-BS> <c-w>

  set joinspaces 

" Today
if !exists('usersign') 
let usersign=$username
endif
imap <F2> <C-R>=strftime("%d%b%Y")." ".usersign.":"<CR>
if has("menu")
  imenu 35.60 &Insert.&Date<tab>F2      <c-r>=strftime("%d%b%Y")." ".usersign.":"<CR>
  menu  35.60 &Insert.&Date<tab>F2      "=strftime("%d%b%Y")." ".usersign.":"<CR>p
  imenu  35.60 &Insert.Date\ and\ &Username     <c-r>=strftime("%d%b%Y")<CR>
  menu  35.60 &Insert.Date\ and\ &Username      "=strftime("%d%b%Y")<CR>p
endif

set listchars=eol:¶,tab:›…,trail:_
" Enable 'wild menus'
set wildmenu
set showfulltag
set display+=lastline
set printoptions=syntax:y,wrap:y

" Switch on syntax highlighting.
syntax on

