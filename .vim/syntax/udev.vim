" Vim syntax file
" Language:	udev rules
" Author:	Ciaran McCreesh <ciaranm@gentoo.org>
" Version:	20051016
" Copyright:	Copyright (c) 2005 Ciaran McCreesh
" Licence:	You may redistribute this under the same terms as Vim itself

if exists("b:current_syntax")
  finish
endif

syn region udevComment start=/^\s*#/ end=/$/

syn keyword udevCondition ACTION KERNEL DEVPATH SUBSYSTEM BUS DRIVER ID
syn keyword udevCondition PROGRAM RESULT
syn keyword udevCondition SYSFS nextgroup=udevQualifier

syn match udevAction /\w\@<!ENV\w\@!/ nextgroup=udevQualifier
syn match udevCondition /\w\@<!ENV\w\@!\(\({[^}\s]\+}\)\?\(==\|!=\)\)\@=/ nextgroup=udevQualifier

syn keyword udevAction NAME SYMLINK OWNER GROUP MODE RUN
syn keyword udevAction LABEL GOTO WAIT_FOR_SYSFS OPTIONS
syn keyword udevAction IMPORT nextgroup=udevQualifier

syn match udevQualifier /{[^}\s]\+}/ contained

syn keyword udevConstant last_rule ignore_device ignore_remove all_partitions

syn match udevPunctuation /[,=+!:]/
syn match udevPunctuation /\\$/

syn region udevString start=/"/ end=/"/ contains=udevPattern,udevEscape

syn match udevPattern /[*]\|[?]\|\[[^]]\+\]/ contained

syn match udevEscape /%[kbnpmMPrN%]/ contained
syn match udevEscape /%[sec]\%({[^}"]\+}\)\?/ contained

syn match udevEscape /\$\%(kernel\|id\|number\|devpath\|major\|minor\)/ contained
syn match udevEscape /\$\%(enum\|parent\|root\|tempmode\|\$\)/ contained
syn match udevEscape /\$\%(sysfs\|env\|result\)\%({[^}"]\+}\)\?/ contained

hi def link udevComment      Comment
hi def link udevAction       Identifier
hi def link udevCondition    Special
hi def link udevQualifier    Operator
hi def link udevPunctuation  Operator
hi def link udevConstant     Constant
hi def link udevString       String
hi def link udevPattern      Operator
hi def link udevEscape       Special

let b:current_syntax = "udev"

