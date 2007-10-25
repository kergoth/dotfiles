" Language   : Netrw Remote-Directory Listing Syntax
" Maintainer : Charles E. Campbell, Jr.
" Last change: Aug 08, 2007
" Version    : 10
" ---------------------------------------------------------------------

" Syntax Clearing: {{{1
if version < 600
 syntax clear
elseif exists("b:current_syntax")
 finish
endif

" ---------------------------------------------------------------------
" Directory List Syntax Highlighting: {{{1
syn cluster NetrwGroup contains=netrwHide,netrwSortBy,netrwSortSeq,netrwQuickHelp,netrwVersion,netrwCopyTgt

syn match  netrwSpecial		"\%(\S\+ \)*\S\+[*|=]\ze\%(\s\{2,}\|$\)" contains=netrwClassify
syn match  netrwDir		"\.\{1,2}/"			contains=netrwClassify
syn match  netrwDir		"\%(\S\+ \)*\S\+/"		contains=netrwClassify
syn match  netrwDir		"^\S*/"				contains=netrwClassify
syn match  netrwSizeDate	"\<\d\+\s\d\{1,2}/\d\{1,2}/\d\{4}\s"	contains=netrwDateSep skipwhite nextgroup=netrwTime
syn match  netrwSymLink		"\%(\S\+ \)*\S\+@\ze\%(\s\{2,}\|$\)"  contains=netrwClassify
syn match  netrwExe		"\%(\S\+ \)*\S\+\*\ze\%(\s\{2,}\|$\)" contains=netrwClassify,netrwTreeIgnore
syn match  netrwTreeIgnore contained "^\%(| \)*"

syn match  netrwClassify	"[*=|@/]\ze\%(\s\{2,}\|$\)"	contained
syn match  netrwDateSep		"/"				contained
syn match  netrwTime		"\d\{1,2}:\d\{2}:\d\{2}"	contained contains=netrwTimeSep
syn match  netrwTimeSep		":"

syn match  netrwComment		'".*\%(\t\|$\)'			contains=@NetrwGroup
syn match  netrwHide		'^"\s*\(Hid\|Show\)ing:'	skipwhite nextgroup=netrwHidePat
syn match  netrwSlash		"/"				contained
syn match  netrwHidePat		"[^,]\+"			contained skipwhite nextgroup=netrwHideSep
syn match  netrwHideSep		","				contained transparent skipwhite nextgroup=netrwHidePat
syn match  netrwSortBy		"Sorted by"			contained transparent skipwhite nextgroup=netrwList
syn match  netrwSortSeq		"Sort sequence:"		contained transparent skipwhite nextgroup=netrwList
syn match  netrwCopyTgt		"Copy/Move Tgt:"		contained transparent skipwhite nextgroup=netrwList
syn match  netrwList		".*$"				contained contains=netrwComma
syn match  netrwComma		","				contained
syn region netrwQuickHelp	matchgroup=Comment start="Quick Help:\s\+" end="$" contains=netrwHelpCmd keepend contained
syn match  netrwHelpCmd		"\S\ze:"			contained skipwhite nextgroup=netrwCmdSep
syn match  netrwCmdSep		":"				contained nextgroup=netrwCmdNote
syn match  netrwCmdNote		".\{-}\ze  "			contained
syn match  netrwVersion		"(netrw.*)"			contained

" ---------------------------------------------------------------------
" Highlighting Links: {{{1
if !exists("did_drchip_netrwlist_syntax")
 let did_drchip_netrwlist_syntax= 1
 hi link netrwClassify	Function
 hi link netrwCmdSep	Delimiter
 hi link netrwComment	Comment
 hi link netrwDir	Directory
 hi link netrwHelpCmd	Function
 hi link netrwHidePat	Statement
 hi link netrwList	Statement
 hi link netrwVersion	Identifier
 hi link netrwSymLink	Special
 hi link netrwExe	PreProc
 hi link netrwDateSep	Delimiter

 hi link netrwTimeSep	netrwDateSep
 hi link netrwComma	netrwComment
 hi link netrwHide	netrwComment
 hi link netrwMarkFile	Identifier
endif

" Current Syntax: {{{1
let   b:current_syntax = "netrwlist"
" ---------------------------------------------------------------------
" vim: ts=8 fdm=marker
