" Vim filetype plugin file
" Language:	Windows PowerShell
" Maintainer:	Peter Provost <peter@provost.org>
" Version: 1.0
"
" $LastChangedDate $
" $Rev $

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin") | finish | endif

" Don't load another plug-in for this buffer
let b:did_ftplugin = 1

setlocal tw=0
setlocal commentstring=#%s
setlocal formatoptions=tcqro

" Change the browse dialog on Win32 to show mainly PowerShell-related files
if has("gui_win32")
	let b:browsefilter = "PowerShell Files (*.ps1)\t*.ps1\n" .
		\ "All Files (*.*)\t*.*\n"
endif

" Undo the stuff we changed
let b:undo_ftplugin = "setlocal tw< cms< fo<" .
	\ " | unlet! b:browsefilter"
