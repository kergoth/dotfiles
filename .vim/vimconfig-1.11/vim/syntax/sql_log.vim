" Vim syntax file
" Language:		SQL with some syntax highlighting addons
" Maintainer:	Lubomir Host 'rajo' <rajo AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/syntax/sql_log.vim,v 1.1 2004/03/08 09:50:15 rajo Exp $


if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

if !exists("main_syntax")
  let main_syntax = 'sql_log'
endif

if version < 600
  so <sfile>:p:h/sql.vim
else
  runtime syntax/sql.vim
  unlet b:current_syntax
endif

" Comments:
syn match sqlComment	'^"[^"]\+$'
syn match sqlError		'^-- ERROR:.*$'

hi def link sqlError Error

let b:current_syntax = "sql_log"

