" File: strace.vim
" Maintainer:	Lubomir Host 'rajo' <rajo AT platon.sk>
" Version:		$Platon: vimconfig/vim/strace.vim,v 1.7 2005/01/13 11:34:25 rajo Exp $
"
" Description: Source this file for removing some unimportang
"              lines from strace output.


:silent! execute 'g/^\(\d\+ \{1,2}\)\{0,1}brk/d'
:silent! execute 'g/^\(\d\+ \{1,2}\)\{0,1}rt_sig/d'
:silent! execute 'g/ELF/d'
:silent! execute 'g/^\(\d\+ \{1,2}\)\{0,1}time/d'
:silent! execute 'g/^\(\d\+ \{1,2}\)\{0,1}gettimeofday/d'
:silent! execute 'g/^\(\d\+ \{1,2}\)\{0,1}select/d'

" Modeline {{{
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3
" }}}

