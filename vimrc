" Don't try to be backwards compatible
set nocompatible

" Load file-type specific plugins and indent definitions
filetype plugin indent on

" Don't manually sync the swap to disk on unix, since that's periodically done
" for us, so the risk of losing data is relatively small, and this should
" improve performance slightly.
if has('unix')
  set swapsync=
endif

" Paths for backups, swap files, and undo files
set backupdir=~/.vim/tmp
set directory=~/.vim/tmp
if has('persistent_undo')
  set undodir=~/.vim/tmp
endif

" Write backup files
set backup

" Rename the file to the backup when possible.
set backupcopy=auto

" Enable mouse support
if has('mouse')
  set mouse=a
  if has('unix') && ! has('gui_running')
    set ttymouse=xterm2
  endif
endif

if !has('win32')
  let $TEMP = '/tmp'
endif

" Do this unconditionally, as the 'mswin' behavior is not what I prefer, even
" on win32.
behave xterm

" Change the current directory to the location of the
" file being edited.
com! -nargs=0 -complete=command   Bcd lcd %:p:h
" Set the compiler to the filetype by default
au FileType * try | exe 'compiler ' . &filetype | catch | endtry

try
  " if we have a Vim which supports QuickFixCmdPost (Vim7),
  " give us an error window after running make, grep etc, but
  " only if results are available.
  au QuickFixCmdPost * botright cwindow 5
catch
endtry

" Close out the quickfix window if it's the only open window
fun! <SID>QuickFixClose()
  if &buftype == 'quickfix'
    " if this window is last on screen quit without warning
    if winbufnr(2) == -1
      quit!
    endif
  endif
endfun
au BufEnter * call <SID>QuickFixClose()
" Don't use old weak encryption for Vim 7.3
if has('cryptv')
  try
    set cryptmethod=blowfish
  catch
  endtry
endif
set diffopt+=iwhite
syntax on

" Line numbering
if v:version >= 700
  set number
endif

" Assume a fast terminal connect
set ttyfast

" Set a sane default level for concealed items
if has('conceal')
  set conceallevel=2
endif

" Allow setting window title for screen
if &term =~ '^screen'
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
set titleold=

" Window resize behavior when splitting
set noequalalways

set splitright
set splitbelow

" Show normal-mode commands as you type
set showcmd

" Show cursor and file position
set ruler

" Display as much of the last line in a window as possible
set display+=lastline

" Show whitespace as unicode chars
if (&termencoding == 'utf-8') || has('gui_running')
  set showbreak=↪

  set listchars=tab:»·,extends:…,precedes:…,eol:¬

  if v:version >= 700
    set listchars+=nbsp:‗
  endif

  if (! has('gui_running')) && (&t_Co < 3)
    set listchars+=trail:·
  endif
else
  let &showbreak = '> '

  set listchars=tab:>-,extends:>

  if v:version >= 700
    set listchars+=nbsp:_
  endif

  if (! has('gui_running')) && (&t_Co < 3)
    set listchars+=trail:.
  endif
endif

if &term == 'xterm-256color'
  set t_Co=256
endif

" Make sure the gui is initialized before setting up colors
if has('gui_running')
  gui
endif

set background=dark
colorscheme baycomb
" Backspace over anything
set backspace=indent,eol,start

" Allow virtual editing in visual block mode
set virtualedit+=block

" Don't insert two spaces after a '.' with the join command
set nojoinspaces

" Disable entering of digraphs in Insert mode
set nodigraph

" Many levels of undo
set undolevels=500

