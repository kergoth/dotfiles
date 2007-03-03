" IndentConsistencyCopAutoCmds.vim: autocmds for IndentConsistencyCop.vim
"
" DESCRIPTION:
"   The autocmds in this script automatically trigger the IndentConsistencyCop
"   for certain, configurable filetypes (such as c, cpp, html, xml, which
"   typically contain lots of indented lines) once when you load the file in
"   VIM. The entire buffer will be checked for inconsistent indentation, and you
"   will receive a report on its findings. With this automatic background check,
"   you'll become aware of indentation problems before you start editing. 
"
" DEPENDENCIES:
"   - Requires IndentConsistencyCop.vim. 
"
" USAGE:
"   Triggering happens automatically; of cause, you can still start the
"   IndentConsistencyCop ex command to re-check the buffer after changes. 
"
"   For very large files, the check may take a couple of seconds. You can abort
"   the script run with CTRL-C, like any other VIM command. 
"
" INSTALLATION:
"   Put the script into your user or system VIM plugin directory (e.g.
"   ~/.vim/plugin). 
"
" CONFIGURATION:
"   If you don't like the default filetypes that are inspected, modify the
"   comma-separated list of filetypes in g:indentconsistencycop_filetypes. 
"
" Copyright: (C) 2006 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	0.01	16-Oct-2006	file creation

" Avoid installing twice or when in compatible mode
if exists("loaded_indentconsistencycopautocmds") || (v:version < 700)
    finish
endif
let loaded_indentconsistencycopautocmds = 1

if ! exists('g:indentconsistencycop_filetypes')
    let g:indentconsistencycop_filetypes = 'ant,c,cpp,cs,csh,css,dosbatch,html,java,javascript,jsp,lisp,pascal,perl,php,python,ruby,scheme,sh,sql,tcsh,vb,vim,wsh,xhtml,xml,xsd,xslt,zsh'
endif

function! s:StartCopBasedOnFiletype( filetype )
    let l:activeFiletypes = split( g:indentconsistencycop_filetypes, ', *' )
    if count( l:activeFiletypes, a:filetype ) > 0
	" Modelines have not been processed yet, but we need them because they
	" very likely change the buffer indent settings. So we set up a second
	" autocmd BufWinEnter (which is processed after the modelines), that
	" will trigger the IndentConsistencyCop and remove itself (i.e. a "run
	" once" autocmd). 
	augroup IndentConsistencyCopBufferCmds
	    autocmd!
	    " When a buffer is loaded, the FileType event will fire before the
	    " BufWinEnter event, so that the IndentConsistencyCop is triggered. 
	    autocmd BufWinEnter <buffer> execute 'IndentConsistencyCop' |  autocmd! IndentConsistencyCopBufferCmds * <buffer>
	    " When the filetype changes in an existing buffer, the BufWinEnter
	    " event is not fired. We use the CursorHold event to trigger the
	    " IndentConsistencyCop when the user pauses for a brief period.
	    " (There's no better event for that.)
	    autocmd CursorHold <buffer> execute 'IndentConsistencyCop' |  autocmd! IndentConsistencyCopBufferCmds * <buffer>
	augroup END
    endif
endfunction

augroup IndentConsistencyCopAutoCmds
    autocmd!
    autocmd FileType * call <SID>StartCopBasedOnFiletype( expand('<amatch>') )
augroup END

