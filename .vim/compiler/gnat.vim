"------------------------------------------------------------------------------
"  Description: Vim Ada/GNAT compiler file
"     Language: Ada (GNAT)
"          $Id: gnat.vim 214 2006-05-25 09:24:57Z krischik $
"    Copyright: Copyright (C) 2006 Martin Krischik
"   Maintainer:	Martin Krischik
"      $Author: krischik $
"        $Date: 2006-05-25 11:24:57 +0200 (Do, 25 Mai 2006) $
"      Version: 2.0 
"    $Revision: 214 $
"     $HeadURL: https://svn.sourceforge.net/svnroot/gnuada/trunk/tools/vim/compiler/gnat.vim $
"      History: 24.05.2006 MK Unified Headers
"	 Usage: copy to compiler directory
"------------------------------------------------------------------------------

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
" $Id: gnat.vim 214 2006-05-25 09:24:57Z krischik $
"------------------------------------------------------------------------------
" vim: textwidth=78 wrap tabstop=8 shiftwidth=4 softtabstop=4 noexpandtab
" vim: filetype=vim encoding=latin1 fileformat=unix
