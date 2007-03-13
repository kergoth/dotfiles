" -*- vim -*-
" File: {rtp}/fold/c-fold.vim
" Last Official Modification: "Sun, 04 Nov 2001 15:54:28 +0100 (joze)"
" Last Change:	26th Jan 2004
"
" ChangeLog: {{{2
"   26th Jan 2004 (lh <hermitte at free dot fr>)
"    (*) little adjustments regarding string stripping
"   04th Dec 2003 (lh <hermitte at free dot fr>)
"    (*) b:fold_blank : to fold the blank lines that precede a region to fold
"   21st Nov 2003 (lh <hermitte at free dot fr>)
"    (*) "case xxx:" and "default:" correctly folded when using the expected
"        indentation
"    (*) End of "switch (...) { ... }" correctly recognized.
"   14th Nov 2003 (lh <hermitte at free dot fr>)
"    (*) cleaner implementation
"    (*) trim template parameters when the text for folded region exceed the
"        width of current window -- &foldcolumn is taken into account
"    (*) fixed some badly computed fold-text.
"   21st jul 2002 (lh <hermitte at free dot fr>)
"    (*) if 'b:show_if_and_else' is true, 'if {\n...\n} else {\n...\n}' are
"        displayed in two folders ; and 'try ... catch' as well
"    (*) support 'case' and 'default'
"    (*) building of 'ts' fixed ; used to test '8 = &ts' instead of '8 == &ts'
"    (*) heavily depends on indentation. For instance, tested ok with :
"         &cindent = 1
"         &cinoptions = g0,t0,h1s
" }}}1
" (C) 2001 by Johannes Zellner, <johannes@zellner.org>
" $Id: c.vim,v 1.8 2001/11/05 19:34:01 joze Exp $
" ======================================================================
"
" setlocal foldmethod=syntax
" finish

" [-- local settings --]               {{{1
setlocal foldexpr=CFold0(v:lnum)
setlocal foldtext=CFoldText()

if !exists('b:show_if_and_else')
  let b:show_if_and_else = 1
endif
if !exists('b:show_template_arguments')
  let b:show_template_arguments = 0
endif
if !exists('b:fold_blank')
  let b:fold_blank = 0
endif

" [-- global definitions --]           {{{1
if exists('*CFold')
  setlocal foldmethod=expr
  " finish
endif

" Function: s:IsACommentLine(lnum)               {{{2
function! s:IsACommentLine(lnum, or_blank)
  let line = getline(a:lnum)
  if line =~ '^\s*//'. (a:or_blank ? '\|^\s*$' : '')
    " C++ comment line / empty line => continue
    return 1
  elseif line =~ '\S.*\(//\|/\*.\+\*/\)'
    " Not a comment line => break
    return 0
  else
    let id = synIDattr(synID(a:lnum, strlen(line)-1, 0), 'name')
    return id =~? 'comment\|doxygen'
  endif
endfunction

" Function: s:PrevNonComment(lnum)               {{{2
" Comments => ignore them:
" the fold level is determined by the code that follows
function! s:PrevNonComment(lnum, or_blank)
  let lnum = a:lnum
  while (lnum > 0) && s:IsACommentLine(lnum, a:or_blank)
    let lnum = lnum - 1
  endwhile
  return lnum
endfunction

" Function: s:NextNonCommentNonBlank(lnum)       {{{2
" Comments => ignore them:
" the fold level is determined by the code that follows
function! s:NextNonCommentNonBlank(lnum, or_blank)
  let lnum = a:lnum
  let lastline = line('$')
  while (lnum <= lastline) && s:IsACommentLine(lnum, a:or_blank)
    let lnum = lnum + 1
  endwhile
  return lnum
endfunction

