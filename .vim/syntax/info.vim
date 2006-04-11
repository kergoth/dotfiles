" Info.vim : syntax highlighting for info
"  Language:	info
"  Maintainer:	Charles E. Campbell, Jr.
"  Last Change:	May 10, 2005
"  Version:		1
" syntax highlighting based on Slavik Gorbanyov's work
let g:loaded_syntax_info= "v1"

syn clear
syn case match
syn match  infoMenuTitle	/^\* Menu:/hs=s+2,he=e-1
syn match  infoTitle		/^[A-Z][0-9A-Za-z `',/&]\{,43}\([a-z']\|[A-Z]\{2}\)$/
syn match  infoTitle		/^[-=*]\{,45}$/
syn match  infoString		/`[^`]*'/
syn region infoLink			start=/\*[Nn]ote/ end=/::/
syn match  infoLink			/\*[Nn]ote \([^():]*\)\(::\|$\)/
syn match  infoLink			/^\* \([^:]*\)::/hs=s+2
syn match  infoLink			/^\* [^:]*: \(([^)]*)\)/hs=s+2
syn match  infoLink			/^\* [^:]*:\s\+[^(]/hs=s+2,he=e-2

if !exists("g:did_info_syntax_inits")
  let g:did_info_syntax_inits = 1
  hi def link infoMenuTitle	Title
  hi def link infoTitle		Comment
  hi def link infoLink		Directory
  hi def link infoString	String
endif
" vim: ts=4
