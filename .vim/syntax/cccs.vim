" Vim syntax file
" Language:	Clearcase config spec
" Maintainer:	Jean-Alain Geay <jageay@free.fr>
" Last Change:	2005 May 25

"
" Filetype detection
"
" 1. To set the filetype to cccs, type :
"         :set ft=cccs
" in Normal mode.
"
" 2. If you assume a config spec always selects checked-out versions first,
" you can add something like :
"         let s:cccs_pattern='element\s\+\*\s\+CHECKEDOUT'
"         if getline(1) =~ s:cccs_pattern || getline(2) =~ s:cccs_pattern || getline(3) =~ s:cccs_pattern
"             setfiletype cccs
"             finish
"         endif
" in you personal scripts.vim (:h new-filetype).
" Each time you will edit a file that contains the pattern, its fileype will
" be set automatically to cccs.
"
" 3. (From Gary Johnson)
" If you've set Vim as the editor to be invoked within the edcs subcommand,
" it's a good idea to set the filetype to cccs on the temporary file that is opened.
" On Unix you can achieve this by adding :
"         au! BufRead,BufNewFile /tmp/tmp[0-9]*	if $CLEARCASE_CMDLINE =~ "edcs" | setfiletype cccs | endif
" to your personal filetype.vim.
"
" It also works on Cygwin with :
"         au! BufRead,BufNewFile c:/TEMP/tmp[0-9]*	if $CLEARCASE_CMDLINE =~ "edcs" | setfiletype cccs | endif
"
" The cleartool command set the variable CLEARCASE_CMDLINE in the environment
" in which edcs runs. CLEARCASE_CMDLINE holds a string specifying the cleartool
" subcommand (edcs) and any options and arguments included on the command line.

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

set iskeyword+=-

syntax keyword cccsType       element
syntax keyword cccsType       -file -directory -eltype

syntax keyword cccsConstant   main LATEST CHECKEDOUT
syntax match   cccsConstant   /[\\/]0\>/hs=s+1
syntax match   cccsConstant   /lost+found/

syntax keyword cccsStatement  mkbranch time load
syntax match   cccsStatement  /end\s\+mkbranch/
syntax match   cccsStatement  /end\s\+time/

syntax keyword cccsOptionalClause  -mkbranch -nocheckout -time
syntax keyword cccsOptionalClause  -override
syntax keyword cccsOptionalClause  -config -none -error

syntax keyword cccsFunction   created_since created_by

syntax keyword cccsInclude    include

syntax match   cccsComment    "#.*$"

" Default highlighting
if version >= 508 || !exists("did_cccs_syntax_inits")
  if version < 508
    let did_cccs_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink cccsType       Type
  HiLink cccsConstant   Constant
  HiLink cccsStatement  Statement
  HiLink cccsOptionalClause  Statement
  HiLink cccsFunction   Function
  HiLink cccsInclude    Include
  HiLink cccsComment    Comment
  delcommand HiLink
endif

let b:current_syntax = "cccs"