" Function: CFold(lnum)                          {{{2
fun! CFold(lnum)
  let lnum = s:NextNonCommentNonBlank(a:lnum, b:fold_blank)
  let last = line('$')
  if lnum > last
    return -1
  endif


  " Fold level of the previous line
  if a:lnum > 1
    let prev_lvl = foldlevel(a:lnum-1) 
    " Test if prec line was special
    let pline = getline(a:lnum - 1)
    let pline = substitute(pline, '{[^}]*}', '', 'g')
    let pline = substitute(pline, '"\%(\\"\|[^"]\)*"'    , '', 'g')
    let pline = substitute(pline, "'\\%(\\\\'\\|[^']\\)*'", '', 'g')
    let pline = substitute(pline, '\/\/.*$', '', 'g')

    if s:IsACommentLine(a:lnum-1, b:fold_blank)
      let was = 'nothing'
    elseif pline =~ '^\s*#'
      let was = 'precomp'
    elseif pline =~ '}[ \t;]*$'
      let was = 'closing'
    elseif pline =~ '^\s*\(default\|case\s*\k\+\)\s*:\s*$'
      let was = 'case'
    elseif pline =~ '[;:]\s*$' || pline =~ '^\s*$'
      let was = 'instr'
    elseif pline =~ '{\s*$'
      let was = 'opening'
    else 
      let was = 'nothing'
    endif
  else 
    let prev_lvl = 1
    let was = 'beginning'
  endif
  let g:was = was

  if was == 'nothing'
    return '='
    " return prev_lvl+1
  endif

  while lnum <= last
    let line = getline(lnum)
    if line =~ '^\s*#'
      " preprocessor line
      return '='
    endif
    " Strip one-line blocks of code
    let line = substitute(line, '{[^}]*}', '', 'g')
    " Strip strings and //-comments
    let line = substitute(line, '"\(\\"\|[^"]\)*"'    , '', 'g')
    let line = substitute(line, "'\\(\\\\'\\|[^']\\)*'", '', 'g')
    let line = substitute(line, '\/\/.*$', '', 'g')

    if line =~ '}[ \t;]*$'
      " let ind = (indent(lnum) / &sw)
      " exe 'return "<'.ind.'"'
      if lnum == a:lnum
	" let ind = (indent(lnum) / &sw)  + 1
	" exe 'return "<'.ind.'"'
	" exe 'return "<'.(prev_lvl).'"'
	let p = searchpair('{', '', '}.*$', 'bn', 
	      \  "synIDattr(synID(line('.'),col('.'), 0), 'name') "
	      \ ."=~? 'string\\|comment\\|doxygen'")
	if (getline(p) =~ 'switch\s*(.*)\s*{')
	      \ || (getline(s:PrevNonComment(p-1, b:fold_blank)) =~ 'switch\s*(.*)\s*{')
	  return 's2'
	else
	  return 's1'
	endif
	
      else
	return '='
      endif
    elseif line =~ '^\s*\(default\|case\s\+.\+\)\s*:\s*$'
      " cases for 'switch' statement
      " => new folder of fold level 'indent()+1'
      " return 'a1'
      " let ind = (indent(lnum) / &sw) + 1
      " exe 'return ">'.ind.'"'
      " return 'a1'
      exe 'return ">'.prev_lvl.'"'
    elseif line =~ '[;:]\s*$' || line =~ '^\s*$'
      " lines ending with a ';', empty lines or labels => keep folding level
      " auch: return -1
      " oder: return '='
      " return ind
      return '='
    elseif line =~ '{\s*$'
      " return 'a1'
      " let ind = (indent(lnum) / &sw) + 1
      if b:show_if_and_else && line =~ '^\s*}'
	" => new folder of fold level 'ind'
	" exe 'return ">'.ind.'"'
	" return 'a1'
	exe 'return ">'.(prev_lvl).'"'
      else
	" => folder of fold level 'indent()' (not necesseraly a new one)
	" exe 'return '.ind
	" exe 'return "'.(prev_lvl+1).'"'
	return 'a1'
	exe 'return "'.(prev_lvl+1).'"'
      endif
    endif
    let lnum = s:NextNonCommentNonBlank(lnum + 1, b:fold_blank)
  endwhile
endfun

" Function: CFold0(lnum)                          {{{2
fun! CFold0(lnum)
  let lnum = s:NextNonCommentNonBlank(a:lnum, b:fold_blank)
  let last = line('$')
  if lnum > last
    return -1
  endif


  while lnum <= last
    let line = getline(lnum)
    if line =~ '^\s*#'
      " preprocessor line
      " return '='
      return foldlevel(a:lnum-1)
    endif
    " Strip one-line blocs of code
    let line = substitute(line, '{[^}]*}', '', 'g')
    " Strip strings and //-comments
    let pline = substitute(pline, '"\%(\\"\|[^"]\)*"'    , '', 'g')
    let pline = substitute(pline, "'\\%(\\\\'\\|[^']\\)*'", '', 'g')
    " let line = substitute(line, '"[^"]*"', '', 'g')
    " let line = substitute(line, "'[^']*'", '', 'g')
    let line = substitute(line, '\/\/.*$', '', 'g')

    if line =~ '}[ \t;]*$'
      " let ind = (indent(lnum) / &sw)
      " exe 'return "<'.ind.'"'
      if lnum == a:lnum
	let ind = (indent(lnum) / &sw)  + 1
	" let ind = foldlevel(a:lnum - 1) " if not a comment...
	let p = searchpair('{', '', '}.*$', 'bn', 
	      \  "synIDattr(synID(line('.'),col('.'), 0), 'name') "
	      \ ."=~? 'string\\|comment\\|doxygen'")
	if (getline(p) =~ 'switch\s*(.*)\s*{')
	      \ || (getline(s:PrevNonComment(p-1, b:fold_blank)) =~ 'switch\s*(.*)\s*{')
	  " exe 'return "<'.(ind-1).'"'
	  return '<'.(ind-1)
	else
	  " exe 'return "<'.ind.'"'
	  return '<'.ind
	endif
      else
	" return '='
	return foldlevel(a:lnum-1)
      endif
    elseif line =~ '^\s*\(default\|case\s\+.\+\)\s*:\s*$'
      " cases for 'switch' statement
      " => new folder of fold level 'indent()+1'
      " return 'a1'
      let ind = (indent(lnum) / &sw) + 1
      exe 'return ">'.ind.'"'
    elseif line =~ '[;:]\s*$' || line =~ '^\s*$'
      " lines ending with a ';', empty lines or labels => keep folding level
      " auch: return -1
      " oder: return '='
      " return ind
      return '='
    elseif line =~ '{\s*$'
      " return 'a1'
      let ind = (indent(lnum) / &sw) + 1
      if b:show_if_and_else && line =~ '^\s*}'
	" => new folder of fold level 'ind'
	exe 'return ">'.ind.'"'
      else
	" => folder of fold level 'indent()' (not necesseraly a new one)
	exe 'return '.ind
      endif
    endif
    let lnum = s:NextNonCommentNonBlank(lnum + 1, b:fold_blank)
  endwhile
