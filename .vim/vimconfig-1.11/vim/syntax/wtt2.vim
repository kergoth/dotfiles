" Vim syntax file
" Language:		Template Toolkit (http://www.template-toolkit.org/)
"               template for WML (WAP page) 
" Maintainer:	Lubomir Host 'rajo' <rajo AT platon.sk>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/syntax/wtt2.vim,v 1.2 2005/01/13 11:34:33 rajo Exp $


if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

if !exists("main_syntax")
  let main_syntax = 'wtt2'
endif

if version < 600
  so <sfile>:p:h/wml.vim
else
  runtime syntax/wml.vim
  unlet b:current_syntax
endif

syn case ignore

syn match tt2Block contained "[\[\]]"

" Env Variables
syn keyword	tt2EnvVar	GATEWAY_INTERFACE SERVER_NAME SERVER_SOFTWARE SERVER_PROTOCOL REQUEST_METHOD QUERY_STRING DOCUMENT_ROOT HTTP_ACCEPT HTTP_ACCEPT_CHARSET HTTP_ENCODING HTTP_ACCEPT_LANGUAGE HTTP_CONNECTION HTTP_HOST HTTP_REFERER HTTP_USER_AGENT REMOTE_ADDR REMOTE_PORT SCRIPT_FILENAME SERVER_ADMIN SERVER_PORT SERVER_SIGNATURE PATH_TRANSLATED SCRIPT_NAME REQUEST_URI	contained

" Function and Methods ripped from http://www.php.net/distributions/manual/php_manual_de.tar.bz2 Apr 2003
syn keyword	tt2Functions	contained format upper lower ucfirst lcfirst trim collapse 
syn keyword	tt2Functions	contained html html_entity html_para html_break html_para_break html_line_break 
syn keyword	tt2Functions	contained indent truncate repeat remove
syn keyword	tt2Functions	contained uri replace redirect
syn keyword	tt2Functions	contained eval evaltt perl evalperl 
syn keyword	tt2Functions	contained stdout stderr null latex

" Scalar Virtual Methods
syn keyword	tt2Functions	contained defined length repeat replace match search split chunk list hash size
" Hash Virtual Methods
syn keyword	tt2Functions	contained keys values each sort nsort import defined exists size item list
" List Virtual Methods
syn keyword	tt2Functions	contained first last size max reverse join grep sort nsort unshift push shift pop unique merge slice splice 

syn keyword	tt2Functions	contained nsort1


syn keyword tt2Functions GET CALL SET DEFAULT WRAPPER
syn keyword tt2Functions BLOCK MACRO
syn keyword tt2Functions FILTER USE PERL RAWPERL
syn keyword tt2Functions TRY THROW CATCH FINAL
syn keyword tt2Functions NEXT LAST RETURN CLEAR META
syn keyword tt2Functions TAGS DEBUG VIEW

syn keyword tt2Repeat IF UNLESS ELSIF ELSE END SWITCH CASE FOREACH FOR WHILE

"syn keyword tt2InFunc ne eq

syn keyword tt2Filter format upper lower ucfirst lcfirst trim collapse
syn keyword tt2Filter html html_entity html_para html_break html_para_break html_line_break
syn keyword tt2Filter uri indent truncate repeat remove replace redirect
syn keyword tt2Filter eval evaltt perl evalperl stdout stderr null latex

"syn keyword tt2Property contained "file="
"syn keyword tt2Property contained "loop="
"syn keyword tt2Property contained "name="
"syn keyword tt2Property contained "include="
"syn keyword tt2Property contained "skip="
"syn keyword tt2Property contained "section="

" Operator
syn match	tt2Operator	"[-=+%^&|*!.~?:]"	contained display
syn match	tt2Operator	"[-+*/%^&|.]="	contained display
syn match	tt2Operator	"/[^*/]"me=e-1	contained display
syn match	tt2Operator	"\$"	contained display
syn match	tt2Operator	"&&\|\<and\>"	contained display
syn match	tt2Operator	"||\|\<x\=or\>"	contained display

syn match	tt2Relation	"[!=<>]="	contained display
syn match	tt2Relation	"[<>]"	contained display
syn match	tt2MemberSelector	"->"	contained display
syn match	tt2VarSelector	"\$"	contained display

" Identifier
syn match	tt2Identifier	"$\h\w*"	contained contains=tt2EnvVar,tt2VarSelector display
syn match	tt2IdentifierSimply	"${\h\w*}"	contains=tt2Operator,tt2Parent	contained display
syn region	tt2IdentifierComplex	matchgroup=tt2Parent start="{\$"rs=e-1 end="}"	contains=tt2Identifier,tt2MemberSelector,tt2VarSelector,tt2IdentifierComplexP	contained extend
syn region	tt2IdentifierComplexP	matchgroup=tt2Parent start="\[" end="]"	contains=@tt2ClInside	contained

" Methoden
syn match	tt2MethodsVar	"->\h\w*"	contained contains=tt2Methods,tt2MemberSelector display

" Include
syn keyword tt2Include INSERT INCLUDE PROCESS contained

" Number
syn match tt2Number	"-\=\<\d\+\>"	contained display
syn match tt2Number	"\<0x\x\{1,8}\>"	contained display

" Float
syn match tt2Float	"\(-\=\<\d+\|-\=\)\.\d\+\>"	contained display

" SpecialChar
syn match tt2SpecialChar	"\\[abcfnrtyv\\]"	contained display
syn match tt2SpecialChar	"\\\d\{3}"	contained contains=tt2OctalError display
syn match tt2SpecialChar	"\\x\x\{2}"	contained display

" Todo
syn keyword	tt2Todo	todo fixme xxx	contained

" Comment
syn match	tt2Comment	"#.\{-}%]"me=e-2	contained contains=tt2Todo

" String
if exists("tt2_parent_error_open")
  syn region	tt2StringDouble	matchgroup=None start=+"+ skip=+\\\\\|\\"+ end=+"+	contains=@tt2AddStrings,tt2Identifier,tt2SpecialChar,tt2IdentifierSimply,tt2IdentifierComplex	contained keepend
  syn region	tt2StringSingle	matchgroup=None start=+'+ skip=+\\\\\|\\'+ end=+'+	contains=@tt2AddStrings contained keepend
else
  syn region	tt2StringDouble	matchgroup=None start=+"+ skip=+\\\\\|\\"+ end=+"+	contains=@tt2AddStrings,tt2Identifier,tt2SpecialChar,tt2IdentifierSimply,tt2IdentifierComplex contained extend keepend
  syn region	tt2StringSingle	matchgroup=None start=+'+ skip=+\\\\\|\\'+ end=+'+	contains=@tt2AddStrings contained keepend extend
endif

"syn region tt2Zone matchgroup=Delimiter start="\[%[-]*" end="[-]*%\]" contains=tt2Property, tt2String, tt2Block, tt2TagName, tt2InFunc, tt2Filter, tt2IdentifierComplex
syn region tt2Zone matchgroup=Delimiter start="\[%[-]*" end="[-]*%\]" contains=@tt2ClTop

syn region  htmlString   contained start=+"+ end=+"+ contains=htmlSpecialChar,javaScriptExpression,@htmlPreproc,tt2Zone
syn region  htmlString   contained start=+'+ end=+'+ contains=htmlSpecialChar,javaScriptExpression,@htmlPreproc,tt2Zone
syn region  htmlLink start="<a\>\_[^>]*\<href\>" end="</a>"me=e-4 contains=@Spell,htmlTag,htmlEndTag,htmlSpecialChar,htmlPreProc,htmlComment,javaScript,@htmlPreproc,tt2Zone

syn match tt2Parent	"[({[\]})]"	contained

syn cluster	tt2ClConst	contains=tt2Functions,tt2Identifier,tt2Conditional,tt2Repeat,tt2Statement,tt2Operator,tt2Relation,tt2StringSingle,tt2StringDouble,tt2Number,tt2Float,tt2Keyword,tt2Type,tt2Boolean,tt2Structure,tt2MethodsVar,tt2Constants,tt2CoreConstants
syn cluster	tt2ClInside	contains=@tt2ClConst,tt2Comment,tt2Label,tt2Parent,tt2ParentError,tt2Include,tt2HereDoc
syn cluster	tt2ClFunction	contains=@tt2ClInside,tt2Define,tt2ParentError,tt2StorageClass
syn cluster	tt2ClTop	contains=@tt2ClFunction,tt2FoldFunction,tt2FoldClass


if version >= 508 || !exists("did_tt2_syn_inits")
	if version < 508
		let did_tt2_syn_inits = 1
		command -nargs=+ HiLink hi link <args>
	else
		command -nargs=+ HiLink hi def link <args>
	endif

	HiLink tt2TagName Identifier
	HiLink tt2Property Constant

	" if you want the text inside the braces to be colored, then
	" remove the comment in from of the next statement
	"HiLink tt2Zone Include
	HiLink tt2Zone Comment

	HiLink tt2Repeat	Repeat
	"HiLink tt2InFunc Function
	HiLink tt2Block Constant
	HiLink tt2Filter Function
	HiLink tt2Operator Operator
	HiLink	 tt2Parent	Delimiter

	HiLink	 tt2Constants	Constants
	HiLink	 tt2CoreConstants	Constants
	HiLink	 tt2Comment	Comment
	HiLink	 tt2Boolean	Boolean
	HiLink	 tt2StorageClass	StorageClass
	HiLink	 tt2Structure	Structure
	HiLink	 tt2StringSingle	String
	HiLink	 tt2StringDouble	String
	HiLink	 tt2Number	Number
	HiLink	 tt2Float	Float
	HiLink	 tt2Methods	Function
	HiLink	 tt2Functions	Function
	HiLink	 tt2Baselib	Function
	HiLink	 tt2Repeat	Repeat
	HiLink	 tt2Conditional	Conditional
	HiLink	 tt2Label	Label
	HiLink	 tt2Statement	Statement
	HiLink	 tt2Keyword	Statement
	HiLink	 tt2Type	Type
	HiLink	 tt2Include	Include
	HiLink	 tt2Define	Define
	HiLink	 tt2SpecialChar	SpecialChar
	HiLink	 tt2Parent	Delimiter
	HiLink	 tt2IdentifierConst	Delimiter
	HiLink	 tt2ParentError	Error
	HiLink	 tt2OctalError	Error
	HiLink	 tt2Todo	Todo
	HiLink	 tt2MemberSelector	Structure

	HiLink	tt2IntVar	Identifier
	HiLink	tt2EnvVar	Identifier
	HiLink	tt2Operator	Operator
	HiLink	tt2VarSelector	Operator
	HiLink	tt2Relation	Operator
	HiLink	tt2Identifier	Identifier
	HiLink	tt2IdentifierSimply	Identifier
	delcommand HiLink
endif


" Modeline {{{
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3
" }}}

