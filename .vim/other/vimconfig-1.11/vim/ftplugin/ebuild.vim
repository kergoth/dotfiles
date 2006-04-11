" Vim filetype plugin file
" Language:		Ebuild (Gentoo Linux)
" Maintainer:	Ondrej Jombík <nepto AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/ftplugin/ebuild.vim,v 1.2 2005/01/13 11:32:18 rajo Exp $


" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
	finish
endif
let b:did_ftplugin = 1

" These settings are based on official Gentoo Linux Developers HOWTO
" http://www.gentoo.org/doc/en/gentoo-howto.xml

setlocal tabstop=4
setlocal shiftwidth=4
setlocal noexpandtab

" Modeline {{{
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3
" }}}

