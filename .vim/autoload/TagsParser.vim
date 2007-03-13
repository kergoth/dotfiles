" File:         autoload/TagsParser.Vim
" Description:  Dynamic file tagging and mini-window to display tags
" Version:      0.9.1
" Date:         March, 04 2007
" Author:       A. Aaron Cornelius (ADotAaronDotCorneliusAtgmailDotcom)
"
" Installation:
" ungzip and untar The TagsParser.tar.gz somewhere in your Vim runtimepath
" (typically this should be something like $HOME/.Vim, $HOME/vimfiles or
" $VIM/vimfiles) Once this is done run :helptags <dir>/doc where <dir> is The
" directory that you ungziped and untarred The TagsParser.tar.gz archive in.
"
" Usage:
" For help on The usage of this plugin to :help TagsParser after you have
" finished The installation steps.
"
" Copyright (C) 2006 A. Aaron Cornelius <<<
"
" This program is free software; you can redistribute it and/or
" modify it under The terms of The GNU General Public License
" as published by The Free Software Foundation; either version 2
" of The License, or (at your option) any later version.
"
" This program is distributed in The hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even The implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See The
" GNU General Public License for more details.
"
" You should have received a copy of The GNU General Public License
" along with this program; if not, write to The Free Software
" Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
" USA.
" >>>

let s:cpoSave = &cpo
set cpo&vim

" Init Check <<<
if exists('loaded_tagsparser_autoload')
  finish
endif
let loaded_tagsparser_autoload = 1
" >>>

" Initialization Functions

" TagsParserInit - Init the default type names <<<
function! TagsParser#Init()
  " Define the variables to be used for tag folding
  let s:matchedTagWasFolded = 0
  let s:matchedTagLines = []

  " define the data needed for displaying the tag data, define it in
  " the order desired for parsing, and each entry has the key into the
  " tags hash, the title for those types, and what fold level to put it at
  " the default fold level is 3 which allows for something along the lines of
  " namespace->class->function()

  " If you define a new set of types, make sure to prefix the name with
  " a "- " string so that it will be picked up by the "Type" syntax...  
  let s:adaTypes = [ [ 'P', '- Package Specs' ], [ 'p', '- Packages' ], [ 'T', '- Type Specs' ], [ 't', '- Types' ], [ 'U', '- Subtype Specs' ], [ 'u', '- Subtypes' ], [ 'c', '- Components' ], [ 'l', '- Literals' ], [ 'V', '- Variable Specs' ], [ 'v', '- Variables' ], [ 'n', '- Constants' ], [ 'x', '- Exceptions' ], [ 'f', '- Formal Params' ], [ 'R', '- Subprogram Specs' ], [ 'r', '- Subprograms' ], [ 'K', '- Task Specs' ], [ 'k', '- Tasks' ], [ 'O', '- Protected Data Specs' ], [ 'o', '- Protected Data' ], [ 'E', '- Entry Specs' ], [ 'e', '- Entries' ], [ 'b', '- Labels' ], [ 'i', '- Identifiers' ], [ 'a', '- Auto Vars' ], [ 'y', '- Blocks' ] ]

  let s:adaTypes = [ [ 'P', '- Package Specs' ], [ 'p', '- Packages' ], [ 'T', '- Type Specs' ], [ 't', '- Types' ], [ 'U', '- Subtype Specs' ], [ 'u', '- Subtypes' ], [ 'c', '- Components' ], [ 'l', '- Literals' ], [ 'V', '- Variable Specs' ], [ 'v', '- Variables' ], [ 'n', '- Constants' ], [ 'x', '- Exceptions' ], [ 'f', '- Formal Params' ], [ 'R', '- Subprogram Specs' ], [ 'r', '- Subprograms' ], [ 'K', '- Task Specs' ], [ 'k', '- Tasks' ], [ 'O', '- Protected Data Specs' ], [ 'o', '- Protected Data' ], [ 'E', '- Entry Specs' ], [ 'e', '- Entries' ], [ 'b', '- Labels' ], [ 'i', '- Identifiers' ], [ 'a', '- Auto Vars' ], [ 'y', '- Blocks' ] ]

  let s:asmTypes = [ [ 'd', '- Defines' ], [ 't', '- Types' ], [ 'm', '- Macros' ], [ 'l', '- Labels' ] ]

  let s:aspTypes = [ [ 'f', '- Functions' ], [ 's', '- Subroutines' ], [ 'v', '- Variables' ] ]

  let s:awkTypes = [ [ 'f', '- Functions' ] ]

  let s:betaTypes = [ [ 'f', '- Fragment Defs' ], [ 'p', '- All Patterns' ], [ 's', '- Slots' ], [ 'v', '- Patterns' ] ]

  let s:cTypes = [ [ 'n', '- Namespaces' ], [ 'c', '- Classes' ], [ 'd', '- Macros' ], [ 't', '- Typedefs' ], [ 's', '- Structures' ], [ 'g', '- Enumerations' ], [ 'u', '- Unions' ], [ 'x', '- External Vars' ], [ 'v', '- Variables' ], [ 'p', '- Prototypes' ], [ 'f', '- Functions' ], [ 'm', '- Struct/Union Members' ], [ 'e', '- Enumerators' ], [ 'l', '- Local Vars' ] ]

  let s:csTypes = [ [ 'c', '- Classes' ], [ 'd', '- Macros' ], [ 'e', '- Enumerators' ], [ 'E', '- Events' ], [ 'f', '- Fields' ], [ 'g', '- Enumerations' ], [ 'i', '- Interfaces' ], [ 'l', '- Local Vars' ], [ 'm', '- Methods' ], [ 'n', '- Namespaces' ], [ 'p', '- Properties' ], [ 's', '- Structs' ], [ 't', '- Typedefs' ] ]

  let s:cobolTypes = [ [ 'd', '- Data Items' ], [ 'f', '- File Descriptions' ], [ 'g', '- Group Items' ], [ 'p', '- Paragraphs' ], [ 'P', '- Program IDs' ], [ 's', '- Sections' ] ]

  let s:eiffelTypes = [ [ 'c', '- Classes' ], [ 'f', '- Features' ], [ 'l', '- Local Entities' ] ]

  let s:erlangTypes = [ [ 'd', '- Macro Defs' ], [ 'f', '- Functions' ], [ 'm', '- Modules' ], [ 'r', '- Record Defs' ] ]

  let s:fortranTypes = [ [ 'b', '- Block Data' ], [ 'c', '- Common Blocks' ], [ 'e', '- Entry Points' ], [ 'f', '- Functions' ], [ 'i', '- Interface Contents/Names/Ops' ], [ 'k', '- Type/Struct Components' ], [ 'l', '- Labels' ], [ 'L', '- Local/Common/Namelist Vars' ], [ 'm', '- Modules' ], [ 'n', '- Namelists' ], [ 'p', '- Programs' ], [ 's', '- Subroutines' ], [ 't', '- Derived Types/Structs' ], [ 'v', '- Program/Module Vars' ] ]

  let s:htmlTypes = [ [ 'a', '- Named Anchors' ], [ 'f', '- Javascript Funcs' ] ]

  let s:javaTypes = [ [ 'c', '- Classes' ], [ 'f', '- Fields' ], [ 'i', '- Interfaces' ], [ 'l', '- Local Vars' ], [ 'm', '- Methods' ], [ 'p', '- Packages' ] ]

  let s:javascriptTypes = [ [ 'f', '- Functions' ] ]

  let s:lispTypes = [ [ 'f', '- Functions' ] ]

  let s:luaTypes = [ [ 'f', '- Functions' ] ]

  let s:makeTypes = [ [ 'm', '- Macros' ] ]

  let s:pascalTypes = [ [ 'f', '- Functions' ], [ 'p', '- Procedures' ] ]

  let s:perlTypes = [ [ 'c', '- Constants' ], [ 'l', '- Labels' ], [ 's', '- Subroutines' ] ]

  let s:phpTypes = [ [ 'c', '- Classes' ], [ 'd', '- Constants' ], [ 'f', '- Functions' ], [ 'v', '- Variables' ] ]

  let s:pythonTypes = [ [ 'c', '- Classes' ], [ 'm', '- Class Members' ], [ 'f', '- Functions' ] ]

  let s:rexxTypes = [ [ 's', '- Subroutines' ] ]

  let s:rubyTypes = [ [ 'c', '- Classes' ], [ 'f', '- Methods' ], [ 'F', '- Singleton Methods' ], [ 'm', '- Modules' ] ]

  let s:schemeTypes = [ [ 'f', '- Functions' ], [ 's', '- Sets' ] ]

  let s:shTypes = [ [ 'f', '- Functions' ] ]

  let s:slangTypes = [ [ 'f', '- Functions' ], [ 'n', '- Namespaces' ] ]

  let s:smlTypes = [ [ 'e', '- Exception Defs' ], [ 'f', '- Function Defs' ], [ 'c', '- Functor Defs' ], [ 's', '- Signatures' ], [ 'r', '- Structures' ], [ 't', '- Type Defs' ], [ 'v', '- Value Bindings' ] ]

  let s:sqlTypes = [ [ 'c', '- Cursors' ], [ 'd', '- Prototypes' ], [ 'f', '- Functions' ], [ 'F', '- Record Fields' ], [ 'l', '- Local Vars' ], [ 'L', '- Block Label' ], [ 'P', '- Packages' ], [ 'p', '- Procedures' ], [ 'r', '- Records' ], [ 's', '- Subtypes' ], [ 't', '- Tables' ], [ 'T', '- Triggers' ], [ 'v', '- Variables' ] ]

  let s:tclTypes = [ [ 'c', '- Classes' ], [ 'm', '- Methods' ], [ 'p', '- Procedures' ] ]

  let s:veraTypes = [ [ 'c', '- Classes' ], [ 'd', '- Macro Defs' ], [ 'e', '- Enumerators' ], [ 'f', '- Functions' ], [ 'g', '- Enumerations' ], [ 'l', '- Local Vars' ], [ 'm', '- Class/Struct/Union Members' ], [ 'p', '- Programs' ], [ 'P', '- Prototypes' ], [ 't', '- Tasks' ], [ 'T', '- Typedefs' ], [ 'v', '- Variables' ], [ 'x', '- External Vars' ] ]

  let s:verilogTypes = [ [ 'c', '- Constants' ], [ 'e', '- Events' ], [ 'f', '- Functions' ], [ 'm', '- Modules' ], [ 'n', '- Net Data Types' ], [ 'p', '- Ports' ], [ 'r', '- Register Data Types' ], [ 't', '- Tasks' ] ]

  let s:vimTypes = [ [ 'a', '- Autocommand Groups' ], [ 'f', '- Functions' ], [ 'v', '- Variables' ] ]

  let s:yaccTypes = [ [ 'l', '- Labels' ] ]

  let s:typeMap = { 'ada': s:adaTypes, 'asm': s:asmTypes, 'asp': s:aspTypes, 'awk': s:awkTypes, 'beta':  s:betaTypes, 'c': s:cTypes, 'cpp': s:cTypes, 'cs': s:csTypes, 'cobol': s:cobolTypes, 'eiffel': s:eiffelTypes, 'erlang': s:erlangTypes, 'fortran': s:fortranTypes, 'html': s:htmlTypes, 'java': s:javaTypes, 'javascript': s:javascriptTypes, 'lisp': s:lispTypes, 'lua': s:luaTypes, 'make': s:makeTypes, 'pascal': s:pascalTypes, 'perl': s:perlTypes, 'php': s:phpTypes, 'python': s:pythonTypes, 'rexx': s:rexxTypes, 'ruby': s:rubyTypes, 'scheme': s:schemeTypes, 'sh': s:shTypes, 'slang': s:slangTypes, 'sml': s:smlTypes, 'sql': s:sqlTypes, 'tcl': s:tclTypes, 'vera': s:veraTypes, 'verilog': s:verilogTypes, 'vim': s:vimTypes, 'yacc': s:yaccTypes }

  " create a subtype hash, much like the typeMap.  This will list what
  " sub-types to display, so for example, C struct types will only have it's
  " "m" member list checked which will list the fields of that struct, while
  " namespaces can have all of the types listed in the @cType array.
  let s:adaSubTypes = { 'i': s:adaTypes, 't': [ [ 'c', '' ], [ 'l', '' ], [ 'a', '- Discriminants' ] ], 'u': [ [ 'c', '' ], [ 'l', '' ], [ 'a', '- Discriminants' ] ], 'P': s:adaTypes, 'p': s:adaTypes, 'R': s:adaTypes, 'r': s:adaTypes, 'K': s:adaTypes, 'k': s:adaTypes, 'O': s:adaTypes, 'o': s:adaTypes, 'E': s:adaTypes, 'e': s:adaTypes, 'y': s:adaTypes }

  let s:cSubTypes  = { 'f': [ [ 'l', '' ] ], 's': [ [ 'm', '' ] ], 'u': [ [ 'm', '' ] ], 'g': [ [ 'e', '' ] ], 'c': s:cTypes, 'n': s:cTypes }

  let s:subTypeMap = { 'ada': s:adaSubTypes, 'c': s:cSubTypes, 'cpp': s:cSubTypes }

  " Disable any languages which the user wants disabled
  for l:key in keys(s:typeMap)
    if exists('g:TagsParserDisableLang_{l:key}')
      unlet s:typeMap[l:key]
    endif
  endfor

  " Lastly, remove any headings that the user wants explicitly disabled
  for l:key in keys(s:typeMap)
    " now remove any unwanted types, start at the end of the list so that we
    " don't mess things up by deleting entries and changing the length of the
    " array
    let l:index = len(s:typeMap[l:key]) - 1
    while l:index > 0
      if exists('g:TagsParserDisableType_{l:key}_' . 's:typeMap[l:key][l:index][0]')
        call remove(s:typeMap[l:key], l:index)
      endif
      let l:index -= 1
    endwhile " while l:index > 0
  endfor " for l:key in keys(s:typeMap)

  let s:typeMapHeadingFold = { }

  " build up a list of any headings that the user wants to be automatically
  " folded
  for l:key in keys(s:typeMap)
    " loop through the headings, and add the actual heading pattern to the
    " heading fold structure
    let l:index = 0
    while l:index < len(s:typeMap[l:key])
      if exists('g:TagsParserFoldHeading_{l:key}_{s:typeMap[l:key][l:index][0]}')
        if !exists('s:typeMapHeadingFold[l:key]')
          let s:typeMapHeadingFold[l:key] = [ ]
        endif

        call add(s:typeMapHeadingFold[l:key], s:typeMap[l:key][l:index][1])
      endif
      let l:index += 1
    endwhile " while l:index < len(s:typeMap[l:key])
  endfor " for l:key in keys(s:typeMap)

  " Init the list of supported filetypes
  let s:supportedFileTypes = join(keys(s:typeMap), '$\|^')
  let s:supportedFileTypes = '^' . s:supportedFileTypes . '$'

  " setup the kind mappings for types that have member-types
  let s:adaKinds = { 'P': 'packspec', 'p': 'package', 'T': 'typespec', 't': 'type', 'U': 'subspec', 'u': 'subtype', 'c': 'component', 'l': 'literal', 'V': 'varspec', 'v': 'variable', 'n': 'constant', 'x': 'exception', 'f': 'formal', 'R': 'subprogspec', 'r': 'subprogram', 'K': 'taskspec', 'k': 'task', 'O': 'protectspec', 'o': 'protected', 'E': 'entryspec', 'e': 'entry', 'b': 'label', 'i': 'identifier', 'a': 'autovar', 'y': 'annon' }

  let s:cKinds = { 'c': 'class', 'g': 'enum', 'n': 'namespace', 's': 'struct', 'u': 'union' }

  " define the kinds which we can map in a hierarchical fashion
  let s:kindMap = { 'ada': s:adaKinds, 'c': s:cKinds, 'h': s:cKinds, 'cpp': s:cKinds }

endfunction " function! TagsParser#Init()
" >>>
" TagsParserPerlInit - Init the default type names using Perl <<<
function! TagsParser#PerlInit()
perl << PerlFunc
  use strict;
  use warnings;
  no warnings 'redefine';

  # Define the variables to be used for tag folding
  our $matchedTagWasFolded : unique = 0 unless($matchedTagWasFolded);
  our @matchedTagLines : unique = () unless(@matchedTagLines);

  # define the data needed for displaying the tag data, define it in
  # the order desired for parsing, and each entry has the key into the
  # tags hash, the title for those types, and what fold level to put it at
  # the default fold level is 3 which allows for something along the lines of
  # namespace->class->function()

  # if you define a new set of types, make sure to prefix the name with
  # a "- " string so that it will be picked up by the "Type" syntax
  my @adaTypes = ( [ "P", "- Package Specs" ],
                   [ "p", "- Packages" ],
                   [ "T", "- Type Specs" ],
                   [ "t", "- Types" ],
                   [ "U", "- Subtype Specs" ],
                   [ "u", "- Subtypes" ],
                   [ "c", "- Components" ],
                   [ "l", "- Literals" ],
                   [ "V", "- Variable Specs" ],
                   [ "v", "- Variables" ],
                   [ "n", "- Constants" ],
                   [ "x", "- Exceptions" ],
                   [ "f", "- Formal Params" ],
                   [ "R", "- Subprogram Specs" ],
                   [ "r", "- Subprograms" ],
                   [ "K", "- Task Specs" ],
                   [ "k", "- Tasks" ],
                   [ "O", "- Protected Data Specs" ],
                   [ "o", "- Protected Data" ],
                   [ "E", "- Entry Specs" ],
                   [ "e", "- Entries" ],
                   [ "b", "- Labels" ],
                   [ "i", "- Identifiers" ],
                   [ "a", "- Auto Vars" ],
                   [ "y", "- Blocks" ] );

  my @asmTypes = ( [ "d", "- Defines" ],
                   [ "t", "- Types" ],
                   [ "m", "- Macros" ],
                   [ "l", "- Labels" ] );

  my @aspTypes = ( [ "f", "- Functions" ],
                   [ "s", "- Subroutines" ],
                   [ "v", "- Variables" ] );

  my @awkTypes = ( [ "f", "- Functions" ] );

  my @betaTypes = ( [ "f", "- Fragment Defs" ],
                    [ "p", "- All Patterns" ],
                    [ "s", "- Slots" ],
                    [ "v", "- Patterns" ] );

  my @cTypes = ( [ "n", "- Namespaces" ],
                 [ "c", "- Classes" ],
                 [ "d", "- Macros" ],
                 [ "t", "- Typedefs" ],
                 [ "s", "- Structures" ],
                 [ "g", "- Enumerations" ],
                 [ "u", "- Unions" ],
                 [ "x", "- External Vars" ],
                 [ "v", "- Variables" ],
                 [ "p", "- Prototypes" ],
                 [ "f", "- Functions" ],
                 [ "m", "- Struct/Union Members" ],
                 [ "e", "- Enumerators" ],
                 [ "l", "- Local Vars" ] );

  my @csTypes = ( [ "c", "- Classes" ],
                  [ "d", "- Macros" ],
                  [ "e", "- Enumerators" ],
                  [ "E", "- Events" ],
                  [ "f", "- Fields" ],
                  [ "g", "- Enumerations" ],
                  [ "i", "- Interfaces" ],
                  [ "l", "- Local Vars" ],
                  [ "m", "- Methods" ],
                  [ "n", "- Namespaces" ],
                  [ "p", "- Properties" ],
                  [ "s", "- Structs" ],
                  [ "t", "- Typedefs" ] );

  my @cobolTypes = ( [ "d", "- Data Items" ],
                     [ "f", "- File Descriptions" ],
                     [ "g", "- Group Items" ],
                     [ "p", "- Paragraphs" ],
                     [ "P", "- Program IDs" ],
                     [ "s", "- Sections" ] );

  my @eiffelTypes = ( [ "c", "- Classes" ],
                      [ "f", "- Features" ],
                      [ "l", "- Local Entities" ] );

  my @erlangTypes = ( [ "d", "- Macro Defs" ],
                      [ "f", "- Functions" ],
                      [ "m", "- Modules" ],
                      [ "r", "- Record Defs" ] );

  my @fortranTypes = ( [ "b", "- Block Data" ],
                       [ "c", "- Common Blocks" ],
                       [ "e", "- Entry Points" ],
                       [ "f", "- Functions" ],
                       [ "i", "- Interface Contents/Names/Ops" ],
                       [ "k", "- Type/Struct Components" ],
                       [ "l", "- Labels" ],
                       [ "L", "- Local/Common/Namelist Vars" ],
                       [ "m", "- Modules" ],
                       [ "n", "- Namelists" ],
                       [ "p", "- Programs" ],
                       [ "s", "- Subroutines" ],
                       [ "t", "- Derived Types/Structs" ],
                       [ "v", "- Program/Module Vars" ] );

  my @htmlTypes = ( [ "a", "- Named Anchors" ],
                    [ "f", "- Javascript Funcs" ] );

  my @javaTypes = ( [ "c", "- Classes" ],
                    [ "f", "- Fields" ],
                    [ "i", "- Interfaces" ],
                    [ "l", "- Local Vars" ],
                    [ "m", "- Methods" ],
                    [ "p", "- Packages" ] );

  my @javascriptTypes = ( [ "f", "- Functions" ] );

  my @lispTypes = ( [ "f", "- Functions" ] );

  my @luaTypes = ( [ "f", "- Functions" ] );

  my @makeTypes = ( [ "m", "- Macros" ] );

  my @pascalTypes = ( [ "f", "- Functions" ],
                      [ "p", "- Procedures" ] );

  my @perlTypes = ( [ "c", "- Constants" ],
                    [ "l", "- Labels" ],
                    [ "s", "- Subroutines" ] );

  my @phpTypes = ( [ "c", "- Classes" ],
                   [ "d", "- Constants" ],
                   [ "f", "- Functions" ],
                   [ "v", "- Variables" ] );

  my @pythonTypes = ( [ "c", "- Classes" ],
                      [ "m", "- Class Members" ],
                      [ "f", "- Functions" ] );

  my @rexxTypes = ( [ "s", "- Subroutines" ] );

  my @rubyTypes = ( [ "c", "- Classes" ],
                    [ "f", "- Methods" ],
                    [ "F", "- Singleton Methods" ],
                    [ "m", "- Modules" ] );

  my @schemeTypes = ( [ "f", "- Functions" ],
                      [ "s", "- Sets" ] );

  my @shTypes = ( [ "f", "- Functions" ] );

  my @slangTypes = ( [ "f", "- Functions" ],
                     [ "n", "- Namespaces" ] );

  my @smlTypes = ( [ "e", "- Exception Defs" ],
                   [ "f", "- Function Defs" ],
                   [ "c", "- Functor Defs" ],
                   [ "s", "- Signatures" ],
                   [ "r", "- Structures" ],
                   [ "t", "- Type Defs" ],
                   [ "v", "- Value Bindings" ] );

  my @sqlTypes = ( [ "c", "- Cursors" ],
                   [ "d", "- Prototypes" ],
                   [ "f", "- Functions" ],
                   [ "F", "- Record Fields" ],
                   [ "l", "- Local Vars" ],
                   [ "L", "- Block Label" ],
                   [ "P", "- Packages" ],
                   [ "p", "- Procedures" ],
                   [ "r", "- Records" ],
                   [ "s", "- Subtypes" ],
                   [ "t", "- Tables" ],
                   [ "T", "- Triggers" ],
                   [ "v", "- Variables" ] );

  my @tclTypes = ( [ "c", "- Classes" ],
                   [ "m", "- Methods" ],
                   [ "p", "- Procedures" ] );

  my @veraTypes = ( [ "c", "- Classes" ],
                    [ "d", "- Macro Defs" ],
                    [ "e", "- Enumerators" ],
                    [ "f", "- Functions" ],
                    [ "g", "- Enumerations" ],
                    [ "l", "- Local Vars" ],
                    [ "m", "- Class/Struct/Union Members" ],
                    [ "p", "- Programs" ],
                    [ "P", "- Prototypes" ],
                    [ "t", "- Tasks" ],
                    [ "T", "- Typedefs" ],
                    [ "v", "- Variables" ],
                    [ "x", "- External Vars" ] );

  my @verilogTypes = ( [ "c", "- Constants" ],
                       [ "e", "- Events" ],
                       [ "f", "- Functions" ],
                       [ "m", "- Modules" ],
                       [ "n", "- Net Data Types" ],
                       [ "p", "- Ports" ],
                       [ "r", "- Register Data Types" ],
                       [ "t", "- Tasks" ] );

  my @vimTypes = ( [ "a", "- Autocommand Groups" ],
                   [ "f", "- Functions" ],
                   [ "v", "- Variables" ] );

  my @yaccTypes = ( [ "l", "- Labels" ] );

  our %typeMap : unique = ( ada => \@adaTypes,
                            asm => \@asmTypes,
                            asp => \@aspTypes,
                            awk => \@awkTypes,
                            beta =>  \@betaTypes,
                            c => \@cTypes,
                            cpp => \@cTypes,
                            cs => \@csTypes,
                            cobol => \@cobolTypes, 
                            eiffel => \@eiffelTypes, 
                            erlang => \@erlangTypes, 
                            fortran => \@fortranTypes, 
                            html => \@htmlTypes, 
                            java => \@javaTypes, 
                            javascript => \@javascriptTypes, 
                            lisp => \@lispTypes, 
                            lua => \@luaTypes, 
                            make => \@makeTypes,
                            pascal => \@pascalTypes, 
                            perl => \@perlTypes,
                            php => \@phpTypes, 
                            python => \@pythonTypes,
                            rexx => \@rexxTypes, 
                            ruby => \@rubyTypes,
                            scheme => \@schemeTypes, 
                            sh => \@shTypes, 
                            slang => \@slangTypes, 
                            sml => \@smlTypes, 
                            sql => \@sqlTypes, 
                            tcl => \@tclTypes,
                            vera => \@veraTypes, 
                            verilog => \@verilogTypes, 
                            Vim => \@vimTypes,
                            yacc => \@yaccTypes ) unless(%typeMap);

  # create a subtype hash, much like the typeMap.  This will list what
  # sub-types to display, so for example, C struct types will only have it's
  # "m" member list checked which will list the fields of that struct, while
  # namespaces can have all of the types listed in the @cType array.
  my %adaSubTypes  = ( i => \@adaTypes,
                       t => [ [ "c", "" ],
                              [ "l", "" ],
                              [ "a", "- Discriminants" ] ],
                       u => [ [ "c", "" ],
                              [ "l", "" ],
                              [ "a", "- Discriminants" ] ],
                       P => \@adaTypes,
                       p => \@adaTypes,
                       R => \@adaTypes,
                       r => \@adaTypes,
                       K => \@adaTypes,
                       k => \@adaTypes,
                       O => \@adaTypes,
                       o => \@adaTypes,
                       E => \@adaTypes,
                       e => \@adaTypes,
                       y => \@adaTypes );

  my %cSubTypes  = ( f => [ [ "l", "" ] ],
                     s => [ [ "m", "" ] ],
                     u => [ [ "m", "" ] ],
                     g => [ [ "e", "" ] ],
                     c => \@cTypes,
                     n => \@cTypes );

  our %subTypeMap : unique = ( ada => \%adaSubTypes,
                               c => \%cSubTypes,
                               cpp => \%cSubTypes ) unless(%subTypeMap);

  my $success = 0;
  my $value = 0;

  # Disable any languages which the user wants disabled
  foreach my $key (keys %typeMap) {
    ($success, $value) = VIM::Eval("exists('g:TagsParserDisableLang_$key')");
    delete $typeMap{$key} if ($success == 1 and $value == 1);
  }

  # Lastly, remove any headings that the user wants explicitly disabled
  foreach my $key (keys %typeMap) {
    my $typeRef;

    # now remove any unwanted types, start at the end of the list so that we
    # don't mess things up by deleting entries and changing the length of the
    # array
    for (my $i = @{$typeMap{$key}} - 1; $typeRef = $typeMap{$key}[$i]; $i--) {
      ($success, $value) = VIM::Eval("exists('g:TagsParserDisableType_" .
        $key . "_" . $typeRef->[0] . "')");
      splice(@{$typeMap{$key}}, $i, 1) if ($success == 1 and $value == 1);
    }
  }

  our %typeMapHeadingFold : unique = ( ) unless(%typeMapHeadingFold);

  # build up a list of any headings that the user wants to be automatically
  # folded
  foreach my $key (keys %typeMap) {
    my $typeRef;

    # loop through the headings, and add the actual heading pattern to the
    # heading fold structure
    for (my $i = 0; $typeRef = $typeMap{$key}[$i]; $i++) {
      ($success, $value) = VIM::Eval("exists('g:TagsParserFoldHeading_" .
        $key . "_" . $typeRef->[0] . "')");
      push(@{$typeMapHeadingFold{$key}}, $typeRef->[1]) if
        ($success == 1 and $value == 1);
    }
  }

  # Init the list of supported filetypes
  VIM::DoCommand "let s:supportedFileTypes = '" .
    join('$\|^', keys %typeMap) . "'";
  VIM::DoCommand "let s:supportedFileTypes = '^' . s:supportedFileTypes . '\$'";

  # setup the kind mappings for types that have member-types
  my %adaKinds = ( P => "packspec",
                   p => "package",
                   T => "typespec",
                   t => "type",
                   U => "subspec",
                   u => "subtype",
                   c => "component",
                   l => "literal",
                   V => "varspec",
                   v => "variable",
                   n => "constant",
                   x => "exception",
                   f => "formal",
                   R => "subprogspec",
                   r => "subprogram",
                   K => "taskspec",
                   k => "task",
                   O => "protectspec",
                   o => "protected",
                   E => "entryspec",
                   e => "entry",
                   b => "label",
                   i => "identifier",
                   a => "autovar",
                   y => "annon" );
  
  my %cKinds = ( c => "class",
                  g => "enum",
                  n => "namespace",
                  s => "struct",
                  u => "union" );

  # define the kinds which we can map in a hierarchical fashion
  our %kindMap : unique = ( ada => \%adaKinds,
                            c => \%cKinds,
                            h => \%cKinds,
                            cpp => \%cKinds ) unless(%kindMap);
PerlFunc
endfunction " function! TagsParser#PerlInit()
" >>>

" Global Variable Initialization <<<
"init the tag matching variable
let s:matchedTagLine = 0

"init the update values 
let s:tagsDataUpdated = 1
let s:lastFileDisplayed = ""

"init the buffer/window management values
let s:autoOpenCloseTurnedOff = 0
let s:closedBufName = ""
let s:curNumWindows = -1
let s:winLeaveBufName = ""
let s:newColumns = 0
let s:newLines = 0
let s:tagsWindowSize = 0

"based on The window position configuration variables, setup the tags window 
"split command
if g:TagsParserWindowLeft != 1 && g:TagsParserHorizontalSplit != 1
  let s:TagsWindowPosition = "botright vertical"
elseif g:TagsParserHorizontalSplit != 1
  let s:TagsWindowPosition = "topleft vertical"
elseif g:TagsParserWindowTop != 1
  let s:TagsWindowPosition = "botright"
else
  let s:TagsWindowPosition = "topleft"
endif

"if we are in the C:/WINDOWS/SYSTEM32 dir, change to C.  Odd things seem to
"happen if we are in the system32 directory
if has('win32') && getcwd() ==? 'C:\WINDOWS\SYSTEM32'
  let s:cwdChanged = 1
  cd C:\
else
  let s:cwdChanged = 0
endif

"Check to see if the current version of ctags has the "typeref" field, if it 
"does we must disable it.
if system(g:TagsParserTagsProgram . "--fields=-t") =~ "Unsupported parameter 't' for \"fields\" option"
  let s:ctagsFieldsOptions = "--fields=+nS"
else
  let s:ctagsFieldsOptions = "--fields=+nS-t"
endif

if s:cwdChanged == 1
  cd C:\WINDOWS\SYSTEM32
endif
" >>>

" Project Data Get Functions

" TagsParserGetProject - Returns the hash key for the current project <<<
" The current project is found by identifying all hash keys which match 
" a portion of the current working directory, the longest match is returned as 
" the current project key.
function! TagsParser#GetProject()
  call TagsParser#Debug(1, "TagsParser#GetProject()")
  " Init the match key to empty
  let l:matchKey = ""

  " Check the Vim version here, though this should never be called if the Vim 
  " version is not high enough.
  if v:version >=700 && exists("g:TagsParserProjectConfig")
    let l:matchPrj = {}

    " Build up a list of all project possibilities... If this is windows then 
    " do a case insensitive comparison.
    if has("win32")
      let l:matchPrj = filter(copy(g:TagsParserProjectConfig), 'glob(v:key) ==? getcwd()[0:len(glob(v:key)) - 1]')
    else
      let l:matchPrj = filter(copy(g:TagsParserProjectConfig), 'glob(v:key) ==# getcwd()[0:len(glob(v:key)) - 1]')
    endif

    let l:matchLen = 0

    " Now find the most accurate match
    for l:key in keys(l:matchPrj)
      if len(l:key) > l:matchLen
        let l:matchLen = len(l:key)
        let l:matchKey = l:key
      endif
    endfor " for l:key in keys(l:matchPrj)
  endif " if v:version >=700 && exists("g:TagsParserProjectConfig")

  call TagsParser#Debug(1, "TagsParser#GetProject() = " . l:matchKey)
  return l:matchKey
endfunction " function TagsParser#GetProject()
" >>>
" TagsParserGetTagsPath - Returns the current applicable TagsPath <<<
" If there is a project that matches the current working directory then the 
" project.tagsPath is returned, if it exists.  If it does not exist, but the 
" project exists then the global TagsParserTagsPath is returned.  If there is 
" no applicable project, but the TagsParserProjectConfig is configured then an 
" empty string is returned to indicate that the requested function should not 
" be running for files in the current working directory.  If the 
" TagsParserProjectConfig is not configured then the global TagsParserTagsPath 
" is returned.
function! TagsParser#GetTagsPath(prjKey)
  call TagsParser#Debug(1, "TagsParser#GetTagsPath(" . a:prjKey . ")")
  " Setup the default return data, this is just the global config 
  let l:data = g:TagsParserTagsPath

  " Make sure that the Vim version can do this and that a project config is 
  " defined.
  if v:version >= 700 && exists("g:TagsParserProjectConfig")
    if a:prjKey != "" 
      " Only set the data to the project value if it exists, otherwise the 
      " default config value will be returned.
      if exists("g:TagsParserProjectConfig[a:prjKey].tagsPath")
        let l:data = g:TagsParserProjectConfig[a:prjKey].tagsPath

        " Check for a + as the first character of the returned data.  If it is 
        " then the default TagsPath should be prepended to this project data.
        if l:data[0] == '+' && len(l:data) > 1
          let l:data = g:TagsParserTagsPath . l:data[1:-1]
        endif
      endif " if exists("g:TagsParserProjectConfig[a:prjKey].tagsPath")
    else
      " If the project does not exist, return an empty string
      let l:data = ""
    endif " if a:prjKey != "" 
  endif " if v:version >= 700 && exists("g:TagsParserProjectConfig")

  " Now return the data
  call TagsParser#Debug(1, "TagsParser#GetTagsPath() = " . l:data)
  return l:data
endfunction " function TagsParser#GetTagsPath()
" >>>
" TagsParserGetTagsLib - Returns the current TagsLib <<<
" If there is a project that matches the current working directory then the 
" project.tagsLib is returned, if it exists.  If it does not exist, but the 
" project exists then the global TagsParserTagsLib is returned.  If there is 
" no applicable project, but the TagsParserProjectConfig is configured then an 
" empty string is returned to indicate that the requested function should not 
" be running for files in the current working directory.  If the 
" TagsParserProjectConfig is not configured then the global TagsParserTagsLib 
" is returned.
function! TagsParser#GetTagsLib(prjKey)
  call TagsParser#Debug(1, "TagsParser#GetTagsLib(" . a:prjKey . ")")
  " Setup the default return data, this is just the global config 
  let l:data = g:TagsParserTagsLib

  " Make sure that the Vim version can do this and that a project config is 
  " defined.
  if v:version >= 700 && exists("g:TagsParserProjectConfig")
    if a:prjKey != "" 
      " Only set the data to the project value if it exists, otherwise the 
      " default config value will be returned.
      if exists("g:TagsParserProjectConfig[a:prjKey].tagsLib")
        let l:data = g:TagsParserProjectConfig[a:prjKey].tagsLib

        " Check for a + as the first character of the returned data.  If it is 
        " then the default TagsLib should be prepended to this project data.
        if l:data[0] == '+' && len(l:data) > 1
          let l:data = g:TagsParserTagsLib . l:data[1:-1]
        endif
      endif " if exists("g:TagsParserProjectConfig[a:prjKey].tagsLib")
    else
      " If the project does not exist, return an empty string
      let l:data = ""
    endif " if a:prjKey != "" 
  endif " if v:version >= 700 && exists("g:TagsParserProjectConfig")

  " Now return the data
  call TagsParser#Debug(1, "TagsParser#GetTagsLib() = " . l:data)
  return l:data
endfunction
" >>>
" TagsParserGetQualifiedTagSeparator - Returns the QualifiedTagSeparator <<<
" If there is a project that matches the current working directory then the 
" project.qualifiedTagSeparator is returned, if it exists.  If it does not 
" exist, but the project exists then the global 
" TagsParserCtagsQualifiedTagSeparator is returned.  If there is no applicable 
" project, but the TagsParserProjectConfig is configured then an empty string 
" is returned to indicate that the requested function should not be running 
" for files in the current working directory.  If the TagsParserProjectConfig 
" is not configured then the global TagsParserCtagsQualifiedTagSeparator is 
" returned.
function! TagsParser#GetQualifiedTagSeparator(prjKey)
  call TagsParser#Debug(1, "TagsParser#GetQualifiedTagSeparator(" . a:prjKey . ")")
  " Setup the default return data, this is just the global config 
  let l:data = g:TagsParserCtagsQualifiedTagSeparator

  " Make sure that the Vim version can do this and that a project config is 
  " defined.
  if v:version >= 700 && exists("g:TagsParserProjectConfig")
    if a:prjKey != "" 
      " Only set the data to the project value if it exists, otherwise the 
      " default config value will be returned.
      if exists("g:TagsParserProjectConfig[a:prjKey].qualifiedTagSeparator")
        let l:data = g:TagsParserProjectConfig[a:prjKey].qualifiedTagSeparator

        " Check for a + as the first character of the returned data.  If it is 
        " then the default QualifiedTagSeparator should be prepended to this 
        " project data.
        if l:data[0] == '+' && len(l:data) > 1
          let l:data = g:TagsParserCtagsQualifiedTagSeparator . l:data[1:-1]
        endif
      endif " if exists("g:TagsParserProjectConfig[a:prjKey]. ...
    else
      " If the project does not exist, return an empty string
      let l:data = ""
    endif " if a:prjKey != "" 
  endif " if v:version >= 700 && exists("g:TagsParserProjectConfig")

  " Now return the data
  call TagsParser#Debug(1, "TagsParser#GetQualifiedTagSeparator() = " . l:data)
  return l:data
endfunction
" >>>
" TagsParserGetDirExcludePattern - Returns the current DirExcludePattern <<<
" If there is a project that matches the current working directory then the 
" project.dirExcludePattern is returned, if it exists.  If it does not exist, 
" but the project exists then the global TagsParserDirExcludePattern is 
" returned.  If there is no applicable project, but the 
" TagsParserProjectConfig is configured then an empty string is returned to 
" indicate that the requested function should not be running for files in the 
" current working directory.  If the TagsParserProjectConfig is not configured 
" then the global TagsParserDirExcludePattern is returned.
function! TagsParser#GetDirExcludePattern(prjKey)
  call TagsParser#Debug(1, "TagsParser#GetDirExcludePattern(" . a:prjKey . ")")
  " Setup the default return data, this is just the global config 
  let l:data = g:TagsParserDirExcludePattern

  " Make sure that the Vim version can do this and that a project config is 
  " defined.
  if v:version >= 700 && exists("g:TagsParserProjectConfig")
    if a:prjKey != "" 
      " Only set the data to the project value if it exists, otherwise the 
      " default config value will be returned.
      if exists("g:TagsParserProjectConfig[a:prjKey].dirExcludePattern")
        let l:data = g:TagsParserProjectConfig[a:prjKey].dirExcludePattern

        " Check for a + as the first character of the returned data.  If it is 
        " then the default DirExcludePattern should be prepended to this 
        " project data.
        if l:data[0] == '+' && len(l:data) > 1
          let l:data = g:TagsParserDirExcludePattern . l:data[1:-1]
        endif
      endif " if exists("g:TagsParserProjectConfig[a:prjKey]. ...
    else
      " If the project does not exist, return an empty string
      let l:data = ""
    endif " if a:prjKey != "" 
  endif " if v:version >= 700 && exists("g:TagsParserProjectConfig")

  " Now return the data
  call TagsParser#Debug(1, "TagsParser#GetDirExcludePattern() = " . l:data)
  return l:data
endfunction
" >>>
" TagsParserGetDirIncludePattern - Returns the current DirIncludePattern <<<
" If there is a project that matches the current working directory then the 
" project.dirIncludePattern is returned, if it exists.  If it does not exist, 
" but the project exists then the global TagsParserDirIncludePattern is 
" returned.  If there is no applicable project, but the 
" TagsParserProjectConfig is configured then an empty string is returned to 
" indicate that the requested function should not be running for files in the 
" current working directory.  If the TagsParserProjectConfig is not configured 
" then the global TagsParserDirIncludePattern is returned.
function! TagsParser#GetDirIncludePattern(prjKey)
  call TagsParser#Debug(1, "TagsParser#GetDirIncludePattern(" . a:prjKey . ")")
  " Setup the default return data, this is just the global config 
  let l:data = g:TagsParserDirIncludePattern

  " Make sure that the Vim version can do this and that a project config is 
  " defined.
  if v:version >= 700 && exists("g:TagsParserProjectConfig")
    if a:prjKey != "" 
      " Only set the data to the project value if it exists, otherwise the 
      " default config value will be returned.
      if exists("g:TagsParserProjectConfig[a:prjKey].dirIncludePattern")
        let l:data = g:TagsParserProjectConfig[a:prjKey].dirIncludePattern

        " Check for a + as the first character of the returned data.  If it is 
        " then the default DirIncludePattern should be prepended to this 
        " project data.
        if l:data[0] == '+' && len(l:data) > 1
          let l:data = g:TagsParserDirIncludePattern . l:data[1:-1]
        endif
      endif " if exists("g:TagsParserProjectConfig[a:prjKey]. ...
    else
      " If the project does not exist, return an empty string
      let l:data = ""
    endif " if a:prjKey != "" 
  endif " if v:version >= 700 && exists("g:TagsParserProjectConfig")

  " Now return the data
  call TagsParser#Debug(1, "TagsParser#GetDirIncludePattern() = " . l:data)
  return l:data
endfunction
" >>>
" TagsParserGetFileExcludePattern - Returns the current FileExcludePattern <<<
" If there is a project that matches the current working directory then the 
" project.fileExcludePattern is returned, if it exists.  If it does not exist, 
" but the project exists then the global TagsParserFileExcludePattern is 
" returned.  If there is no applicable project, but the 
" TagsParserProjectConfig is configured then an empty string is returned to 
" indicate that the requested function should not be running for files in the 
" current working directory.  If the TagsParserProjectConfig is not configured 
" then the global TagsParserFileExcludePattern is returned.
function! TagsParser#GetFileExcludePattern(prjKey)
  call TagsParser#Debug(1, "TagsParser#GetFileExcludePattern(" . a:prjKey . ")")
  " Setup the default return data, this is just the global config 
  let l:data = g:TagsParserFileExcludePattern

  " Make sure that the Vim version can do this and that a project config is 
  " defined.
  if v:version >= 700 && exists("g:TagsParserProjectConfig")
    if a:prjKey != "" 
      " Only set the data to the project value if it exists, otherwise the 
      " default config value will be returned.
      if exists("g:TagsParserProjectConfig[a:prjKey].fileExcludePattern")
        let l:data = g:TagsParserProjectConfig[a:prjKey].fileExcludePattern

        " Check for a + as the first character of the returned data.  If it is 
        " then the default FileExcludePattern should be prepended to this 
        " project data.
        if l:data[0] == '+' && len(l:data) > 1
          let l:data = g:TagsParserFileExcludePattern . l:data[1:-1]
        endif
      endif " if exists("g:TagsParserProjectConfig[a:prjKey]. ...
    else
      " If the project does not exist, return an empty string
      let l:data = ""
    endif " if a:prjKey != "" 
  endif " if v:version >= 700 && exists("g:TagsParserProjectConfig")

  " Now return the data
  call TagsParser#Debug(1, "TagsParser#GetFileExcludePattern() = " . l:data)
  return l:data
endfunction
" >>>
" TagsParserGetFileIncludePattern - Returns the current FileIncludePattern <<<
" If there is a project that matches the current working directory then the 
" project.fileIncludePattern is returned, if it exists.  If it does not exist, 
" but the project exists then the global TagsParserFileIncludePattern is 
" returned.  If there is no applicable project, but the 
" TagsParserProjectConfig is configured then an empty string is returned to 
" indicate that the requested function should not be running for files in the 
" current working directory.  If the TagsParserProjectConfig is not configured 
" then the global TagsParserFileIncludePattern is returned.
function! TagsParser#GetFileIncludePattern(prjKey)
  call TagsParser#Debug(1, "TagsParser#GetFileIncludePattern(" . a:prjKey . ")")
  " Setup the default return data, this is just the global config 
  let l:data = g:TagsParserFileIncludePattern

  " Make sure that the Vim version can do this and that a project config is 
  " defined.
  if v:version >= 700 && exists("g:TagsParserProjectConfig")
    if a:prjKey != "" 
      " Only set the data to the project value if it exists, otherwise the 
      " default config value will be returned.
      if exists("g:TagsParserProjectConfig[a:prjKey].fileIncludePattern")
        let l:data = g:TagsParserProjectConfig[a:prjKey].fileIncludePattern

        " Check for a + as the first character of the returned data.  If it is 
        " then the default FileIncludePattern should be prepended to this 
        " project data.
        if l:data[0] == '+' && len(l:data) > 1
          let l:data = g:TagsParserFileIncludePattern . l:data[1:-1]
        endif
      endif " if exists("g:TagsParserProjectConfig[a:prjKey]. ...
    else
      " If the project does not exist, return an empty string
      let l:data = ""
    endif " if a:prjKey != "" 
  endif " if v:version >= 700 && exists("g:TagsParserProjectConfig")

  " Now return the data
  call TagsParser#Debug(1, "TagsParser#GetFileIncludePattern() = " . l:data)
  return l:data
endfunction
" >>>

" Functions

