"------------------------------------------------------------------------------
"  Description: Vim Ada omnicompletion file
"     Language:	Ada (2005)
"          $Id: adacomplete.vim 214 2006-05-25 09:24:57Z krischik $
"   Maintainer:	Martin Krischik 
"      $Author: krischik $
"        $Date: 2006-05-25 11:24:57 +0200 (Do, 25 Mai 2006) $
"      Version: 2.1 
"    $Revision: 214 $
"     $HeadURL: https://svn.sourceforge.net/svnroot/gnuada/trunk/tools/vim/autoload/adacomplete.vim $
"      History: 24.05.2006 MK Unified Headers
"               26.05.2006 MK improved search for begin of word.
"	 Usage: copy to autoload directory
"------------------------------------------------------------------------------

" Set completion with CTRL-X CTRL-O to autoloaded function.  This check is in
" place in case this script is sourced directly instead of using the autoload
" feature.  Do not set the option if already set since this results in an E117
" warning.
"
if exists ('+omnifunc') && &omnifunc == ""
    setlocal omnifunc=adacomplete#Complete
endif

if exists ('g:loaded_syntax_completion') || version < 700
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
	    while start > 0 && line[start - 1] =~ '\i\|'''
		let start -= 1
	    endwhile
	    return start
	else
	    "
	    " look up matches
	    "
	    let l:Pattern = '^' . a:base . '.*$'
	    "
	    " add keywords
	    "
	    if exists ('g:Ada_Keywords')
		for Tag_Item in g:Ada_Keywords
		    if l:Tag_Item['word'] =~? l:Pattern
			if complete_add (l:Tag_Item) == 0
			    return []
			endif
			if complete_check ()
			    return []
			endif
		    endif
		endfor
	    endif
	    "
	    "  search tag file for matches
	    "
	    let l:Tag_List = taglist (l:Pattern)
	    " 
	    " add symbols
	    "
	    for Tag_Item in l:Tag_List
		if l:Tag_Item['kind'] == ''
		    let l:Tag_Item['kind'] = 's'
		endif
	        let l:Match_Item = {
		    \ 'word':  l:Tag_Item['name'],
		    \ 'menu':  l:Tag_Item['filename'],
		    \ 'info':  "Symbol from file " . l:Tag_Item['filename'] . " line " . l:Tag_Item['cmd'],
		    \ 'kind':  l:Tag_Item['kind'],
		    \ 'icase': 1}
		if complete_add (l:Match_Item) == 0
		    return []
		endif
		if complete_check ()
		    return []
		endif
	    endfor
	    return []
	endif
    endfunction adacomplete#Complete
    finish
endif

"------------------------------------------------------------------------------
"   Copyright (C) 2006  Martin Krischik
"
"   This program is free software; you can redistribute it and/or
"   modify it under the terms of the GNU General Public License
"   as published by the Free Software Foundation; either version 2
"   of the License, or (at your option) any later version.
"   
"   This program is distributed in the hope that it will be useful,
"   but WITHOUT ANY WARRANTY; without even the implied warranty of
"   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"   GNU General Public License for more details.
"   
"   You should have received a copy of the GNU General Public License
"   along with this program; if not, write to the Free Software
"   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
"------------------------------------------------------------------------------
" vim: textwidth=78 wrap tabstop=8 shiftwidth=4 softtabstop=4 noexpandtab
" vim: filetype=vim encoding=latin1 fileformat=unix
