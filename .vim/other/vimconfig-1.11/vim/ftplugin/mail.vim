" Vim filetype plugin file
" Language:		Mail
" Maintainer:	Lubomir Host 'rajo' <rajo AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/ftplugin/mail.vim,v 1.9 2005/01/13 11:32:19 rajo Exp $


" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Don't use modelines in e-mail messages, avoid trojan horses
setlocal nomodeline

" many people recommend keeping e-mail messages 72 chars wide
setlocal textwidth=72

" Set 'formatoptions' to break text lines and keep the comment leader ">".
setlocal formatoptions=crqt12

setlocal autoindent

" Replace <Tab> with 4 spaces
setlocal tabstop=4
setlocal shiftwidth=4
setlocal expandtab

let g:input_method = "iso8859-2"

" Add mappings, unless the user didn't want this.
if !exists("no_plugin_maps") && !exists("no_mail_maps")
  " Quote text by inserting "> "
  if !hasmapto('<Plug>MailQuote')
    vmap <buffer> <LocalLeader>q <Plug>MailQuote
    nmap <buffer> <LocalLeader>q <Plug>MailQuote
  endif
  vnoremap <buffer> <Plug>MailQuote :s/^/> /<CR>:noh<CR>``
  nnoremap <buffer> <Plug>MailQuote :.,$s/^/> /<CR>:noh<CR>``

  " Ctrl-F reformat paragraph
  if !hasmapto('<Plug>MailFormat')
    imap <buffer> <C-F> <Plug>MailFormat
    map  <buffer> <C-F> <Plug>MailFormat
  endif
  inoremap <buffer> <Plug>MailFormat <Esc>gqapi
  noremap  <buffer> <Plug>MailFormat gqap
  vnoremap <buffer> <Plug>MailFormat gq
endif

" Modeline {{{
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3
" }}}

