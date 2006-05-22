"  Description: Vim Ada/GNAT compiler file
"     Language: Ada (GNAT)
"    Copyright: Copyright (C) 2006 Martin Krischik
" Name Of File: colors/martin_krischik.vim
"   Maintainer:	Martin Krischik $Author: krischik $
" Last Changed: $Date: 2006-05-16 19:20:24 +0200 (Di, 16 Mai 2006) $
"      Version: 1.0 $Revision: 197 $
"	   URL: $HeadURL: https://svn.sourceforge.net/svnroot/gnuada/trunk/tools/vim/compiler/gnat.vim $
"	 Usage: copy to compilers directory
"      History: 

if exists("current_compiler")
    finish
else
    let current_compiler = "gnat"

    if exists(":CompilerSet") != 2		" older Vim always used :setlocal
      command -nargs=* CompilerSet setlocal <args>
    endif

    " A workable errorformat for GNAT
    CompilerSet errorformat=%f:%l:%c:\ %trror:\ %m,
			   \%f:%l:%c:\ %tarning:\ %m,
			   \%f:%l:%c:\ (%ttyle)\ %m'

    " default make
    CompilerSet makeprg=make

    function! <SID>Make ()
	wall
	make
	copen
	set wrap
	wincmd W
    endfunction Make 

    command! Make :call <SID>Make ()

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
" $Id: gnat.vim 197 2006-05-16 17:20:24Z krischik $
"------------------------------------------------------------------------------
" vim: textwidth=78 wrap tabstop=8 shiftwidth=4 softtabstop=4 noexpandtab
" vim: filetype=vim encoding=latin1 fileformat=unix
