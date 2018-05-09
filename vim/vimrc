" Defaults {{{
if v:version >= 800 && !has("nvim")
  unlet! skip_defaults_vim
  source $VIMRUNTIME/defaults.vim
else
  " The default vimrc file.
  "
  " Maintainer:	Bram Moolenaar <Bram@vim.org>
  " Last change:	2017 Jun 13
  "
  " This is loaded if no vimrc file was found.
  " Except when Vim is run with "-u NONE" or "-C".
  " Individual settings can be reverted with ":set option&".
  " Other commands can be reverted as mentioned below.

  " When started as "evim", evim.vim will already have done these settings.
  if v:progname =~? "evim"
    finish
  endif

  " Bail out if something that ran earlier, e.g. a system wide vimrc, does not
  " want Vim to use these default values.
  if exists('skip_defaults_vim')
    finish
  endif

  " Use Vim settings, rather than Vi settings (much better!).
  " This must be first, because it changes other options as a side effect.
  " Avoid side effects when it was already reset.
  if &compatible
    set nocompatible
  endif

  " When the +eval feature is missing, the set command above will be skipped.
  " Use a trick to reset compatible only when the +eval feature is missing.
  silent! while 0
    set nocompatible
  silent! endwhile

  " Allow backspacing over everything in insert mode.
  set backspace=indent,eol,start

  set history=200	" keep 200 lines of command line history
  set noruler		" no need for this with airline
  set showcmd		" display incomplete commands
  set wildmenu		" display completion matches in a status line

  set ttimeout		" time out for key codes
  set ttimeoutlen=100	" wait up to 100ms after Esc for special key

  " Show @@@ in the last line if it is truncated.
  try
    set display=truncate
  catch
  endtry

  " Show a few lines of context around the cursor.  Note that this makes the
  " text scroll if you mouse-click near the start or end of the window.
  set scrolloff=5

  " Do incremental searching when it's possible to timeout.
  if has('reltime')
    set incsearch
  endif

  " Enable live substitution previews
  if has("nvim")
    set inccommand=nosplit
  endif

  " Do not recognize octal numbers for Ctrl-A and Ctrl-X, most users find it
  " confusing.
  set nrformats-=octal

  " For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries.
  if has('win32')
    set guioptions-=t
  endif

  " Don't use Ex mode, use Q for formatting.
  " Revert with ":unmap Q".
  map Q gq

  " CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
  " so that you can undo CTRL-U after inserting a line break.
  " Revert with ":iunmap <C-U>".
  inoremap <C-U> <C-G>u<C-U>

  " In many terminal emulators the mouse works just fine.  By enabling it you
  " can position the cursor, Visually select and scroll with the mouse.
  if has('mouse')
    set mouse=a
  endif

  " Switch syntax highlighting on when the terminal has colors or when using the
  " GUI (which always has colors).
  if &t_Co > 2 || has("gui_running")
    " Revert with ":syntax off".
    syntax on

    " I like highlighting strings inside C comments.
    " Revert with ":unlet c_comment_strings".
    let c_comment_strings=1
  endif

  " Only do this part when compiled with support for autocommands.
  if has("autocmd")

    " Enable file type detection.
    " Use the default filetype settings, so that mail gets 'tw' set to 72,
    " 'cindent' is on in C files, etc.
    " Also load indent files, to automatically do language-dependent indenting.
    " Revert with ":filetype off".
    filetype plugin indent on

    " Put these in an autocmd group, so that you can revert them with:
    " ":augroup vimStartup | au! | augroup END"
    augroup vimStartup
      au!

      " When editing a file, always jump to the last known cursor position.
      " Don't do it when the position is invalid, when inside an event handler
      " (happens when dropping a file on gvim) and for a commit message (it's
      " likely a different one than last time).
      autocmd BufReadPost *
        \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
        \ |   exe "normal! g`\""
        \ | endif

    augroup END

  endif " has("autocmd")

  " Convenient command to see the difference between the current buffer and the
  " file it was loaded from, thus the changes you made.
  " Only define it when not defined already.
  " Revert with: ":delcommand DiffOrig".
  if !exists(":DiffOrig")
    command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		    \ | wincmd p | diffthis
  endif

  if has('langmap') && exists('+langremap')
    " Prevent that the langmap option applies to characters that result from a
    " mapping.  If set (default), this may break plugins (but it's backward
    " compatible).
    set nolangremap
  endif
