" Vim universal .txt syntax file
" Language:     txt 1.0
" Maintainer:   Tomasz Kalkosiñski <tomasz2k@poczta.onet.pl>
" Last change:  28 Apr 2006
"
" This is an universal syntax script for all text documents, logs, changelogs, readmes
" and all other strange and undetected filetypes.
" The goal is to keep it very simple. 
" It colors numbers, operators, signs, cites, brackets, delimiters, comments,
" TODOs, errors, debug and basic simleys ;]
"
" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case ignore

syn cluster txtAlwaysContains add=txtTodo,txtError

syn cluster txtContains	add=txtNumber,txtOperator,txtLink

syn match txtOperator "[~\-_+*<>\[\]{}=|#@$%&\\/:&\^\.,!?]"

" Common strings
syn match txtString "[[:alpha:]]" contains=txtOperator

" Numbers
syn match txtNumber "\d\(\.\d\+\)\?"

" Cites
syn region txtCite	start="\""	end="\""	contains=@txtContains,@txtAlwaysContains
syn region txtCite	start="\„"	end="\""	contains=@txtContains,@txtAlwaysContains
syn region txtCite	start="\(\s\|^\)\@<='"	end="'"		contains=@txtContains,@txtAlwaysContains

" Comments
syn region txtComment	start="("	end=")"		contains=@txtContains,txtCite,@txtAlwaysContains
syn region txtComments	matchgroup=txtComments start="\/\/"	end="$"		contains=@txtAlwaysContains	oneline
syn region txtComments	start="\/\*"	end="\*\/"	contains=@txtAlwaysContains

syn region txtDelims	matchgroup=txtOperator start="<"	end=">"		contains=@txtContains,@txtAlwaysContains oneline
syn region txtDelims	matchgroup=txtOperator start="{"	end="}"		contains=@txtContains,@txtAlwaysContains oneline
syn region txtDelims	matchgroup=txtOperator start="\["	end="\]"		contains=@txtContains,@txtAlwaysContains oneline 

syn match txtLink	"\(http\|https\|ftp\)\(\w\|[\-&=,?\:\.\/]\)*"	contains=txtOperator

syn match txtSmile	"[:;=8][\-]\?\([(\/\\)\[\]]\+\|[OoPpDdFf]\+\)"

syn keyword txtTodo todo fixme xxx

syn keyword txtError error bug

syn keyword txtDebug debug

syn case match

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
  if version < 508
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink txtNumber	       	Number
  HiLink txtString	       	Identifier "Statement Identifier
  HiLink txtOperator		Operator
  HiLink txtCite		String
  HiLink txtComments		Comment
  HiLink txtComment		Comment "Constant 
  HiLink txtDelims		Delimiter
  HiLink txtLink		Special
  HiLink txtSmile		PreProc
  HiLink txtError		Error
  HiLink txtTodo		Todo
  HiLink txtDebug		Debug

  delcommand HiLink

let b:current_syntax = "txt"
" vim: ts=8
