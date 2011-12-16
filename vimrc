" Load any installed bundles
call pathogen#infect()

" Sadly, we can't rely on the distro to be sane for the basics
syntax on
filetype plugin indent on

" General settings {{{
" Enable backup files
set backup

" Don't store all the backup and swap files in cwd
let &backupdir = './.vimtmp,' . $HOME . '/.vim/tmp,/var/tmp,' . $TEMP
let &directory = &backupdir

" Ensure we cover all temp files for backup file creation
if has('macunix')
  set backupskip+=/private/tmp/*
endif

augroup vimrc
  au!

  " Jump to the last position when reopening a file
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") |
                   \ exe "normal! g'\"" |
                   \ endif

  " Resize splits when the window is resized
  au VimResized * exe "normal! \<c-w>="

  " Give us an error window after running make, grep etc, but only if results
  " are available.
  au QuickFixCmdPost * botright cwindow 5
augroup END

" Intuitive backspacing in insert mode
set backspace=indent,eol,start

" Don't insert 2 spaces after the end of a sentence
set nojoinspaces

" Allow hiding buffers with modifications
set hidden

" Automatically reload files changed outside of vim
set autoread

" Automatically write buffers on switch/make/exit
set autowrite
set autowriteall

" Longer command/search history
set history=1000

" Kill annoying Press ENTER or type command to continue prompts
set shortmess=atI

if has('folding')
  " Start with most folds closed
  set foldlevelstart=1

  " Default to indent based folding rather than manual
  set foldmethod=indent
endif

" Show completion list
set wildmenu

" Make completion list behave more like a shell
set wildmode=list:longest

" Files we don't want listed
set wildignore+=.hg,.git,.svn                    " Version control
set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg   " binary images
set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest " compiled object files
set wildignore+=*.sw?                            " Vim swap files
set wildignore+=*.DS_Store                       " OSX metadata
set wildignore+=*.luac                           " Lua byte code
set wildignore+=*.pyc,*.pyo                      " Python byte code

" Less annoying escaping for regexes
set magic

" Smart case handling for searches
set ignorecase
set smartcase

" Try to match case when using insert mode completion
set infercase

" Modelines are handy
set modeline
set modelines=5

" Fast terminal, bump sidescroll to 1
set sidescroll=1

" Show 2 rows/cols of context when scrolling
set scrolloff=2
set sidescrolloff=2

" Persistent undo
if has('persistent_undo')
  set undofile
  let &undodir = &backupdir
endif

" Use ack if available
if executable('ack')
  set grepprg=ack\ -H\ --nocolor\ --nogroup\ --column\ $*
  set grepformat=%f:%l:%c:%m
endif

" Ignore binary files matched with grep by default
set grepformat+=%-OBinary\ file%.%#

" Prompt me rather than aborting an action
set confirm

" Display of hidden characters
set listchars=tab:»·,extends:…,precedes:…,eol:¬

" Show trailing whitespace this way if we aren't highlighting it
if &t_Co < 3 && (! has('gui_running'))
  set listchars+=trail:·
endif

" Make soft word wrapping obvious
set showbreak=↪

" Vim makes assumptions about shell behavior, so don't rely on $SHELL
set shell=sh

" Prefer opening splits down and right rather than up and left
set splitbelow
set splitright

" Use the vim version of monokai
colorscheme molokai
" }}}
" Performance {{{
" Don't manually sync the swap to disk on unix, since that's periodically done
" for us, so the risk of losing data is relatively small, and this should
" improve performance slightly.
if has('unix')
  set swapsync=
endif

" Rename the file to the backup when possible.
set backupcopy=auto
" }}}
" Indentation and formatting {{{
set formatoptions=qrn1

" 4 space indentation by default
set shiftwidth=4
set softtabstop=4
set expandtab

" Copy indent from current line when starting a new line
set autoindent

" Copy structure of existing line's indent when adding a new line
set copyindent

" When changing a line's indent, preserve as much of the structure as possible
set preserveindent

" Wrap at column 78
set textwidth=78
" }}}
" Syntax and highlighting {{{
" Colors red both trailing whitespace:
"  foo   
"  bar	
" And spaces before tabs:
"  foo 	bar
hi def link RedundantWhitespace Error
match RedundantWhitespace /\s\+$\| \+\ze\t/

hi def link vimModeline Special
2match vimModeline /vim:\s*set[^:]\{-1,\}:/

" Highlight VCS conflict markers
3match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" Highlight the textwidth column
if exists('&colorcolumn')
  set colorcolumn=+1
endif

" Highlight the cursor line
set cursorline
" }}}
" Commands {{{
" Make the 'Man' command available
runtime! ftplugin/man.vim

" Change the current directory to the location of the
" file being edited.
command! -nargs=0 -complete=command Bcd lcd %:p:h
" }}}
" Key Mapping {{{
" , is much more convenient than \, as it's closer to the home row
let mapleader = ','
let maplocalleader = mapleader

" Toggle display of hidden characters
nnoremap <leader>l :set list!<cr>

" Toggle display of line numbers
nnoremap <leader>n :set number!<cr>

" Toggle paste mode with ,P
set pastetoggle=<leader>P

" Select the just-pasted text
nnoremap <expr> <leader>p '`[' . strpart(getregtype(), 0, 1) . '`]'

" Navigate over visual lines
noremap j gj
noremap k gk

" Pressing ,ss will toggle spell checking
map <leader>ss :set spell!<cr>

" Open a file in the same directory as the current file
map <leader>ew :e <c-r>=expand("%:p:h") . "/" <cr>
map <leader>es :sp <c-r>=expand("%:p:h") . "/" <cr>
map <leader>ev :vsp <c-r>=expand("%:p:h") . "/" <cr>
map <leader>et :tabe <c-r>=expand("%:p:h") . "/" <cr>

" Quickfix window manipulation
nmap <leader>cwc :cclose<cr>
nmap <leader>cwo :botright copen 5<cr><c-w>p
nmap <leader>ccn :cnext<cr>

" Delete trailing whitespace
map <leader>dtw  :%s/\s\+$//<cr>:let @/=''<cr>

" Make zO recursively open whatever top level fold we're in, no matter where
" the cursor happens to be.
nnoremap zO zCzO
" }}}
" Terminal and display {{{
" Default to hiding concealed text
if has('conceal')
  set conceallevel=2
endif

" Show the cursor position all the time
set ruler

" Show partial command in last line
set showcmd

" Enable line number column
set number

" Allow setting window title for screen
if &term =~ '^screen'
  set t_ts=k
  set t_fs=\
endif

" Nice window title
if has('gui_running') || &title
  set titlestring=%f    " Path.
  set titlestring+=%m   " Modified flag.
  set titlestring+=%r   " Readonly flag.
  set titlestring+=%w   " Preview window flag.
  set titlestring+=\ -\ %{v:progname}  " Program name
endif

" Always show the status line
set laststatus=2

" Shortened filename/path for statuslines
"
" Example: /home/kergoth/.dotfiles/vimrc -> /h/k/.d/vimrc
fun! StatusLine_FileName()
  try
    let fn = pathshorten(expand('%f')) . ' '
  catch
    let fn = expand('%f') . ' '
  endtry
  return fn
endfun

" Status line format
set statusline=%-3.3n\         " buffer number
set statusline+=%(%{StatusLine_FileName()}\ %) " Shortened path
set statusline+=%m            " Modified flag.
set statusline+=%r            " Readonly flag.
set statusline+=%w            " Preview window flag.
set statusline+=\ %(\[%{&ft}]%) " file type

set statusline+=%=   " Right align.

" File format, encoding and type.  Ex: "(unix/utf-8/python)"
set statusline+=(
set statusline+=%{&ff}                        " Format (unix/DOS).
set statusline+=/
set statusline+=%{strlen(&fenc)?&fenc:&enc}   " Encoding (utf-8).
set statusline+=/
set statusline+=%{&ft}                        " Type (python).
set statusline+=)

" Line and column position and counts.
set statusline+=\ (line\ %l\/%L,\ col\ %03c)

" Assume we have a decent terminal, as vim only recognizes a very small set of
" $TERM values for the default enable.
set ttyfast

if has('mouse_xterm')
  " Enable mouse support in terminals
  set mouse=a

  " Assume we're using a terminal that can handle this, as vim's automatic
  " enable only recognizes a limited set of $TERM values
  if !&ttymouse
    set ttymouse=xterm2
  endif
endif
" }}}
" GUI settings {{{
if has('gui_running')
  if has('gui_macvim')
    set guifont=Ubuntu\ Mono:h13
  else
    set guifont=Ubuntu\ Mono\ 13
  endif

  " Turn off toolbar and menu
  set guioptions-=T
  set guioptions-=m

  " use console dialogs instead of popup
  " dialogs for simple choices
  set guioptions+=c

  " Use a line-drawing char for pretty vertical splits.
  set fillchars+=vert:│

  augroup gvimrc
    au!
    au GUIEnter * set columns=96 lines=48
  augroup END
end
" }}}
" File type settings {{{
augroup vimrc_filetypes
  au!
  " Add headings with <localleader> + numbers
  au Filetype rst nnoremap <buffer> <localleader>1 yypVr=
  au Filetype rst nnoremap <buffer> <localleader>2 yypVr-
  au Filetype rst nnoremap <buffer> <localleader>3 yypVr~
  au Filetype rst nnoremap <buffer> <localleader>4 yypVr`
  au Filetype markdown nnoremap <buffer> <localleader>1 yypVr=
  au Filetype markdown nnoremap <buffer> <localleader>2 yypVr-
  au Filetype markdown nnoremap <buffer> <localleader>3 I### <esc>

  " Show diff when editing git commit messages
  au FileType gitcommit DiffGitCached | wincmd p

  " Map S to cycle through the interactive rebase choices
  au FileType gitrebase nnoremap <buffer> <silent> S :Cycle<cr>

  " Use man.vim for K in types we know don't override keywordprg
  au FileType sh,c,cpp nnoremap <buffer> <silent> K :exe 'Man ' . expand('<cword>')<cr>

  " Use :help for K in vim files
  au FileType vim nnoremap <buffer> <silent> K :exe 'help ' . expand('<cword>')<cr>

  " Kill the highlighted text width column in certain files
  au FileType help set tw=0
  au FileType man set tw=0

  " Default indentation for vim files
  au FileType vim set sts=2 sw=2

  " Proper golang indentation
  au FileType go set ts=4 sts=0 noet

  " Set up folding methods
  au FileType c,cpp,lua,vim,sh,python set fdm=syntax
  au FileType man set fdl=99 fdm=manual

  " Diff context begins with a space, so blank lines of context
  " are being inadvertantly flagged as redundant whitespace.
  " Adjust the match to exclude the first column.
  au Syntax diff match RedundantWhitespace /\%>1c\(\s\+$\| \+\ze\t\)/
augroup END

" Highlight GNU gcc specific items
let g:c_gnu = 1

" Allow posix elements like $() in /bin/sh scripts
let g:is_posix = 1

" Fold shell functions
let g:sh_fold_enabled = 1

" Enable syntax folding for vimL
let g:vimsyn_folding = 1

" Disable new bitbake file template
let g:bb_create_on_empty = 0
" }}}
" Potentially useful, but never used {{{
" Don't use old weak encryption for Vim 7.3
if has('cryptv') && exists('&cryptmethod')
  set cryptmethod=blowfish
endif

" More useful % matching
runtime macros/matchit.vim

" Char to fill deleted lines with in vim diff mode
set fillchars=diff:⣿

" Diff context begins with a space, so blank lines of context
" are being inadvertantly flagged as redundant whitespace.
" Adjust the match to exclude the first column.
au Syntax diff match RedundantWhitespace /\%>1c\(\s\+$\| \+\ze\t\)/

" Match a line containing just '--' as an error, as beginning a signature
" with the dashes, but without the trailing space, is a common mistake.
au Syntax mail \
   syn match mailInvalidSignature contains=@mailLinks,@mailQuoteExps "^--$"
hi def link mailInvalidSignature Error

" Email signatures generally start with '-- '.  Adjust the
" RedundantWhitespace match for the 'mail' filetype to not
" highlight that particular trailing space in red.
match RedundantWhitespace /\(^--\)\@<!\s\+$/

" When selecting with the mouse, copy to clipboard on release.
vnoremap <LeftRelease> '+y<LeftRelease>gv
vnoremap <RightRelease> '+y<RightRelease>gv
" }}}

" Load a site specific vimrc if one exists (useful for things like font sizes)
if !exists('$HOSTNAME') && executable('hostname')
  let $HOSTNAME = substitute(system('hostname -s'), "\n", "", "")
endif
runtime vimrc.$HOSTNAME

" vim:set sts=2 sw=2 et fdm=marker fdl=0:
