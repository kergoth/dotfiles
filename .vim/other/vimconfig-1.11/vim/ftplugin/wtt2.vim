" Vim filetype plugin file
" Language:		Template Toolkit (http://www.template-toolkit.org/)
"               template for WML (WAP page) 
" Maintainer:	Lubomir Host 'rajo' <rajo AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/ftplugin/wtt2.vim,v 1.3 2005/01/13 11:32:19 rajo Exp $


" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1


let b:input_method = "unicode-html"
call UseDiacritics()

" set regular expresion for Smart backspacing
let g:smartBS_wtt2 = '\(' .
			\ "&#x[0-9A-Fa-f]\\{2,4};" .
			\ '\)' . "$"

" map <BS> to function SmartBS()
inoremap <buffer> <BS> <C-R>=SmartBS()<CR>

" Modeline {{{
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3
" }}}

