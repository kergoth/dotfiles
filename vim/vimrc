" vint: -ProhibitUnnecessaryDoubleQuote -ProhibitSetNoCompatible
" Defaults {{{
if v:version >= 800 && !has("nvim")
  unlet! skip_defaults_vim
  source $VIMRUNTIME/defaults.vim
else
  " The default vimrc file.
  "
  " Maintainer:	Bram Moolenaar <Bram@vim.org>
  " Last change:	2019 Feb 18
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

  set history=200		" keep 200 lines of command line history
  set ruler		" show the cursor position all the time
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

  " Only do this part when Vim was compiled with the +eval feature.
  if 1

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

  endif

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
" }}}
" Filesystem paths {{{
let $MYVIMRC = expand('<sfile>:p')
let $VIMDOTDIR = expand('<sfile>:p:h')
let $DOTFILESDIR = expand('<sfile>:p:h:h')
set runtimepath^=$VIMDOTDIR runtimepath+=$VIMDOTDIR/after

" Also include $DOTFILESDIR/*/vim/
let g:dtvim = glob($DOTFILESDIR . '/*/vim/', 0, 1)
let &runtimepath = $VIMDOTDIR . ',' . join(g:dtvim, ',') . ',' . &runtimepath . ',' . join(g:dtvim, '/after,') . '/after'

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
" }}}
" Encoding {{{
if has('multi_byte')
  if !has('nvim')
    " Termencoding will reflect the current system locale, but internally,
    " we use utf-8, and for files, we use whichever encoding from
    " &fileencodings was detected for the file in question.
    let &termencoding = &encoding
    set encoding=utf-8
    set fileencodings=ucs-bom,utf-8,default,latin1
  endif
  " Global fileencoding value is used for new files
  set fileencoding=utf-8
  scriptencoding utf-8
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

" Allow hiding buffers with modifications
set hidden

" Prompt me rather than aborting an action
set confirm

" Automatically reload files changed outside of vim
set autoread

" Navigate over visual lines
noremap j gj
noremap k gk
noremap gj j
noremap gk k

" Keep cursor in the same column when possible
set nostartofline

" Don't insert 2 spaces after the end of a sentence
set nojoinspaces

" Automatically write buffers on switch/make/exit
set autowrite
set autowriteall

" Kill annoying Press ENTER or type command to continue prompts
set shortmess=atIWocOTF

" Further reduce the Press ENTER prompts
set cmdheight=1

" Longer command/search history
set history=1000

if has('folding')
  " Default with all folds open
  set foldlevelstart=99
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

" Fast terminal, bump sidescroll to 1
set sidescroll=1

" Show columns of context when scrolling horizontally
set sidescrolloff=5

" Enable modelines
set modeline

" Persistent undo
if has('persistent_undo')
  set undofile
  set undolevels=5000
endif

" Search tools
if executable('rg')
  set grepprg=rg\ --smart-case\ --vimgrep\ $*
  command! -bang -nargs=* Search
    \ call fzf#vim#grep('rg --vimgrep --smart-case --color=always ' . shellescape(<q-args>), 1, <bang>0)
elseif executable('ag')
  set grepprg=ag\ -H\ --nocolor\ --nogroup\ --column\ $*
  command! -bang -nargs=* Search call fzf#vim#ag(<q-args>, 1, <bang>0)
elseif executable('ack')
  set grepprg=ack\ -H\ --nocolor\ --nogroup\ --column\ $*
  command! -bang -nargs=* Search
    \ call fzf#vim#grep('ack -H --nocolor --nogroup --column ' . shellescape(<q-args>), 1, <bang>0)
endif
set grepformat=%f:%l:%c:%m

" Ignore binary files matched with grep by default
set grepformat+=%-OBinary\ file%.%#

if has('multi_byte') && &encoding ==# 'utf-8'
  " Display of hidden characters
  set listchars=tab:»·,eol:¬,extends:❯,precedes:❮,nbsp:±

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
  set cpoptions+=n
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

if &term ==# 'rxvt-unicode'
  set t_Co=256
endif

function! OverrideColors() abort
  hi! link Error NONE
  hi! Error ctermbg=darkred guibg=darkred ctermfg=black guifg=black
endfunction

set background=dark
if &t_Co < 88 && (! has('gui_running'))
  colorscheme desert
else
  try
    let g:dracula_italic = 0
    colorscheme dracula
    let g:lightline_theme = 'dracula'
  catch
    colorscheme baycomb
  endtry
  call OverrideColors()
endif

augroup colorscheme_override
  au!
  au ColorScheme call OverrideColors()
augroup END

augroup vimrc
  au!

  " Reload vimrc on save
  au BufWritePost $MYVIMRC source $MYVIMRC

  " Default to closed marker folds in my vimrc
  au BufRead $MYVIMRC setl fdm=marker | if &foldlevel == &foldlevelstart | setl foldlevel=0 | endif

  " Resize splits when the window is resized
  au VimResized * exe "normal! \<c-w>="

  " Automatically open, but do not go to (if there are errors) the quickfix /
  " location list window, or close it when is has become empty.
  "
  " Note: Must allow nesting of autocmds to enable any customizations for quickfix
  " buffers.
  autocmd QuickFixCmdPost [^l]* nested cwindow
  autocmd QuickFixCmdPost    l* nested lwindow

  " Adjust the quickfix window height to avoid unnecessary padding
  function! AdjustWindowHeight(minheight, maxheight)
    let l = 1
    let n_lines = 0
    let w_width = winwidth(0)
    while l <= line('$')
      " number to float for division
      let l_len = strlen(getline(l)) + 0.0
      let line_width = l_len/w_width
      let n_lines += float2nr(ceil(line_width))
      let l += 1
    endw
    exe max([min([n_lines, a:maxheight]), a:minheight]) . "wincmd _"
  endfunction
  au FileType qf call AdjustWindowHeight(3, 10)

  " Close out the quickfix window if it's the only open window
  function! s:QuickFixClose()
    if &buftype ==# 'quickfix'
      " if this window is last on screen, quit
      if winnr('$') < 2
        quit
      endif
    endif
  endfunction
  au BufEnter * call <SID>QuickFixClose()

  " Close preview window when the completion menu closes
  autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

  " Unset paste on InsertLeave
  au InsertLeave * silent! set nopaste

  if exists('$TMUX')
    function! s:TmuxRename() abort
      if !exists('g:tmux_automatic_rename')
        let l:tmux_output = system('tmux show-window-options -v automatic-rename')
        if l:tmux_output ==# ''
          let l:tmux_output = system('tmux show-window-options -gv automatic-rename')
        endif
        try
          let g:tmux_automatic_rename = trim(l:tmux_output)
        catch
          let g:tmux_automatic_rename = split(l:tmux_output)[0]
        endtry
      endif
      return g:tmux_automatic_rename ==# 'on'
    endfunction

    au BufEnter * if s:TmuxRename() && empty(&buftype) | call system('tmux rename-window '.expand('%:t:S')) | endif
    au VimLeave * if s:TmuxRename() | call system('tmux set-window automatic-rename on') | endif
  endif

  " Expand the fold where the cursor lives
  autocmd BufWinEnter * silent! exe "normal! zv"

  " Automatically create missing directory
  function! s:MkNonExDir(file, buf) abort
    if empty(getbufvar(a:buf, '&buftype')) && a:file!~#'\v^\w+\:\/'
      let dir=fnamemodify(a:file, ':h')
      if !isdirectory(dir)
        call mkdir(dir, 'p')
      endif
    endif
  endfunction
  autocmd BufWritePre,FileWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END
" }}}
" Vim language interfaces {{{

" Let vim's python support load the pyenv python libraries
if !has("nvim") && executable('pyenv')
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
    for pyver in ['3.6', '3.7']
      let b:python3 = system('pyenv which python' . pyver)
      if !empty(b:python3)
        let &pythonthreehome = fnamemodify(substitute(b:python3, '\n', '', ''), ':h:h')
        if has('macunix')
          let &pythonthreedll = &pythonthreehome . '/lib/libpython' . pyver . 'm.dylib'
        else
          let &pythonthreedll = &pythonthreehome . '/lib/libpython' . pyver . 'm.so.1.0'
        endif
      endif
    endfor
  catch
  endtry
endif
" }}}
" Indentation and formatting {{{
set formatoptions+=rn1j
set formatoptions-=t

" 4 space indentation by default
set shiftwidth=4
set softtabstop=4
set expandtab

" Copy indent from current line when starting a new line
set autoindent

" Copy structure of existing line's indent when adding a new line
set copyindent

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
match RedundantWhitespace /\S\zs\s\+$\| \+\ze\t/

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
    au InsertLeave * set colorcolumn=
  augroup END
endif

" Highlight the cursor line
set cursorline
" }}}
" Commands {{{
" Make the 'Man' command available, loading on demand
function! s:Man(...)
  runtime ftplugin/man.vim
  execute 'Man' join(a:000, ' ')
endfunction
command! -nargs=+ -complete=shellcmd Man delcommand Man | call s:Man(<f-args>)

" Change the current directory to the location of the
" file being edited.
command! -nargs=0 -complete=command Bcd lcd %:p:h

" Add Fix/Format commands for ALEFix
command! -bar -nargs=* -complete=customlist,ale#fix#registry#CompleteFixers Format :call ale#fix#Fix(bufnr(''), '', <f-args>)
" }}}
" Abbreviations {{{
iabbrev adn and
iabbrev teh the
" }}}
" Key Mapping {{{
" , is much more convenient than \, as it's closer to the home row
let mapleader = ','
let maplocalleader = mapleader

" Fix command typos
nmap ; :
nnoremap <leader>; ;

" :help is the best interface, not F1
nnoremap <F1> <nop>

" Make zO recursively open whatever top level fold we're in, no matter where
" the cursor happens to be.
nnoremap zO zCzO

" Show the new foldlevel when changing it
nnoremap <silent> zr zr:<c-u>setlocal foldlevel?<CR>
nnoremap <silent> zm zm:<c-u>setlocal foldlevel?<CR>
nnoremap <silent> zR zR:<c-u>setlocal foldlevel?<CR>
nnoremap <silent> zM zM:<c-u>setlocal foldlevel?<CR>

" Maintain cursor position when joining lines
nnoremap J mzJ`z

" Allow selection past the end of the file for block selection
set virtualedit=block

" Make Y behave sanely (consistent with C, D, ..)
map Y y$

" Make jumping to a mark's line+column more convenient with ', not `
nnoremap ' `
nnoremap ` '

" Use space to toggle folds and create manual folds
nnoremap <silent> <Space> @=(foldlevel('.')?'za':"\<Space>")<CR>
vnoremap <Space> zf

" Easy window navigation
noremap <C-h>  <C-w>h
noremap <C-j>  <C-w>j
noremap <C-k>  <C-w>k
noremap <C-l>  <C-w>l
noremap <C-\>  <C-w>p
nnoremap <silent> <C-S-\> :TmuxNavigatePrevious<cr>

" Switch between the last two files
nnoremap <leader><leader> <c-^>

" Use < and >, not << and >>, and don't lose visual selection while indenting
nnoremap < <<
nnoremap > >>
vnoremap < <gv
vnoremap > >gv

" Walk history with j/k
cnoremap <c-j> <down>
cnoremap <c-k> <up>

" Tmux will send xterm-style keys when its xterm-keys option is on
if &term =~# '^screen'
  execute "set <xUp>=\e[1;*A"
  execute "set <xDown>=\e[1;*B"
  execute "set <xRight>=\e[1;*C"
  execute "set <xLeft>=\e[1;*D"
endif

" Toggle display of invisible characters
nnoremap <leader>i :set list!<cr>

" Toggle display of line numbers
nnoremap <leader>n :set number!<cr>

" Toggle paste mode with ,P
set pastetoggle=<leader>P

" Clear search, refresh diff, sync syntax, redraw the screen
nnoremap <silent> <leader>U :nohlsearch<cr>:diffupdate<cr>:syntax sync fromstart<cr>:redraw!<cr>

" Ensure arrows always work correctly with command-T
map <Esc>[B <Down>

" Paste and re-indent
nnoremap <leader>p p`[v`]=

" Select the just-pasted text
nnoremap <expr> <leader><leader>` '`[' . strpart(getregtype(), 0, 1) . '`]'

" Toggle spell checking
map <leader>ss :set spell!<cr>

" Global search & replace
nmap <leader>s :%s//g<LEFT><LEFT>

" Global search & replace the word under the cursor
nmap <leader>S :%s/\<<C-r><C-w>\>//<Left>

" Open a file in the same directory as the current file
map <leader>e :e <c-r>=escape(expand('%:p:h'), ' \') . '/' <cr>

function! GetBufferList()
  redir =>buflist
  silent! ls!
  redir END
  return buflist
endfunction

function! ToggleList(bufname, pfx)
  let buflist = GetBufferList()
  for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ "'.a:bufname.'"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if bufwinnr(bufnum) != -1
      exec(a:pfx.'close')
      return
    endif
  endfor
  if a:pfx ==# 'l' && len(getloclist(0)) == 0
    echohl ErrorMsg
    echo a:bufname . " is Empty."
    return
  elseif a:pfx ==# 'c' && len(getqflist()) == 0
    echohl ErrorMsg
    echo a:bufname . " is Empty."
    return
  endif
  let winnr = winnr()
  exec(a:pfx.'open')
  if winnr() != winnr
    wincmd p
  endif
endfunction

" Toggle loclist and quickfix windows
nmap <silent> <leader>l :call ToggleList("Location List", 'l')<CR>
nmap <silent> <leader>c :call ToggleList("Quickfix List", 'c')<CR>

" Open a Quickfix window for the last search.
nnoremap <silent> <leader>/ :execute 'vimgrep /'.@/.'/g %'<CR>:copen<CR>

" Show highlight groups under the cursor
nmap <silent> <leader>hl   :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" Delete trailing whitespace
function! StripTrailingWhitespace()
  if !&binary && &filetype !=# 'diff'
    normal! mz
    normal! Hmy
    %s/\s\+$//e
    normal! 'yz<CR>
    normal! `z
  endif
endfunction
nnoremap <leader>dtw :call StripTrailingWhitespace()<CR>

" Edit the vimrc
nmap <silent> <leader>v :e $MYVIMRC<CR>

" Replace file contents with the selection
vnoremap <leader>F "qy<CR>:<C-U>exe "normal! ggdG\"qP"<CR>

" Toggle conceal (i.e. hiding)
function! ToggleConceal() abort
  if &conceallevel == 0
    set conceallevel=1
  else
    set conceallevel=0
  endif
endfunction
nnoremap <silent> <leader>H :call ToggleConceal()<cr>

" Close loclist/quickfix/help
nnoremap <silent> <leader>C :lclose \| cclose \| helpclose<cr>

" Delete this buffer
nnoremap <silent> <leader>D :bd<cr>

" Easier getting out of terminal mode
try
  tnoremap <Esc> <C-\><C-n>
  tnoremap <M-[> <Esc>
  tnoremap <C-v><Esc> <Esc>]
catch
endtry

" Convert a single line shell script to multiline
function! SplitShellLine() abort
    silent! exe '%s/ *; */\r/g'
    silent! exe '%s/ *&& */ \\\r \&\&/g'
    silent! exe '%s/ *|| */ \\\r ||/g'
    silent! exe '%s/^\(do\|then\) \(.*\)/\1\r\2/g'
    Format
endfunction

augroup vimrc_mapping
  au!

  au FileType sh,zsh nnoremap <buffer> <silent> L :call SplitShellLine()<cr>

  " dirvish: map `gr` to reload.
  autocmd FileType dirvish nnoremap <silent><buffer>
        \ gr :<C-U>Dirvish %<CR>

  " dirvish: map `gh` to hide dot-prefixed files.  Press `R` to "toggle" (reload).
  autocmd FileType dirvish nnoremap <silent><buffer>
        \ gh :silent keeppatterns g@\v/\.[^\/]+/?$@d _<cr>:setl cole=3<cr>

  " Let <leader>C also close the dirvish window, from that window
  autocmd FileType dirvish nnoremap <silent><buffer> <leader>C <Plug>(dirvish_quit)

  " Let <leader>C also close the command-line window
  autocmd CmdWinEnter * nnoremap <silent><buffer> <leader>C <C-c><C-c>
augroup END

" Plugin Key Mapping {{{
" Bind <leader>f to fixing/formatting with ALE
nmap <leader>f <Plug>(ale_fix)

" Fzf binds
let g:fzf_command_prefix = 'FZF'
nnoremap <silent> <c-b> :FZFBuffers<cr>
nnoremap <silent> <c-p> :FZFFiles<cr>

nmap <leader>u :UndotreeToggle<CR>
nmap <leader>m :Modeliner<CR>

" surround.vim
nmap ysw ysiW
" }}}
" Paired Key Mapping {{{
" Core functionality from https://github.com/tpope/vim-unimpaired
" Written by Tim Pope <http://tpo.pe/>
function! s:MapNextFamily(map, cmd)
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
call s:MapNextFamily('a', '')
" buffers
call s:MapNextFamily('b', 'b')
" location list
call s:MapNextFamily('l', 'l')
" quickfix
call s:MapNextFamily('q', 'c')
" tags
call s:MapNextFamily('t', 't')
" undo
nnoremap [u g-
nnoremap ]u g+
" }}}
" }}}
" Text Objects {{{
" Fold text-object
vnoremap af :<C-U>silent! normal! [zV]z<CR>
omap     af :normal Vaf<CR>
vnoremap if :<C-U>silent! normal! [zjV]zk<CR>
omap     if :normal Vif<CR>
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

if has('gui_running')
  set guicursor=a:block,a:blinkon0

  " mode aware cursors
  set guicursor+=o:hor50-Cursor
  set guicursor+=n:Cursor
  set guicursor+=i-ci-sm:InsertCursor-ver25
  set guicursor+=r-cr:ReplaceCursor-hor20
  set guicursor+=c:CommandCursor
  set guicursor+=v-ve:VisualCursor

  hi def link InsertCursor Cursor
  hi def link ReplaceCursor Cursor
  hi def link CommandCursor Cursor
  hi def link VisualCursor Cursor
else
  " Adjust cursor in insert mode (bar) and replace mode (underline)
  let &t_SI = "\e[6 q"
  try
    let &t_SR = "\e[4 q"
  catch
  endtry
  let &t_EI = "\e[2 q"

  if !exists('$CURSORCODE')
    let $CURSORCODE = "\e[0 q"
  endif

  augroup vimrc_cursor
    au!
    " Reset cursor on start and exit
    autocmd VimEnter * silent !printf '\e[2 q\n'
    autocmd VimLeave * silent !printf "$CURSORCODE"
  augroup END
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

" No need for a mode indicator when I can rely on the cursor
set noshowmode

" Assume we have a decent terminal, as vim only recognizes a very small set of
" $TERM values for the default enable.
set ttyfast

" Avoid unnecessary redraws
set lazyredraw

if has('mouse_xterm')
  " Assume we're using a terminal that can handle this, as vim's automatic
  " enable only recognizes a limited set of $TERM values
  if !&ttymouse
    set ttymouse=xterm2
  endif
endif

" Folding text function from Gregory Pakosz, with l:end removed
function! FoldText()
  let l:lpadding = &foldcolumn
  redir => l:signs
  execute 'silent sign place buffer='.bufnr('%')
  redir End
  let l:lpadding += l:signs =~# 'id=' ? 2 : 0

  if exists("+relativenumber")
    if (&number)
      let l:lpadding += max([&numberwidth, strlen(line('$'))]) + 1
    elseif (&relativenumber)
      let l:lpadding += max([&numberwidth, strlen(v:foldstart - line('w0')), strlen(line('w$') - v:foldstart), strlen(v:foldstart)]) + 1
    endif
  else
    if (&number)
      let l:lpadding += max([&numberwidth, strlen(line('$'))]) + 1
    endif
  endif

  " expand tabs
  let l:start = substitute(getline(v:foldstart), '\t', repeat(' ', &tabstop), 'g')

  let l:info = ' (' . (v:foldend - v:foldstart) . ')'
  let l:infolen = strlen(substitute(l:info, '.', 'x', 'g'))
  let l:width = winwidth(0) - l:lpadding - l:infolen

  let l:separator = ' … '
  let l:separatorlen = strlen(substitute(l:separator, '.', 'x', 'g'))
  let l:start = strpart(l:start , 0, l:width - l:separatorlen)
  let l:text = l:start . ' … '

  return l:text . repeat(' ', l:width - strlen(substitute(l:text, ".", "x", "g"))) . l:info
endfunction
set foldtext=FoldText()
" }}}
" GUI settings {{{
if has('gui_running')
  if has('gui_macvim')
    set guifont=InputMonoNarrow\ Thin:h14
    set macligatures
    set macthinstrokes
    set macmeta
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

  au BufNewFile,BufRead TODO,BUGS,README set ft=text
  au BufNewFile,BufRead ~/.config/git/config set ft=gitconfig
  au BufNewFile,BufRead /tmp/dvtm-editor.* set ft=dvtm-editor

  " My dotfiles install scripts are shell
  au BufNewFile,BufRead install setf sh

  " Mentor Embedded Linux & OpenEmbedded/Yocto
  au BufNewFile,BufRead local.conf.append* set ft=bitbake
  au BufNewFile,BufRead setup-environment,oe-init-build-env set ft=sh

  " Default ft is 'text'
  au BufNewFile,BufReadPost * if &ft ==# '' | set ft=text | endif

  " Treat buffers from stdin (e.g.: echo foo | vim -) as scratch.
  au StdinReadPost * :set buftype=nofile
augroup END
" }}}
" File type settings {{{
augroup vimrc_filetypes
  au!

  " Set filetypes

  " File type specific indentation settings
  au FileType vim set sts=2 sw=2 et
  au FileType c,cpp,go,taskpaper set ts=4 sw=4 sts=0 noet
  au FileType gitconfig set sts=0 sw=8 ts=8 noet

  " Matchit
  au FileType make let b:match_words='\<ifndef\>\|\<ifdef\>\|\<ifeq\>\|\<ifneq\>:\<else\>:\<endif\>'

  " Search Path
  au FileType vim let &l:path = &path . ',' . &runtimepath

  " Comment string
  au FileType fish set cms=#%s
  au FileType gitconfig set cms=#%s
  au FileType cfg set cms=#%s

  " Set up folding
  au FileType c,cpp,lua,vim,sh,python,go,gitcommit set fdm=syntax
  au FileType text set fdm=indent
  au FileType man set fdl=99 fdm=manual
  au FileType taskpaper call taskpaper#fold_projects()

  " Default to indent based folding rather than manual
  au FileType *
        \ if  &filetype == '' |
        \   set fdm=indent |
        \ endif

  " Use Braceless for indent-sensitive types
  au FileType python,yaml BracelessEnable +indent

  " Set up completion
  au FileType vim let b:vcm_tab_complete = 'vim'

  " Default to syntax completion if we have nothing better
  au FileType *
        \ if &omnifunc == "" |
        \   set omnifunc=syntaxcomplete#Complete |
        \ else |
        \   let b:vcm_tab_complete = 'omni' |
        \ endif

  " Run gofmt on save
  au FileType go let b:ale_fix_on_save = 1

  " Diff context begins with a space, so blank lines of context
  " are being inadvertantly flagged as redundant whitespace.
  " Adjust the match to exclude the first column.
  au Syntax diff match RedundantWhitespace /\%>1c\(\s\+$\| \+\ze\t\)/

  " Add headings with <localleader> + numbers
  au Filetype rst nnoremap <buffer> <localleader>1 yypVr=
  au Filetype rst nnoremap <buffer> <localleader>2 yypVr-
  au Filetype rst nnoremap <buffer> <localleader>3 yypVr~
  au Filetype rst nnoremap <buffer> <localleader>4 yypVr`
  au Filetype markdown nnoremap <buffer> <localleader>1 I# 
  au Filetype markdown nnoremap <buffer> <localleader>2 I## 
  au Filetype markdown nnoremap <buffer> <localleader>3 I### 
  au Filetype markdown nnoremap <buffer> <localleader>4 I#### 

  " Use man.vim for K in types we know don't override keywordprg
  au FileType sh,c,cpp nnoremap <buffer> <silent> K :exe 'Man ' . expand('<cword>')<cr>

  " Use :help for K in vim files
  au FileType vim,help nnoremap <buffer> <silent> K :exe 'help ' . expand('<cword>')<cr>

  " Don't restore position in a git commit message
  au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])

  " Kill unnecessary bits when acting as dvtm copymode
  au FileType dvtm-editor set nonumber
  au FileType dvtm-editor hi def link RedundantWhitespace NONE
augroup END

" Kill unnecessary bits when acting as a pager
function! LessInitFunc()
  set nonumber
  hi def link RedundantWhitespace NONE
endfunction

" Highlight GNU gcc specific items
let g:c_gnu = 1

" Allow posix elements like $() in /bin/sh scripts
let g:is_posix = 1

" Enable syntax folding
let g:javaScript_fold = 1
let g:markdown_folding = 1
let g:perl_fold = 1
let g:perl_fold_blocks = 1
let g:php_folding = 1
let g:r_syntax_folding = 1
let g:ruby_fold = 1
let g:rust_fold = 1
let g:sh_fold_enabled = 7
let g:tex_fold_enabled = 1
let g:vimsyn_folding = 'af'
let g:xml_syntax_folding = 1

" Disable new bitbake file template
let g:bb_create_on_empty = 0
" }}}
" Plugin configuration {{{
if !has("nvim")
  if v:version >= 800
    packadd! matchit
  else
    runtime macros/matchit.vim
  endif
endif

" Disable built-in plugins
let g:loaded_2html_plugin = 1
let g:loaded_getscript = 1
let g:loaded_getscriptPlugin = 1
let g:loaded_gzip = 1
let g:loaded_logiPat = 1
let g:loaded_netrw = 1
let g:loaded_netrwFileHandlers = 1
let g:loaded_netrwPlugin = 1
let g:loaded_netrwSettings = 1
let g:loaded_rrhelper = 1
let g:loaded_spellfile_plugin = 1
let g:loaded_tar = 1
let g:loaded_tarPlugin = 1
let g:loaded_tohtml = 1
let g:loaded_tutor = 1
let g:loaded_vimball = 1
let g:loaded_vimballPlugin = 1
let g:loaded_zip = 1
let g:loaded_zipPlugin = 1

let g:sneak#label = 1
let g:sneak#use_ic_scs = 1
let g:sleuth_automatic = 1
let g:editorconfig_blacklist = {'filetype': ['git.*', 'fugitive']}

let g:undotree_SetFocusWhenToggle = 1
let g:undotree_WindowLayout = 2
let g:Modeliner_format = 'sts= sw= et fdm'

if exists('$SSH_CONNECTION')
  let g:vitality_always_assume_iterm = 1
endif

" Error and warning signs
let g:ale_sign_error = '⤫'
let g:ale_sign_warning = '⚠'

let g:ale_linters = {
\   'python': ['flake8', 'mypy'],
\   'sh': ['shellcheck'],
\}

let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'vim': ['remove_trailing_lines'],
\   'python': ['isort', 'autopep8'],
\   'sh': ['shfmt'],
\   'go': ['gofmt'],
\   'elixir': ['mix_format'],
\}

let g:ale_sh_shfmt_options = '-ci -bn -i 4'

let g:tmuxline_powerline_separators = 0
let g:promptline_powerline_symbols = 1

" Align with the behavior of tmuxline without powerline separators enabled
let g:promptline_symbols = {
    \ 'left'           : '',
    \ 'right'          : '',
    \ 'left_alt'       : '|',
    \ 'right_alt'      : '|',
    \ 'dir_sep'        : '/'}

function! Promptline_git_ahead_behind(...)
  return { 'function_name': 'Promptline_git_ahead_behind',
          \'function_body': readfile(globpath(&runtimepath, "autoload/promptline/slices/git_ahead_behind.sh", 0, 1)[0])}
endfunction

try
  let g:promptline_preset = {
          \'b' : [ promptline#slices#vcs_branch(), __promptline_git_ahead_behind() ],
          \'c' : [ '$(disambiguate -k $PWD; echo $REPLY)' ],
          \'x' : [ promptline#slices#jobs() ],
          \'y' : [ promptline#slices#python_virtualenv() ],
          \'z' : [ promptline#slices#user(), promptline#slices#host({'only_if_ssh': 1}) ],
          \'warn' : [ promptline#slices#last_exit_code() ]}
catch
endtry

let g:lightline = {
      \ 'colorscheme': g:lightline_theme,
      \ 'active': {
      \   'left': [ [ 'paste' ],
      \             [ 'readonly', 'filename' ],
      \             [ 'pwd' ] ],
      \   'right': [ [ 'lineinfo' ],
      \              [ 'percent' ],
      \              [ 'fileformat', 'fileencoding', 'filetype' ] ],
      \ },
      \ 'component_function': {
      \   'fileencoding': 'Statusline_Fileencoding_Hide_Utf8',
      \   'fileformat': 'Statusline_Fileformat_Hide_Unix',
      \   'filetype': 'Statusline_Filetype_Hide_Empty',
      \   'filename': 'Statusline_Filename_Modified',
      \   'readonly': 'Statusline_Readonly',
      \   'pwd': 'Statusline_Pwd',
      \ },
      \ 'component_visible_condition': {
      \   'readonly': '&readonly',
      \   'paste': '&paste',
      \   'fileformat': '&fileformat != "unix"',
      \   'fileencoding': '&fileencoding != "utf-8"',
      \   'filetype': '&filetype != ""',
      \ },
      \ }

function! Statusline_Fileformat_Hide_Unix() abort
  return &fileformat !=# 'unix' ? &fileformat : ''
endfunction

function! Statusline_Fileencoding_Hide_Utf8() abort
  return &fileencoding !=# 'utf-8' ? &fileencoding : ''
endfunction

function! Statusline_Filetype_Hide_Empty() abort
  return &filetype !=# '' ? &filetype : ''
endfunction

function! Statusline_Readonly()
  return &readonly && &filetype !=# 'help' ? 'RO' : ''
endfunction

function! Statusline_Filename_Modified()
  " Avoid the component separator between filename and modified indicator
  let filename = expand('%')
  if filename ==# ''
    return '[No Name]'
  endif
  try
    let filename = pathshorten(fnamemodify(filename, ":~:."))
  catch
    let filename = fnamemodify(filename, ':t')
  endtry
  let modified = &modified ? ' +' : ''
  return filename . modified
endfunction

function! Statusline_Pwd()
  let pwd = fnamemodify(getcwd(), ':~')
  try
    let pwd = pathshorten(pwd)
  catch
  endtry
  return pwd
endfunction

" Fix lightline when vimrc reloads
if exists('g:loaded_lightline') && exists('#lightline')
  call lightline#enable()
endif
" }}}
" Finale {{{
" Load topic-specific vim settings from dotfiles, shortcut method rather than
" creating some_topic/vim/plugin/some_topic.vim
for f in glob('$DOTFILESDIR/*/topic.vim', 0, 1)
    exe 'source ' . f
endfor

" Load a site specific vimrc if one exists (useful for things like font sizes)
if !exists('$HOSTNAME')
  let $HOSTNAME = hostname()
endif
runtime vimrc.$HOSTNAME
runtime vimrc.local
" }}}
