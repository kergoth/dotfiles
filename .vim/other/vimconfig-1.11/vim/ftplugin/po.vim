" Vim filetype plugin file
" Language:		PO (gettext) files
" Maintainer:	Ondrej Jombík <nepto@platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/ftplugin/po.vim,v 1.1 2005/01/13 16:51:05 nepto Exp $


" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
	finish
endif
let b:did_ftplugin = 1

let b:input_method = "iso8859-2"

" turn on IMAP() input method
call UseDiacritics()

" Modeline {{{
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3
" }}}

