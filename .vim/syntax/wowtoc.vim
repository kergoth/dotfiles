" Vim syntax file
"
" Copyright (C) 2007  Chris Larson <clarson@kergoth.com>
" This file is licensed under the MIT license.
"
" Language:	WOW Toc
" Maintainer:	Chris Larson <clarson@kergoth.com>
" Filenames:	*.toc

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case match

syn match wtFilename "^.\+$"

syn match wtComment "^##.*$" display contains=wtVarDef,@Spell
syn match wtVarDef "\([a-zA-Z0-9\-]\)\+\s*:\s*.*$" contained contains=wtVarName,wtValue
syn match wtVarName "\([a-zA-Z0-9\-]\)\+\ze\s*:" contained
syn match wtNumber "[0-9]\+" contained
syn match wtValue ":\s*\zs.*$" contained contains=wtNumber,wtBoolValue
syn match wtBoolValue "\([eE]n\|[dD]is\)abled" contained

hi def link wtVarName Identifier
hi def link wtComment Comment
hi def link wtValue String
hi def link wtNumber Number
hi def link wtBoolValue Boolean
" hi def link wtFilename Special
