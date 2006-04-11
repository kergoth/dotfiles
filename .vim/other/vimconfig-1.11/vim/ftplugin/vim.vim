" Vim filetype plugin file
" Language:		Vim
" Maintainer:	Lubomir Host 'rajo' <rajo AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/ftplugin/vim.vim,v 1.2 2003/11/03 08:20:21 rajo Exp $

" MakeVimFolds: see ../plugin/syntaxFolds.vim for documentation {{{
function! MakeVimFolds(force)
	if &ft != 'vim'
		return
	end

	" call FoldRegions('^" =\{70,}', '^[^"]*$', 1, 0)
	let b:startPat_1 = '^" Function: '
	let b:endPat_1 = '\s*endf\(u\|un\|unc\|unct\|uncti\|unctio\|unction\)'
	let b:startOff_1 = 0
	let b:endOff_1 = 0

	let b:startPat_2 = '^\s*f\(u\|un\|unc\|unct\|uncti\|unctio\|unction\)'
	let b:endPat_2 = '\s*endf\(u\|un\|unc\|unct\|uncti\|unctio\|unction\)'
	let b:startOff_2 = 0
	let b:endOff_2 = 0

	call MakeSyntaxFolds(a:force)
endfunction

" }}}
 
" Modeline {{{ 
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3 nowrap:
" }}}