endif

" Longer command/search history
set history=1000
" }}} Defaults
" Filesystem paths {{{
let $MYVIMRC = expand('<sfile>:p')
let $VIMDOTDIR = expand('<sfile>:p:h')
let &runtimepath = $VIMDOTDIR . ',' . &runtimepath . ',' . $VIMDOTDIR . '/after'

" Also include $DOTFILESDIR/*/vim/
let g:dtvim = glob(expand('<sfile>:p:h:h') . '/*/vim/', 0, 1)
let &runtimepath = $VIMDOTDIR . ',' . join(g:dtvim, ',') . ',' . &runtimepath . ',' . $VIMDOTDIR . '/after'

if !exists('$XDG_DATA_HOME')
  let $XDG_DATA_HOME = $HOME . '/.local/share'
endif

if !isdirectory(expand('$XDG_DATA_HOME/vim'))
  call mkdir(expand('$XDG_DATA_HOME/vim'))
endif

" System temporary files
if !exists('$TEMP')
  let $TEMP = '/tmp'
endif

" Backups and swap files
set directory=$XDG_DATA_HOME/vim/swap,/tmp,/var/tmp,$TEMP
set backupdir=$XDG_DATA_HOME/vim/backup,/tmp,/var/tmp,$TEMP
if has('persistent_undo')
  set undodir=$XDG_DATA_HOME/vim/undo,/tmp,/var/tmp,$TEMP
endif

