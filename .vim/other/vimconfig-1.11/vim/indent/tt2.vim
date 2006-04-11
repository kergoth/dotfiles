" Vim filetype plugin file
" Description:	Template Toolkit indenter
" Language:		Template Toolkit (http://www.template-toolkit.org/)
" Maintainer:	Lubomir Host 'rajo' <rajo AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/indent/tt2.vim,v 1.1 2003/08/18 17:21:10 rajo Exp $


" Only load this indent file when no other was loaded.
if exists("b:did_indent")
    finish
endif
" we don't set b:did_indent, because we need source indent/html.vim file
"let b:did_indent = 1


if version < 600
	so <sfile>:p:h/html.vim
else
	runtime indent/html.vim
endif


