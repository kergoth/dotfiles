
if exists("s:loaded_modlines")
    finish
else
    let s:loaded_modlines=1

    "------------------------------------------------------------------------------
    "
    "   Insert Modelines with standart informationss
    " 
    function! <SID>Modelines_Insert ()
	let l:Line = line (".")
       
	call append (
	    \ l:Line + 0, 
	    \ substitute (
		\ &commentstring				,
		\ "\%s"						,
		\ " vim: textwidth="	. &textwidth		.
		\ (&wrap ? " " : " no")	. "wrap"		.
		\ " tabstop="		. &tabstop		.
		\ " shiftwidth="		. &shiftwidth	.
		\ " softtabstop="		. &softtabstop	.
		\ (&expandtab ? " " : " no") . "expandtab"	,
		\ ""))
	call append (
	    \ l:Line + 1,
	    \ substitute (
		\ &commentstring			,
		\ "\%s"					,
		\ " vim: filetype="	. &filetype	. 
		\ " encoding="	. &encoding		.
		\ " fileformat="	. &fileformat	,
		\ ""))
    endfunction

    execute "nnoremap <unique>" . escape(g:mapleader . "im" , '\') .      " :call <SID>Modelines_Insert ()<CR>"
    execute "inoremap <unique>" . escape(g:mapleader . "im" , '\') . " <C-O>:call <SID>Modelines_Insert ()<CR>"

    execute "47menu Plugin.Insert.Modelines<Tab>" . escape(g:mapleader . "im" , '\') . " :call <SID>Modelines_Insert ()<CR>"
endif

finish

"-------------------------------------------------------------------------------
" vim: textwidth=0 nowrap tabstop=8 shiftwidth=4 softtabstop=4 noexpandtab
" vim: filetype=vim encoding=latin1 fileformat=unix