" Avoid storing persistent undo information for temporary files
if has('persistent_undo')
  au BufReadPre .netrwhist set noundofile
  au BufReadPre $TEMP/* set noundofile
  au BufReadPre .git/COMMIT_EDITMSG set noundofile
endif

" Longer commandline and search history
if has('cmdline_hist')
  set history=500
endif

" Viminfo file behavior
if has('viminfo')
  " f1  store file marks
  " '   # of previously edited files to remember marks for
  " :   # of lines of command history
  " /   # of lines of search pattern history
  " <   max # of lines for each register to be saved
  " s   max # of Kb for each register to be saved
  " h   don't restore hlsearch behavior
  if !exists('$VIMINFO')
    let $VIMINFO = "~/.vim/viminfo"
  endif
  let &viminfo = "f1,'1000,:1000,/1000,<1000,s100,h,r" . $TEMP . ",n" . $VIMINFO
endif

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
" Also don't do it when the mark is in the first line, that is the default
" position when opening a file.
function! <SID>RestorePosition()
  if &ft == 'gitcommit'
    return
  endif

  if line("'\"") > 1 && line("'\"") <= line("$")
    exe "normal! g`\""
  endif
endfunction

autocmd BufReadPost * call <SID>RestorePosition()

" Only save the current tab page
set sessionoptions-=tabpages

" Don't save help windows
set sessionoptions-=help

" When selecting with the mouse, copy to clipboard on release.
vnoremap <LeftRelease> '+y<LeftRelease>gv
vnoremap <RightRelease> '+y<RightRelease>gv

" Reload file with the correct encoding if fenc was set in the modeline
au BufReadPost * let b:reloadcheck = 1
au BufWinEnter *
      \ if exists('b:reloadcheck') |
      \   if &mod != 0 && &fenc != '' |
      \     exe 'e! ++enc=' . &fenc |
      \   endif |
      \   unlet b:reloadcheck |
      \ endif

" Make operations like yank, which normally use the unnamed register, use the
" * register instead (yanks go to the system clipboard).
set clipboard=autoselect,unnamed
if has('gui_running') && has('unix')
  set clipboard+=exclude:cons\|linux
end

" Ignore binary files matched with grep by default
set grepformat=%f:%l:%m,%f:%l%m,%f\ \ %l%m,%-OBinary\ file%.%#

" Use ack if available
if executable('ack')
  set grepprg=ack\ -H\ --nocolor\ --nogroup\ --column\ $*\ /dev/null
  set grepformat=%f:%l:%c:%m
endif

" Prompt for confirmation where appropriate, rather than failing
set confirm

set guioptions=Acgae

" Default window size
" Behavior of full screen mode
try
  set fuoptions=maxvert,maxhorz
catch
endtry

fun! SetFont(font, size)
  if has('macunix') && has('gui')
    let &guifont = a:font . ':h' . a:size
  elseif has('gui_win32')
    let &guifont = a:font . ':h' . a:size . 'cANSI'
  else
    let &guifont = a:font . ' ' . a:size
  endif
endfun

call SetFont('Inconsolata', '13')

augroup GuiSettings
  au!
  " Default window size
  au VimEnter * set lines=50 columns=112
augroup END

" Indent by shiftwidth at beginning of line rather than ts/sts
set smarttab

" Disable insertion of tabs as compression / indentation
set expandtab

" How many spaces a hard tab in the file is shown as, and how many
" spaces are replaced with one hard tab when using sts != ts and noet.
set tabstop=8

" Indentation width (affects indentation plugins, indent based
" folding, etc, and when smarttab is on, is used instead of ts/sts
" for the indentation at beginning of line.
set shiftwidth=4

" Number of spaces that the tab key counts for when editing
" Only really useful if different from ts, or if using et.
" When 0, it is disabled.
set softtabstop=4

" Round indent to a multiple of 'shiftwidth'
set shiftround


set cinoptions=>s,e0,n0,f0,{0,}0,^0,:s,=s,l0,g0,hs,ps,ts,+s,c3,C0,(0,us,\U0,w0,m0,j0,)20,*30
set cinkeys=0{,0},0),:,0#,!^F,o,O,e

set autoindent
set copyindent
set preserveindent
set nosmartindent
" FIXME: move these to the correct plugins and add comments

set whichwrap=<,>,h,l,[,]
set textwidth=0

set isk+=_,$,@,%,#,-
set shortmess=atItToO

set noshowmatch
set formatoptions=crqn
set fillchars=vert:\|
" Default folding settings, enabled, indent based, all open
if has('folding')
  set foldenable
  set foldcolumn=0
  set foldminlines=1
  set foldmethod=indent
  set foldlevel=99
  set foldlevelstart=99
endif

" Automatically write buffers on switch/make/exit
set nohidden
set autowrite
set autowriteall

" Buffer switching behaviors
" useopen   If included, jump to the first open window that
"           contains the specified buffer (if there is one).
" split     If included, split the current window before loading a buffer
set switchbuf+=useopen
" set switchbuf+=split

" No incremental searches or search highlighting
set noincsearch
set nohlsearch

" More bash-like tab completion
set wildmode=longest,list,full
set wildmenu
set wildignore+=*.o,*~,*.swp,*.bak,*.pyc,*.pyo

" Return cursor to start of edit after repeat
nmap . .`[

" Ignore case on search unless search has uppercase characters
set ignorecase
set smartcase
set infercase

" Fast terminal, bump sidescroll to 1
set sidescroll=1

" Show 2 rows/cols of context when scrolling
set scrolloff=2
set sidescrolloff=2

" Keep cursor in the same column if possible (see help).
set nostartofline
let mapleader = ","
let maplocalleader = ","

" Paste mode
set pastetoggle=<Leader>P

" Fast saving
nmap <leader>w :w!<cr>

" Spelling
nmap <silent> <leader>ss :set spell!<CR>

" Toggle display of newlines, hard tabs, etc
nmap <leader>l :set list!<CR>

" Open a file in the same directory as the current file
nmap <leader>ew :e <C-R>=expand("%:p:h") . "/" <CR>

" Default to navigating by virtual lines, using the 'g' versions to move by
" physical lines
nnoremap k gk
nnoremap j gj
nnoremap gk k
nnoremap gj j

" Make 'Y' follow 'D' and 'C' conventions
nnoremap Y y$

" Select just-pasted text
nnoremap <leader>v V`]

" Ctrl+return to add a new line below the current line in insert mode
inoremap <c-cr> <esc>A<cr>

" Delete trailing whitespace
nmap <leader>dtw :%s/\s\+$//<CR>

nnoremap <Leader>f :ToggleNERDTree<Enter>
nnoremap <Leader>F :NERDTreeFind<Enter>
set dictionary+=/usr/share/dict/words

if v:version >= 700
  set spelllang=en_us
endif
set laststatus=2
if has('statusline')
  set statusline=
  set statusline+=%-3.3n\                      " buffer number
  set statusline+=%(%{StatusLine_FileName()}\ %) " filename
  set statusline+=%h%m%r%w                     " status flags
  set statusline+=%{StatusLine_Pasting()}      " 'paste' option state

  set statusline+=%(\[%{&ft}]%)               " file type
  set statusline+=%=                          " right align remainder
  set statusline+=%-14(%l,%c%V%)              " line, character
  set statusline+=%<%P                        " file position
endif

fun! StatusLine_FileName()
  try
    let fn = pathshorten(expand('%f')) . ' '
  catch
    let fn = expand('%f') . ' '
  endtry
  return fn
endfun

fun! StatusLine_Pasting()
  if &paste
    return '[paste]'
  else
    return ''
  endif
endfun

if has('syntax')
  syntax enable
endif

augroup KergothSyntax
  au!
  " Conceal fold markers if the feature is available
  if has('conceal')
    au BufRead,BufNewFile *
          \ syn match foldMarker contains= contained conceal /{{{[1-9]\?\|}}}[1-9]\?/
  else
    au BufRead,BufNewFile *
          \ syn match foldMarker contains= contained /{{{[1-9]\?\|}}}[1-9]\?/
  endif

  " Highlight vim modelines
  au BufRead,BufNewFile * syn match vimModeline contains=@NoSpell contained /vim:\s*set[^:]\{-1,\}:/
augroup END

" Mark the 81st column magenta
"highlight OverLength ctermbg=Magenta ctermfg=white guibg=#592929
hi def link OverLength Error
match OverLength /\%81v./

" Colors red both trailing whitespace:
"  foo   
"  bar	
" And spaces before tabs:
" foo 	bar
hi def link RedundantWhitespace Error
match RedundantWhitespace /\s\+$\| \+\ze\t/

" Highlighting of Vim modelines, and hiding of fold markers
hi def link vimModeline Special
hi def link foldMarker NonText

" The default coloring of concealed items is terrible
hi! def link Conceal SpecialKey

" Set a default filetype
au BufReadPost,BufNewFile,VimEnter * if &ft == '' | setfiletype text | endif