" TagsParserPerformOp - Checks that The current file is in the tag path <<<
" Based on the input, it will either open the tag window or tag the file.
" For either op, it will make sure that the current file is within the
" g:TagsParserTagsPath path, and then perform some additional checks based on
" the operation it is supposed to perform
function! TagsParser#PerformOp(op, file)
  call TagsParser#Debug(1, "TagsParser#PerformOp(" . a:op . ", " . a:file . ")")
  if a:file == ""
    let l:pathName = expand("%:p:h")
    let l:fileName = expand("%:t")
    let l:curFile = expand("%:p")
  else
    let l:pathName = fnamemodify(a:file, ":p:h")
    let l:fileName = fnamemodify(a:file, ":t")
    let l:curFile = fnamemodify(a:file, ":p")
  endif

  call TagsParser#Debug(4, "path = " . l:pathName)
  call TagsParser#Debug(4, "file (short) = " . l:fileName)
  call TagsParser#Debug(4, "file = " . l:curFile)

  "Make sure that the file we are working on is _not_ a directory
  if isdirectory(l:curFile)
    return
  endif

  " Get the critical data first.
  let l:prjKey = TagsParser#GetProject()
  let l:tagsPath = TagsParser#GetTagsPath(l:prjKey)

  "If this is windows change the backslashes to slashes in the path so that 
  "the dir exclude and include patterns will work over multiple directories
  if has('win32')
    let l:pathName = substitute(l:pathName, '\', '/', 'g')
  endif

  " Before we do anything, if the operation is "auto", and the current file is 
  " not withing a valid project path, or the tag file is not readable, and so 
  " on, then close the tag window.  Or if the operation is "deletetag" and the 
  " file exists, but the current tag path is empty, delete the tag file.  And 
  " then quit.
  if (a:op == "auto" && g:TagsParserAutoOpenClose == 1) && (l:tagsPath == "" || filereadable(l:pathName . "/" . g:TagsParserTagsDir . "/" .  substitute(l:fileName, " ", "_", "g") . ".tags") == 0 && &filetype =~ s:supportedFileTypes)
    call TagsParser#CloseTagWindow("close")
    return
  elseif a:op == "deletetag" && l:tagsPath == "" && filereadable(l:pathName . "/" . g:TagsParserTagsDir . "/" .  substitute(l:fileName, " ", "_", "g") . ".tags") != 0
    call delete(l:pathName . "/" . g:TagsParserTagsDir . "/" .  substitute(l:fileName, " ", "_", "g") . ".tags")
    return
  endif

  "Now, since we are continuing, get the rest of the project data.
  let l:dirExcludePattern = TagsParser#GetDirExcludePattern(l:prjKey)
  let l:dirIncludePattern = TagsParser#GetDirIncludePattern(l:prjKey)
  let l:fileExcludePattern = TagsParser#GetFileExcludePattern(l:prjKey)
  let l:fileIncludePattern = TagsParser#GetFileIncludePattern(l:prjKey)

  "before we check to see if this file is in within TagsParserTagsPath, do the 
  "simple checks to see if this file name and/or path meet the include or
  "exclude criteria
  "The general logic here is, if the pattern is not empty (therefore not
  "disabled), and an exclude pattern matches, or an include pattern fails to 
  "match, return early.
  if (l:dirExcludePattern != "" && l:pathName =~ l:dirExcludePattern) || (l:fileExcludePattern != "" && l:fileName =~ l:fileExcludePattern) || (l:dirIncludePattern != "" && l:pathName !~ l:dirIncludePattern) || (l:fileIncludePattern != "" && l:fileName !~ l:fileIncludePattern)
    return
  endif

  if l:tagsPath != ""
    let l:tagPathFileMatch = globpath(l:tagsPath, l:fileName)
  
    " Put the path, and file into lowercase if this is windows... Since 
    " windows filenames are case-insensitive.
    if has('win32')
      let l:curFile = tolower(l:curFile)
      let l:tagPathFileMatch = tolower(l:tagPathFileMatch)
    endif

    " See if the file is within the current path
    if stridx(l:tagPathFileMatch, l:curFile) != -1
      if a:op == "tag"
        call TagsParser#TagFile(a:file)
      elseif (a:op == "open" || a:op == "auto") && g:TagsParserAutoOpenClose == 1 && filereadable(l:pathName . "/" . g:TagsParserTagsDir . "/" .  substitute(l:fileName, " ", "_", "g") . ".tags") && &filetype =~ s:supportedFileTypes
        call TagsParser#OpenTagWindow()
      endif
    endif " if stridx(l:tagPathFileMatch, l:curFile) != -1
  endif " if l:tagsPath != ""
endfunction " function! TagsParser#PerformOp(op, file)
" >>>
" TagsParserTagFile - Runs tags on a file and names The tag file <<<
" this function will run Ctags for a file and write it to 
" ./<tagDir>/<file>.tags it will also create the ./<tagDir> directory if it 
" doesn't exist
function! TagsParser#TagFile(file)
  call TagsParser#Debug(1, "TagsParser#TagFile(" . a:file . ")")
  "if the file argument is empty, make it the current file with fully
  "qualified path
  if a:file == ""
    let l:fileName = expand("%:p")

    "gather any user options that may be defined
    if exists("g:TagsParserCtagsOptions_{&filetype}")
      let l:userOptions = g:TagsParserCtagsOptions_{&filetype}
    else
      let l:userOptions = ""
    endif
  else
    let l:fileName = a:file
    let l:userOptions = ""

    "check the list of types that options are defined for, if a filetype is in 
    "the list, and the g:TagsParserCtagsOptions_{type} variable exists, append 
    "it to the userOptions string.  But only do this if the vim version is 7.0 
    "or greater.
    if v:version >= 700 && g:TagsParserForceUsePerl != 1
      for l:type in g:TagsParserCtagsOptionsTypeList
        if exists("g:TagsParserCtagsOptions_{l:type}")
          let l:userOptions = l:userOptions . g:TagsParserCtagsOptions_{l:type} . " "
        endif
      endfor
    endif " if v:version >= 700 && g:TagsParserForceUsePerl != 1
  endif " if a:file == ""

  "cleanup the tagfile, regular file and directory names, we have to replace
  "spaces in the actual file name with underscores for the tag file, or else
  "the sort option throws an error for some reason
  let l:baseDir = substitute(fnamemodify(l:fileName, ":h"), '\', '/', 'g')
  let l:tagDir = substitute(fnamemodify(l:fileName, ":h") . "/" . g:TagsParserTagsDir, '\', '/', 'g')
  let l:tagFileName = substitute(fnamemodify(l:fileName, ":h") . "/" . g:TagsParserTagsDir . "/" . fnamemodify(l:fileName, ":t") . ".tags", '\', '/', 'g')
  let l:fileName = substitute(l:fileName, '\', '/', 'g')

  "Before writing this tag file, make sure that it has been long enough since 
  "the tag file was last saved, if it has not been long enough, just exit this 
  "function.
  if (getftime(l:tagFileName) + g:TagsParserSaveInterval) > localtime()
    return
  endif

  "make the <tagDir> directory if it doesn't exist yet
  if !isdirectory(l:tagDir)
    call system("mkdir \"" . l:tagDir . "\"")
    let l:noTagFile = "true"
  elseif !filereadable(l:tagFileName)
    let l:noTagFile = "true"
  else 
    let l:noTagFile = "false"
  endif
  
  "if we are in the C:/WINDOWS/SYSTEM32 dir, change to C.  Odd things seem to
  "happen if we are in the system32 directory
  if has('win32') && getcwd() ==? 'C:\WINDOWS\SYSTEM32'
    let s:cwdChanged = 1
    cd C:\
  else
    let s:cwdChanged = 0
  endif

  "now run the tags program
  call system(g:TagsParserTagsProgram . " -f \"" . l:tagFileName . "\" " . g:TagsParserCtagsOptions . " " . l:userOptions . " --format=2 --extra=+q --excmd=p " . s:ctagsFieldsOptions . " --sort=yes --tag-relative=yes \"" . l:fileName . "\"")

  if s:cwdChanged == 1
    cd C:\WINDOWS\SYSTEM32
  endif

  if filereadable(l:tagFileName)
    let l:tagFileExists = "true"
  else
    let l:tagFileExists = "false"
  endif

  "if this file did not have a <tagDir>/*.tags file up until this point and
  "now it does call TagsParserExpandTagsPath to get the new file included
  if l:noTagFile == "true" && l:tagFileExists == "true"
    call TagsParser#ExpandTagsPath()
  endif
endfunction " function! TagFile(file)
" >>>
" TagsParserExpandTagsPath - Expands a directory into a list of tags <<< 
" This will expand The g:TagsParserTagsPath directory list into valid tag
" files
function! TagsParser#ExpandTagsPath()
  call TagsParser#Debug(1, "TagsParser#ExpandTagsPath()")
  if !exists("s:OldTagsPath")
    let s:OldTagsPath = &tags
  endif

  let l:prjKey = TagsParser#GetProject()
  let l:tagsPath = TagsParser#GetTagsPath(l:prjKey)
  let l:tagsLib = TagsParser#GetTagsLib(l:prjKey)

  if l:tagsPath != ""
    " for the tags path we must make sure that all \'s are turned into /'s.  
    " Additionally, if there are any spaces they must be escaped by a \.
    let &tags = substitute(substitute(join(split(globpath(l:tagsPath, g:TagsParserTagsDir . '/*.tags'), '\n'), ","), '\', '/', 'g'), ' ', '\\ ', 'g') . "," . l:tagsLib
  else
    " If there is not TagsPath set then just reinstate the default Vim tags 
    " setting.
    let &tags = s:OldTagsPath
  endif " if l:tagsPath != ""
endfunction " function! TagsParser#ExpandTagsPath()
" >>>
" TagsParserSetupDirectoryTags - creates tags for all files in this dir <<<
" This takes a directory as a parameter and creates tag files for all files
" under this directory based on The same include/exclude rules that are used
" when a file is written out.  Except that this function does not need to
" follow the TagsParserPath rules.
function! TagsParser#SetupDirectoryTags(dir)
  call TagsParser#Debug(1, "TagsParser#SetupDirectoryTags(" . a:dir . ")")
  "if the TagsParserOff flag is set, print out an error and do nothing
  if g:TagsParserOff != 0
    echomsg "TagsParser cannot tag files in this directory because plugin is turned off"
    return
  endif

  "make sure that a:dir does not contain \ but contains /
  let l:dir = substitute(expand(a:dir), '\', '/', "g")

  "If the direcory passed in contains a / at the end of it, remove it.
  if l:dir[-1] == "/"
    call remove(l:dir, -1)
  endif

  if !isdirectory(l:dir)
    echomsg "Directory provided : " . l:dir . " is not a valid directory"
    return
  endif

  "If this is a valid directory cd to it so that the correct project config 
  "can be detected.  Save the current directory first so that we can return to 
  "it later.
  let l:cwd = getcwd()
  silent exec TagsParser#Exec("cd " . l:dir)

  "find all files in this directory and all subdirectories
  let l:fileList = globpath(l:dir . '/**,' . l:dir, '*')

  "now parse those into separate files using Perl and then call the
  "TagFile for each file to give it a tag list
  if v:version >= 700 && g:TagsParserForceUsePerl != 1
    for l:file in split(l:fileList, '\n')
      call TagsParser#PerformOp('tag', l:file)
    endfor
  else
    call TagsParser#PerlFinishPerformOp(l:fileList)
  endif

  "Return to the previous current directory
  silent exec TagsParser#Exec("cd " . l:cwd)
endfunction " function! TagsParser#SetupDirectoryTags(dir)
" >>>
" TagsParserDisplayEntry - Used to recursively display tag information <<<
function! TagsParser#DisplayEntry(entry)
  call TagsParser#Debug(1, "TagsParser#DisplayEntry(" . a:entry.tag . ")")
  " set the display string, tag or signature
  if g:TagsParserDisplaySignature == 1
    let l:dispString = a:entry.pattern
    " remove all whitespace from the beginning and end of the display 
    " string
    call substitute(l:dispString, '^\s*\(.*\)\s\*$', '\1', 'g')
  else
    let l:dispString = a:entry.tag
  endif

  " each tag must have a {{{ at the end of it or else it could mess with 
  " the folding... Since there are no end folds each tag must have a fold 
  " marker
  call add(s:printData, [ repeat("\t", s:printLevel) . l:dispString . ' {{{' . (s:printLevel + 1), a:entry ])

  " now print any members there might be
  if exists('a:entry.members') && exists('s:subTypeMap[s:origFileType][a:entry.tagtype]')
    let s:printLevel += 1

    " now print any members that this entry may have, only show types 
    " which make sense, so for a "s" entry only display "m", this is based 
    " on the subTypeMap data.
    for l:subTypeRef in s:subTypeMap[s:origFileType][a:entry.tagtype]
      " for each entry in the subTypeMap for this particular entry, check 
      " if there are any entries, if there are print them
      if exists('a:entry.members[l:subTypeRef[0]]')
        " display a header (if one exists)
        if l:subTypeRef[1] != ""
          call add(s:printData, [ repeat("\t", s:printLevel) . l:subTypeRef[1] . ' {{{' . (s:printLevel + 1) ])
          let s:printLevel += 1
        endif

        " display the data for this sub type, sort them properly based
        " on the global flag
        if g:TagsParserSortType == "alpha"
          for l:member in sort(a:entry.members[l:subTypeRef[0]], "TagsParser#TagSort")
            call TagsParser#DisplayEntry(l:member)
          endfor
        else
          for l:member in sort(a:entry.members[l:subTypeRef[0]], "TagsParser#LineSort")
            call TagsParser#DisplayEntry(l:member)
          endfor
        endif " if g:TagsParserSortType == "alpha"

        " reduce the print level if we increased it earlier and print 
        " a fold end marker
        if l:subTypeRef[1] != ""
          let s:printLevel -= 1
        endif
      endif " if exists('a:entry.members[l:subTypeRef[0]]')
    endfor " for l:subTypeRef in s:subTypeMap[s:origFileType][a:entry.tagtype]

    let s:printLevel -= 1
  endif " if exists('a:entry.members') && exists('s:subTypeMap[...
endfunction " function DisplayEntry(entry)
" >>>
" TagsParserDisplayTags - This will display The tags for the current file <<<
function! TagsParser#DisplayTags()
  call TagsParser#Debug(1, "TagsParser#DisplayTags()")
  "For some reason the ->Append(), ->Set() and ->Delete() functions don't
  "work unless the Perl buffer object is the current buffer... So, change
  "to the tags buffer.
  let l:tagBufNum = bufnr(TagsParser#WindowName())
  if l:tagBufNum == -1
    return
  endif

  let l:curBufNum = bufnr("%")

  "now change to the tags window if the two buffers are not the same
  if l:curBufNum != l:tagBufNum
    "if we were not originally in the tags window, we need to save the
    "filetype before we move, otherwise the calling function will have saved
    "it for us
    let s:origFileType = &filetype
    let s:origFileName = expand("%:t")
    let s:origFileTagFileName = expand("%:p:h") . "/" . g:TagsParserTagsDir . "/" . expand("%:t") . ".tags"
    exec TagsParser#Exec(bufwinnr(l:tagBufNum) . "wincmd w")
  endif

  "before we start drawing the tags window, check for the update flag, and
  "make sure that the filetype we are attempting to display is supported
  if s:tagsDataUpdated == 0 && s:lastFileDisplayed == s:origFileName ||
        \ s:origFileType !~ s:supportedFileTypes
    "we must return to the previous window before we can just exit
    if l:curBufNum != l:tagBufNum
      exec TagsParser#Exec(bufwinnr(s:origFileName) . "wincmd w")
    endif

    return
  endif

  "before we start editing the contents of the tags window we need to make
  "sure that the tags window is modifiable
  setlocal modifiable

  if v:version >= 700 && g:TagsParserForceUsePerl == 0
    " make sure that s:tags is created
    if !exists('s:tags')
      let s:tags = { }
    endif

    " temp array to store our tag info... At the end of the file we will check
    " to see if this is different than the globalPrintData, if it is we update
    " the screen, if not then we do nothing so as to maintain any folded 
    " sections the user has created.
    let s:printData = [ ]
    let s:printLevel = 0

    " at the very top, print out the filename and a blank line
    call add(s:printData, [ s:origFileName . ' {{{' . (s:printLevel + 1) ] )
    call add(s:printData, [ "" ])
    let s:printLevel += 1

    for l:ref in s:typeMap[s:origFileType]
      " verify that there are any entries defined for this particular tag type 
      " before we start trying to print them and that they don't have a parent 
      " tag.
      let l:printTopLevelType = 0
      if exists('s:tags[s:origFileTagFileName][l:ref[0]]')
        for l:typeCheckRef in s:tags[s:origFileTagFileName][l:ref[0]]
          if !exists('l:typeCheckRef.parent')
            let l:printTopLevelType = 1
          endif
        endfor
      endif

      if l:printTopLevelType == 1
        call add(s:printData, [ repeat("\t", s:printLevel) . l:ref[1] . ' {{{' . (s:printLevel + 1) ])
    
        let s:printLevel += 1
        " now display all the tags for this particular type, and sort them 
        " according to the sortType
        if g:TagsParserSortType == "alpha"
          for l:tagRef in sort(s:tags[s:origFileTagFileName][l:ref[0]], "TagsParser#TagSort")
            if !exists('l:tagRef.parent')
              call TagsParser#DisplayEntry(l:tagRef)
            endif
          endfor
        else
          for l:tagRef in sort(s:tags[s:origFileTagFileName][l:ref[0]], "TagsParser#LineSort")
            if !exists('l:tagRef.parent')
              call TagsParser#DisplayEntry(l:tagRef)
            endif
          endfor
        endif " if g:TagsParserSortType == "alpha"

        let s:printLevel -= 1
        " between each listing put a line
        call add(s:printData, [ "" ])
      endif " if l:printTopLevelType == 1
    endfor " for l:ref in s:typeMap[s:origFileType]

    " this hash will be used to keep all of the data referenceable... So that 
    " we will be able to print the correct information, reach that info when 
    " the tag is to be selected, and find the current tag that the cursor is 
    " on in the main window
    if !exists('s:globalPrintData')
      let s:globalPrintData = [ ]
    endif

    " check to see if the data has changed
    let l:update = 1
    if s:lastFileDisplayed != "" && len(s:printData) == len(s:globalPrintData)
      let l:update = 0

      let l:index = 0
      while l:index < len(s:globalPrintData)
        if s:printData[l:index][0] != s:globalPrintData[l:index][0]
          let l:update = 1
        endif

        " no matter if the display data changed or not, make sure to assign
        " the tag reference to the global data... Otherwise things like line 
        " numbers may have changed and the tag window would not have the 
        " proper data.
        if exists('s:printData[l:index][1]')
          let s:globalPrintData[l:index][1] = s:printData[l:index][1]
        endif

        let l:index += 1
      endwhile " while l:index < len(s:globalPrintData)
    endif " if s:lastFileDisplayed != "" && len(s:printData) == len(...

    " if the data did not change, do nothing and quit, but if it did get 
    " updated, display the new data.
    if l:update == 1
      " If the data has changed, be sure to reset the fold data.
      let s:matchedTagWasFolded = 0
      let s:matchedTagLines = []

      let s:globalPrintData = copy(s:printData)

      " first clean the window, using the "_ register to prevent the text from 
      " being collected into the "" register.
      " note - % or 1,$ ranges cannot be used because they seem to pickup 
      " incorrect values for the last line number
      exec TagsParser#Exec("1," . line("$") . ":delete _")

      " then set the first line
      call setline(0, "")

      " lastly append the rest of the data into the window
      for l:line in reverse(s:printData)
        call append(1, l:line[0])
      endfor
    endif " if l:update == 1

    " if the fold level is not set, go through the window now and fold any 
    " tags that have members
    if !exists('g:TagsParserFoldLevel') || g:TagsParserFoldLevel == 0
      let l:foldLevel = -1
    else
      let l:foldLevel = g:TagsParserFoldLevel
    endif

    if !exists('s:typeMapHeadingFold')
      let s:typeMapHeadingFold = { }
    endif

    " in the perl version there is a "FOLD_LOOP:" label here, and to terminate 
    " the following loop early it simply does a "next FOLD_LOOP;".  Vim does 
    " not have such devices so I enclose the loop in a try block and will just 
    " throw an error if the loop can be abandoned early.  This loop is 
    " repeated twice, once for all normal folding, and then a second time for 
    " heading folding.
    let l:index = 0
    while l:index < len(s:globalPrintData)
      try " FOLD_LOOP
        let l:line = s:globalPrintData[l:index]
        " if this is a tag that has a parent and members, and is not already 
        " folded, fold it.
        if l:foldLevel == -1 && exists('l:line[1].members')
          if exists('l:line[1].parent') && foldclosed(l:index + 2) == -1
            exec TagsParser#Exec(l:index + 2 . "foldclose")
          else
            for l:memberKey in keys(l:line[1].members)
              for l:possibleType in s:subTypeMap[s:origFileType][l:line[1].tagtype]
                " immediately skip to the next loop iteration if we find that 
                " a member exists for this tag which contains a non-empty 
                " heading
                if l:memberKey == l:possibleType[0] && l:possibleType[1] != ""
                  throw "FOLD_LOOP"
                endif
              endfor " for l:possibleType in s:subTypeMap[s:origFileType]...
            endfor " for l:memberKey in keys(l:line[1].members)

            " if we made it this far then this tag should be folded
            if foldclosed(l:index + 2) == -1
              exec TagsParser#Exec(l:index + 2 . "foldclose")
            endif
          endif " if exists('l:line[1].parent') && foldclosed(l:index ...
        endif " if l:foldLevel == -1 && exists('l:line[1].members')
      catch FOLD_LOOP
      endtry " end FOLD_LOOP try
      let l:index += 1
    endwhile " while l:index < len(s:globalPrintData)

    " Now do heading folding.
    let l:index = 0
    while l:index < len(s:globalPrintData)
      try " FOLD_LOOP
        let l:line = s:globalPrintData[l:index]
        if exists('s:typeMapHeadingFold[s:origFileType]') && !exists('l:line[1]') && l:line[0] =~ '^\s\+- .* {{{\d\+$'
          " lastly, if this is a heading which has been marked for folding, 
          " fold it
          for l:heading in s:typeMapHeadingFold[s:origFileType]
            if l:line[0] =~ '^\s\+' . l:heading . ' {{{\d\+$' && foldclosed(l:index + 2) == -1
              exec TagsParser#Exec(l:index + 2 . "foldclose")
            endif
          endfor
        endif " if exists('s:typeMapHeadingFold[s:origFileType]') && ...
      catch FOLD_LOOP
      endtry " end FOLD_LOOP try
      let l:index += 1
    endwhile " while l:index < len(s:globalPrintData)

    " before continuing, we must delete the printLevel and printData temp 
    " variables
    unlet s:printData
    unlet s:printLevel
  else
    call TagsParser#PerlDisplayTags()
  endif " if v:version >= 700 && g:TagsParserForceUsePerl != 1

  "before we go back to the previous window, mark this one as not
  "modifiable, but only if this is currently the tags window
  setlocal nomodifiable

  "mark the update flag as false, and the last file we displayed as what we
  "just worked through
  let s:tagsDataUpdated = 0
  let s:lastFileDisplayed = s:origFileName

  "mark the last tag selected as not folded so accidental folding does not
  "occur
  let s:matchedTagWasFolded = 0

  "go back to the window we were in before moving here, if we were not
  "originally in the tags buffer
  if l:curBufNum != l:tagBufNum
    exec TagsParser#Exec(bufwinnr(s:origFileName) . "wincmd w")

    if g:TagsParserHighlightCurrentTag == 1
      call TagsParser#HighlightTag(1)
    endif
  endif
endfunction " function! TagsParser#DisplayTags()
" >>>
" TagsParserParseCurrentFile - parses The tags file for the current file <<<
" This takes the current file, parses the tag file (if it has not been
" parsed yet, or the tag file has been updated), and saves it into a global
" Perl hash struct for use by the function which prints out the data
function! TagsParser#ParseCurrentFile()
  call TagsParser#Debug(1, "TagsParser#ParseCurrentFile()")
  "get the name of the tag file to parse, for the tag file name itself,
  "replace any spaces in the original filename with underscores
  let l:tagFileName = expand("%:p:h") . "/" . g:TagsParserTagsDir . "/" . expand("%:t") . ".tags"

  "make sure that the tag file exists before we start this
  if !filereadable(l:tagFileName)
    return
  endif

  if v:version >= 700 && g:TagsParserForceUsePerl != 1
    " Initialize the variables used to hold the tag data
    if !exists('s:tags')
      let s:tags = { }
    endif
    if !exists('s:tagMTime')
      let s:tagMTime = { }
    endif
    if !exists('s:tagsByLine')
      let s:tagsByLine = { }
    endif

    " initialize the last modify time if it has not been accessed yet
    if !exists('s:tagMTime[l:tagFileName]')
      let s:tagMTime[l:tagFileName] = 0
    endif

    " if this file has been tagged before and the tag file has not been 
    " updated, just exit
    if getftime(l:tagFileName) <= s:tagMTime[l:tagFileName]
      let s:tagsDataUpdated = 0
      return
    endif

    " otherwise, record the current write time of the tag file, and mark the 
    " update flag.
    let s:tagMTime[l:tagFileName] = getftime(l:tagFileName)
    let s:tagsDataUpdated = 1

    " clear out the current tag data for this tag file
    if exists('s:tags[l:tagFileName]')
      unlet s:tags[l:tagFileName]
    endif

    " initialize this entry to empty
    let s:tags[l:tagFileName] = { }

    " Get the tag separator for this file
    let l:prjKey = TagsParser#GetProject()
    let l:qualifiedTagSeparator = TagsParser#GetQualifiedTagSeparator(l:prjKey)

    " open up the tag file and read the data
    for l:line in readfile(l:tagFileName)
      if l:line =~ '^!_TAG.*'
        continue
      endif

      " split the stuff around the pattern with tabs
      let [ l:tag, l:file; l:rest ] = split(l:line, "\t")

      " now join l:rest by tabs and split on the ;\"\t string
      let [ l:pattern, l:restString ] = split(join(l:rest, "\t"), ";\"\t")

      " split the remaining items into the type and field list
      let [ l:type; l:fields ] = split(l:restString, "\t")

      " cleanup pattern to remove the / / from around the tag search pattern, 
      " the hard part is that sometimes the $ may not be at the end of the 
      " pattern
      if l:pattern =~ '/^.*$/'
        let l:pattern = substitute(l:pattern, '/^\(.*\)$/', '\1', 'g')
      else
        let l:pattern = substitute(l:pattern, '/^\(.*\)/', '\1', 'g')
      endif " if l:pattern =~ '/^.*$/'

      " there may be some escaped /'s in the pattern, un-escape them
      let l:pattern = substitute(l:pattern, '\\\/', '/', 'g')

      " if the " file:" tag is here, remove it, we want it to be in the file 
      " since Vim can use the file: field to know if something is file static, 
      " but we don't care about it much for this script, and it messes up my 
      " hash creation
      let l:fileIdx = index(l:fields, 'file:')
      if l:fileIdx != -1
        call remove(l:fields, l:fileIdx)
      endif

      " now add all these items to the tag hash/dictionary
      let l:tmpEntry = { }
      let l:tmpEntry = { 'tag': l:tag, 'tagtype': l:type, 'pattern': l:pattern }
      for l:pair in l:fields
        " when splitting up the pairs make sure only to split on a single :, 
        " otherwise some of the C/C++ __anon#::__anon# parent structure names 
        " can mess up the hash construction
        let [ l:key, l:value ] = split(l:pair, '\%(:\)\@<!:\%(:\)\@!')
        let l:tmpEntry[l:key] = l:value
      endfor

      if !exists('s:tags[l:tagFileName][l:type]')
        let s:tags[l:tagFileName][l:type] = [ ]
      endif

      " Only create the tag if the l:tmpEntry.tag does not contain 
      " a separation character such as . or :... However, a tag is not 
      " a qualified tag if the tag name appears in the search pattern.
      if l:tmpEntry.tag !~ l:qualifiedTagSeparator || stridx(l:tmpEntry.pattern, l:tmpEntry.tag) != -1
        call add(s:tags[l:tagFileName][l:type], deepcopy(l:tmpEntry))
      endif 
    endfor " for l:line in readfile(l:tagFileName)

    " before worrying about anything else, make up a line number-oriented hash 
    " of the tags, this will make finding a match, or what the current tag is 
    " easier
    "if exists('s:tagsByLine[l:tagFileName]')
    "  call remove(s:tagsByLine, l:tagFileName)
    "endif
    let s:tagsByLine[l:tagFileName] = { }

    for [ l:key, l:typeArray ] in items(s:tags[l:tagFileName])
      for l:tagEntry in l:typeArray
        if !exists('s:tagsByLine[l:tagFileName][l:tagEntry.line]')
          let s:tagsByLine[l:tagFileName][l:tagEntry.line] = [ ]
        endif

        call add(s:tagsByLine[l:tagFileName][l:tagEntry.line], l:tagEntry)
      endfor
    endfor

    " parse the data we just read into hierarchies... If we don't have a kind 
    " hash entry for the current file type or nested tag display is disabled, 
    " just skip the rest of this function
    if !exists('s:kindMap[&filetype]') || g:TagsParserNoNestedTags == 1
      return
    endif

    " for each key, sort it's entries.  These are the tags for each tag, check 
    " for any types which have a scope, and if they do, reference that type to 
    " the correct parent type
    "
    " yeah, this loop sucks, but I haven't found a more efficient way to do it 
    " yet
    for l:key in keys(s:tags[l:tagFileName])
      for l:tagEntry in s:tags[l:tagFileName][l:key]
        for [ l:tagType, l:tagTypeName ] in items(s:kindMap[&filetype])
          " search for any member types of the current tagEntry, but only if 
          " such a member is defined for the current tag
          if exists('l:tagEntry[l:tagTypeName]') && exists('s:tags[l:tagFileName][l:tagType]')
            " sort the possible member entries into reverse order by line 
            " number so that when looking for the parent entry we are sure to 
            " only get the one who's line is just barely less than the current 
            " tag's line
            for l:tmpEntry in sort(s:tags[l:tagFileName][l:tagType], "TagsParser#ReverseLineSort")
              " for the easiest way to do this, only consider tags a match if 
              " the line number of the possible parent tag is less than or 
              " equal to the line number of the current tagEntry.  Instead of 
              " just doing line <= line add 0 to the line numbers to prevent 
              " them from being compared like strings.
              if (l:tmpEntry.tag == l:tagEntry[l:tagTypeName]) && ((0 + l:tmpEntry.line) <= (0 + l:tagEntry.line))
                if !exists('l:tmpEntry.members')
                  let l:tmpEntry.members = { }
                endif

                if !exists('l:tmpEntry.members[l:key]')
                  let l:tmpEntry.members[l:key] = [ ]
                endif

                call add(l:tmpEntry.members[l:key], l:tagEntry)
                let l:tagEntry.parent = l:tmpEntry

                " since we found the correct parent entry for the current tag, 
                " break out of the innermost for loop
                break
              endif " if l:tmpEntry.tag == l:tagEntry[l:tagTypeName] && ...
            endfor " for l:tmpEntry in sort(s:tags[l:tagFileName]...
          endif " if exists('l:tagEntry[l:tagTypeName]') && exists...
        endfor " for [ l:tagType, l:tagTypeName ] in values(s:kindMap...
      endfor " for l:tagEntry in s:tags[l:tagFileName][l:key]
    endfor " for l:key in keys(s:tags[tagFile])

    " processing those local vars for C/C++
    if &filetype =~ 'c\|h\|cpp' && exists('s:tags[l:tagFileName].l') && exists('s:tags[l:tagFileName].f')
      " setup a reverse list of local variable references sorted by line
      let l:vars = sort(s:tags[l:tagFileName].l, "TagsParser#ReverseLineSort")

      " sort the functions by reversed line entry... Then we will go through 
      " the list of local variables until we find one who's line number 
      " exceeds that of the functions.  Then we remove that variable from the 
      " var list and move to the next function
      for l:funcRef in sort(s:tags[l:tagFileName].f, "TagsParser#ReverseLineSort")
        while len(l:vars) > 0
          let l:varRef = l:vars[0]

          if (0 + l:varRef.line) >= (0 + l:funcRef.line)
            if !exists('l:funcRef.members')
              let l:funcRef.members = { }
            endif

            if !exists('l:funcRef.members.l')
              let l:funcRef.members.l = [ ]
            endif

            call add(l:funcRef.members.l, l:varRef)
            let l:varRef.parent = l:funcRef

            " sine we used this varRef, we must remove it from the l:vars list
            call remove(l:vars, 0)
          else
            " break out of the var loop and head to the next function, because 
            " we hit a function whose line number is larger than the 
            " variable's line number
            break
          endif " if l:varRef.line >= l:funcRef.line
        endwhile " while len(l:vars) != 0
      endfor " for l:funcRef in sort(s:tags[l:tagFileName].f, ...
    endif " if &filetype =~ 'c\|h\|cpp' && exists('s:tags...
  else
    call TagsParser#PerlParseFile(l:tagFileName)
  endif " if v:version >= 700 && g:TagsParserForceUsePerl != 1
endfunction
" >>>
" TagsParserOpenTagWindow - Opens up The tag window <<<
function! TagsParser#OpenTagWindow()
  call TagsParser#Debug(1, "TagsParser#OpenTagWindow()")
  "ignore events while opening the tag window
  let l:oldEvents = &eventignore
  set eventignore=all

  "save the window number and potential tag file name for the current file
  let s:origFileName = expand("%:t")
  let s:origFileTagFileName = expand("%:p:h") . "/" . g:TagsParserTagsDir . "/" . expand("%:t") . ".tags"
  "before we move to the new tags window, we must save the type of file
  "that we are currently in
  let s:origFileType = &filetype

  "parse the current file
  call TagsParser#ParseCurrentFile()

  let l:tagWindowName = TagsParser#WindowName()
  if bufwinnr(bufnr(l:tagWindowName)) == -1
    " make a list of all the buffers currently opened in this tab, if a tag 
    " window is already opened, but the tab number is wrong, move to that 
    " window and open the correct buffer.  But only if this is Vim 7.0.
    let l:tagWinOpen = -1
    if v:version >= 700
      for l:bufnum in tabpagebuflist()
        if stridx(bufname(l:bufnum), g:TagsParserWindowName) == 0
          let l:tagWinOpen = bufwinnr(l:bufnum)
        endif
      endfor
    endif " if v:version >= 700

    " If this is not Vim 7.0, this if will never be true
    if l:tagWinOpen != -1
      " In this case a tag window is already open, move to the correct window 
      " and open the proper buffer.
      exec TagsParser#Exec(l:tagWinOpen . "wincmd w")

      " There is a possibility that the correct buffer for this window does 
      " not exist yet, if this is the case, we should open the tag window, but 
      " we should not resize the Vim window.
      if bufnr(l:tagWindowName) == -1
        exec TagsParser#Exec("edit " . l:tagWindowName)
      else
        exec TagsParser#Exec(bufnr(l:tagWindowName) . "buffer")
      endif

      " If a window was opened, set the last file displayed as empty to force 
      " an update
      let s:lastFileDisplayed = ""

      " force new window to have the correct size.
      exec TagsParser#Exec(s:TagsWindowPosition . " resize " . g:TagsParserWindowSize)
    else
      " In this case no window is open.  Resize the Vim window, unless 
      " NoResize is set, or the Tag Window was viewable already from within 
      " another tab.
      if g:TagsParserHorizontalSplit != 1
        if g:TagsParserNoResize == 0 && s:newColumns != &columns
          " track the current window size, so that when we close the tags tab, 
          " if we were not able to resize the current window, that we don't 
          " decrease it any more than we increased it when we opened the tab
          let s:origColumns = &columns
          "open the tag window, + 1 for the split divider
          let &columns = &columns + g:TagsParserWindowSize + 1
          let s:columnsAdded = &columns - s:origColumns
          let s:newColumns = &columns
        endif " if g:TagsParserNoResize == 0
      else
        if g:TagsParserNoResize == 0 && s:newLines != &lines
          " track the current window size, so that when we close the tags tab, 
          " if we were not able to resize the current window, that we don't  
          " decrease it any more than we increased it when we opened the tab
          let s:origLines = &lines
          "open the tag window, + 1 for the split divider
          let &lines = &lines + g:TagsParserWindowSize + 1
          let s:linesAdded = &lines - s:origLines
          let s:newLines = &lines
        endif " if g:TagsParserNoResize == 0
      endif " if g:TagsParserHorizontalSplit != 1

      " Open the tag window, if the buffer has already been opened, don't do 
      " a normal split, do an sbuffer command.
      if bufnr(l:tagWindowName) != -1
        exec TagsParser#Exec(s:TagsWindowPosition . " sbuffer " . bufnr(l:tagWindowName))
      else
        exec TagsParser#Exec(s:TagsWindowPosition . " split " . l:tagWindowName)
      endif

      " If a window was opened, set the last file displayed as empty to force 
      " an update
      let s:lastFileDisplayed = ""

      " force the new window to have the correct size.
      exec TagsParser#Exec(s:TagsWindowPosition . " resize " . g:TagsParserWindowSize)
    endif

    " Save the current tag window size, even if it was not resized.
    if g:TagsParserHorizontalSplit != 1
      if winwidth(bufwinnr(l:tagWindowName)) != &columns
        let s:tagsWindowSize = winwidth(bufwinnr(l:tagWindowName))
      endif
    else
      if winheight(bufwinnr(l:tagWindowName)) != &lines
        let s:tagsWindowSize = winheight(bufwinnr(l:tagWindowName))
      endif
    endif

    " Set the tag window to keep a constant size if configured
    if g:TagsParserTagWindowFixedSize == 1
      if g:TagsParserHorizontalSplit != 1
        setlocal winfixwidth
      else
        setlocal winfixheight
      endif
    endif

    " Configure the Tag Window
    setlocal nonumber
    setlocal nobuflisted
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete

    if v:version >= 700
      setlocal nospell
    endif

    "formatting related settings
    setlocal nowrap
    setlocal tabstop=2

    "fold related settings
    if exists('g:TagsParserFoldLevel')
      let &l:foldlevel = g:TagsParserFoldLevel
    else
      "if the foldlevel is not defined, default it to something large so that
      "the default folding method takes over
      setlocal foldlevel=100
    endif

    "only turn the fold column on if the disabled flag is not set
    if g:TagsParserFoldColumnDisabled == 0
      setlocal foldcolumn=3
    endif

    setlocal foldenable
    setlocal foldmethod=marker
    setlocal foldtext=TagsParser#FoldFunction()
    setlocal fillchars=fold:\ 

    "if the highlight tag option is on, reduce the updatetime... But not too
    "much because it is global and it could impact overall VIM performance
    if g:TagsParserHighlightCurrentTag == 1
      let &l:updatetime = g:TagsParserUpdateTime
    endif

    "command to go to tag in previous window:
    nnoremap <buffer> <silent> <CR> :call TagsParser#SelectTag()<CR>
    nnoremap <buffer> <silent> <2-LeftMouse> :call TagsParser#SelectTag()<CR>

    if !hlexists('TagsParserFileName')
      hi link TagsParserFileName Underlined
    endif

    if !hlexists('TagsParserTypeName')
      hi link TagsParserTypeName Special 
    endif

    if !hlexists('TagsParserTag')
      hi link TagsParserTag Normal
    endif

    if !hlexists('TagsParserFoldMarker')
      hi link TagsParserFoldMarker Ignore
    endif

    if !hlexists('TagsParserHighlight')
      hi link TagsParserHighlight ToDo
    endif

    "setup the syntax for the tags window
    syntax match TagsParserTag '\(- \)\@<!\S\(.*\( {{{\)\@=\|.*\)'
          \ contains=TagsParserFoldMarker
    syntax match TagsParserFileName '^\w\S*'
    syntax match TagsParserTypeName '^\t*- .*' contains=TagsParserFoldMarker
    syntax match TagsParserFoldMarker '{{{.*\|\s*}}}'
  endif " if bufwinnr(bufnr(l:tagWindowName)) == -1

  "the augroup we are going to setup will override this initial
  "autocommand so stop it from running
  autocmd! TagsParserBufEnterWindowNotOpen

  "setup and autocommand so that when you enter a new buffer, the new file 
  "is parsed and then displayed
  augroup TagsParserBufEnterEvents
    autocmd!
    autocmd BufEnter ?* call TagsParser#Debug(2, "BufEnter - " . 
          \ expand("<amatch>")) | call TagsParser#HandleBufEnter()

    "when a file is written, add an event so that the new tag file is 
    "parsed and displayed (if there are updates)
    autocmd BufWritePost ?* call TagsParser#Debug(2, "BufWritePost - " . 
          \ expand("<amatch>")) | call TagsParser#ParseCurrentFile() |
          \ call TagsParser#DisplayTags()

    "properly handle the BufWinLeave event
    autocmd BufWinLeave ?* call TagsParser#Debug(2, "BufWinLeave - " . 
          \ expand("<amatch>")) | call TagsParser#HandleBufWinLeave()

    "make sure that we don't accidentally close the Vim session when 
    "loading up a new buffer
    autocmd BufAdd * call TagsParser#Debug(2, "BufAdd - " . 
          \ expand("<amatch>")) | let s:newBufBeingCreated = 1
  augroup END

  "If this is Vim version >= 7.0 then we need to install some additional 
  "events that will detect if the tag window is being closed in a tab while 
  "still being open in another tab (as if with the :q command).
  if v:version >= 700
    augroup TagsParserVer7WinEvents
      autocmd!
      autocmd WinLeave ?* call TagsParser#Debug(2, "WinLeave - " . 
            \ expand("<amatch>")) | let s:curNumWindows = winnr("$") |
            \ let s:winLeaveBufName = expand("<afile>")
      autocmd WinEnter ?* call TagsParser#Debug(2, "WinEnter - " . 
            \ expand("<amatch>")) |  call TagsParser#HandleWinEnter()
    augroup END
  endif

  "add the event to do the auto tag highlighting if the event is set
  if g:TagsParserHighlightCurrentTag == 1
    augroup TagsParserCursorHoldEvent
      autocmd!
      autocmd CursorHold ?* call TagsParser#Debug(2, "CursorHold - " . 
            \ expand("<amatch>")) | call TagsParser#HighlightTag(0)
    augroup END
  endif

  "display the tags
  call TagsParser#DisplayTags()

  "highlight the current tag (if flag is set)
  if g:TagsParserHighlightCurrentTag == 1
    call TagsParser#HighlightTag(1)
  endif

  "go back to the previous window, find the winnr for the buffer, and
  "do a :<N>wincmd w
  exec TagsParser#Exec(bufwinnr(s:origFileName) . "wincmd w")

  "un ignore events 
  let &eventignore=l:oldEvents
  unlet l:oldEvents
endfunction
" >>>
" TagsParserCloseTagWindow - Closes The tags window <<<
function! TagsParser#CloseTagWindow(closeCommand)
  call TagsParser#Debug(1, "TagsParser#CloseTagWindow()")
  "ignore events while closing the tag window
  let l:oldEvents = &eventignore
  set eventignore=all

  "if the window exists, find it and close it
  if bufwinnr(bufnr(TagsParser#WindowName())) != -1
    "save current file bufnr
    let l:curBufNum = bufnr("%")

    "save the current tags window size, this variable should have the most up 
    "to date window size from the last BufEnter event, but this is just to be 
    "safe.  Only take this new size though, if it is not the entire width of 
    "the current window.
    if g:TagsParserHorizontalSplit != 1
      if winwidth(bufwinnr(TagsParser#WindowName())) != &columns
        let s:tagsWindowSize = winwidth(bufwinnr(TagsParser#WindowName()))
      endif
    else
      if winheight(bufwinnr(TagsParser#WindowName())) != &lines
        let s:tagsWindowSize = winheight(bufwinnr(TagsParser#WindowName()))
      endif
    endif

    "go to and close the tags window
    exec TagsParser#Exec(bufwinnr(TagsParser#WindowName()) . "wincmd w")
    exec TagsParser#Exec(a:closeCommand)
    
    "now go back to the file we were just in assuming it wasn't the
    "tags window in which case this will simply fail silently, and we'll be in 
    "a different window anyway.
    exec TagsParser#Exec(bufwinnr(l:curBufNum) . "wincmd w")
  endif " if bufwinnr(bufnr(TagsParser#WindowName())) != -1

  " Find out if there are any tabs that are viewing the tag window.
  let l:tagWinOpen = 0
  if v:version >=  700
    let l:bufList = []
    " create a list of currently open buffers
    for l:tabnum in range(tabpagenr("$"))
      let l:tabnum += 1
      call extend(l:bufList, tabpagebuflist(l:tabnum))
    endfor

    " Now find out which of the open buffers are tag windows (if any)
    for l:bufnum in l:bufList
      if (stridx(bufname(l:bufnum), g:TagsParserWindowName) == 0)
        let l:tagWinOpen += 1
      endif
    endfor
  endif

  " Resize the Vim window if it is allowed, and there are no tag windows being 
  " viewed in other tabs.
  if g:TagsParserNoResize == 0 && l:tagWinOpen == 0
    "If the s:tagsWindowSize variable is greater than 0, resize the Vim 
    "window.
    if s:tagsWindowSize > 0 
      "before resizing, check to see if this is a horizontally or vertically 
      "split tag window.
      if g:TagsParserHorizontalSplit != 1
        if g:TagsParserWindowSize == s:tagsWindowSize && s:newColumns == &columns
          let &columns = &columns - s:columnsAdded
        else
          "if the window sizes have been changed since the window was opened,
          "attempt to save the new sizes to use later
          let g:TagsParserWindowSize = s:tagsWindowSize
          let &columns = &columns - g:TagsParserWindowSize - 1
        endif
      else
        if g:TagsParserWindowSize == s:tagsWindowSize && s:newLines == &lines
          let &lines = &lines - s:linesAdded
        else
          "if the window sizes have been changed since the window was opened,
          "attempt to save the new sizes to use later
          let g:TagsParserWindowSize = s:tagsWindowSize
          let &lines = &lines - g:TagsParserWindowSize - 1
        endif
      endif " if g:TagsParserHorizontalSplit != 1
      " Now that the window has been resized, set the current tag window size 
      " to 0
      let s:tagsWindowSize = 0
    endif " if s:tagsWindowSize != 0 
  endif " if g:TagsParserNoResize == 0

  "zero out the last file displayed variable so that if the tags window is
  "reopened then the tags should be redrawn
  let s:lastFileDisplayed = ""

  "remove all buffer related autocommands
  autocmd! TagsParserBufEnterEvents

  if g:TagsParserHighlightCurrentTag == 1
    autocmd! TagsParserCursorHoldEvent
  endif

  if v:version >= 700
    autocmd! TagsParserVer7WinEvents
  endif

  " Reinstall the BufEnter events for when the Tag Window is not open.
  augroup TagsParserBufEnterWindowNotOpen
    autocmd BufEnter ?* call TagsParser#Debug(2, "BufEnter - " . 
          \ expand("<amatch>")) | call TagsParser#PerformOp("open", "")
  augroup END

  " Now set the tags path back to the original path.
  let &tags = s:OldTagsPath 

  "un ignore events 
  let &eventignore=l:oldEvents
  unlet l:oldEvents
endfunction " TagsParserCloseTagWindow
" >>>
" TagsParserToggle - Will toggle The tags window open or closed <<<
function! TagsParser#Toggle()
  call TagsParser#Debug(1, "TagsParser#Toggle()")
  "if the TagsParserOff flag is set, print out an error and do nothing
  if g:TagsParserOff != 0
    echomsg "TagsParser window cannot be opened because plugin is turned off"
    return
  elseif g:TagsParserNoTagWindow == 1
    echomsg "TagsParser window cannot be opened because the Tag window has been disabled by the g:TagsParserNoTagWindow variable"
    return
  endif

  "check to see if the tags window is loaded, if it is not, open it, if it
  "is, close it
  if bufwinnr(bufnr(TagsParser#WindowName())) != -1
    "if the tags parser is forced closed, turn off the auto open/close flag
    if g:TagsParserAutoOpenClose == 1
      let g:TagsParserAutoOpenClose = 0
      let s:autoOpenCloseTurnedOff = 1
    endif

    call TagsParser#CloseTagWindow("close")
  else
    if s:autoOpenCloseTurnedOff == 1
      let g:TagsParserAutoOpenClose = 1
      let s:autoOpenCloseTurnedOff = 0
    endif

    call TagsParser#OpenTagWindow()
  endif " if bufwinnr(bufnr(TagsParser#WindowName())) != -1
endfunction " TagsParserToggle
" >>>
" TagsParserHandleBufEnter - handles The BufEnter event <<<
function! TagsParser#HandleBufEnter()
  call TagsParser#Debug(1, "TagsParser#HandleBufEnter()")
  call TagsParser#Debug(4, "bufname('%') = " . bufname('%'))
  "if the tag window is viewable, save it's width
  let l:tagWindowName = TagsParser#WindowName()
  if bufwinnr(bufnr(l:tagWindowName)) != -1
    if g:TagsParserHorizontalSplit != 1
      if winwidth(bufwinnr(l:tagWindowName)) != &columns
        let s:tagsWindowSize = winwidth(bufwinnr(l:tagWindowName))
      endif
    else
      if winheight(bufwinnr(l:tagWindowName)) != &lines
        let s:tagsWindowSize = winheight(bufwinnr(l:tagWindowName))
      endif
    endif
  endif

  "Before we do anything else, first check if this is the tags window, and if 
  "all other windows are closed.  If this is true then just quit everything 
  "now.
  if s:closedBufName != "" && bufname("%") == l:tagWindowName && winbufnr(2) == -1
    " If this is Vim 7.0 or greater, make sure that this is the last tabpage 
    " before quiting...  If it is a version less than 7.0 then just quit.
    if (v:version >= 700 && tabpagenr() == 1 && tabpagenr("$") == 1) || v:version < 700
      call TagsParser#CloseTagWindow("confirm qall")

      "If Vim is still open at this point move to the first modifiable buffer 
      "because the user decided not to exit Vim.
      let l:bufnr = 1
      while bufexists(l:bufnr) != -1
        if getbufvar(l:bufnr, "&modified")
          exec TagsParser#Exec(l:bufnr . "buffer!")
          echomsg "TagsParser - qall canceled by user, moved to first modified buffer"
          return
        endif
      endwhile
    else
      " If there are more tabpages left just quit out of this Tag Window so 
      " that the next tab will be activated...  This statement should only be 
      " reached if the Vim version is >= 7.0 but there are more tab pages 
      " left.  So we should just turn off events and do a tabclose, unless 
      " there are no more tag windows viewable.  If that is the case then we 
      " should close the tag window.
      let l:bufList = []
      for l:tabnum in range(tabpagenr("$"))
        let l:tabnum += 1
        " create a list of currently open buffers
        call extend(l:bufList, tabpagebuflist(l:tabnum))
      endfor

      " Now find out which of the open buffers are tag windows (if any), 
      " besides the current one.
      let l:tagWinOpen = 0
      for l:bufnum in l:bufList
        if (stridx(bufname(l:bufnum), g:TagsParserWindowName) == 0) && (bufname(l:bufnum) != l:tagWindowName)
          let l:tagWinOpen += 1
        endif
      endfor
      
      " If there is no more tag windows open, close it down, otherwise just 
      " close this tab.
      if l:tagWinOpen == 0
        " Just supply an empty string because there are no more tag windows 
        " left to close.  Set the current tag window size so that the window 
        " will get resized.
        call TagsParser#CloseTagWindow("tabclose")
      else
        let l:oldEvents = &eventignore
        set eventignore=all
        tabclose
        let &eventignore=l:oldEvents
        unlet l:oldEvents
      endif
    endif " if (v:version >= 700 && tabpagenr() == 1 && tabpagenr("$") ...
  endif

  "Don't forget to zero out the closed buffer name before we continue
  let s:closedBufName = ""

  "if the buffer we just entered is unmodifiable do nothing and return
  if &modifiable == 0
    return
  endif

  "if the auto open/close flag is set, see if there is a tag file for the
  "new buffer, if there is, call open, otherwise, call close
  if g:TagsParserAutoOpenClose == 1
    call TagsParser#PerformOp("auto", "")
  else
    "else parse the current file and call display tags
    call TagsParser#ParseCurrentFile()
    call TagsParser#DisplayTags()

    "highlight the current tag (if flag is set)
    if g:TagsParserHighlightCurrentTag == 1
      call TagsParser#HighlightTag(1)
    endif
  endif
endfunction " function! TagsParser#HandleBufEnter()
">>>
" TagsParserHandleBufWinLeave - handles The BufWinLeave event <<<
function! TagsParser#HandleBufWinLeave()
  call TagsParser#Debug(1, "TagsParser#HandleBufWinLeave()")
  call TagsParser#Debug(4, "bufname('%') = " . bufname('%'))
  "if we are unloading the tags window, and the auto open/close flag is on,
  "turn it off
  if bufname("%") == TagsParser#WindowName()
    " If the tags window is being manually closed, turn the auto open/close 
    " feature off.
    if g:TagsParserAutoOpenClose == 1
      let g:TagsParserAutoOpenClose = 0
      let s:autoOpenCloseTurnedOff = 1
    endif
    call TagsParser#CloseTagWindow("close")
  else
    "if this is not the tag window, just store the name of the closed 
    "buffer.
    let s:closedBufName = bufname("%")
  endif
endfunction
">>>
" TagsParserHandleWinEnter - Handles the WinEnter event for Vim 7.0 <<<
function! TagsParser#HandleWinEnter()
  call TagsParser#Debug(1, "TagsParser#HandleWinEnter()")
  " So... if the current number of windows is 1 less than the value stored by 
  " the WinLeave event, and if the name of buffer caught in the WinLeave event 
  " is the Tag Window name, but the s:closedBufName variable has not been set, 
  " close the tag window manually.  This is because in Vim 7.0 with tabs, if 
  " a window is closed (using something like :q) but it is still open in 
  " another tab the BufWinLeave event will not be activated.
  if s:curNumWindows == winnr("$") + 1 && s:winLeaveBufName == TagsParser#WindowName() && s:closedBufName == ""
    "set the manual close variables
    if g:TagsParserAutoOpenClose == 1
      let g:TagsParserAutoOpenClose = 0
      let s:autoOpenCloseTurnedOff = 1
    endif

    "close the tag window
    call TagsParser#CloseTagWindow("close")
  endif

  "now reinit the WinLeave variables
  let s:curNumWindows = -1
  let s:winLeaveBufName = ""
endfunction
" >>>
" TagsParserSelectTag - activates a tag (if it is a tag) <<<
function! TagsParser#SelectTag()
  call TagsParser#Debug(1, "TagsParser#SelectTag()")
  "before we start finding a tag, make sure we are not on the first line of 
  "the tag window
  if line(".") == 1
    return
  endif

  "ignore events while selecting a tag
  let l:oldEvents = &eventignore
  set eventignore=all

  if v:version >= 700 && g:TagsParserForceUsePerl != 1
    "clear out any previous match
    if s:matchedTagWasFolded == 1
      while(len(s:matchedTagLines) != 0)
        exec TagsParser#Exec(s:matchedTagLines[0][0] . "," . s:matchedTagLines[0][1] . "foldclose")
        call remove(s:matchedTagLines, 0)
      endwhile
      let s:matchedTagWasFolded = 0
    endif

    let s:matchedTagLine = 0
    match none

    if !exists('s:globalPrintData')
      let s:globalPrintData = [ ]
    endif

    " subtract 2 (1 for the append offset, and 1 because it starts at 0) from 
    " the line number to get the proper globalPrintData index
    let l:indexNum = line(".") - 2

    " if this is a tag, there will be a reference to the correct tag entry in 
    " the referenced globalPrintData array
    if exists('s:globalPrintData[l:indexNum][1]')
      " While the desired line is still folded, keep unfolding.
      while foldclosed(line(".")) != -1
        call insert(s:matchedTagLines, [ foldclosed(line(".")), foldclosedend(line(".")) ])
        " I've seen a strange bug lately where the foldclosedend() can 
        " return a value that is larger than the number of lines in the 
        " buffer.  So as a work around if the end line # is too big just 
        " reset it to be the last line in the buffer.
        if s:matchedTagLines[0][1] > line("$")
          let s:matchedTagLines[0][1] = line("$")
        endif

        exec TagsParser#Exec(s:matchedTagLines[0][0] . "," . s:matchedTagLines[0][1] . "foldopen")
        let s:matchedTagWasFolded = 1
      endwhile

      " now match this tag
      exec TagsParser#Exec('match TagsParserHighlight /\%' . line(".") . 'l\S.*\%( {{{\)\@=/')
      let s:matchedTagLine = line(".")

      " go to the proper window, go the correct line, unfold it (if 
      " necessary), move to the correct word (the tag) and finally, set a mark
      exec TagsParser#Exec(bufwinnr(s:origFileName) . "wincmd w")
      exec TagsParser#Exec(s:globalPrintData[l:indexNum][1].line)

      " now find out where the tag is on the current line
      let l:position = match(getline("."), '\s\zs' . s:globalPrintData[l:indexNum][1].tag)
      " move to that column if we got a valid value
      if l:position != -1
        exec TagsParser#Exec('normal! 0' . l:position . 'l')
      endif

      if foldclosed(".") != -1
        .foldopen
      endif

      normal! m'
    else
      " otherwise we should just toggle this fold open/closed if the line is 
      " actually folded
      if foldclosed(".") != -1
        .foldopen
      else
        .foldclose
      endif
    endif " if exists('s:globalPrintData[l:indexNum][1]')
  else
    call TagsParser#PerlSelectTag()
  endif " if v:version >= 700 && g:TagsParserForceUsePerl != 1

  "un ignore events 
  let &eventignore=l:oldEvents
  unlet l:oldEvents
endfunction
" >>>
" TagsParserHighlightTag - highlights The tag that the cursor is on <<<
function! TagsParser#HighlightTag(resetCursor)
  call TagsParser#Debug(1, "TagsParser#HighlightTag(" . a:resetCursor . ")")
  "if this buffer is unmodifiable, do nothing
  if &modifiable == 0
    return
  endif

  "get the current and tags buffer numbers
  let l:curBufNum = bufnr("%")
  let l:tagBufNum = bufnr(TagsParser#WindowName())

  "return if the tags buffer is not open or this is the tags window we are
  "currently in
  if l:tagBufNum == -1 || l:curBufNum == l:tagBufNum
    return
  endif
  
  let l:curPattern = getline(".")
  let l:curLine = line(".")
  let l:curWord = expand("<cword>")

  "ignore events before changing windows
  let l:oldEvents = &eventignore
  set eventignore=all

  "goto the tags window
  exec TagsParser#Exec(bufwinnr(l:tagBufNum) . "wincmd w")
  
  if v:version >= 700 && g:TagsParserForceUsePerl != 1
    "clear out any previous match
    if s:matchedTagWasFolded == 1
      while(len(s:matchedTagLines) != 0)
        exec TagsParser#Exec(s:matchedTagLines[0][0] . "," . s:matchedTagLines[0][1] . "foldclose")
        call remove(s:matchedTagLines, 0)
      endwhile
      let s:matchedTagWasFolded = 0
    endif

    let s:matchedTagLine = 0
    match none

    if !exists('s:globalPrintData')
      let s:globalPrintData = [ ]
    endif

    if !exists('s:tagsByLine')
      let s:tagsByLine = { }
    endif

    " now look up this tag, try to find an exact match (useful for lists of 
    " variables, enumerations and so on).
    if exists('s:tagsByLine[s:origFileTagFileName][l:curLine]')
      for l:ref in s:tagsByLine[s:origFileTagFileName][l:curLine]
        if l:curPattern[0:len(l:ref.pattern) - 1] == l:ref.pattern
          if l:curWord == l:ref.tag
            let l:trueRef = l:ref
          elseif !exists('l:easyRef')
            let l:easyRef = l:ref
          endif
        endif " if l:curPattern[0:len(l:ref.pattern)] == l:ref.pattern
      endfor " for l:ref in s:tagsByLine[s:origFileTagFileName][l:curLine]
    endif " if exists('s:tagsByLine[s:origFileTagFileName][l:curLine]')

    " if we didn't find an exact match go with the default match
    if !exists('l:trueRef') && exists('l:easyRef')
      let l:trueRef = l:easyRef
    endif

    " now we have to find the correct line for this tag in the globalPrintData
    let l:index = 0
    for l:line in s:globalPrintData
      if exists('l:line[1]') && exists('l:trueRef') && l:line[1] is l:trueRef
        let l:tagLine = l:index + 2

        " While the desired line is still folded, keep unfolding.
        while foldclosed(l:tagLine) != -1
          call insert(s:matchedTagLines, [ foldclosed(l:tagLine), foldclosedend(l:tagLine) ])

          " I've seen a strange bug lately where the foldclosedend() can 
          " return a value that is larger than the number of lines in the 
          " buffer.  So as a work around if the end line # is too big just 
          " reset it to be the last line in the buffer.
          if s:matchedTagLines[0][1] > line("$")
            let s:matchedTagLines[0][1] = line("$")
          endif

          exec TagsParser#Exec(s:matchedTagLines[0][0] . "," . s:matchedTagLines[0][1] . "foldopen")
          let s:matchedTagWasFolded = 1
        endwhile

        " now match this tag
        exec TagsParser#Exec('match TagsParserHighlight /\%' . l:tagLine . 'l\S.*\%( {{{\)\@=/')
        let s:matchedTagLine = l:tagLine

        " now that the tag has been highlighted, go to the tag and make the 
        " line visible, and then go back to the tag line so that the cursor is 
        " in the correct place
        exec l:tagLine
        exec winline()
        exec l:tagLine

        " if the correct line was found, break out of this loop
        break
      endif " if exists('l:line[1]') && l:line[1] is l:trueRef

      let l:index += 1
    endfor " for l:line in s:globalPrintData
  else
    call TagsParser#PerlFindTag(l:curPattern, l:curLine, l:curWord)
  endif " if v:version >= 700 && g:TagsParserForceUsePerl != 1
  
  "before we go back to the previous window... Check if we found a match.  If
  "we did not, and the resetCursor parameter is 1 then move the cursor to the
  "top of the window
  if a:resetCursor == 1 && s:matchedTagLine == 0
    exec 1
    exec winline()
    exec 1
  endif

  "go back to the old window
  exec TagsParser#Exec(bufwinnr(l:curBufNum) . "wincmd w")

  "un ignore events 
  let &eventignore=l:oldEvents
  unlet l:oldEvents
endfunction
">>>
" TagsParserFoldFunction - function to make proper tags for folded tags <<<
function! TagsParser#FoldFunction()
  let l:line = getline(v:foldstart)
  let l:tabbedLine = substitute(l:line, "\t", "  ", "g")
  let l:finishedLine = substitute(l:tabbedLine, " {{{.*", "", "")
  let l:numLines = v:foldend - v:foldstart
  return l:finishedLine . " : " . l:numLines . " lines"
endfunction
" >>>
" TagsParserOff - function to turn off all TagsParser functionality <<<
function! TagsParser#Off()
  call TagsParser#Debug(1, "TagsParser#Off()")
  "only do something if The TagsParser is not off already
  if g:TagsParserOff == 0
    "to turn off the TagsParser, call the TagsParserCloseTagWindow() function,
    "which will uninstall all autocommands except for the default
    "TagsParserAutoCommands group (which is always on) and the
    "TagsParserBufEnterWindowNotOpen group (which is on when the window is
    "closed)
    call TagsParser#CloseTagWindow("close")
    
    autocmd! TagsParserAutoCommands
    autocmd! TagsParserBufEnterWindowNotOpen
    autocmd! TagsParserAlwaysOnCommands

    "finally, set the TagsParserOff flag to 1
    let g:TagsParserOff = 1
  endif
endfunction
" >>>
" TagsParserOn - function to turn all TagsParser functionality back on <<<
function! TagsParser#On()
  call TagsParser#Debug(1, "TagsParser#On()")

  augroup TagsParserAutoCommands
    autocmd!
    "setup an autocommand that will expand the path described by
    "g:TagsParserTagsPath into a valid tag path
    autocmd VimEnter * call TagsParser#Debug(2, "VimEnter - ".
          \ expand("<amatch>")) | call TagsParser#ExpandTagsPath()

    "setup an autocommand so that when a file is written to it writes a tag
    "file if it a file that is somewhere within the tags path or the
    "g:TagsParserTagsPath path
    autocmd BufWritePost ?* call TagsParser#Debug(2, "BufWritePost - ".
          \ expand("<amatch>")) | call TagsParser#PerformOp("tag", "")
  augroup END

  if g:TagsParserNoTagWindow == 0
    augroup TagsParserBufEnterWindowNotOpen
      autocmd BufEnter ?* call TagsParser#Debug(2, "BufEnter - ".
          \ expand("<amatch>")) | call TagsParser#PerformOp("open", "")
    augroup END
  endif

  " Autocommands that will always be installed, unless the plugin is off.
  augroup TagsParserAlwaysOnCommands
    " Setup an autocommand that will tag a file when it is opened
    if g:TagsParserFileReadTag == 1
      autocmd BufRead ?* call TagsParser#Debug(2, "BufRead - ".
          \ expand("<amatch>")) | call TagsParser#PerformOp("tag", "")
    endif

    " Setup an autocommand that will remove any tag file that exists, when it 
    " is opened, if the file is not in a project path.
    if g:TagsParserFileReadDeleteTag == 1
      autocmd BufRead ?* call TagsParser#Debug(2, "BufRead - ".
          \ expand("<amatch>")) | call TagsParser#PerformOp("deletetag", "")
    endif
  augroup END

  let g:TagsParserOff = 0
endfunction
" >>>
" TagsParserCOpen - opens The quickfix window nicely <<<
function! TagsParser#COpen(...)
  call TagsParser#Debug(1, "TagsParser#COpen(...)")
  let l:windowClosed = 0

  "if the tag window is open, close it
  if bufloaded(TagsParser#WindowName()) && s:TagsWindowPosition =~ "vertical"
    call TagsParser#CloseTagWindow("close")
    let l:windowClosed = 1
  endif

  "get the current window number
  let l:curBuf = bufnr("%")

  "now open the quickfix window
  if(a:0 == 1)
    exec TagsParser#Exec("copen " . a:1)
  else
    exec TagsParser#Exec("copen")
  endif

  "go back to the original window
  exec TagsParser#Exec(bufwinnr(l:curBuf) . "wincmd w")

  "go to the first error
  silent "cfirst"

  "reopen the tag window if necessary
  if l:windowClosed == 1
    call TagsParser#OpenTagWindow()
  endif
endfunction
" >>>
" TagsParserCWindow - opens The quickfix window nicely <<<
function! TagsParser#CWindow(...)
  call TagsParser#Debug(1, "TagsParser#COpen(...)")
  let l:windowClosed = 0

  "if the tag window is open, close it
  if bufloaded(TagsParser#WindowName()) && s:TagsWindowPosition =~ "vertical"
    call TagsParser#CloseTagWindow("close")
    let l:windowClosed = 1
  endif

  "get the current window number
  let l:curBuf = bufnr("%")

  "now open the quickfix window
  if(a:0 == 1)
    exec TagsParser#Exec("cwindow " . a:1)
  else
    exec TagsParser#Exec("cwindow")
  endif
  
  "go back to the original window, if we actually changed windows
  if l:curBuf != bufnr("%")
    exec TagsParser#Exec(bufwinnr(l:curBuf) . "wincmd w")

    "go to the first error
    silent "cfirst"
  endif

  "reopen the tag window if necessary
  if l:windowClosed == 1
    call TagsParser#OpenTagWindow()
  endif
endfunction
" >>>
" TagsParserBufSwitch - Cycles through buffers in one window <<<
function! TagsParser#BufSwitch(reverse)
  call TagsParser#Debug(1, "TagsParser#BufSwitch(" . a:reverse . ")")
  " Initialize the next buffer variable to the current buffer.
  let l:nextBuf = bufnr("%")

  while 1
    " Find the next modifiable buffer in the requested direction.
    if a:reverse == 1
      let l:nextBuf = l:nextBuf - 1
    else
      let l:nextBuf = l:nextBuf + 1
    endif

    " Make sure that the l:nextBuf is not beyond the end or beginning of the 
    " current buffer list... Or if it equals the current buffer, if it does 
    " then there is nowhere to go and just exit.
    if l:nextBuf <= 0
      let l:nextBuf = bufnr("$")
    elseif l:nextBuf > bufnr("$")
      let l:nextBuf = 1
    elseif l:nextBuf == bufnr("%")
      return
    endif

    " Finally, check to see if the new buffer is modifiable, if it is then 
    " move to it.
    if getbufvar(l:nextBuf, "&modifiable") && buflisted(l:nextBuf)
      echomsg l:nextBuf . "buffer"
      exec TagsParser#Exec(l:nextBuf . "buffer")
      return
    endif
  endwhile " while 1
endfunction
" >>>
" TagsParserTabBufferOpen - Opens files not yet opened in new tabs <<<
function! TagsParser#TabBufferOpen()
  call TagsParser#Debug(1, "TagsParser#TabBufferOpen()")
  if v:version >= 700
    " Gather a list of all buffers currently opened.
    let l:bufList = []
    for l:index in range(tabpagenr("$"))
      let l:index += 1
      call extend(l:bufList, tabpagebuflist(l:index))
    endfor

    " Now, if we are at the end of the list of tabs find the first unopened 
    " buffer and open it in a new tab.
    for l:index in range(bufnr("$"))
      let l:buf = l:index + 1
      if len(filter(copy(l:bufList), 'v:val == l:buf')) == 0 && getbufvar(l:buf, "&modifiable") && buflisted(l:buf)
        " Before we open the new tab, move to the last tab so that the new one 
        " is at the end of the current list of tabs.
        tablast
        exec TagsParser#Exec("tabedit " . bufname(l:buf))
        return
      endif 
    endfor " for i in range(bufnr('$'))
  endif " if v:version >= 700
endfunction
" >>>
" TagsParserTagSort - Sort function for tag entries based on tag name <<<
function! TagsParser#TagSort(one, two)
  return a:one.tag == a:two.tag ? 0 : a:one.tag > a:two.tag ? 1 : -1
endfunction
" >>>
" TagsParserLineSort - Sort function for tag entries based on line # <<<
function! TagsParser#LineSort(one, two)
  return (0 + a:one.line) == (0 + a:two.line) ? 0 : (0 + a:one.line) > (0 + a:two.line) ? 1 : -1
endfunction
" >>>
" TagsParserReverseLineSort - Like TagsParserLineSort but reversed <<<
function! TagsParser#ReverseLineSort(one, two)
  return (0 + a:two.line) == (0 + a:one.line) ? 0 : (0 + a:two.line) > (0 + a:one.line) ? 1 : -1
endfunction
" >>>
" TagsParserWindowName - returns the name of the current tag buffer <<<
function! TagsParser#WindowName()
  call TagsParser#Debug(1, "TagsParser#WindowName() = " . g:TagsParserWindowName . tabpagenr())
  return g:TagsParserWindowName . tabpagenr()
endfunction
" >>>
" TagsParserExists- performs an exists test, and enables debugging. <<<
function! TagsParser#Exists(var)
  "return TagsParser#Debug(2, "exists(" . a:var . ") = " . a:val)
  "return "exists(a:var)"
endfunction!
" >>>
" TagsParserExec - Used to debug an exec command. <<<
function! TagsParser#Exec(command)
  call TagsParser#Debug(3, a:command)
  return a:command
endfunction!
" >>>
" TagsParserDebug - prints debugging messages if debug is enabled. <<<
function! TagsParser#Debug(level, string)
  if a:level <= g:TagsParserDebugFlag
    if g:TagsParserDebugTime == 1
      echomsg a:string . " ++ " . strftime("%X")
    elseif
      echomsg a:string
    endif
  endif
endfunction
" >>>

" Perl Functions

" TagsParserPerlFinishPerformOp - Call the correct op on files in the list <<<
function! TagsParser#PerlFinishPerformOp(fileList)
  call TagsParser#Debug(1, "TagsParser#PerlFinishPerformOp(" . a:fileList . ")")
perl << PerlFunc
  use strict;
  use warnings;
  no warnings 'redefine';

  my ($success, $files) = VIM::Eval('a:fileList');
  die "Failed to access list of files to tag" if !$success; 

  foreach my $file (split(/\n/, $files)) {
    VIM::DoCommand "call TagsParser#PerformOp('tag', '" . $file . "')";
  }
PerlFunc
endfunction
" >>>
" TagsParserPerlDisplayTags - Display perl tags data <<<
function! TagsParser#PerlDisplayTags()
  call TagsParser#Debug(1, "TagsParser#PerlDisplayTags()")
perl << PerlFunc
  use strict;
  use warnings;
  no warnings 'redefine';

  our %typeMap : unique unless (%typeMap);
  our %subTypeMap : unique unless (%subTypeMap);
  our $matchedTagWasFolded : unique unless($matchedTagWasFolded);
  our @matchedTagLines : unique unless(@matchedTagLines);

  # verify that we are able to display the correct file type
  my ($success, $kind) = VIM::Eval('s:origFileType');
  die "Failed to access filetype" if !$success;

  # get the name of the tag file for this file
  ($success, my $tagFileName) = VIM::Eval('s:origFileTagFileName');
  die "Failed to access tag file name ($tagFileName)" if !$success;

  # make sure that %tags is created (or referenced)
  our %tags : unique unless (%tags);

  # temp array to store our tag info... At the end of the file we will check
  # to see if this is different than the globalPrintData, if it is we update
  # the screen, if not then we do nothing so as to maintain any folded sections
  # the user has created.
  my @printData = ( );

  my $printLevel = 0;

  # get the name of the tag file for this file
  ($success, my $fileName) = VIM::Eval('s:origFileName');
  die "Failed to access file name ($fileName)" if !$success;

  # get the sort type flag
  ($success, my $sortType) = VIM::Eval('g:TagsParserSortType');
  die "Failed to access sort type ($sortType)" if !$success;

  # check on how we should display the tags
  ($success, my $dispSig) = VIM::Eval('g:TagsParserDisplaySignature');
  die "Failed to access display signature flag" if !$success;

  sub DisplayEntry {
    my $entryRef = shift(@_);
    my $localPrintLevel = shift(@_);

    # set the display string, tag or signature
    my $dispString;
    if ($dispSig == 1) {
      $dispString = $entryRef->{"pattern"};

      # remove all whitespace from the beginning and end of the display string
      $dispString =~ s/^\s*(.*)\s*$/$1/;
    }
    else {
      $dispString = $entryRef->{"tag"};
    }

    # each tag must have a {{{ at the end of it or else it could mess with the
    # folding... Since there are no end folds each tag must have a fold marker
    push @printData, [ ("\t" x $localPrintLevel) . $dispString .
      " {{{" . ($localPrintLevel + 1), $entryRef ];

    # now print any members there might be
    if (defined($entryRef->{"members"}) and
        defined($subTypeMap{$kind}{$entryRef->{"tagtype"}})) {
      $localPrintLevel++;
      # now print any members that this entry may have, only
      # show types which make sense, so for a "s" entry only
      # display "m", this is based on the subTypeMap data
      foreach my $subTypeRef (@{$subTypeMap{$kind}{$entryRef->{"tagtype"}}}) {
        # for each entry in the subTypeMap for this particular
        # entry, check if there are any entries, if there are print them
        if (defined $entryRef->{"members"}{$subTypeRef->[0]}) {
          # display a header (if one exists)
          if ($subTypeRef->[1] ne "") {
            push @printData, [ ("\t" x $localPrintLevel) . $subTypeRef->[1] .
              " {{{" . ($localPrintLevel + 1) ];
            $localPrintLevel++;
          }
       
          # display the data for this sub type, sort them properly based
          # on the global flag
          if ($sortType eq "alpha") {
            foreach my $member (sort { $a->{"tag"} cmp $b->{"tag"} }
              @{$entryRef->{"members"}{$subTypeRef->[0]}}) {
              DisplayEntry($member, $localPrintLevel);
            }
          }
          else {
            foreach my $member (sort { $a->{"line"} <=> $b->{"line"} }
              @{$entryRef->{"members"}{$subTypeRef->[0]}}) {
              DisplayEntry($member, $localPrintLevel);
            }
          }
       
          # reduce the print level if we increased it earlier
          # and print a fold end marker
          if ($subTypeRef->[1] ne "") {
            $localPrintLevel--;
          }
        }
      }
      $localPrintLevel--;
    }
  }

  # at the very top, print out the filename and a blank line
  push @printData, [ "$fileName {{{" . ($printLevel + 1) ];
  push @printData, [ "" ];
  $printLevel++;

  foreach my $ref (@{$typeMap{$kind}}) {
    # verify that there are any entries defined for this particular tag
    # type before we start trying to print them and that they don't have a
    # parent tag.

    my $printTopLevelType = 0;
    foreach my $typeCheckRef (@{$tags{$tagFileName}{$ref->[0]}}) {
      $printTopLevelType = 1 if !defined($typeCheckRef->{"parent"});
    }
     
    if ($printTopLevelType == 1) {
      push @printData, [ ("\t" x $printLevel) . $ref->[1] . " {{{" .
        ($printLevel + 1) ] ;
    
      $printLevel++;
      # now display all the tags for this particular type, and sort them
      # according to the sortType
      if ($sortType eq "alpha") {
        foreach my $tagRef (sort { $a->{"tag"} cmp $b->{"tag"} }
          @{$tags{$tagFileName}{$ref->[0]}}) {
          unless (defined $tagRef->{"parent"}) {
            DisplayEntry($tagRef, $printLevel);
          }
        }
      }
      else {
        foreach my $tagRef (sort { $a->{"line"} <=> $b->{"line"} }
          @{$tags{$tagFileName}{$ref->[0]}}) {
          unless (defined $tagRef->{"parent"}) {
            DisplayEntry($tagRef, $printLevel);
          }
        }
      }
      $printLevel--;

      # between each listing put a line
      push @printData, [ "" ];
    }
  }

  # this hash will be used to keep all of the data referenceable... So that we
  # will be able to print the correct information, reach that info when the tag
  # is to be selected, and find the current tag that the cursor is on in the
  # main window
  our @globalPrintData : unique = ( ) unless(@globalPrintData);

  # check the last file displayed... If it is blank then this is a forced
  # update
  ($success, my $lastFileDisplayed) = VIM::Eval('s:lastFileDisplayed');
  die "Failed to access last file displayed" if !$success;

  # check to see if the data has changed
  my $update = 1;
  if (($lastFileDisplayed ne "") and ($#printData == $#globalPrintData)) {
    $update = 0;
    for ( my $index = 0; $index <= $#globalPrintData; $index++ ) {
      if ($printData[$index][0] ne $globalPrintData[$index][0]) {
        $update = 1;
      }
      # no matter if the display data changed or not, make sure to assign the
      # tag reference to the global data... Otherwise things like line numbers
      # may have changed and the tag window would not have the proper data
      $globalPrintData[$index][1] = $printData[$index][1];
    }
  }

  # if the data did not change, do nothing and quit
  if ($update == 1) {
    # If the data has changed, be sure to reset the fold data.
    $matchedTagWasFolded = 0;
    @matchedTagLines = ();

    # set the globalPrintData array to the new print data contents
    @globalPrintData = @printData;

    # first clean the window
    $main::curbuf->Delete(1, $main::curbuf->Count());

    # set the first line
    $main::curbuf->Set(1, "");

    # append the rest of the data into the window, if this line looks
    # frightening, do a "perldoc perllol" and look at the Slices section
    $main::curbuf->Append(1, map { $printData[$_][0] } 0 .. $#printData);
  }

  # if the fold level is not set, go through the window now and fold any
  # tags that have members
  ($success, my $foldLevel) = VIM::Eval('exists("g:TagsParserFoldLevel")');
  $foldLevel = -1 if($success == 0 || $foldLevel == 0);

  our %typeMapHeadingFold : unique = ( ) unless(%typeMapHeadingFold);

  # Do this loop twice, once for normal folds, and a second time for heading
  # folds.
  FOLD_LOOP:
  for (my $index = 0; my $line = $globalPrintData[$index]; $index++) {
    # if this is a tag that has a parent and members, fold it
    if (($foldLevel == -1) and (defined $line->[1]) and
        (defined $line->[1]{"members"}) and (defined $line->[1]{"parent"})) {
      VIM::DoCommand("if foldclosed(" . ($index + 2) . ") == -1 | " .
                     ($index + 2) . "foldclose | endif");
    } # if (($foldLevel == -1) and (defined $line->[1]) and ...
    # we should fold all tags which only have members with empty headings
    elsif (($foldLevel == -1) and (defined $line->[1]) and
           (defined $line->[1]{"members"})) {
      foreach my $memberKey (keys %{$line->[1]{"members"}}) {
        foreach my $possibleType
          (@{$subTypeMap{$kind}{$line->[1]{"tagtype"}}}) {
          # immediately skip to the next loop iteration if we find that a
          # member exists for this tag which contains a non-empty heading
          next FOLD_LOOP if (($memberKey eq $possibleType->[0]) and
                             ($possibleType->[1] ne ""));
        }
      } # foreach my $memberKey (keys %{$line->[1]{"members"}}) {

      # if we made it this far then this tag should be folded
      VIM::DoCommand("if foldclosed(" . ($index + 2) . ") == -1 | " .
                     ($index + 2) . "foldclose | endif");
    } # elsif (($foldLevel == -1) and (defined $line->[1]) and ...
  } # for (my $index = 0; my $line = $globalPrintData[$index]; $index++) {

  FOLD_LOOP:
  for (my $index = 0; my $line = $globalPrintData[$index]; $index++) {
    # if this is a heading which has been marked for folding, fold it
    if ((defined $typeMapHeadingFold{$kind}) and
        (not defined $line->[1]) and ($line->[0] =~ /^\s+- .* {{{\d+$/)) {
      foreach my $heading (@{$typeMapHeadingFold{$kind}}) {
        VIM::DoCommand("if foldclosed(" . ($index + 2) . ") == -1 | " .
                       ($index + 2) . "foldclose | endif")
          if ($line->[0] =~ /^\s+$heading {{{\d+$/);
      }
    } # if ((defined $typeMapHeadingFold{$kind}) and
  } # for (my $index = 0; my $line = $globalPrintData[$index]; $index++) {
PerlFunc
endfunction
" >>>
" TagsParserPerlParseFile - Gather perl tags data <<<
function! TagsParser#PerlParseFile(tagFileName)
  call TagsParser#Debug(1, "TagsParser#PerlParseFile(" . a:tagFileName . ")")
perl << PerlFunc
  use strict;
  use warnings;
  no warnings 'redefine';

  use File::stat;

  # use local to keep %tags available for other functions
  our %tags : unique unless (%tags);
  our %tagMTime : unique unless (%tagMTime);
  our %tagsByLine : unique unless(%tagsByLine);
  our %kindMap : unique unless(%kindMap);
  
  # get access to the tag file and check it's last modify time
  my ($success, $tagFile) = VIM::Eval('a:tagFileName');
  die "Failed to access tag file variable ($tagFile)" if !$success;

  my $tagInfo = stat($tagFile);
  die "Failed to stat $tagFile" if !$tagInfo;

  # initialize the last modify time if it has not been accessed yet
  $tagMTime{$tagFile} = 0 if !defined($tagMTime{$tagFile});

  # if this file has been tagged before and the tag file has not been
  # updated, just exit
  if ($tagInfo->mtime <= $tagMTime{$tagFile}) {
    VIM::DoCommand "let s:tagsDataUpdated = 0";
    return;
  }
  $tagMTime{$tagFile} = $tagInfo->mtime;
  VIM::DoCommand "let s:tagsDataUpdated = 1";

  # if the tag entries are defined already for this file, delete them now
  delete $tags{$tagFile} if defined($tags{$tagFile});

  # open up the tag file and read the data
  open(TAGFILE, "<", $tagFile) or die "Failed to open tagfile $tagFile";
  while(<TAGFILE>) {
    next if /^!_TAG.*/;
    # process the data
    chomp;

    # split the stuff around the pattern with tabs, and remove the pattern
    # using the special separator ;" character sequence to guard against the
    # possibility of embedded tabs in the pattern
    my ($tag, $file, $rest) = split(/\t/, $_, 3);
    (my $pattern, $rest) = split(/;"\t/, $rest, 2);
    my ($type, $fields) = split(/\t/, $rest, 2);

    # cleanup pattern to remove the / /;" from the beginning and end of the
    # tag search pattern, the hard part is that sometimes the $ may not be at
    # the end of the pattern
    if ($pattern =~ m|/\^(.*)\$/|) {
      $pattern = $1;
    }
    else {
      $pattern =~ s|/\^(.*)/|$1|;
    }

    # there may be some escaped /'s in the pattern, un-escape them
    $pattern =~ s|\\/|/|g;

    # if the " file:" tag is here, remove it, we want it to be in the file
    # since Vim can use the file: field to know if something is file static,
    # but we don't care about it much for this script, and it messes up my
    # hash creation
    $fields =~ s/\tfile://;

    # Verify that a separator exists.
    ($success, my $prjKey) = VIM::Eval("TagsParser#GetProject()");
    die "Failed to retrieve project" if !$success;
    ($success, my $separator) = VIM::Eval(
      "TagsParser#GetQualifiedTagSeparator($prjKey)");
    die "Failed to retrieve qualified tag separator" if !$success;

    if (length($separator) != 0) {
      # Since the separator exists, check to see if there is one in the
      # current tag.
      ($success, my $noSeparator) = VIM::Eval(
        "'$tag' !~ g:TagsParserCtagsQualifiedTagSeparator");
      die "Failed to check if $tag contains a qualified tag separator"
        if !$success;
    
      if ($noSeparator or (index($pattern, $tag) != -1)) {
        push @{$tags{$tagFile}{$type}}, { "tag", $tag, "tagtype", $type,
          "pattern", $pattern, split(/\t|:/, $fields) };
      }
    } # if (length($separator) != 0) {
  } # while(<TAGFILE>) {
  close(TAGFILE);

  # before worrying about anything else, make up a line number-oriented hash of
  # the tags, this will make finding a match, or what the current tag is easier
  delete $tagsByLine{$tagFile} if defined($tagsByLine{$tagFile});

  while (my ($key, $typeArray) = each %{$tags{$tagFile}}) {
    foreach my $tagEntry (@{$typeArray}) {
      push @{$tagsByLine{$tagFile}{$tagEntry->{"line"}}}, $tagEntry;
    }
  }

  ($success, my $kind) = VIM::Eval('&filetype');
  die "Failed to access current file type" if !$success;

  ($success, my $noNestedTags) = VIM::Eval('g:TagsParserNoNestedTags');
  die "Failed to access the nested tag display flag" if !$success;

  # parse the data we just read into hierarchies... If we don't have a
  # kind hash entry for the current file type, just skip the rest of this
  # function
  return if (not defined($kindMap{$kind}) or $noNestedTags == 1);

  # for each key, sort it's entries.  These are the tags for each tag,
  # check for any types which have a scope, and if they do, reference that type
  # to the correct parent type
  #
  # yeah, this loop sucks, but I haven't found a more efficient way to do
  # it yet
  foreach my $key (keys %{$tags{$tagFile}}) {
    foreach my $tagEntry (@{$tags{$tagFile}{$key}}) {
      while (my ($tagType, $tagTypeName) = each %{$kindMap{$kind}}) {
        # search for any member types of the current tagEntry, but only if
        # such a member is defined for the current tag
        if (defined($tagEntry->{$tagTypeName}) and
            defined($tags{$tagFile}{$tagType})) {
          # sort the possible member entries into reverse order by line number 
          # so that when looking for the parent entry we are sure to only get
          # the one who's line is just barely less than the current tag's line
          FIND_PARENT:
          foreach my $tmpEntry (sort { $b->{"line"} <=> $a->{"line"} }
            @{$tags{$tagFile}{$tagType}}) {
            # for the easiest way to do this, only consider tags a match if
            # the line number of the possible parent tag is less than or equal
            # to the line number of the current tagEntry
            if (($tmpEntry->{"tag"} eq $tagEntry->{$tagTypeName}) and
              ($tmpEntry->{"line"} <= $tagEntry->{"line"})) {
              # push a reference to the current tag onto the parent tag's
              # member stack
              push @{$tmpEntry->{"members"}{$key}}, $tagEntry;
              $tagEntry->{"parent"} = $tmpEntry;
              last FIND_PARENT;
            } # if (($tmpEntry->{"tag"} eq $tagEntry->{$tagTypeName}) ...
          } # foreach my $tmpEntry (sort { $b->{"line"} <=> ...
        } # if (defined($tagEntry->{$tagTypeName}) and ...
      } # while (my ($tagType, $tagTypeName) = each %{$kindMap{$kind}}) {
    } # foreach my $tagEntry (@{$tags{$tagFile}{$key}}) {
  } # foreach my $key (keys %{$tags{$tagFile}}) {

  # processing those local vars for C
  if (($kind =~ /c|h|cpp/) and (defined $tags{$tagFile}{"l"}) and
    (defined $tags{$tagFile}{"f"})) {
    # setup a reverse list of local variable references sorted by line
    my @vars = sort { $b->{"line"} <=> $a->{"line"} } @{$tags{$tagFile}{"l"}};

    # sort the functions by reversed line entry... Then we will go through the
    # list of local variables until we find one who's line number exceeds that
    # of the functions.  Then we unshift the array and go to the next function
    FUNC: foreach my $funcRef (sort { $b->{"line"} <=> $a->{"line"} }
      @{$tags{$tagFile}{"f"}}) {
      VAR: while (my $varRef = shift @vars) {
        if ($varRef->{"line"} >= $funcRef->{"line"}) {
          push @{$funcRef->{"members"}{"l"}}, $varRef;
          $varRef->{"parent"} = $funcRef;
          next VAR;
        }
        else {
          unshift(@vars, $varRef);
          next FUNC;
        }
      }
    }
  }
PerlFunc
endfunction
" >>>
" TagsParserPerlSelectTag - Use perl data move to current tag <<<
function! TagsParser#PerlSelectTag()
  call TagsParser#Debug(1, "TagsParser#PerlSelectTag()")
perl << PerlFunc
  use strict;
  use warnings;
  no warnings 'redefine';

  our $matchedTagWasFolded : unique unless($matchedTagWasFolded);
  our @matchedTagLines : unique unless(@matchedTagLines);

  # clear out any previous match
  if ($matchedTagWasFolded == 1) {
    while (scalar(@matchedTagLines) != 0) {
      VIM::DoCommand "$matchedTagLines[0][0],$matchedTagLines[0][1]foldclose";
      shift @matchedTagLines;
    }
    $matchedTagWasFolded = 0;
  }

  VIM::DoCommand "let s:matchedTagLine = 0";
  VIM::DoCommand "match none";

  my ($success, $lineNum) = VIM::Eval('line(".")');
  die "Failed to access The current line" if !$success;

  our @globalPrintData : unique unless(@globalPrintData);

  # subtract 2 (1 for the append offset, and 1 because it starts at 0) from
  # the line number to get the proper globalPrintData index
  my $indexNum = $lineNum - 2;

  # if this is a tag, there will be a reference to the correct tag entry in
  # the referenced globalPrintData array
  if (defined $globalPrintData[$indexNum][1]) {
    # if this line is folded, unfold it
    ($success, my $folded) = VIM::Eval("foldclosed($lineNum)");
    die "Failed to verify if $lineNum is folded" if !$success;

    # While the desired line is still folded, keep unfolding.
    while ($folded != -1) {
      ($success, my $foldEnd) = VIM::Eval("foldclosedend($lineNum)");
      die "Failed to retrieve end of fold for line $lineNum" if !$success;

      # I've seen a strange bug lately where the foldclosedend() can 
      # return a value that is larger than the number of lines in the 
      # buffer.  So as a work around if the end line # is too big just 
      # reset it to be the last line in the buffer.
      ($success, my $lastLine) = VIM::Eval("line('\$')");
      die "Failed to retrieve last line in buffer ($lastLine)" if !$success;

      $foldEnd = $lastLine if($foldEnd > $lastLine);

      unshift(@matchedTagLines, [ $folded, $foldEnd ]);

      # Now unfold the current line
      VIM::DoCommand "$matchedTagLines[0][0],$matchedTagLines[0][1]foldopen";
      $matchedTagWasFolded = 1;

      ($success, $folded) = VIM::Eval("foldclosed($lineNum)");
      die "Failed to verify if $lineNum is folded" if !$success;
    } # while ($folded != -1) {

    # now match this tag
    VIM::DoCommand 'match TagsParserHighlight /\%' . $lineNum .
      'l\S.*\( {{{\)\@=/';
    VIM::DoCommand "let s:matchedTagLine = $lineNum";

    # go to the proper window, go the correct line, unfold it (if necessary),
    # move to the correct word (the tag) and finally, set a mark
    VIM::DoCommand
      'exec TagsParser#Exec(bufwinnr(s:origFileName) . "wincmd w")';
    VIM::DoCommand $globalPrintData[$indexNum][1]{"line"};

    # now find out where the tag is on the current line, and move to it if a
    # valid match is found
    VIM::DoCommand "let l:position = match(getline('.'), '\\s\\zs" .
      $globalPrintData[$indexNum][1]{"tag"} . "') | if l:position != -1 | " .
      "exec TagsParser#Exec('normal! 0' . l:position . 'l') | endif";

    VIM::DoCommand "if foldclosed('.') != -1 | .foldopen | endif";
    VIM::DoCommand "normal! m\'";
  } # if (defined $globalPrintData[$indexNum][1]) {
  else {
    # otherwise we should just toggle this fold open/closed if the line is
    # actually folded
    VIM::DoCommand "if foldclosed('.') != -1 | .foldopen | else | .foldclose | endif";
  }
PerlFunc
endfunction
" >>>
" TagsParserPerlFindTag - Find currently highlighted tag in perl tag data <<<
function! TagsParser#PerlFindTag(curPattern, curLine, curWord)
  call TagsParser#Debug(1, "TagsParser#PerlFindTag(" . a:curPattern . ", " . a:curLine . ", " . a:curWord . ")")
perl << PerlFunc
  use strict;
  use warnings;
  no warnings 'redefine';

  our $matchedTagWasFolded : unique unless($matchedTagWasFolded);
  our @matchedTagLines : unique unless(@matchedTagLines);

  # clear out any previous match
  if ($matchedTagWasFolded == 1) {
    while (scalar(@matchedTagLines) != 0) {
      VIM::DoCommand "$matchedTagLines[0][0],$matchedTagLines[0][1]foldclose";
      shift @matchedTagLines;
    }
    $matchedTagWasFolded = 0;
  }

  VIM::DoCommand "let s:matchedTagLine = 0";
  VIM::DoCommand "match none";

  my ($success, $curPattern) = VIM::Eval('a:curPattern');
  die "Failed to access current pattern" if !$success;

  ($success, my $curLine) = VIM::Eval('a:curLine');
  die "Failed to access current line" if !$success;

  ($success, my $curWord) = VIM::Eval('a:curWord');
  die "Failed to access current word" if !$success;

  # get the name of the tag file for this file
  ($success, my $tagFileName) = VIM::Eval('s:origFileTagFileName ');
  die "Failed to access file name ($tagFileName)" if !$success;

  our @globalPrintData : unique unless (@globalPrintData);
  our %tagsByLine : unique unless(%tagsByLine);

  my $easyRef = undef;
  my $trueRef = undef;

  # now look up this tag, try to find an exact match (useful for lists of
  # variables, enumerations and so on).
  if (defined $tagsByLine{$tagFileName}{$curLine}) {
    TRUE_REF_SEARCH:
    foreach my $ref (@{$tagsByLine{$tagFileName}{$curLine}}) {
      if (substr($curPattern, 0, length($ref->{"pattern"})) eq
          $ref->{"pattern"}) {
        if ($curWord eq $ref->{"tag"}) {
          $trueRef = $ref;
          last TRUE_REF_SEARCH;
        }
        elsif (!defined $easyRef) {
          $easyRef = $ref;
        }
      } # if (substr($curPattern, 0, length($ref->{"pattern"})) eq ...
    } # TRUE_REF_SEARCH: ...

    # if we didn't find an exact match go with the default match
    $trueRef = $easyRef if (not defined($trueRef));

    # now we have to find the correct line for this tag in the globalPrintData
    my $index = 0;
    while (my $line = $globalPrintData[$index++]) {
      if (defined $line->[1] and $line->[1] == $trueRef) {
        my $tagLine = $index + 1;

        # get the initial fold start
        ($success, my $folded) = VIM::Eval("foldclosed($tagLine)");
        die "Failed to verify if $tagLine is folded" if !$success;
      
        # While the desired line is still folded, keep unfolding.
        while ($folded != -1) {
          ($success, my $foldEnd) = VIM::Eval("foldclosedend($tagLine)");
          die "Failed to retrieve end of fold for line $tagLine" if !$success;

          # I've seen a strange bug lately where the foldclosedend() can 
          # return a value that is larger than the number of lines in the 
          # buffer.  So as a work around if the end line # is too big just 
          # reset it to be the last line in the buffer.
          ($success, my $lastLine) = VIM::Eval("line('\$')");
          die "Failed to retrieve last line in buffer ($lastLine)"
            if !$success;
         
          $foldEnd = $lastLine if($foldEnd > $lastLine);

          unshift(@matchedTagLines, [ $folded, $foldEnd ]);
         
          # Now unfold the current line
          VIM::DoCommand
            "$matchedTagLines[0][0],$matchedTagLines[0][1]foldopen";
          $matchedTagWasFolded = 1;
         
          ($success, $folded) = VIM::Eval("foldclosed($tagLine)");
          die "Failed to verify if $tagLine is folded" if !$success;
        } # while ($folded != -1) {

        # now match this tag
        VIM::DoCommand 'match TagsParserHighlight /\%' . $tagLine .
          'l\S.*\( {{{\)\@=/';
        VIM::DoCommand "let s:matchedTagLine = $tagLine";

        # now that the tag has been highlighted, go to the tag and make the
        # line visible, and then go back to the tag line so that the cursor
        # is in the correct place
        VIM::DoCommand $tagLine;
        VIM::DoCommand "exec winline()";
        VIM::DoCommand $tagLine;

        last;
      } # if ($line->[1] == $trueRef) {
    } # while (my $line = $globalPrintData[$index++]) {
  } # if (defined $tagsByLine{$tagFileName}{$curLine}) {
PerlFunc
endfunction
" >>>

let &cpo = s:cpoSave
unlet s:cpoSave

" vim:ft=vim:fdm=marker:ff=unix:wrap:ts=2:sw=2:sts=2:sr:et:fmr=<<<,>>>:fdl=0
