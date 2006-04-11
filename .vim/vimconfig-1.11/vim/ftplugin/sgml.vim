" Vim filetype plugin file
" Language:		SGML (DocBook)
" Maintainer:	Ondrej Jombík <nepto AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/ftplugin/sgml.vim,v 1.6 2005/01/13 11:32:19 rajo Exp $


" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
	finish
endif
let b:did_ftplugin = 1

" Set window width to 80
setlocal tw=78
setlocal autoindent


let b:input_method = "iso8859-2"

" turn on IMAP() input method
call UseDiacritics()

" Modeline {{{
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3
" }}}