endfun

" Function: s:Build_ts()                         {{{2
function! s:Build_ts()
  if !exists('s:ts_d') || (s:ts_d != &ts)
    let s:ts = ''
    let i = &ts
    while i>0
      let s:ts = s:ts . ' '
      let i = i - 1
    endwhile
    let s:ts_d = &ts
  endif
  return s:ts
endfunction

" Function: CFoldText()                          {{{2
fun! CFoldText()
  let ts = s:Build_ts()
  let lnum = v:foldstart
  let lastline = line('$')
  " if lastline - lnum > 5 " use at most 5 lines
    " let lastline = lnum + 5
  " endif
  let line = ''
  let lnum = s:NextNonCommentNonBlank(lnum, b:fold_blank)
  
  " Loop for all the lines in the fold                {{{3
  while lnum <= lastline
    let current = getline(lnum)
    let current = substitute(current, '{\{3}\d\=.*$', '', 'g')
    let current = substitute(current, '/\*.*\*/', '', 'g')
    if current =~ '[^:]:[^:]'
      " class XXX : ancestor
      let current = substitute(current, '\([^:]\):[^:].*$', '\1', 'g')
      let break = 1
    elseif current =~ '{\s*$'
      " '  } else {'
      let current = substitute(current, '^\(\s*\)}\s*', '\1', 'g')
      let current = substitute(current, '{\s*$', '', 'g')
      let break = 1
    else
      let break = 0
    endif
    if '' == line
      " preserve indention: substitute leading tabs by spaces
      let leading_tabs = strlen(substitute(current, "[^\t].*$", '', 'g'))
      if leading_tabs > 0
	let leading = ''
	let i = leading_tabs
	while i > 0
	  let leading = leading . ts
	  let i = i - 1
	endwhile
	" let current = leading . strpart(current, leading_tabs, 999999)
	let current = leading . strpart(current, leading_tabs)
      endif
    else
      " remove leading and trailing white spaces
      let current = matchstr(current, '^\s*\zs.\{-}\ze\s*$')
      " let current = substitute(current, '^\s*', '', 'g')
    endif
    if '' != line && current !~ '^\s*$'
      " add a separator
      let line = line . ' '
    endif
    let line = line . current
    if break
      break
    endif
    " Goto next line
    let lnum = s:NextNonCommentNonBlank(lnum + 1, b:fold_blank)
  endwhile

  " Strip template parameters                         {{{3
  if strlen(line) > (winwidth(winnr()) - &foldcolumn)
	\ && !b:show_template_arguments && line =~ '\s*template\s*<'
    let c0 = stridx(line, '<') + 1 | let lvl = 1
    let c = c0
    while c > 0
      let c = match(line, '[<>]', c+1)
      if     line[c] == '<'
	let lvl = lvl + 1
      elseif line[c] == '>' 
	if lvl == 1 | break | endif
	let lvl = lvl - 1
      endif
    endwhile 
    let line = strpart(line, 0, c0) . '...' . strpart(line, c)
  endif

  " Strip whatever follows "case xxx:" and "default:" {{{3
  let line = substitute(line, 
	\ '^\(\s*\%(case\s\+.\{-}[^:]:\_[^:]\|default\s*:\)\).*', '\1', 'g')

  " Return the result                                 {{{3
  return substitute(line, "\t", ' ', 'g')
  " let lines = v:folddashes . '[' . (v:foldend - v:foldstart + 1) . ']'
  " let len = 10 - strlen(lines)
  " while len > 0
  "     let lines = lines . ' '
  "     let len = len - 1
  " endwhile
  " return lines . line
endfun

" }}}1

setlocal foldmethod=expr

" ======================================================================
" vim600: set fdm=marker:
