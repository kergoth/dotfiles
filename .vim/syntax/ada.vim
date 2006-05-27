"------------------------------------------------------------------------------
"  Description: Vim Ada syntax file
"     Language:	Ada (2005)
"          $Id: ada.vim 214 2006-05-25 09:24:57Z krischik $
"    Copyright: Copyright (C) 2006 Martin Krischik
"   Maintainer:	Martin Krischik 
"               David A. Wheeler <dwheeler@dwheeler.com>
"               Simon Bradley <simon.bradley@pitechnology.com>
" Contributors: Preben Randhol.
"      $Author: krischik $
"        $Date: 2006-05-25 11:24:57 +0200 (Do, 25 Mai 2006) $
"      Version: 2.1 
"    $Revision: 214 $
"     $HeadURL: https://svn.sourceforge.net/svnroot/gnuada/trunk/tools/vim/syntax/ada.vim $
"               http://www.dwheeler.com/vim
"      History: 24.05.2006 MK Unified Headers
"               26.05.2006 MK ' should not be in iskeyword.
"	 Usage: copy to syntax directory
"------------------------------------------------------------------------------
" The formal spec of Ada 2005 (ARM) is the "Ada 2005 Reference Manual".
" For more Ada 2005 info, see http://www.gnuada.org and http://www.adapower.com.
"
" This vim syntax file works on vim 5.6, 5.7, 5.8 6.x and 7.0
" It implements Bram Moolenaar's April 25, 2001 recommendations to make
" the syntax file maximally portable across different versions of vim.
" If vim 6.0+ is available,
" this syntax file takes advantage of the vim 6.0 advanced pattern-matching
" functions to avoid highlighting uninteresting leading spaces in
" some expressions containing "with" and "use".
"------------------------------------------------------------------------------
" Customize:
"    let g:ada_standard_types		= 1     Hilight standart types
"    let g:ada_space_errors		= 1     Hilight space errors
"    let g:ada_no_trail_space_error     = 1         - but not tail spaces
"    let g:ada_no_tab_space_error       = 1         - but not tab use
"    let g:ada_all_tab_usage            = 1         - highligt all tab use
"    let g:ada_line_errors              = 1     Hilight lines longer then 79
"    let g:ada_folding			= 1     Use folding
"    let g:ada_abbrev			= 1     Add some abbrevs
"    let g:ada_with_gnat_project_files	= 1     Add gnat project file keywords
"    let g:ada_withuse_ordinary         = 1     no special use and with colors
"    let g:ada_rainbow_color            = 1     use rainbow color for ( and )
"    let g:ada_begin_preproc            = 1     special begin colors
"    let g:ada_default_compiler         = gnat  set default compiler
"------------------------------------------------------------------------------

if exists("b:current_syntax") || version < 700
    finish
else
    " Ada is entirely case-insensitive.
    syntax case ignore
    setlocal nosmartcase
    setlocal ignorecase

    " Highlighting commands.  There are 72 reserved words in total in Ada2005.
    " Some keywords are used in more than one way. For example:
    " 1. "end" is a general keyword, but "end if" ends a Conditional.
    " 2. "then" is a conditional, but "and then" is an operator.

    if  !exists ('g:Ada_Keywords')
        runtime ftplugin/ada.vim
    endif

    for b:Item in g:Ada_Keywords
        " Standard Exceptions (including I/O).
        " We'll highlight the standard exceptions, similar to vim's Python mode.
        " It's possible to redefine the standard exceptions as something else,
        " but doing so is very bad practice, so simply highlighting them makes sense.
        if b:Item['kind'] == "x" 
            execute "syntax keyword adaException " . b:Item['word']
        endif
        if b:Item['kind'] == "a" 
            execute 'syntax match adaAttribute "\V' . b:Item['word'] . '"'
        endif
        " We don't normally highlight types in package Standard
        " (Integer, Character, Float, etc.).  I don't think it looks good
        " with the other type keywords, and many Ada programs define
        " so many of their own types that it looks inconsistent.
        " However, if you want this highlighting, turn on "ada_standard_types".
        " For package Standard's definition, see ARM section A.1.
        if b:Item['kind'] == "t" && exists ("g:ada_standard_types")
            execute "syntax keyword adaBuiltinType " . b:Item['word']
        endif
    endfor 

    syntax keyword  adaLabel	others

    syntax keyword  adaOperator	abs mod not rem xor
    syntax match    adaOperator	"\<and\>"
    syntax match    adaOperator	"\<and\s\+then\>"
    syntax match    adaOperator	"\<or\>"
    syntax match    adaOperator	"\<or\s\+else\>"
    syntax match    adaOperator	"[-+*/<>&]"
    syntax keyword  adaOperator	**
    syntax match    adaOperator	"[/<>]="
    syntax keyword  adaOperator	=>
    syntax match    adaOperator	"\.\."
    syntax match    adaOperator	"="

    " Handle the box, <>, specially:
    syntax keyword  adaSpecial      <>

    if exists("g:ada_rainbow_color")
        syntax match    adaSpecial	 "[:;.,]"
        runtime plugin/Rainbow_Parenthsis.vim
    else
        syntax match    adaSpecial	 "[:;().,]"
    endif

    " We won't map "adaAssignment" by default, but we need to map ":=" to
    " something or the "=" inside it will be mislabelled as an operator.
    " Note that in Ada, assignment (:=) is not considered an operator.
    syntax match adaAssignment		":="

    " Numbers, including floating point, exponents, and alternate bases.
    syntax match   adaNumber		"\<\d[0-9_]*\(\.\d[0-9_]*\)\=\([Ee][+-]\=\d[0-9_]*\)\=\>"
    syntax match   adaNumber		"\<\d\d\=#\x[0-9A-Fa-f_]*\(\.\x[0-9A-Fa-f_]*\)\=#\([Ee][+-]\=\d[0-9_]*\)\="

    " Identify leading numeric signs. In "A-5" the "-" is an operator,
    " but in "A:=-5" the "-" is a sign. This handles "A3+-5" (etc.) correctly.
    " This assumes that if you put a don't put a space after +/- when it's used
    " as an operator, you won't put a space before it either -- which is true
    " in code I've seen.
    syntax match adaSign "[[:space:]<>=(,|:;&*/+-][+-]\d"lc=1,hs=s+1,he=e-1,me=e-1

    " Labels for the goto statement.
    syntax region  adaLabel		start="<<"  end=">>"

    " Boolean Constants.
    syntax keyword adaBoolean	true false

    " Warn people who try to use C/C++ notation erroneously:
    syntax match adaError "//"
    syntax match adaError "/\*"
    syntax match adaError "=="


    if exists("g:ada_space_errors")
      if !exists("g:ada_no_trail_space_error")
        syntax match   adaSpaceError     excludenl "\s\+$"
      endif
      if !exists("g:ada_no_tab_space_error")
        syntax match   adaSpaceError     " \+\t"me=e-1
      endif
      if !exists("g:ada_all_tab_usage")
        syntax match   adaSpecial        "\t"
      endif  
    endif

    " Unless special ("end loop", "end if", etc.), "end" marks the end of a
    " begin, package, task etc. Assiging it to adaEnd.
    syntax match    adaEnd	"\<end\>"

    syntax keyword adaPreproc		pragma

    syntax keyword adaRepeat	exit for loop reverse while
    syntax match adaRepeat		"\<end\s\+loop\>"

    syntax keyword adaStatement	accept delay goto raise requeue return
    syntax keyword adaStatement	terminate
    syntax match adaStatement	"\<abort\>"

    " Handle Ada's record keywords.
    " 'record' usually starts a structure, but "with null record;" does not,
    " and 'end record;' ends a structure.  The ordering here is critical -
    " 'record;' matches a "with null record", so make it a keyword (this can
    " match when the 'with' or 'null' is on a previous line).
    " We see the "end" in "end record" before the word record, so we match that
    " pattern as adaStructure (and it won't match the "record;" pattern).
    syntax match adaStructure	 "\<record\>"
    syntax match adaStructure	 "\<end\s\+record\>"
    syntax match adaKeyword		 "\<record;"me=e-1

    syntax keyword adaStorageClass	abstract access aliased array at constant delta
    syntax keyword adaStorageClass	digits limited of private range tagged
    syntax keyword adaStorageClass	interface synchronized
    syntax keyword adaTypedef	subtype type

    " Conditionals. "abort" after "then" is a conditional of its own.
    syntax match    adaConditional  "\<then\>"
    syntax match    adaConditional	"\<then\s\+abort\>"
    syntax match    adaConditional	"\<else\>"
    syntax match    adaConditional	"\<end\s\+if\>"
    syntax match    adaConditional	"\<end\s\+case\>"
    syntax match    adaConditional	"\<end\s\+select\>"
    syntax keyword  adaConditional	if case select
    syntax keyword  adaConditional	elsif when

    syntax keyword  adaKeyword      all do exception in is new null out
    syntax keyword  adaKeyword      separate until overriding

    " These keywords begin various constructs, and you _might_ want to
    " highlight them differently.
    syntax keyword  adaBegin        begin body declare entry function generic 
    syntax keyword  adaBegin	package procedure protected renames task  

    if exists("ada_with_gnat_project_files")
       syntax keyword adaBegin	project 
    endif

    if exists("ada_withuse_ordinary")
       " Don't be fancy. Display "with" and "use" as ordinary keywords in all cases.
       syntax keyword adaKeyword		with use
    else
       " Highlight "with" and "use" clauses like C's "#include" when they're used
       " to reference other compilation units; otherwise they're ordinary keywords.
       " If we have vim 6.0 or later, we'll use its advanced pattern-matching
       " capabilities so that we won't match leading spaces.
       syntax match adaKeyword	"\<with\>"
       syntax match adaKeyword	"\<use\>"
       if version < 600
          syntax match adaBeginWith "^\s*\(\(with\(\s\+type\)\=\)\|\(use\)\)\>" contains=adaInc
          syntax match adaSemiWith	";\s*\(\(with\(\s\+type\)\=\)\|\(use\)\)\>"lc=1 contains=adaInc
       else
          syntax match adaBeginWith "^\s*\zs\(\(with\(\s\+type\)\=\)\|\(use\)\)\>" contains=adaInc
          syntax match adaSemiWith	";\s*\zs\(\(with\(\s\+type\)\=\)\|\(use\)\)\>" contains=adaInc
       endif
       syntax match adaInc	"\<with\>" contained contains=NONE
       syntax match adaInc	"\<with\s\+type\>" contained contains=NONE
       syntax match adaInc	"\<use\>" contained contains=NONE
       " Recognize "with null record" as a keyword (even the "record").
       syntax match adaKeyword	"\<with\s\+null\s\+record\>"
       " Consider generic formal parameters of subprograms and packages as keywords.
       if version < 600
          syntax match adaKeyword	";\s*with\s\+\(function\|procedure\|package\)\>"
          syntax match adaKeyword	"^\s*with\s\+\(function\|procedure\|package\)\>"
       else
          syntax match adaKeyword	";\s*\zswith\s\+\(function\|procedure\|package\)\>"
          syntax match adaKeyword	"^\s*\zswith\s\+\(function\|procedure\|package\)\>"
        endif
    endif


    " String and character constants.
    syntax region  adaString		start=+"+  skip=+""+  end=+"+
    syntax match   adaCharacter	"'.'"

    " Todo (only highlighted in comments)
    syntax keyword adaTodo contained TODO FIXME XXX

    " Comments.
    syntax region  adaComment oneline contains=adaTodo,adaLineError start="--"  end="$"

    if exists("g:ada_line_errors")
        syntax match adaLineError "\(^.\{79}\)\@<=."  contains=ALL containedin=ALL
    endif 

    " Define the default highlighting.
    " For version 5.7 and earlier: only when not done already
    " For version 5.8 and later: only when an item doesn't have highlighting yet
    if version >= 508 || !exists("g:did_ada_syn_inits")
       if version < 508
          let did_ada_syn_inits = 1
          command -nargs=+ HiLink highlight link <args>
       else
          command -nargs=+ HiLink highlight def link <args>
       endif

       " The default methods for highlighting. Can be overridden later.
       HiLink adaCharacter	   Character
       HiLink adaComment	   Comment
       HiLink adaConditional   Conditional
       HiLink adaKeyword	   Keyword
       HiLink adaLabel	   Label
       HiLink adaNumber	   Number
       HiLink adaSign	   Number
       HiLink adaOperator	   Operator
       HiLink adaPreproc	   PreProc
       HiLink adaRepeat	   Repeat
       HiLink adaSpecial	   Special
       HiLink adaStatement	   Statement
       HiLink adaString	   String
       HiLink adaStructure	   Structure
       HiLink adaTodo	   Todo
       HiLink adaType	   Type
       HiLink adaTypedef	   Typedef
       HiLink adaStorageClass  StorageClass
       HiLink adaBoolean	   Boolean
       HiLink adaException	   Exception
       HiLink adaAttribute	   Tag
       HiLink adaInc	   Include
       HiLink adaError	   Error
       HiLink adaSpaceError	   Error
       HiLink adaLineError	   Error
       HiLink adaBuiltinType   Type
       HiLink adaAssignment	   Special

       if exists ("ada_begin_preproc")
          " This is the old default display:
          HiLink adaBegin	PreProc
          HiLink adaEnd	PreProc
       else
          " This is the new default display:
          HiLink adaBegin	Keyword
          HiLink adaEnd	Keyword
       endif

       delcommand HiLink
    endif

    setlocal commentstring=--\ \ %s
    setlocal comments+=:--\ \ 
    setlocal formatoptions+=ron

    if exists("g:ada_folding")
        syntax sync minlines=1 maxlines=1
        setlocal foldmethod=indent
        setlocal foldignore=--
        setlocal tabstop=8
        setlocal softtabstop=3
        setlocal shiftwidth=3
    else
        " We don't need to look backwards to highlight correctly;
        " this speeds things up greatly.
        syntax sync minlines=1 maxlines=1
    endif

    if exists("g:ada_abbrev")
       iabbrev ret  return
       iabbrev proc procedure
       iabbrev pack package
       iabbrev func function
    endif

    let b:current_syntax = "ada"

    if exists("g:ada_default_compiler")
        execute "compiler" g:ada_default_compiler
    endif
    finish
endif

"------------------------------------------------------------------------------
"   Copyright (C) 2006  Martin Krischik
"
"   This program is free software; you can redistribute it and/or
"   modify it under the terms of the GNU General Public License
"   as published by the Free Software Foundation; either version 2
"   of the License, or (at your option) any later version.
"   
"   This program is distributed in the hope that it will be useful,
"   but WITHOUT ANY WARRANTY; without even the implied warranty of
"   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"   GNU General Public License for more details.
"   
"   You should have received a copy of the GNU General Public License
"   along with this program; if not, write to the Free Software
"   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
"------------------------------------------------------------------------------
"vim: textwidth=78 nowrap tabstop=8 shiftwidth=3 softtabstop=3 noexpandtab
"vim: filetype=vim encoding=latin1 fileformat=unix
