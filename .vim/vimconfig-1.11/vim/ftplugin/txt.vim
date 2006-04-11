" Vim filetype plugin file
" Language:		Plain text
" Maintainer:	Lubomir Host 'rajo' <rajo AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/ftplugin/txt.vim,v 1.5 2005/01/13 11:30:21 rajo Exp $


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


let b:input_method = "iso8859-2"

" turn on IMAP() input method
call UseDiacritics()

" Modeline {{{
" vim:set ts=4:
" vim600: fdm=marker fdl=0 fdc=3
" }}}

