"-------------------------------------------------------------------------------
"  Description: Insert modelines
"   Maintainer:	Martin Krischik
"      $Author: krischik $
"        $Date: 2007-09-17 09:37:42 +0200 (Mo, 17 Sep 2007) $
"          $Id: modelines.vim 772 2007-09-17 07:37:42Z krischik $
"    Copyright: Copyright (C) 2006 Martin Krischik
" Name Of File: plugin/modelines.vim
" Last Changed: Monday, 09 May 2006
"      Version: 2.0
"    $Revision: 772 $
"     $HeadURL: https://gnuada.svn.sourceforge.net/svnroot/gnuada/trunk/tools/vim/plugin/modelines.vim $
"        Usage: copy to plugin directory
"      History: 18.11.2006 MK Bram's suggestion for runtime integration
"		18.11.2006 MK "set: :" syntax for "/* */" languages   
"		17.09.2007 MK change to bundle use NERD_Commenter when
"		              available  
"-------------------------------------------------------------------------------

if exists("g:loaded_modlines")
    finish
else
    let g:loaded_modlines=20

    if exists('g:mapleader')
        execute "nnoremap <unique>" . escape(g:mapleader . "im" , '\') .      " :call modelines#Insert ()<CR>"
        execute "inoremap <unique>" . escape(g:mapleader . "im" , '\') . " <C-O>:call modelines#Insert ()<CR>"

        execute "47menu Plugin.Insert.Modelines<Tab>" . escape(g:mapleader . "im" , '\') . " :call modelines#Insert ()<CR>"
    endif
endif

finish

"-------------------------------------------------------------------------------
" vim: set nowrap tabstop=8 shiftwidth=4 softtabstop=4 expandtab :
" vim: set textwidth=0 filetype=vim foldmethod=marker nospell :
