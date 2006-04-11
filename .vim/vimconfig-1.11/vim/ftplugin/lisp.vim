" Vim filetype plugin file
" Language:		Lisp (ANSI Common Lisp)
" Maintainer:	Ondrej Jombík <nepto AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/ftplugin/lisp.vim,v 1.2 2005/01/13 11:32:18 rajo Exp $


" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
	finish
endif
let b:did_ftplugin = 1

" ensure "showmatch" option is turned on
setlocal showmatch
setlocal tabstop=4
setlocal noexpandtab

" Modeline {{{
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3
" }}}

