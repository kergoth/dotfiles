" Document {{{
" Copyright: Copyright (C) 2005 Bruce Who
"            Permission is hereby granted to use and distribute this code,
"            with or without modifications, provided that this copyright
"            notice is copied with it. Like anything else that's free,
"            bwHomeEndAdv.vim is provided *as is* and comes with no
"            warranty of any kind, either expressed or implied. In no
"            event will the copyright holder be liable for any damages
"            resulting from the use of this software.
" Filename:  bwHomeEndAdv.vim
" URL:       http://vim.sourceforge.net/scripts/script.php?script_id=1316
" Author:    Bruce Who (AKA. 胡旭昭 or HuXuzhao)
" Email:     HuXuzhao@hotmail.com
" Date:      2005-05-10
" $Revision: 1.3 $
" Description:
"   This script enhances the <Home> and <End> key in both normal mode and
"   insert mode. 
"
"   <Home> is enhanced to behave like in Visual C++, you can use <Home> to
"   jump between the first column and the first non-space character of a
"   line.
"
"   Besides, <End> is also enhanced and can be used to jump between the last
"   column and the last non-space character of a line.
"
" Installation:
"   Drop the script to your plugin directory.
" History:
"   2005-08-26:
"     - Bug fix: After Entering VIM, and press <End> for the first time
"                while the cursor is already at the end of the line, an
"                error occurs.
"     - add <silent> to each mapping to make it behave like normal <Home> &
"       <End>.
"     Thanks to Andrzej Zaborowski who reported the bug and gave me a patch,
"     and also gave me the suggestion.
"   2005-07-22:
"     - revise the document
"     - fix a bug: if there is only one traling blank space, you cannot use
"           <END> to jump to the end.
"   2005-05-10:
"     the initial HomeEndAdv.vim script is created
" Bugs:
"   - if the cursor is at a line which only contains spaces in insert mode,
"     <HOME> and <END> doesn't work as expected
" }}}

if exists('g:bwHomeEndAdv') " {{{
  finish
endif
let g:bwHomeEndAdv = 1 " }}}

" Keymaps {{{
" <Home>
inoremap <silent> <Home> <c-o>:call <SID>HomeEnhanced()<CR>
nnoremap <silent> <Home> :call <SID>HomeEnhanced()<CR>
" <End>
inoremap <silent> <End> <C-R>=<SID>IEndEnhanced1()<CR><ESC>:call <SID>IEndEnhanced2()<CR>a
nnoremap <silent> <End> :call <SID>EndEnhanced()<CR>
" }}}

" Implement {{{

function! s:HomeEnhanced()
  let text = strpart(getline('.'), -1, col('.'))
  if text =~ '\m^\s\+$'
    normal! 0
  else              
    normal! ^
  endif
endfunction

function! s:IEndEnhanced1()
  let text = getline('.')
  " if cursor is on the last character
  if strlen(text) < col('.')
    if strpart(text, col('.') - 2, 1) == ' '
      let s:goto_end = 'g_'
    else
      let s:goto_end = '$'
    endif
  else
    let text = strpart(text, col('.') - 1)
    if text =~ '\m^\s\+$'
      let s:goto_end = '$'
    else
      let s:goto_end = 'g_'
    endif
  endif
  return ''
endfunction

function! s:IEndEnhanced2()
  exec 'normal! ' . s:goto_end
endfunction

function! s:EndEnhanced()
  let text = strpart(getline('.'), col('.'))
  if text =~ '\m^\s\+$'
    normal! $
  else
    normal! g_
  endif
endfunction

" }}}

" Modeline for ViM {{{
" vim:fdm=marker fdl=0 fdc=3 fenc=utf-8:
" }}} */
