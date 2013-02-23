set nocompatible
filetype off

" Path to user vim runtimepath
if !exists('$XDG_CONFIG_HOME')
  let $XDG_CONFIG_HOME = expand('~/.config')
endif
let $VIMDOTDIR = $XDG_CONFIG_HOME . '/vim'
let &runtimepath .= "," . $VIMDOTDIR

" System temporary files
if !exists('$TEMP')
  let $TEMP = '/tmp'
endif

" Bundle setup {{{
runtime bundle/pathogen/autoload/pathogen.vim
execute pathogen#infect()
filetype plugin indent on
" }}}
" General settings {{{
syntax on

" Enable backup files
set backup

" These are of limited usefulness, as I write files often
set noswapfile

" I always run on journaled filesystems
set nofsync

" Don't store all the backup files in cwd
let &backupdir = $VIMDOTDIR . '/tmp,/var/tmp,' . $TEMP
let &directory = &backupdir

" Ensure we cover all temp files for backup file creation
if $OSTYPE =~ 'darwin'
  set backupskip+=/private/tmp/*
endif

" Rename the file to the backup when possible.
set backupcopy=auto

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
    let $VIMINFO = $VIMDOTDIR . "/viminfo"
  endif
  let &viminfo = "f1,'1000,:1000,/1000,<1000,s100,h,r" . $TEMP . ",n" . $VIMINFO
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

" Allow hiding buffers with modifications
set hidden

" Prompt me rather than aborting an action
set confirm

" Automatically reload files changed outside of vim
set autoread

" Navigate over visual lines
noremap j gj
noremap k gk

" Intuitive backspacing in insert mode
set backspace=indent,eol,start

" Don't insert 2 spaces after the end of a sentence
set nojoinspaces

" Automatically write buffers on switch/make/exit
set autowrite
set autowriteall

" Longer command/search history
set history=1000

" Kill annoying Press ENTER or type command to continue prompts
set shortmess=atIWo

" Further reduce the Press ENTER prompts
set cmdheight=2

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
set wildignore+=*.DS_Store                       " OSX metadata
set wildignore+=*.luac                           " Lua byte code
set wildignore+=*.pyc,*.pyo                      " Python byte code

" Less annoying escaping for regexes
set magic

" Smart case handling for searches
set ignorecase
set smartcase

" Don't highlight my searches
set nohlsearch

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

if &encoding == 'utf-8'
  " Display of hidden characters
  set listchars=tab:»·,eol:¬,extends:❯,precedes:❮

  " Show trailing whitespace this way if we aren't highlighting it in color
  if &t_Co < 3 && (! has('gui_running'))
    set listchars+=trail:·
  endif

  " Simple display, no unnecessary fills
  set fillchars=

  " Make soft word wrapping obvious
  set showbreak=↪
endif

" Do soft word wrapping at chars in breakat
set linebreak

" Vim makes assumptions about shell behavior, so don't rely on $SHELL
set shell=sh

" Prefer opening splits down and right rather than up and left
set splitbelow
set splitright

" More useful % matching
runtime macros/matchit.vim

if &term == 'rxvt-unicode'
  set t_Co=256
endif

" Use the vim version of monokai
colorscheme molokai
" }}}
" Indentation and formatting {{{
set formatoptions+=rn1
set formatoptions-=t

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
  augroup KergothColorColumn
    au!
    au InsertEnter * set colorcolumn=+1
    au InsertLeave * set colorcolumn=""
  augroup END
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
" Fix command typos
nmap ; :

" Make zO recursively open whatever top level fold we're in, no matter where
" the cursor happens to be.
nnoremap zO zCzO

" Easy buffer navigation
noremap <C-h>  <C-w>h
noremap <C-j>  <C-w>j
noremap <C-k>  <C-w>k
noremap <C-l>  <C-w>l

" Tmux will send xterm-style keys when its xterm-keys option is on
if &term =~ '^screen'
  execute "set <xUp>=\e[1;*A"
  execute "set <xDown>=\e[1;*B"
  execute "set <xRight>=\e[1;*C"
  execute "set <xLeft>=\e[1;*D"
endif

" , is much more convenient than \, as it's closer to the home row
let mapleader = ','
let maplocalleader = mapleader

" Make Y behave sanely (consistent with C, D, ..)
map Y y$

" Toggle display of invisible characters
nnoremap <leader>i :set list!<cr>

" Toggle display of line numbers
nnoremap <leader>n :set number!<cr>

" Toggle paste mode with ,P
set pastetoggle=<leader>P

" Courtesy Steve Losh
nnoremap <leader>U :syntax sync fromstart<cr>:redraw!<cr>

" Ensure arrows always work correctly with command-T
map <Esc>[B <Down>

" Select the just-pasted text
nnoremap <expr> <leader>p '`[' . strpart(getregtype(), 0, 1) . '`]'

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
nnoremap <leader>dtw :%s/\s\+$//<cr>:let @/=''<cr>

" Search for the word under the cursor
nnoremap <leader>S :%s/\<<C-r><C-w>\>//<Left>

" Open a Quickfix window for the last search.
nnoremap <silent> <leader>/ :execute 'vimgrep /'.@/.'/g %'<CR>:copen<CR>

" Insert a modeline
nmap <leader>m :Modeliner<CR>

" Core functionality from https://github.com/tpope/vim-unimpaired
" Written by Tim Pope <http://tpo.pe/>
function! s:MapNextFamily(map,cmd)
  let map = '<Plug>unimpaired'.toupper(a:map)
  let end = ' ".(v:count ? v:count : "")<CR>'
  execute 'nmap <silent> '.map.'Previous :<C-U>exe "'.a:cmd.'previous'.end
  execute 'nmap <silent> '.map.'Next     :<C-U>exe "'.a:cmd.'next'.end
  execute 'nmap <silent> '.map.'First    :<C-U>exe "'.a:cmd.'first'.end
  execute 'nmap <silent> '.map.'Last     :<C-U>exe "'.a:cmd.'last'.end
  execute 'nmap <silent> ['.        a:map .' '.map.'Previous'
  execute 'nmap <silent> ]'.        a:map .' '.map.'Next'
  execute 'nmap <silent> ['.toupper(a:map).' '.map.'First'
  execute 'nmap <silent> ]'.toupper(a:map).' '.map.'Last'
endfunction

" files
call s:MapNextFamily('a','')
" buffers
call s:MapNextFamily('b','b')
" location list
call s:MapNextFamily('l','l')
" quickfix
call s:MapNextFamily('q','c')
" tags
call s:MapNextFamily('t','t')
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

" I hate 'Thanks for flying VIM'
set titleold=

" Allow setting window title for screen
if &term =~ '^screen'
  set t_ts=k
  set t_fs=\
  set notitle
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
" File type detection {{{
augroup vimrc_filetype_detect
  au BufNewFile,BufRead *.md set ft=markdown
  au BufNewFile,BufRead TODO,BUGS,README set ft=text
augroup END
" }}}
" File type settings {{{
augroup vimrc_filetypes
  au!
  " File type specific indentation settings
  au FileType vim set sts=2 sw=2
  au FileType go set ts=4 sw=4 sts=0 noet
  au FileType c,cpp set ts=4 sw=4 sts=0 noet

  " Comment string
  au FileType fish set cms=#%s

  " Set up folding methods
  au FileType c,cpp,lua,vim,sh,python,go set fdm=syntax
  au FileType man set fdl=99 fdm=manual

  " Diff context begins with a space, so blank lines of context
  " are being inadvertantly flagged as redundant whitespace.
  " Adjust the match to exclude the first column.
  au Syntax diff match RedundantWhitespace /\%>1c\(\s\+$\| \+\ze\t\)/


  " Add headings with <localleader> + numbers
  au Filetype rst nnoremap <buffer> <localleader>1 yypVr=
  au Filetype rst nnoremap <buffer> <localleader>2 yypVr-
  au Filetype rst nnoremap <buffer> <localleader>3 yypVr~
  au Filetype rst nnoremap <buffer> <localleader>4 yypVr`
  au Filetype markdown nnoremap <buffer> <localleader>1 yypVr=
  au Filetype markdown nnoremap <buffer> <localleader>2 yypVr-
  au Filetype markdown nnoremap <buffer> <localleader>3 I### <esc>

  " Use man.vim for K in types we know don't override keywordprg
  au FileType sh,c,cpp nnoremap <buffer> <silent> K :exe 'Man ' . expand('<cword>')<cr>

  " Use :help for K in vim files
  au FileType vim nnoremap <buffer> <silent> K :exe 'help ' . expand('<cword>')<cr>


  " Show diff when editing git commit messages
  au FileType gitcommit DiffGitCached | wincmd p

  " Run gofmt against go files on write
  au BufWritePost *.go :silent Fmt
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
" Plugin settings {{{
let g:Powerline_symbols = "unicode"
let g:Powerline_stl_path_style = "short"
let g:syntastic_auto_loc_list = 1
" }}}

" Load a site specific vimrc if one exists (useful for things like font sizes)
if !exists('$HOSTNAME') && executable('hostname')
  let $HOSTNAME = substitute(system('hostname -s'), "\n", "", "")
endif
runtime vimrc.$HOSTNAME

" vim:set sts=2 sw=2 et fdm=marker fdl=0:
