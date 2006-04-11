"        File: tex.vim
"        Type: compiler plugin for LaTeX
"      Author: Srinath Avadhanula
"       Email: srinath AT fastmail DOT fm
" Last Change: Wed Mar 20 12:00 AM 2002 PST
" Description:
"   this file is a simple compiler plugin for the LaTeX typesetting language.
"   unfortunately the compilers output suffers from a lot of problems (chiefly
"   excessive verbosity), some of which are quite serious. therefore, the
"   output from latex needs to be filtered through a couple of sed
"   statements in order to make it usable by vim's quickfix mechanism.
"   these statements are provided in a simple script called vimlatex.
"   which does the following:
"   1. sometimes in latex's output a single number is split into multiple lines.
"      i.e we get errors such as
"      -----%<------
"      LaTeX Warning: There is an error on line 123
"      4.
"      -----%<------
"      where actually the error was on line 1234. vimlatex joins such lines
"      into a single line.
"   2. also vim's 'efm' mechanism is not able to cope with the case where
"      multiple files have to be pushed into the file stack or popped off it
"      from a single line of the latex output. vimlatex ensures that this
"      does not need to be done by splitting lines containing multiple ('s or
"      )'s into seperate lines.

let g:Tex_ignoreSpecifierChangedWarning = 
	\ exists('g:Tex_ignoreSpecifierChangedWarning') ?
	\ g:Tex_ignoreSpecifierChangedWarning : 1
let g:Tex_ignoreMissingNumberWarning = 
	\ exists('g:Tex_ignoreMissingNumberWarning') ?
	\ g:Tex_ignoreMissingNumberWarning : 0

set makeprg=vimlatex\ $*

set efm=

if g:Tex_ignoreMissingNumberWarning
	set efm+= 
		\%-G!\ Missing\ number%.%#
end

if g:Tex_ignoreSpecifierChangedWarning
	set efm+=
		\%-G%.%#specifier\ changed\ to\ %.%#
end

set efm+=
	\%WLaTeX\ %.%#Warning:\ %mon\ input\ line\ %l%.%#,
	\%WLaTeX\ %.%#Warning:\ %m,
	\%E!\ %m,
	\%-Zl.%l\ %m,
	\%-Z\\s%#,
	\%-C%m,
	\%-O%.%#(%.%#)%.%#,
	\%-P%.%#(%f%.%#,
	\%-Q%.%#)%.%#,
	\%-G%.%#
" explanation:
"
" start off by ignoring some duplicate error messages which are generated
" when a figure file is not found. 
" NOTE: i do not know if this is reliable as of yet. but in all my
" experience, this message is only created when an included graphics file
" is not found. just delete this line if you want to see this warning.
"	\%-G!\ Missing\ number%.%#,
"
" then only process warnings which have an associated line numbers on
" them. this automatically ignores all the \hbox warnings.
"	\%WLaTeX\ %.%#Warning:\ %mline\ %l%.%#,
"
" thankfully latex at least consistently starts each error message with a
" ! (bang)
"	\%E!\ %m,
" 
" each error message ends when a line starting with l.\d\+ is encountered
" or when a blank line is encountered.
"	\%-Zl.%l\ %m,
" 	\%-Z\\s%#,
" till then just count every line as a continuation of the error message.
"	\%-C%m,
"
" ignore included files which are surrounded by ( and ). such files
" include the .sty files, etc.
"	\%-O%.%#(%.%#)%.%#,
" NOTE: this operation is safe only because of pre-filtering by vimlatex which
" ensures that there is not more than 1 ( or ) in any line.
"
" push the currently processed file onto the stack...
" NOTE: doing this with the raw latex output is not reliable, because
"       sometimes a single line contains multiple file entries. vim cannot
"       handle pushing multiple files into the stack from a single line.
"       vimlatex filters the raw output and ensures that no line contains
"       multiple brackts.
"	\%-P%.%#(%f%.%#,
" ... and pop it when we encounter the corresponding closing bracket.
" NOTE: again this is reliable only because of vimlatex.
"	\%-Q)%r,
" ... ignore all the rest of the painful stuff spit out by latex.
"	\%-G%.%#