" Ensure we cover all temp files for backup file creation
if $OSTYPE =~? 'darwin'
  set backupskip+=/private/tmp/*
endif

" Appropriate path for viminfo
if has('viminfo')
  if !exists('$VIMINFO')
    let $VIMINFO = $XDG_DATA_HOME . '/vim/viminfo'
  endif
endif
" }}} Filesystem paths
" Encoding {{{
" Termencoding will reflect the current system locale, but internally,
" we use utf-8, and for files, we use whichever encoding from
" &fileencodings was detected for the file in question.
let &termencoding = &encoding
if has('multi_byte')
  set encoding=utf-8
  " fileencoding value is used for new files
  let &fileencoding = &encoding
  set fileencodings=ucs-bom,utf-8,default,latin1
  scriptencoding utf-8
  " set bomb
endif

" Most printers are Latin1, inform Vim so it can convert.
set printencoding=latin1
" }}}
" Bundle setup {{{
call pathogen#infect()
" }}}
" General settings {{{
" Enable backup files
set backup

" These are of limited usefulness, as I write files often
set noswapfile

" I always run on journaled filesystems
set nofsync
try
  set swapsync=
catch
endtry

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
  let &viminfo = "f1,'1000,:1000,/1000,<1000,s100,h,r" . $TEMP . ",n" . $VIMINFO
endif

augroup vimrc
  au!

  " Resize splits when the window is resized
  au VimResized * exe "normal! \<c-w>="

  " Give us an error window after running make, grep etc, but only if results
  " are available.
  au QuickFixCmdPost * botright cwindow 5

  " Close out the quickfix window if it's the only open window
  fun! <SID>QuickFixClose()
    if &buftype ==# 'quickfix'
      " if this window is last on screen, quit
      if winnr('$') < 2
        quit
      endif
    endif
  endfun
  au BufEnter * call <SID>QuickFixClose()

  " Unset paste on InsertLeave
  au InsertLeave * silent! set nopaste

  if exists('$TMUX')
    au BufEnter * if empty(&buftype) | call system('tmux rename-window '.expand('%:t:S')) | endif
    au VimLeave * call system('tmux set-window automatic-rename on')
  endif

  " Expand the fold where the cursor lives
  autocmd BufWinEnter * silent! exe "normal! zO"
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

" Don't insert 2 spaces after the end of a sentence
set nojoinspaces

" Automatically write buffers on switch/make/exit
set autowrite
set autowriteall

" Kill annoying Press ENTER or type command to continue prompts
set shortmess=atIWo

" Further reduce the Press ENTER prompts
set cmdheight=1

if has('folding')
  " Default with all folds open
  set foldlevelstart=99

  " Default to indent based folding rather than manual
  set foldmethod=indent
endif

" Make completion list behave more like a shell
set wildmode=list:longest

" Files we don't want listed
set wildignore+=.hg,.git,.svn                    " Version control
set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg   " binary images
set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest " compiled object files
set wildignore+=*.DS_Store                       " OSX metadata
set wildignore+=*.luac                           " Lua byte code
set wildignore+=*.pyc,*.pyo                      " Python byte code

" Smart case handling for searches
set ignorecase
set smartcase

" Don't highlight my searches
set nohlsearch

" Try to match case when using insert mode completion
set infercase

" We're using the securemodelines plugin, not built in modelines
set nomodeline

" Fast terminal, bump sidescroll to 1
set sidescroll=1

" Show columns of context when scrolling horizontally
set sidescrolloff=5

" Persistent undo
if has('persistent_undo')
  set undofile
endif

" Search tools
if executable('rg')
  set grepprg=rg\ --vimgrep\ $*
  command! -bang -nargs=* Find
    \ call fzf#vim#grep('rg --vimgrep --color=always ' . shellescape(<q-args>), 1, <bang>0)
elseif executable('ag')
  set grepprg=ag\ -H\ --nocolor\ --nogroup\ --column\ $*
  command! -bang -nargs=* Find call fzf#vim#ag(<q-args>, 1, <bang>0)
elseif executable('ack')
  set grepprg=ack\ -H\ --nocolor\ --nogroup\ --column\ $*
  command! -bang -nargs=* Find
    \ call fzf#vim#grep('ack -H --nocolor --nogroup --column ' . shellescape(<q-args>), 1, <bang>0)
endif
set grepformat=%f:%l:%c:%m

" Ignore binary files matched with grep by default
set grepformat+=%-OBinary\ file%.%#

if &encoding ==# 'utf-8'
  " Display of hidden characters
  set listchars=tab:»·,eol:¬,extends:❯,precedes:❮

  " Show trailing whitespace this way if we aren't highlighting it in color
  if &t_Co < 3 && (! has('gui_running'))
    set listchars+=trail:·
  endif

  " Simple display, no unnecessary fills
  set fillchars=
endif

" Do soft word wrapping at chars in breakat
if has('linebreak')
  set linebreak
  try
    set breakindent
  catch
  endtry
  set cpo+=n
end

if has('unix')
  " Vim makes assumptions about shell behavior, so don't rely on $SHELL
  set shell=sh
elseif has('win32')
  " Enable dwrite support
  try
    set renderoptions=type:directx
  catch
  endtry
endif

" Prefer opening splits down and right rather than up and left
set splitbelow
set splitright

" More useful % matching
runtime macros/matchit.vim

if &term ==# 'rxvt-unicode'
  set t_Co=256
endif

if $TERM_PROGRAM != 'Apple_Terminal'
  let base16colorspace=256
endif

set background=dark
if &t_Co < 88 && (! has('gui_running'))
  colorscheme desert
else
  try
    colorscheme base16-tomorrow-night
    let g:airline_theme = 'base16_tomorrow'
  catch
    colorscheme baycomb
  endtry
endif
" }}}
" Vim language interfaces {{{

" Let vim's python support load the pyenv python libraries
if executable('pyenv')
  try
    let b:python2 = system('pyenv which python2.7')
    if !empty(b:python2)
      let &pythonhome = fnamemodify(substitute(b:python2, '\n', '', ''), ':h:h')
      if has('macunix')
        let &pythondll = &pythonhome . '/lib/libpython2.7.dylib'
      else
        let &pythondll = &pythonhome . '/lib/libpython2.7.so.1.0'
      endif
    endif
  catch
  endtry

  try
    let b:python3 = system('pyenv which python3.6')
    if !empty(b:python3)
      let &pythonthreehome = fnamemodify(substitute(b:python3, '\n', '', ''), ':h:h')
      if has('macunix')
        let &pythonthreedll = &pythonthreehome . '/lib/libpython3.6m.dylib'
      else
        let &pythonthreedll = &pythonthreehome . '/lib/libpython3.6m.so.1.0'
      endif
    endif
  catch
  endtry
endif
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

" Only highlight the first 200 characters of a line
set synmaxcol=200

" Colors red both trailing whitespace:
"  foo   
"  bar	
" And spaces before tabs:
"  foo 	bar
hi def link RedundantWhitespace Error
match RedundantWhitespace /\s\+$\| \+\ze\t/

" We care quite a lot about the length of the git commit summary line
hi def link gitcommitOverflow Error

" Highlight our vim modeline
hi def link vimModeline Special
2match vimModeline /vim:\s*set[^:]\{-1,\}:/

" Fix the difficult-to-read default setting for diff text highlighting.  The
" bang (!) is required since we are overwriting the DiffText setting. The highlighting
" for "Todo" also looks nice (yellow) if you don't like the "MatchParen" colors.
hi! link DiffText MatchParen

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
" Abbreviations {{{
iabbrev adn and
iabbrev teh the
" }}}
" Key Mapping {{{
" Fix command typos
nmap ; :

" :help is the best interface, not F1
nnoremap <F1> <nop>

" Make zO recursively open whatever top level fold we're in, no matter where
" the cursor happens to be.
nnoremap zO zCzO

" Maintain cursor position when joining lines
nnoremap J mzJ`z

" Allow selection past the end of the file for block selection
set virtualedit=block

" Make Y behave sanely (consistent with C, D, ..)
map Y y$

" Easy buffer navigation
noremap <C-h>  <C-w>h
noremap <C-j>  <C-w>j
noremap <C-k>  <C-w>k
noremap <C-l>  <C-w>l
noremap <C-\>  <C-w>p
nnoremap <silent> <C-S-\> :TmuxNavigatePrevious<cr>

" Easy indentation in normal/visual mode
nnoremap <Tab> >>
nnoremap <S-Tab> <<
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" Tmux will send xterm-style keys when its xterm-keys option is on
if &term =~# '^screen'
  execute "set <xUp>=\e[1;*A"
  execute "set <xDown>=\e[1;*B"
  execute "set <xRight>=\e[1;*C"
  execute "set <xLeft>=\e[1;*D"
endif

" , is much more convenient than \, as it's closer to the home row
let mapleader = ','
let maplocalleader = mapleader

" Toggle display of invisible characters
nnoremap <leader>i :set list!<cr>

" Toggle display of line numbers
nnoremap <leader>n :set number!<cr>

" Toggle paste mode with ,P
set pastetoggle=<leader>P

" Resync syntax & redraw the screen, courtesy Steve Losh
nnoremap <leader>U :syntax sync fromstart<cr>:redraw!<cr>

" Ensure arrows always work correctly with command-T
map <Esc>[B <Down>

" Paste and re-indent
nnoremap <leader>p p`[v`]=

" Escape alternative from insert-mode
inoremap jj <Esc>

" Select the just-pasted text
nnoremap <expr> <leader><leader>p '`[' . strpart(getregtype(), 0, 1) . '`]'

" Toggle spell checking
map <leader>ss :set spell!<cr>

" Open a file in the same directory as the current file
map <leader>ew :e <c-r>=expand("%:p:h") . "/" <cr>
" Open a file in the same directory as the current file, in a split
map <leader>es :sp <c-r>=expand("%:p:h") . "/" <cr>
" Open a file in the same directory as the current file, in a vsplit
map <leader>ev :vsp <c-r>=expand("%:p:h") . "/" <cr>
" Open a file in the same directory as the current file, in a tab
map <leader>et :tabe <c-r>=expand("%:p:h") . "/" <cr>

" Close quickfix window
nmap <leader>cwc :cclose<cr>

" Open quickfix window
nmap <leader>cwo :botright copen 5<cr><c-w>p

" Next error in the quickfix list
nmap <leader>ccn :cnext<cr>

" Open a Quickfix window for the last search.
nnoremap <silent> <leader>/ :execute 'vimgrep /'.@/.'/g %'<CR>:copen<CR>

" Delete trailing whitespace
nnoremap <leader>dtw :%s/\s\+$//<cr>:let @/=''<cr>

" Search & replace the word under the cursor globally
nnoremap <leader>S :%s/\<<C-r><C-w>\>//<Left>

" Edit the vimrc
nmap <leader>ve :e $MYVIMRC<CR>

" Reload the vimrc
nmap <leader>vr :so $MYVIMRC<CR>

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

" Enable line number column
set number

" Set window title
set title

" I hate 'Thanks for flying VIM'
set titleold=

" Allow setting window title for screen/tmux
if &term =~# '^screen'
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
    set guifont=InputMonoNarrow\ Thin:h14
  else
    set guifont=InputMonoNarrow\ Thin\ 14
  endif

  " Turn off toolbar and menu
  set guioptions-=T
  set guioptions-=m

  " Disable gui tab line in favor of the text one
  set guioptions-=e

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
  au!
  au BufNewFile,BufRead *.taskpaper setf taskpaper
  au BufNewFile,BufRead *.md set ft=markdown
  au BufNewFile,BufRead TODO,BUGS,README set ft=text
  au BufNewFile,BufRead ~/.config/git/config set ft=gitconfig
  au BufNewFile,BufRead setup-environment,oe-init-build-env set ft=sh
augroup END
" }}}
" File type settings {{{
augroup vimrc_filetypes
  au!

  " Set filetypes

  " File type specific indentation settings
  au FileType vim set sts=2 sw=2
  au FileType c,cpp,go,taskpaper set ts=4 sw=4 sts=0 noet
  au FileType gitconfig set sts=0 sw=8 ts=8 noet

  " Comment string
  au FileType fish set cms=#%s
  au FileType gitconfig set cms=#%s
  au FileType cfg set cms=#%s

  " Set up folding
  au FileType c,cpp,lua,vim,sh,python,go set fdm=syntax
  au FileType man set fdl=99 fdm=manual
  au FileType taskpaper call taskpaper#fold_projects()
  au FileType gitcommit set fdm=syntax

  " Diff context begins with a space, so blank lines of context
  " are being inadvertantly flagged as redundant whitespace.
  " Adjust the match to exclude the first column.
  au Syntax diff match RedundantWhitespace /\%>1c\(\s\+$\| \+\ze\t\)/

  " Add headings with <localleader> + numbers
  au Filetype rst nnoremap <buffer> <localleader>1 yypVr=
  au Filetype rst nnoremap <buffer> <localleader>2 yypVr-
  au Filetype rst nnoremap <buffer> <localleader>3 yypVr~
  au Filetype rst nnoremap <buffer> <localleader>4 yypVr`
  au Filetype markdown nnoremap <buffer> <localleader>1 I# <esc>
  au Filetype markdown nnoremap <buffer> <localleader>2 I## <esc>
  au Filetype markdown nnoremap <buffer> <localleader>3 I### <esc>

  " Use man.vim for K in types we know don't override keywordprg
  au FileType sh,c,cpp nnoremap <buffer> <silent> K :exe 'Man ' . expand('<cword>')<cr>

  " Use :help for K in vim files
  au FileType vim,help nnoremap <buffer> <silent> K :exe 'help ' . expand('<cword>')<cr>

  " Show diff when editing git commit messages
  au FileType gitcommit DiffGitCached

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
" Plugin configuration {{{
let g:tmuxline_powerline_separators = 0
let g:shfmt_extra_args = '-i 4 -ci -bn -d'
let g:sleuth_automatic = 1
let g:vundle_default_git_proto = 'git'
let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_smart_case = 1
" let g:EasyMotion_leader_key = '<Leader>'

nmap <leader>G :GundoToggle<CR>

let g:Modeliner_format = 'fenc= sts= sw= et'
nmap <leader>m :Modeliner<CR>

" Fzf binds
let g:fzf_command_prefix = 'FZF'
nnoremap <silent> <c-b> :FZFBuffers<cr>
nnoremap <silent> <c-p> :FZFFiles<cr>

" Add foldlevel to allowed items in modelines
let g:secure_modelines_allowed_items = [
            \ 'textwidth',   'tw',
            \ 'softtabstop', 'sts',
            \ 'tabstop',     'ts',
            \ 'shiftwidth',  'sw',
            \ 'expandtab',   'et',   'noexpandtab', 'noet',
            \ 'filetype',    'ft',
            \ 'foldmethod',  'fdm',
            \ 'foldlevel',   'fdl',
            \ 'readonly',    'ro',   'noreadonly', 'noro',
            \ 'rightleft',   'rl',   'norightleft', 'norl',
            \ 'cindent',     'cin',  'nocindent', 'nocin',
            \ 'smartindent', 'si',   'nosmartindent', 'nosi',
            \ 'autoindent',  'ai',   'noautoindent', 'noai',
            \ 'spell', 'nospell',
            \ 'spelllang'
            \ ]

" Vim's strlen works fine while netrw's Strlen is broken
if has('multi_byte') | let g:netrw_xstrlen = 0 | endif

" Place .netrwhist and .netrwbook in XDG_DATA_HOME, not $VIMDOTDIR
let g:netrw_home = $XDG_DATA_HOME . '/vim'

if exists('$SSH_CONNECTION')
  let g:vitality_always_assume_iterm = 1
endif

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#whitespace#enabled = 0

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_symbols.crypt = '🔒'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.spell = 'Ꞩ'
let g:airline_symbols.notexists = '∄'
let g:airline_symbols.whitespace = 'Ξ'

augroup vimrc_plugins
  au!

  " When airline is showing our mode, we don't need vim to do so
  au VimEnter * if exists('g:loaded_airline') | set noshowmode | endif
augroup end

if has('macunix')
  " Dash.app integration
  let g:dash_map = {
        \ 'python'     : 'python3',
        \ 'lua'        : 'lua',
        \ 'sh'         : 'man',
        \ }

  " Map K to look up the current word in dash for supported filetypes
  augroup DashMap
    au!
    for key in keys(g:dash_map)
      exe 'au FileType ' . key . ' nnoremap <buffer> K :Dash<cr>'
    endfor
  augroup END

  " Disable python-mode's pydoc integration, since we're using Dash
  let g:pymode_doc = 0
endif
" }}}

" Load a site specific vimrc if one exists (useful for things like font sizes)
if !exists('$HOSTNAME') && executable('hostname')
  let $HOSTNAME = substitute(system('hostname -s'), '\n', '', '')
endif
runtime vimrc.$HOSTNAME

" vim: set sts=2 sw=2 et fdm=marker fdl=0:
