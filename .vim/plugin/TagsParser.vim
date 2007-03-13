" File:         plugin/TagsParser.Vim
" Description:  Dynamic file tagging and mini-window to display tags
" Version:      0.9.1
" Date:         March, 04 2007
" Author:       A. Aaron Cornelius (ADotAaronDotCorneliusAtgmailDotcom)
"
" Installation:
" ungzip and untar The TagsParser.tar.gz somewhere in your Vim runtimepath
" (typically this should be something like $HOME/.Vim, $HOME/vimfiles or
" $VIM/vimfiles) Once this is done run :helptags <dir>/doc where <dir> is The
" directory that you ungziped and untarred The TagsParser.tar.gz archive in.
"
" Usage:
" For help on The usage of this plugin to :help TagsParser after you have
" finished The installation steps.
"
" Copyright (C) 2006 A. Aaron Cornelius <<<
"
" This program is free software; you can redistribute it and/or
" modify it under The terms of The GNU General Public License
" as published by The Free Software Foundation; either version 2
" of The License, or (at your option) any later version.
"
" This program is distributed in The hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even The implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See The
" GNU General Public License for more details.
"
" You should have received a copy of The GNU General Public License
" along with this program; if not, write to The Free Software
" Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
" USA.
" >>>

let s:cpoSave = &cpo
set cpo&vim

" Init Check <<<
if exists('loaded_tagsparser')
  finish
endif
let loaded_tagsparser = 1
" >>>

" Configuration

" Perl Check - Warn if Perl is not installed, and Vim 7.0 is not running <<<
if !exists("g:TagsParserForceUsePerl")
  let g:TagsParserForceUsePerl = 0
endif

if (v:version < 700 || g:TagsParserForceUsePerl == 1) && !has('Perl')
  if !exists('g:TagsParserNoPerlWarning') || g:TagsParserNoPerlWarning == 0
    if (v:version < 700)
      echoerr "You must have a perl enabled version of Vim to use the TagsParser plugin."
    elseif g:TagsParserForceUsePerl == 1
      echoerr "The TagsParserForceUsePerl variable is set, but the current Vim version does not have perl enabled.  Please disable this variable to use the TagsParser plugin."
    endif
    echoerr "(to disable this warning set The g:TagsParserNoPerlWarning variable to 1 in your .vimrc)"
    echoerr " -- TagsParser Disabled -- "
  endif
  finish
endif " if (v:version < 700 || g:TagsParserForceUsePerl == 1) && !has('Perl')
" >>>
" Global Variables <<<
if !exists("g:TagsParserDebugTime")
  let g:TagsParserDebugTime = 0
endif

if !exists("g:TagsParserDebugFlag")
  let g:TagsParserDebugFlag = 0
endif

if !exists("g:TagsParserTagsDir")
  let g:TagsParserTagsDir = ".tags"
endif

if !exists("g:TagsParserTagsPath")
  let g:TagsParserTagsPath = ""
endif

if !exists("g:TagsParserTagsLib")
  let g:TagsParserTagsLib = ""
endif

if !exists("g:TagsParserCtrlTabUsage")
  let g:TagsParserCtrlTabUsage = ""
endif

let s:defaultCtagsQualifiedTagSeparator = '\.\|:'
if !exists("g:TagsParserCtagsQualifiedTagSeparator")
  let g:TagsParserCtagsQualifiedTagSeparator = 
        \ s:defaultCtagsQualifiedTagSeparator 
elseif v:version >= 700 && g:TagsParserCtagsQualifiedTagSeparator[0] == '+' && len(g:TagsParserCtagsQualifiedTagSeparator) > 1
  let g:TagsParserCtagsQualifiedTagSeparator = 
        \ s:defaultCtagsQualifiedTagSeparator . 
        \ g:TagsParserCtagsQualifiedTagSeparator[1:-1]
endif

if !exists("g:TagsParserSaveInterval")
  let g:TagsParserSaveInterval = 30
endif

if !exists("g:TagsParserUpdateTime")
  let g:TagsParserUpdateTime = 1000
endif

if !exists("g:TagsParserCtagsOptions")
  let g:TagsParserCtagsOptions = ""
endif

if v:version >= 700
  if !exists("g:TagsParserCtagsOptionsTypeList")
    let g:TagsParserCtagsOptionsTypeList = []
  endif
endif

if !exists("g:TagsParserOff")
  let g:TagsParserOff = 0
endif

if !exists("g:TagsParserCurrentFileCWD")
  let g:TagsParserCurrentFileCWD = 0
endif

if !exists("g:TagsParserLastPositionJump")
  let g:TagsParserLastPositionJump = 0
endif

if !exists("g:TagsParserNoNestedTags")
  let g:TagsParserNoNestedTags = 0
endif

if !exists("g:TagsParserNoTagWindow")
  let g:TagsParserNoTagWindow = 0
endif

if !exists("g:TagsParserTagWindowFixedSize")
  let g:TagsParserTagWindowFixedSize = 1
endif

if !exists("g:TagsParserWindowLeft")
  let g:TagsParserWindowLeft = 0
endif

if !exists("g:TagsParserHorizontalSplit")
  let g:TagsParserHorizontalSplit = 0
endif

if !exists("g:TagsParserWindowTop")
  let g:TagsParserWindowTop = 0
endif

if !exists("g:TagsParserFoldColumnDisabled")
  let g:TagsParserFoldColumnDisabled = 0
endif

if !exists("g:TagsParserWindowSize")
  let g:TagsParserWindowSize = 40
endif

if !exists("g:TagsParserWindowName")
  let g:TagsParserWindowName = "__tags__"
endif

if !exists('g:TagsParserSingleClick')
  let g:TagsParserSingleClick = 0
endif

if !exists('g:TagsParserFileReadTag')
  let g:TagsParserFileReadTag = 0
endif

if !exists('g:TagsParserFileReadDeleteTag')
  let g:TagsParserFileReadDeleteTag = 0
endif

if !exists("g:TagsParserHighlightCurrentTag")
  let g:TagsParserHighlightCurrentTag = 0
endif

if !exists("g:TagsParserAutoOpenClose")
  let g:TagsParserAutoOpenClose = 0
endif

if !exists("g:TagsParserNoResize")
  let g:TagsParserNoResize = 0
endif

if !exists("g:TagsParserSortType") || g:TagsParserSortType != "line"
  let g:TagsParserSortType = "alpha"
endif

if !exists("g:TagsParserDisplaySignature")
  let g:TagsParserDisplaySignature = 0
endif

"Before moving on, validate that the current shell exists.
if executable(&shell) != 1
  echoerr "TagsParser Error - The currently configured shell (" . &shell .
        \ ") is not executable on this system.  This option must be" .
        \ " configured correctly for the TagsParser plugin to work correctly"
  echoerr " -- TagsParser Disabled -- "
  finish
endif

"if we are in the C:/WINDOWS/SYSTEM32 dir, change to C.  Odd things seem to
"happen if we are in the system32 directory
if has('win32') && getcwd() ==? 'C:\WINDOWS\SYSTEM32'
  let s:cwdChanged = 1
  cd C:\
else
  let s:cwdChanged = 0
endif

"if the tags program has not been specified by a user level global define,
"find the right tags program.  This checks exuberant-ctags first to handle the
"case where multiple tags programs are installed it is differentiated by an
"explicit name
if !exists("g:TagsParserTagsProgram")
  if executable("exuberant-ctags")
    let g:TagsParserTagsProgram = "exuberant-ctags"
  elseif executable("ctags")
    let g:TagsParserTagsProgram = "ctags"
  elseif executable("ctags.exe")
    let g:TagsParserTagsProgram = "ctags.exe"
  elseif executable("tags")
    let g:TagsParserTagsProgram = "tags"
  else
    echoerr "TagsParser - tags program not found, go to " .
          \"http://ctags.sourceforge.net/ to download it.  OR" .
          \"specify the path to a the Exuberant Ctags program " .
          \"using the g:TagsParserTagsProgram variable in your .vimrc"
    echoerr " -- TagsParser Disabled -- "
    finish
  endif
endif

"Get the current ctags version
let s:ctagsVersion = system(g:TagsParserTagsProgram . " --version")

"Make sure that this is an Exuberant Ctags program
if s:ctagsVersion !~? "Exuberant Ctags"
  echoerr "TagsParser - ctags = " . g:TagsParserTagsProgram .
        \" go to http://ctags.sourceforge.net/ to download it.  OR" .
        \"specify the path to a the Exuberant Ctags program " .
        \"using the g:TagsParserTagsProgram variable in your .vimrc"
  echoerr " -- TagsParser Disabled -- "
  finish
endif

if s:cwdChanged == 1
  cd C:\WINDOWS\SYSTEM32
endif

"These variables are in Vim-style regular expressions, not per-style like they 
"used to be.  See ":help usr_27.txt" and ":help regexp" for more information.
"If the patterns are empty then they are considered disabled

"Init the directory exclude pattern to remove any . or _ prefixed directories
"because they are generally considered 'hidden'.  This will also have the
"benefit of preventing the tagging of any .tags directories
let s:defaultDirExcludePattern = '.\+/\..\+\|.\+/_.\+\|' .
      \ '.\+/\%(\ctmp\)\|.\+/\%(\ctemp\)\|.\+/\%(\cbackup\)'
if !exists("g:TagsParserDirExcludePattern")
  let g:TagsParserDirExcludePattern = s:defaultDirExcludePattern
elseif v:version >= 700 && g:TagsParserDirExcludePattern[0] == '+' && len(g:TagsParserDirExcludePattern) > 1
  let g:TagsParserDirExcludePattern = s:defaultDirExcludePattern .
        \ g:TagsParserDirExcludePattern[1:-1]
endif

let s:defaultDirIncludePattern = ''
if !exists("g:TagsParserDirIncludePattern")
  let g:TagsParserDirIncludePattern = s:defaultDirIncludePattern 
elseif v:version >= 700 && g:TagsParserDirIncludePattern[0] == '+' && len(g:TagsParserDirIncludePattern) > 1
  let g:TagsParserDirIncludePattern = s:defaultDirIncludePattern .
        \ g:TagsParserDirIncludePattern[1:-1]
endif

"Init the file exclude pattern to take care of typical object, library
"backup, swap, dependency and tag file names and extensions, build artifacts, 
"gcov extenstions, etc.
let s:defaultFileExcludePattern = '^.*\.\%(\co\)$\|^.*\.\%(\cobj\)$\|' .
      \ '^.*\.\%(\ca\)$\|^.*\.\%(\cso\)$\|^.*\.\%(\cd\)$\|' .
      \ '^.*\.\%(\cbak\)$\|^.*\.\%(\cswp\)$\|^.\+\~$\|^\%(\ccore\)$\|' .
      \ '^\%(\ctags\)$\|^.*\.\%(\ctags\)$\|^.*\.\%(\ctxt\)$\|' .
      \ '^.*\.\%(\cali\)$\|^.*\.\%(\cda\)$\|^.*\.\%(\cbb\)$\|' .
      \ '^.*\.\%(\cbbg\)$\|^.*\.\%(\cgcov\)$'
if !exists("g:TagsParserFileExcludePattern")
  let g:TagsParserFileExcludePattern = s:defaultFileExcludePattern  
elseif v:version >= 700 && g:TagsParserFileExcludePattern[0] == '+' && len(g:TagsParserFileExcludePattern) > 1
  let g:TagsParserFileExcludePattern = s:defaultFileExcludePattern .
        \ g:TagsParserFileExcludePattern[1:-1]
endif

let s:defaultFileIncludePattern = ''
if !exists("g:TagsParserFileIncludePattern")
  let g:TagsParserFileIncludePattern = s:defaultFileIncludePattern
elseif v:version >= 700 && g:TagsParserFileIncludePattern[0] == '+' && len(g:TagsParserFileIncludePattern) > 1
  let g:TagsParserFileIncludePattern = s:defaultFileIncludePattern .
        \ g:TagsParserFileIncludePattern[1:-1]
endif

" >>>
" Script Autocommands <<<
" No matter what, always install The LastPositionJump autocommand, if enabled
if g:TagsParserLastPositionJump == 1
  autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | 
        \ exec "normal! g`\"" | if foldclosed('.') != -1 | foldopen |
        \ endif | endif
endif

" No matter what, always install The CurrentFileCWD autocommand, if enabled.  
if g:TagsParserCurrentFileCWD == 1
  autocmd BufEnter * if expand('<afile>:h') != getcwd() && &modifiable == 1 && isdirectory(expand('<afile>:h')) != 0 | silent cd <afile>:h | endif
endif

" only install the autocommands if the g:TagsParserOff variable is not set
if g:TagsParserOff == 0
  augroup TagsParserAutoCommands
    autocmd!
    "setup an autocommand that will expand the path described by
    "g:TagsParserTagsPath into a valid tag path
    autocmd VimEnter * call TagsParser#Debug(2, "VimEnter - ".
          \ expand("<amatch>")) | call TagsParser#ExpandTagsPath()

    "setup an autocommand so that when a file is written to it writes a tag
    "file if it a file that is somewhere within the tags path or the
    "g:TagsParserTagsPath path
    autocmd BufWritePost ?* call TagsParser#Debug(2, "BufWritePost - ".
          \ expand("<amatch>")) | call TagsParser#PerformOp("tag", "")
  augroup END

  if g:TagsParserNoTagWindow == 0
    augroup TagsParserBufEnterWindowNotOpen
      autocmd BufEnter ?* call TagsParser#Debug(2, "BufEnter - ".
          \ expand("<amatch>")) | call TagsParser#PerformOp("open", "")
    augroup END
  endif

  " Autocommands that will always be installed, unless the plugin is off.
  augroup TagsParserAlwaysOnCommands
    " Setup an autocommand that will tag a file when it is opened
    if g:TagsParserFileReadTag == 1
      autocmd BufRead ?* call TagsParser#Debug(2, "BufRead - ".
          \ expand("<amatch>")) | call TagsParser#PerformOp("tag", "")
    endif

    " Setup an autocommand that will remove any tag file that exists, when it 
    " is opened, if the file is not in a project path.
    if g:TagsParserFileReadDeleteTag == 1
      autocmd BufRead ?* call TagsParser#Debug(2, "BufRead - ".
          \ expand("<amatch>")) | call TagsParser#PerformOp("deletetag", "")
    endif
  augroup END
endif " if g:TagsParserOff == 0
" >>>
" Setup Commands <<<

" TagsParser functionality
command! -nargs=0 TagsParserToggle :call TagsParser#Toggle()

command! -nargs=+ -complete=dir TagDir 
      \ :call TagsParser#SetupDirectoryTags(<q-args>)

" A command that can be used to print out all files that are currently in the 
" TagsParserTagsPath path.
command! -nargs=0 TagsParserPrintPath :echo 'g:TagsParserTagsPath = ' . g:TagsParserTagsPath . "\n\n" . globpath(g:TagsParserTagsPath, "*")

" Turning TagsParser functionality completely off (and then back on)
command! -nargs=0 TagsParserOff :call TagsParser#Off()
command! -nargs=0 TagsParserOn :call TagsParser#On()

" do a copen/cwindow so The quickfix window stretches over the whole window
command! -nargs=* TagsParserCBot :botright copen <args>
command! -nargs=* TagsParserCBotWin :botright cwindow <args>

" do a 'smart' copen/cwindow so that the quickfix window is only below the
" main window
command! -nargs=* TagsParserCOpen :call TagsParser#COpen(<f-args>)
command! -nargs=* TagsParserCWindow :call TagsParser#CWindow(<f-args>)

" Create command mappings to the internal mappings unless a user defined map 
" already exists.  With the <unique> mapping, these remappings will fail if 
" the command sequence is already in use.
if !hasmapto('<Plug>TagsParserToggle')
  nmap <leader>t<space> <Plug>TagsParserToggle
endif

if !hasmapto('<Plug>TagsParserOff')
  nmap <leader>tof <Plug>TagsParserOff
endif

if !hasmapto('<Plug>TagsParserOn')
  nmap <leader>ton <Plug>TagsParserOn
endif

if !hasmapto('<Plug>TagsParserCBot')
  nmap <leader>tbo <Plug>TagsParserCBot
endif

if !hasmapto('<Plug>TagsParserCBotWin')
  nmap <leader>tbw <Plug>TagsParserCBotWin
endif

if !hasmapto('<Plug>TagsParserCOpen')
  nmap <leader>to <Plug>TagsParserCOpen
endif

if !hasmapto('<Plug>TagsParserCWindow')
  nmap <leader>tw <Plug>TagsParserCWindow
endif

if !hasmapto('<Plug>TagsParserCClose')
  nmap <leader>tc <Plug>TagsParserCClose
endif

" Setup the buffer/tab switch mappings.
if g:TagsParserCtrlTabUsage == "buffers"
  if !hasmapto('<Plug>TagsParserBufNext')
    nmap <C-Tab> <Plug>TagsParserBufNext
  endif

  if !hasmapto('<Plug>TagsParserBufPrevious')
    nmap <C-S-Tab> <Plug>TagsParserBufPrevious
  endif
elseif g:TagsParserCtrlTabUsage == "tabs" && v:version >= 700
  if !hasmapto('<Plug>TagsParserBufNext')
    nmap <leader>b <Plug>TagsParserBufNext
  endif

  if !hasmapto('<Plug>TagsParserBufPrevious')
    nmap <leader>B <Plug>TagsParserBufPrevious
  endif

  if !hasmapto('<Plug>TagsParserTabNext')
    nmap <C-Tab> <Plug>TagsParserTabNext
  endif

  if !hasmapto('<Plug>TagsParserTabPrevious')
    nmap <C-S-Tab> <Plug>TagsParserTabPrevious
  endif

  if !hasmapto('<Plug>TagsParserTabOpen')
    nmap <C-Space> <Plug>TagsParserTabOpen
  endif
endif

" TagsParser Internal mappings
map <unique> <script> <Plug>TagsParserToggle :TagsParserToggle<CR>
map <unique> <script> <Plug>TagsParserOff :TagsParserOff<CR>
map <unique> <script> <Plug>TagsParserOn :TagsParserOn<CR>
map <unique> <script> <Plug>TagsParserCBot :TagsParserCBot<CR>
map <unique> <script> <Plug>TagsParserCBotWin :TagsParserCBotWin<CR>
map <unique> <script> <Plug>TagsParserCOpen :TagsParserCOpen<CR>
map <unique> <script> <Plug>TagsParserCWindow :TagsParserCWindow<CR>
map <unique> <script> <Plug>TagsParserCClose :cclose<CR>
map <unique> <script> <Plug>TagsParserBufNext :call TagsParser#BufSwitch(0)<CR>
map <unique> <script> <Plug>TagsParserBufPrevious :call TagsParser#BufSwitch(1)<CR>

" The tab commands should only be mapped if vim 7 is being used
if v:version >= 700
  map <unique> <script> <Plug>TagsParserTabNext :tabn<cr>
  map <unique> <script> <Plug>TagsParserTabPrevious :tabp<cr>
  map <unique> <script> <Plug>TagsParserTabOpen :call TagsParser#TabBufferOpen()<CR>
endif

" >>>
" Initialization <<<
" Check for any depreciated variables and options
if exists("g:MyTagsPath")
  echomsg "The MyTagsPath variable is depreciated, please use TagsParserTagsPath instead."
  echomsg "This path should be set in The same way that all VIM paths are, using commas instead of spaces.  Please see ':help path' for more information."
endif

if exists("g:TagsParserFindProgram")
  echomsg "The TagsParserFindProgram variable is no longer necessary, you can remove it from your .vimrc"
endif

"setup the mappings to handle single click
if g:TagsParserSingleClick == 1
  let s:clickmap = ':if bufname("%") == TagsParser#WindowName() <bar> call TagsParser#SelectTag() <bar> endif <CR>'
  if maparg('<LeftMouse>', 'n') == '' 
    " no mapping for leftmouse
    exec ':nnoremap <silent> <LeftMouse> <LeftMouse>' . s:clickmap
  else
    " we have a mapping
    let  s:m = ':nnoremap <silent> <LeftMouse> <LeftMouse>'
    let  s:m = s:m . substitute(substitute(maparg('<LeftMouse>', 'n'), '|', '<bar>', 'g'), '\c^<LeftMouse>', '', '')
    let  s:m = s:m . s:clickmap
    exec s:m
  endif
endif

" Call the proper init function.  Either the Perl or the Vim script version 
" depending on if the user is running Vim 7.0 or later.
if v:version >= 700 && g:TagsParserForceUsePerl != 1
  call TagsParser#Init()
else
  call TagsParser#PerlInit()
endif
" >>>

let &cpo = s:cpoSave
unlet s:cpoSave

" vim:ft=vim:fdm=marker:ff=unix:wrap:ts=2:sw=2:sts=2:sr:et:fmr=<<<,>>>:fdl=0
