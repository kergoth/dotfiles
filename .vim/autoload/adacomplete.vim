"  Description: Vim Ada autocompletion file
"     Language:	Ada (2005)
"   Maintainer:	Martin Krischik 
"      $Author: krischik $
"        $Date: 2006-05-21 11:17:20 +0200 (So, 21 Mai 2006) $
"      Version: 1.1 
"    $Revision: 201 $
"     $HeadURL: https://svn.sourceforge.net/svnroot/gnuada/trunk/tools/vim/autoload/adacomplete.vim $

" Set completion with CTRL-X CTRL-O to autoloaded function.
" This check is in place in case this script is
" sourced directly instead of using the autoload feature. 
if exists ('+omnifunc')
    " Do not set the option if already set since this
    " results in an E117 warning.
    if &omnifunc == ""
	setlocal omnifunc=adacomplete#Complete
    endif
endif

if exists ('g:loaded_syntax_completion')
    finish
else
    let g:loaded_syntax_completion = 20

    "
    " This function is used for the 'omnifunc' option.
    "
    function! adacomplete#Complete(findstart, base)
	if a:findstart == 1
	    "
	    " locate the start of the word
	    "
	    let line = getline ('.')
	    let start = col ('.') - 1
	    while start > 0 && line[start - 1] =~ '\a'
		let start -= 1
	    endwhile
	    return start
	else
	    "
	    " look up matches
	    "
	    let l:Pattern    = '^' . a:base . '.*$'
	    let l:Tag_List   = taglist (l:Pattern)
	    let l:Match_List = []
	    "
	    " add keywords
	    "
	    if exists ('g:Ada_Keywords')
		for Tag_Item in g:Ada_Keywords
		    if l:Tag_Item['word'] =~? l:Pattern
			echo string (l:Tag_Item)
			let l:Match_List += [l:Tag_Item]
		    endif
		endfor
	    endif
	    " 
	    " add symbols
	    "
	    for Tag_Item in l:Tag_List
		if l:Tag_Item['kind'] == ''
		    let l:Tag_Item['kind'] = 's'
		endif
	        let l:Match_List += [{
		    \ 'word':  l:Tag_Item['name'],
		    \ 'menu':  l:Tag_Item['filename'],
		    \ 'info':  "Symbol from file " . l:Tag_Item['filename'] . " line " . l:Tag_Item['cmd'],
		    \ 'kind':  l:Tag_Item['kind'],
		    \ 'icase': 1}]
	    endfor
	    return l:Match_List
	endif
    endfunction adacomplete#Complete
    finish
endif


" vim: textwidth=78 wrap tabstop=8 shiftwidth=4 softtabstop=4 noexpandtab
" vim: filetype=vim encoding=latin1 fileformat=unix
