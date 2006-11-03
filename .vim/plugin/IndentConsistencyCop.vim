" IndentConsistencyCop.vim: Is the buffer's indentation consistent and does it conform to tab settings?
"
" DESCRIPTION: {{{1
"   In order to achieve consistent indentation, you need to agree on the
"   indentation width (e.g. 2, 4 or 8 spaces), and the indentation method (only
"   tabs, only spaces, or a mix of tabs and spaces that minimizes the number of
"   spaces and is called 'softtabstop' in VIM). Unfortunately, different people
"   use different editors and cannot agree on "the right" width and method.
"   Consistency is important, though, to make the text look the same in
"   different editors and on printouts. If any editor inadvertently converts
"   tabs and spaces, version control and diff'ing will be much harder to do. 
"
"   The IndentConsistencyCop examines the indent of the buffer and analyzes the
"   used indent widths and methods. If there are conflicting ones or if bad
"   combinations of tabs and spaces are found, it alerts you and offers help in
"   locating the offenders - just like a friendly policeman: 
"
"   :IndentConsistencyCop
"   Found inconsistent indentation in this buffer; generated from these
"   conflicting settings:
"   - tabstop (1838 of 3711 lines) <- buffer setting
"   - 4 spaces (33 of 3711 lines)
"   - bad mix of spaces and tabs (4 of 3711 lines)
"	[I]gnore, (H)ighlight wrong indents...: h
"   What kind of inconsistent indents do you want to highlight?
"	Not [b]uffer settings (sts4), Not best (g)uess (tab), Not (c)hosen
"	setting..., (I)llegal indents only: g
"   Marked 180 incorrect lines.
"
"   If the buffer contents are okay, the IndentConsistencyCop can evaluate
"   whether VIM's buffer settings are compatible with the indent used in the
"   buffer. The friendly cop offers to correct your buffer settings if you run
"   the risk of screwing up the indent consistency with your wrong buffer
"   settings: 
"   
"   :IndentConsistencyCop
"   The buffer's indent settings are inconsistent with the used indent '8
"   spaces'; these settings must be changed:
"   - expandtab from 0 to 1
"   How do you want to deal with the inconsistency?
"	[I]gnore, (C)hange: c
"   The buffer settings have been changed: tabstop=8 softtabstop=0 shiftwidth=8
"   expandtab
"
"   The IndentConsistencyCop is only concerned with the amount of whitespace
"   from column 1 to the first visible character; it does not check the
"   alignment of tables, equals signs in variable assignments, etc. Neither does
"   it know any specifics about programming languages, or your personal
"   preferred indentation style. 
" 
" USAGE: {{{1
"   Start the examination of the current buffer or range via:
"	:[range]IndentConsistencyCop
"   The triggering can be done automatically for configurable filetypes with the
"   autocmds defined in IndentConsistencyCopAutoCmds.vim (vimscript #1691). 
"
"   If you chose to highlight incorrect indents, either re-start the
"   IndentConsistencyCop to update the highlighting, or execute
"	:IndentConsistencyCopOff
"   to remove the highlightings. 
"
"   If you just want to check a read-only file, or do not intend to modify the
"   file, you don't care if VIM's buffer settings are compatible with the used
"   indent. In this case, you can use 
"	:[range]IndentRangeConsistencyCop
"   instead of :IndentConsistencyCop. 
"
" INSTALLATION: {{{1
"   Put the script into your user or system VIM plugin directory (e.g.
"   ~/.vim/plugin). 
"
" CONFIGURATION:
"   You can select method(s) of highlighting incorrect lines via
"   g:indentconsistencycop_highlighting; the default fills the search pattern,
"   jumps to the first error, uses the 'Error' highlighting and folds away the
"   correct lines. 
"
" LIMITATIONS: {{{1
" - 'softtabstop' is only recognized correctly when a correct combination of
"   tabs and spaces is actually used. If a file only has small indents,
"   resulting in only spaces or tabs (but not the combination), the indent
"   setting is recognized as a combination of 'tab' and 'spc n'. 
" - Highlighting of inconsistent and bad indents is static; i.e. when modifying
"   the buffer / inserting or deleting lines, the highlighting will be wrong /
"   out of place. You need to re-run the IndentConsistencyCop to fix the
"   highlighting. 
"
" ASSUMPTIONS:
" - When using 'softtabstop', 'tabstop' remains at the standard value of 8. 
"   Any other value would sort of undermine the idea of 'softtabstop', anyway. 
" - The indentation value lies in the range of 1-8 spaces or is 1 tab. 
" - When 'smarttab' is set (global setting), 'tabstop' and 'softtabstop' become
"   irrelevant to front-of-the-line indenting; only 'shiftwidth' counts. 
" - There are two possibilities to model 'expandtab': Either set the indent via
"   'tabstop', or keep 'tabstop=8' and set the indent via 'softtabstop'. 
"   We use the following guideline: 
"   If tabstop is kept at the standard 8, we prefer changing the indent via
"   softtabstop. 
"   If tabstop is non-standard, anyway, we rather modify tabstop than turning on
"   softtabstop. 
"
" TODO:
" - Define autocmds to remove the highlighting if it isn't in scope any more
"   (e.g. remove search pattern when buffer is changed, remove error
"   highlighting and folding if another file is loaded into the buffer via :e). 
" - Allow user to override wrongly found consistent setting (e.g. 'sts1' instead
"   of 'tab'), both by specifying the correct setting in the
"   :IndentConsistencyCop call and by choosing 'wrong setting' in the
"   IndentBufferConsistencyCop. 
"
" Copyright: (C) 2006 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS {{{1
"	0.07	02-Nov-2006	BF: Suppressing 'Not buffer setting' option if
"				the buffer setting is inconsistent ('badset'),
"				which threw an exception when selected. 
"	0.06	01-Nov-2006	Corrected unreasonable assumption of a
"				consistent small indent setting (of 1 or 2
"				spaces) when actually only some wrong spaces
"				spoil the consistency. Now, a perfect consistent
"				rating is only accepted if its absolute rating
"				number is also the maximum rating. 
"				BF: Avoiding runtime error in
"				IndentBufferInconsistencyCop() if s:ratings is
"				empty. 
"	0.05	30-Oct-2006	Improved g:indentconsistencycop_non_indent_pattern 
"				to also allow ' *\t' and ' *****' comments. 
"	0.04	20-Oct-2006	Improved undo of highlighting;
"				added :IndentConsistencyCopOff. 
"				Added check IsEnoughIndentForSolidAssessment();
"				user messages now include 'potentially' if the
"				indent is not sufficient. 
"				Print out informational message for large ranges
"				/ buffers. 
"				Added user messages when ignoring
"				inconsistencies. 
"				BF: s:FoldExpr() is now a global function
"				IndentConsistencyCopFoldExpr() to fix problems
"				with set foldexpr=...
"				BF: SetHighlighting() doesn't save buffer
"				settings it has set itself in a previous run any
"				more. 
"	0.03	19-Oct-2006	Added highlighting functionality. 
"				Now coping with special comments indents via
"				g:indentconsistencycop_non_indent_pattern. 
"				Implemented g:indentconsistencycop_highlighting
"				options 'shlm'. 
"				BF: All 'sts n' were treated as compatible to
"				'tab', whereas the multiplicity of the tabstop
"				had to be considered. Added storing of tabstop
"				indents in s:tabstops and corresponding
"				evaluation in
"				GetIncompatiblesForIndentSetting(). 
"				Implemented highlighting via folding. 
"				Correctly cleaning up highlighting. 
"	0.02	11-Oct-2006	Completed consistency check for complete buffer. 
"				Added check for range of the current buffer. 
"				Added user choice to automatically change buffer settings. 
"				Now correctly handling 'smarttab' and the
"				'expandtab' ambiguity. 
"	0.01	08-Oct-2006	file creation

" Avoid installing twice or when in compatible mode
if exists("loaded_indentconsistencycop") || (v:version < 700)
    finish
endif
let loaded_indentconsistencycop = 1
" }}}1

"- configuration ----------------------------------------------------------{{{1
if ! exists('g:indentconsistencycop_highlighting')
    " Defines the highlighting methods of incorrect lines, when this is
    " requested by the user. Multiple methods can be combined. The changes done
    " for highlighting are undone when highlighting is removed via
    " :IndentConsistencyCopOff. 
    "	s - Fill search pattern with all incorrect lines, so that you navigate
    "	    through all incorrect lines with n/N. 
    " 	g - Jump to the first error. 
    " 	l - As a visualization aid, execute ':setlocal list' to see difference
    "	    between tabs and spaces. 
    "	m - Use :2match error highlighting to highlight the wrong indent via the
    "	    'Error' highlighting group. This is especially useful if you don't
    " 	    use the search pattern in combination with 'set hlsearch' to locate
    " 	    the incorrect lines. 
    " 	f:{n} (n = 0..9) - Fold correct lines with a context of {n} lines (like
    "	    in VIM diff mode). 
    " 	TODO:
    " 	q - Populate quickfix list with all incorrect lines. IDEA: Use :cgetexpr. 
    let g:indentconsistencycop_highlighting = 'sglmf:3'
endif

if ! exists('g:indentconsistencycop_non_indent_pattern')
    " Some comment styles use additional whitespace characters inside the
    " comment block to neatly left-align the comment block, e.g. this is often
    " used in Java and C/C++ programs:
    " /* This is a comment that spans multiple 
    "  * lines; neatly left-aligned with asterisks. 
    "  */
    " The IndentConsistencyCop would be confused by these special indents, so we
    " define a non-indent pattern that removes these additional whitespaces from
    " the indent when evaluating lines. 
    let g:indentconsistencycop_non_indent_pattern = ' \*[*/ \t]'
endif

"}}}1

"- list and dictionary utility functions ---------------------------------{{{1
function! s:IncreaseKeyedBy( dict, key, num )
"****D echo '**** ' . a:key
    if has_key( a:dict, a:key )
	let a:dict[ a:key ] += a:num
    else
	let a:dict[ a:key ] = a:num
    endif
endfunction

function! s:IncreaseKeyed( dict, key )
    call s:IncreaseKeyedBy( a:dict, a:key, 1 )
endfunction

function! s:GetKeyedValue( dict, key )
    if has_key( a:dict, a:key )
	return a:dict[a:key]
    else
	return 0
endfunction

function! s:RemoveKey( dict, key )
    if has_key( a:dict, a:key )
	unlet a:dict[a:key]
    endif
endfunction

function! s:RemoveFromList( list, value )
    call filter( a:list, 'v:val != "' . a:value . '"' )
endfunction

"- utility functions -----------------------------------------------------{{{1
function! s:IsDivsorOf( newNumber, numbers )
    for l:number in a:numbers
	if l:number % a:newNumber == 0
	    return 1
	endif
    endfor
    return 0
endfunction

function! s:GetMultiplierFromIndentSetting( indentSetting )
    if a:indentSetting == 'tab'
	return 8
    else
	return str2nr( strpart( a:indentSetting, 3 ) )
    endif
endfunction

function! s:GetSettingFromIndentSetting( indentSetting )
    return strpart( a:indentSetting, 0, 3 )
endfunction

"}}}1

"- Processing of lines in buffer -----------------------------------------{{{1
function! s:CountTabs( tabString )
    " A tab is a tab, and can thus be counted directly. 
    " However, the number of tabs, or the equivalent indent, must be captured to
    " be able to resolve possible compatibilities with softtabstops. 
    call s:IncreaseKeyed( s:occurrences, 'tab' )
    call s:IncreaseKeyed( s:tabstops, len( substitute( a:tabString, '\t', '        ', 'g' ) ) )
endfunction

function! s:CountDoubtful( spaceString )
    call s:IncreaseKeyed( s:doubtful, len( a:spaceString ) )
endfunction

function! s:CountSpaces( spaceString )
    call s:IncreaseKeyed( s:spaces, len( a:spaceString ) )
endfunction

function! s:CountSofttabstops( stsString )
    call s:IncreaseKeyed( s:softtabstops, len( substitute( a:stsString, '\t', '        ', 'g' ) ) )
endfunction

function! s:CountBadSofttabstop( string )
    call s:IncreaseKeyed( s:occurrences, 'badsts')
endfunction

function! s:CountBadMixOfSpacesAndTabs( string )
    call s:IncreaseKeyed( s:occurrences, 'badmix')
endfunction

function! s:GetBeginningWhitespace( lineNum )
    return matchstr( getline(a:lineNum), '^\s\{-}\ze\($\|\S\|' . g:indentconsistencycop_non_indent_pattern . '\)' )
endfunction

function! s:UpdateIndentMax( beginningWhitespace )
    let l:currentIndent = len( substitute( a:beginningWhitespace, '\t', '        ', 'g' ) )
    if l:currentIndent > s:indentMax
	let s:indentMax = l:currentIndent
    endif
endfunction

function! s:IsEnoughIndentForSolidAssessment()
    " Only indents greater than the default tabstop value of 8 allow us to
    " unequivocally recognize soft tabstops. 
    return s:indentMax > 8
endfunction

function! s:InspectLine(lineNum)
"*******************************************************************************
"* PURPOSE:
"   Count the whitespace at the beginning of the passed line (until the first
"   non-whitespace character) and increase one of the counters. There are two
"   types of counters:
"   1. The master counter s:occurrences can be directly filled with elements
"      like all-Tabs or bad Tab-Space combinations, where the number of Tabs /
"      Spaces doesn't matter. 
"   2. The intermediate counters s:spaces, s:softtabstops and s:doubtful also
"      capture the number of the characters. These counters are later
"      consolidated into s:occurrences. 
"   3. The intermediate counter s:tabstops is only necessary to resolve possible
"      compatibilities with other indent settings. 
"
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"   updates s:occurrences, s:tabstops, s:spaces, s:softtabstops, s:doubtful
"   updates s:indentMax
"* INPUTS:
"   lineNum: number of line in the current buffer
"* RETURN VALUES: 
"   none
"*******************************************************************************
"****D echo getline(a:lineNum)
    let l:beginningWhitespace = s:GetBeginningWhitespace( a:lineNum )
    if l:beginningWhitespace == ''
	return
    elseif match( l:beginningWhitespace, '^\t\+$' ) != -1
	call s:CountTabs( l:beginningWhitespace )
	" Tabs-only can also be interpreted as a softtabstop-line without
	" balancing spaces. 
	" If we discarded this, we would neglect to count an indent of 10 tabs
	" (= 80 characters) as 16 * sts5 (the 10 * sts8 will be dropped by the
	" preference of tab over sts8, though). 
	call s:CountSofttabstops( l:beginningWhitespace )
    elseif match( l:beginningWhitespace, '^ \{1,7}$' ) != -1
	" Spaces-only (up to 7) can also be interpreted as a softtabstop-line
	" without tabs. 
	call s:CountDoubtful( l:beginningWhitespace )
    elseif match( l:beginningWhitespace, '^ \{8,}$' ) != -1
	call s:CountSpaces( l:beginningWhitespace )
    elseif match( l:beginningWhitespace, '^\t\+ \{1,7}$' ) != -1
	call s:CountSofttabstops( l:beginningWhitespace )
    elseif match( l:beginningWhitespace, '^\t\+ \{8,}$' ) != -1
	call s:CountBadSofttabstop( l:beginningWhitespace )
    else
	call s:CountBadMixOfSpacesAndTabs( l:beginningWhitespace )
    endif

    call s:UpdateIndentMax( l:beginningWhitespace )
endfunction

function! s:EvaluateIndentsIntoOccurrences( dict, type ) " {{{1
"*******************************************************************************
"* PURPOSE:
"   An actual indent x translates into occurrences for shiftwidths n, 
"   where n is a divisor of x. Divisors that are divisors of other divisors are
"   skipped. 
"   e.g. indent of 18 -> shiftwidth of 6 (1,2,3 skipped)
"	 indent of 21 -> shiftwidths of 7,3 (1 skipped)
"	 indent of 17 -> shiftwidth of 1
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   dict: the dictionary of actual indents for a particular type
"   type: either 'spc' or 'sts'
"* RETURN VALUES: 
"   Modifies the passed dict reference. 
"*******************************************************************************
    for l:indent in keys( a:dict )
	let l:divisors = []
	let l:indentCnt = 8
	while l:indentCnt > 0
	    if l:indent % l:indentCnt == 0
		if ! s:IsDivsorOf( l:indentCnt, l:divisors )
		    "****D echo "**** " . l:indent . " adding " . l:indentCnt
		    call s:IncreaseKeyedBy( s:occurrences, a:type . l:indentCnt, a:dict[ l:indent ] )
		"****D else
		    "****D echo "**** " . l:indent . " discarding " . l:indentCnt . " because already done " . string(l:divisors)
		endif
		let l:divisors += [ l:indentCnt ]
	    endif
	    let l:indentCnt -= 1
	endwhile
    endfor
endfunction

function! s:ApplyPrecedences() " {{{1
"*******************************************************************************
"* PURPOSE:
"   Relates individual indent settings to others, thereby "stronger" indent
"   settings take precedent over "weaker" ones. 
"* ASSUMPTIONS / PRECONDITIONS:
"   s:occurrences contains consolidated indent occurrences. 
"* EFFECTS / POSTCONDITIONS:
"   Modifies s:occurrences. 
"* INPUTS:
"   none
"* RETURN VALUES: 
"   none
"*******************************************************************************
    " Space indents of up to 7 spaces can be either softtabstop or space-indent,
    " and have been collected in the 'dbt n' keys so far. 
    " If there is only either 'sts n' or 'spc n', the 'dbt n' value is moved to
    " that key. If both exist, its value is added to both. If both are zero /
    " non-existing, the 'dbt n' value is moved to 'spc n'; without further
    " evidence, spaces take precedence over softtabstops. 
    let l:indentCnt = 8
    while l:indentCnt > 0
	let l:dbtKey = 'dbt' . l:indentCnt
	let l:dbt = s:GetKeyedValue( s:occurrences, l:dbtKey )
	if l:dbt > 0
	    let l:spcKey = 'spc' . l:indentCnt
	    let l:stsKey = 'sts' . l:indentCnt
	    let l:spc = s:GetKeyedValue( s:occurrences, l:spcKey )
	    let l:sts = s:GetKeyedValue( s:occurrences, l:stsKey )
	    if l:spc == 0 && l:sts == 0
		call s:IncreaseKeyedBy( s:occurrences, l:spcKey, l:dbt )
	    else
		if l:spc > 0
		    call s:IncreaseKeyedBy( s:occurrences, l:spcKey, l:dbt )
		endif
		if l:sts > 0
		    call s:IncreaseKeyedBy( s:occurrences, l:stsKey, l:dbt )
		endif
	    endif
	    call s:RemoveKey( s:occurrences, l:dbtKey )
	endif

	let l:indentCnt -= 1
    endwhile

    " The occurrence 'sts8' has only been collected because of the parallelism
    " with 'spc8'. Effectively, 'sts8' is the same as 'tab', and is removed. 
    if s:GetKeyedValue( s:occurrences, 'sts8' ) != s:GetKeyedValue( s:occurrences, 'tab' )
	throw "assert sts8 == tab"
    endif
    call s:RemoveKey( s:occurrences, 'sts8' )
endfunction


"- Check for compatible indent settings ----------------------------------{{{1
function! s:IsIndentProduceableWithIndentSetting( indent, indentSetting )
    let l:indentMultiplier = s:GetMultiplierFromIndentSetting( a:indentSetting )
    if l:indentMultiplier == 0
	return 0 " This is for the 'badsts' and 'badmix' indent settings. 
    else
	return (a:indent % l:indentMultiplier == 0)
    endif
endfunction

function! s:InspectForCompatibles( incompatibles, indents, baseIndentSetting, testSetting )
"*******************************************************************************
"* PURPOSE:
"   Uses the passed list of indents to find indent settings in a:testSetting
"   that are compatible with a:baseIndentSetting. 
"   Candidates are: tabs may count as softtabstops, short indents (captured in
"   s:doubtful) may be both softtabstops or spaces. Spaces and softtabstops may
"   have different multipliers (e.g. sts5 and sts3) that may be compatible (e.g.
"   for indents 15, 30, 45). 
"* ASSUMPTIONS / PRECONDITIONS:
"   none
"* EFFECTS / POSTCONDITIONS:
"   Modifies the passed a:incompatibles. 
"* INPUTS:
"   a:incompatibles: reference to the pre-initialized list of (possibly)
"	incompatibles. Will contain only *real* incompatibles after the function
"	run. 
"   a:indents:	list of actual indents that have occurred in the buffer. 
"	The list should exclude indents that are not caused by
"	a:baseIndentSetting, so that no false positives are found. 
"   a:baseIndentSetting: indent setting (e.g. 'sts6') on which the search for
"	compatibles is based on
"   a:testSetting: setting (e.g. 'sts') which filters the indent settings to be
"	searched for compatibles. 
"* RETURN VALUES: 
"   none
"* EXAMPLES:
"   s:InspectForCompatibles( l:incompatibles, [ 6, 12, 48, 60 ], 'sts6', 'sts' )
"	searches for compatibles to 'sts6' that match 'sts', using the passed
"	indent list. It'll return [ 'sts1', 'sts2', 'sts3' ]. 
"*******************************************************************************
    " Seed possible incompatibles with passed set; filter is testSetting. 
    let l:isIncompatibles = {}	" Key: indentSetting; value: boolean (0/1). 
    for l:incompatible in a:incompatibles
	if s:GetSettingFromIndentSetting( l:incompatible ) == a:testSetting
	    let l:isIncompatibles[ l:incompatible ] = 0
	endif
    endfor

    for l:isIncompatible in keys( l:isIncompatibles )
	for l:indent in a:indents
	    " Find indents all that match l:isIncompatible and test whether is
	    " also matches with a:baseIndentSetting
	    if s:IsIndentProduceableWithIndentSetting( l:indent, l:isIncompatible )
		if ! s:IsIndentProduceableWithIndentSetting( l:indent, a:baseIndentSetting )
		    " Indent isn't compatible, mark as incompatible. 
		    let l:isIncompatibles[ l:isIncompatible ] = 1
		    " We're through with this possible incompatible. 
		    break
		endif
	    endif
	endfor
    endfor

    " Remove the incompatibles that have been found compatible from
    " a:incompatibles. 
    for l:isIncompatible in keys( l:isIncompatibles )
	if ! l:isIncompatibles[ l:isIncompatible ]
	    call s:RemoveFromList( a:incompatibles, l:isIncompatible )
"****D echo '**** ' . l:isIncompatible . ' is actually compatible with ' . a:baseIndentSetting
	endif
    endfor
endfunction

function! s:GetIncompatiblesForIndentSetting( indentSetting )
"*******************************************************************************
"* PURPOSE:
"   This function encodes the straightforward (i.e. general, settings-wide)
"   compatibility rules for the indent settings. Compatibilities that require
"   inspection of the actual indents in the buffer are delegated to
"   s:InspectForCompatibles(). 
"* ASSUMPTIONS / PRECONDITIONS:
"   s:occurrences dictionary; key: indent setting; value: number of
"	lines that have that indent setting
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"	? Explanation of each argument that isn't obvious.
"* RETURN VALUES: 
"    list of indent settings.
"*******************************************************************************
    " Start by assuming all indent settings are incompatible. 
    let l:incompatibles = keys( s:occurrences )
    " The indent setting is compatible with itself. 
    call s:RemoveFromList( l:incompatibles, a:indentSetting )

    let l:setting = s:GetSettingFromIndentSetting( a:indentSetting )
    if l:setting == 'tab'
	" 'sts' could be compatible with 'tab'. 
	" softtabstops must be inspected; doubtful contains indents that are too small (<8) for 'tab'. 
"****D echo '**** Inspecting for "tab": ' . string( keys( s:softtabstops ) )
	call s:InspectForCompatibles( l:incompatibles, keys( s:softtabstops ), a:indentSetting, 'sts' )
    elseif l:setting == 'sts'
	" 'tab' could be compatible with 'sts' if the multipliers are right; tabstops must be inspected. 
"****D echo '**** Inspecting for "sts": ' . string( keys( s:tabstops ))
	call s:InspectForCompatibles( l:incompatibles, keys( s:tabstops ), a:indentSetting, 'tab' )
	" 'spc' is incompatible
	" Other 'sts' multipliers could be compatible; softtabstops and doubtful must be inspected. 
"****D echo '**** Inspecting for "sts": ' . string( keys( s:softtabstops ) + keys( s:doubtful ))
	call s:InspectForCompatibles( l:incompatibles, keys( s:softtabstops ) + keys( s:doubtful ), a:indentSetting, 'sts' )
    elseif l:setting == 'spc'
	" 'tab' is incompatible. 
	" 'sts' is incompatible. 
	" Other 'spc' multipliers could be compatible; spaces and doubtful must be inspected. 
"****D echo '**** Inspecting for "spc": ' . string( keys( s:spaces ) + keys( s:doubtful ))
	call s:InspectForCompatibles( l:incompatibles, keys( s:spaces ) + keys( s:doubtful ), a:indentSetting, 'spc' )
    elseif l:setting == 'bad'
	" for bad, all are incompatible. 
    else
	throw 'Unknown indent setting: ' . l:setting
    endif

    return l:incompatibles
endfunction

function! s:EvaluateIncompatibleIndentSettings()
"*******************************************************************************
"* PURPOSE:
"   Each found indent setting (in s:occurrences) may be compatible with another
"   (e.g. 'sts4' could be unified with 'sts6', if the actual indents found in
"   s:softtabstops and s:doubtful are 12 and 24 (but not 6, 18)). To do this
"   evaluation, the actual indents in s:spaces, s:softtabstops and s:doubtful
"   must be inspected. 
"* ASSUMPTIONS / PRECONDITIONS:
"   s:occurrences dictionary; key: indent setting; value: number of
"	lines that have that indent setting
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"	? Explanation of each argument that isn't obvious.; value: list of
"	indent settings. 
"* RETURN VALUES: 
"    Key: indent setting; value: list of indent settings.
"*******************************************************************************
    let l:incompatibles = {}
    for l:indentSetting in keys( s:occurrences )
	let l:incompatibles[ l:indentSetting ] = s:GetIncompatiblesForIndentSetting( l:indentSetting )
    endfor
    return l:incompatibles
endfunction

"- Rating generation -----------------------------------------------------{{{1
function! s:EvaluateOccurrenceAndIncompatibleIntoRating( incompatibles )
"*******************************************************************************
"* PURPOSE:
"   For each indent setting, calculates a single (unnormalized) rating; the
"   higher, the more probable the indent setting. 
"   The formula is 
"	rating( indent setting ) = # of indent setting occurrences /
"	    (1 + sum( # of occurrences of incompatible indent settings )). 
"   If there are no incompatible indent settings, the rating is deemed
"   "perfect", which is indicated by a negative rating. Apart from multiplying
"   the result with -1, above formula stays valid:
"	rating( perfect indent setting ) = -1 * # of indent setting occurrences. 
"* ASSUMPTIONS / PRECONDITIONS:
"   s:occurrences dictionary; key: indent setting; value: number of
"	lines that have that indent setting
"   s:ratings: empty dictionary
"* EFFECTS / POSTCONDITIONS:
"   Fills s:ratings: dictionary of ratings; key: indent setting; value: rating number
"   A negative rating represents a perfect rating (i.e. no incompatibles)
"   There is at most one perfect rating. 
"* INPUTS:
"   a:incompatibles: dictionary of incompatibles
"* RETURN VALUES: 
"   none
"*******************************************************************************
    let s:ratings = {}
    let l:hasPerfectRatingOccurred = 0
    for l:indentSetting in keys( s:occurrences )
	let l:incompatibles = a:incompatibles[ l:indentSetting ]
	if empty( l:incompatibles )
	    if l:hasPerfectRatingOccurred
		throw 'assert there is only one perfect rating'
	    endif
	    " No incompatibles; this gets the perfect rating. 
	    let s:ratings[ l:indentSetting ] = -10000 * s:occurrences[ l:indentSetting ] " / 1
	    let l:hasPerfectRatingOccurred = 1
	else
	    let l:incompatibleOccurrences = 1
	    for l:incompatible in l:incompatibles
		let l:incompatibleOccurrences += s:occurrences[ l:incompatible ]
	    endfor
	    let s:ratings[ l:indentSetting ] = 10000 * s:occurrences[ l:indentSetting ] / l:incompatibleOccurrences
	endif
    endfor
endfunction

"- Rating normalization --------------------------------------------------{{{1
function! s:IsContainsPerfectRating()
    return (min( s:ratings ) < 0)
endfunction

function! s:NormalizePerfectRating()
    for l:rating in keys( s:ratings )
	if s:ratings[ l:rating ] < 0
	    " Normalize to 100%
	    let s:ratings[ l:rating ] = 100
	else
	    unlet s:ratings[ l:rating ] 
	endif
    endfor
endfunction

function! s:IsBadIndentSetting( indentSetting )
    return s:GetSettingFromIndentSetting( a:indentSetting ) == 'bad'
endfunction

function! s:NormalizeNonPerfectRating()
    let l:ratingThreshold = 10	" Remove everything below this percentage. Exception: indent setting 'bad'. 

    let l:valueSum = 0
    for l:value in values( s:ratings )
	let l:valueSum += l:value
    endfor
    if l:valueSum <= 0 
	throw "assert valueSum > 0"
    endif

    for l:rating in keys( s:ratings )
	let l:newRating = 100 * s:ratings[ l:rating ] / l:valueSum
	if l:newRating < l:ratingThreshold && ! s:IsBadIndentSetting( l:rating )
	    unlet s:ratings[ l:rating ] 
	else
	    let s:ratings[ l:rating ] = l:newRating
	endif
    endfor
endfunction

function! s:DemotePerfectRating()
    for l:rating in keys( s:ratings )
	if s:ratings[ l:rating ] < 0
	    let s:ratings[ l:rating ] = -1 * s:ratings[ l:rating ]
	endif
    endfor
endfunction

function! s:IsPerfectRatingAlsoTheBestRating()
    let l:absolutePerfectRating = -1 * min( s:ratings )
    if l:absolutePerfectRating <= 0
	throw 'assert perfect rating < 0'
    endif

    let l:bestNonPerfectRating = max( s:ratings )
    if l:bestNonPerfectRating <= 0
	if -1 * l:bestNonPerfectRating == l:absolutePerfectRating
	    " There is no other rating than the perfect rating; max() == min().  
	    return 1
	else
	    throw 'assert best rating > 0'
	endif
    endif
"****D echo '**** perfect rating = ' . l:absolutePerfectRating . '; best other rating = ' . l:bestNonPerfectRating
    return (l:absolutePerfectRating >= l:bestNonPerfectRating)
endfunction

function! s:NormalizeRatings()
"*******************************************************************************
"* PURPOSE:
"   Changes the values in the s:ratings dictionary to that the sum of all values
"   is 100; i.e. make percentages out of the ratings. 
"   Values below a certain percentage threshold are dropped from the dictionary
"   *after* the normalization, in order to remove clutter when displaying the
"   results to the user. 
"* ASSUMPTIONS / PRECONDITIONS:
"   s:ratings dictionary; key: indent setting; value: raw rating number >= 0 or
"	-1 means a perfect rating (i.e. no incompatibles)
"* EFFECTS / POSTCONDITIONS:
"   s:ratings dictionary; key: indent setting; value: percentage 
"	rating (100: checked range is consistent; < 100: inconsistent. 
"   Modifies values in s:ratings. 
"   Removes entries that fall below the threshold. 
"* INPUTS:
"   none
"* RETURN VALUES: 
"   none
"*******************************************************************************
    if s:IsContainsPerfectRating()
	" A perfect rating (i.e. an indent setting that is consistent throughout the
	" entire buffer / range) is only accepted if its absolute rating number is
	" also the maximum rating. Without this qualification, a few small indent
	" settings (e.g. sts1, spc2) could be deemed the consistent setting, even
	" though they actually are just indent errors that sabotage the actual,
	" larger desired indent setting (e.g. sts4, spc4). In other words, the cop
	" must not be fooled by some wrong spaces into believing that we have a
	" consistent sts1, although the vast majority of indents suggests an sts4
	" with some inconsistencies. 
	if s:IsPerfectRatingAlsoTheBestRating()
	    call s:NormalizePerfectRating()
	else
	    call s:DemotePerfectRating()
	    call s:NormalizeNonPerfectRating()
	endif
    else
	call s:NormalizeNonPerfectRating()
    endif
endfunction

"}}}1

function! s:CheckBufferConsistency( startLineNum, endLineNum ) " {{{1
"*******************************************************************************
"* PURPOSE:
"   Checks the consistency of the indents in the current buffer, range of
"   startLine to endLine. 
"* ASSUMPTIONS / PRECONDITIONS:
"   none
"* EFFECTS / POSTCONDITIONS:
"   Fills the s:occurrences dictionary; key: indent setting; value: number of
"	lines that have that indent setting
"   Fills the s:ratings dictionary; key: indent setting; value: raw rating
"   number, or -1 means a perfect rating (i.e. no incompatibles)
"* INPUTS:
"   a:startLineNum
"   a:endLineNum
"* RETURN VALUES: 
"   -1: checked range does not contain indents
"    0: checked range is not consistent
"    1: checked range is consistent
"*******************************************************************************
    if a:startLineNum > a:endLineNum
	throw assert startLineNum <= a:endLineNum
    endif

    " This variable stores the maximum indent encountered. 
    let s:indentMax = 0

    " This dictionary collects the occurrences of all found indent settings. It
    " is the basis for all evaluations and statistics. 
    let s:occurrences = {}  " key: indent setting (e.g. 'sts4'); value: number of lines that have that indent setting. 

    " These intermediate dictionaries will be processed into s:occurences via
    " EvaluateIndentsIntoOccurrences(). 
    let s:tabstops = {}	    " key: number of indent spaces (8*n); value: number of lines that have the number of indent spaces. 
    let s:spaces = {}	    " key: number of indent spaces (>=8); value: number of lines that have the number of indent spaces. 
    let s:softtabstops = {} " key: number of indent softtabstops (converted to spaces); value: number of lines that have the number of spaces. 
    let s:doubtful = {}	    " key: number of indent spaces (<8) which may be either spaces or softtabstops; value: number of lines that have the number of spaces. 

    let l:lineNum = a:startLineNum
    while l:lineNum <= a:endLineNum
	call s:InspectLine(l:lineNum)
	let l:lineNum += 1
    endwhile

    " s:tabstops need not be evaluated into occurrences, as there are no
    " multiplicity ambiguities. The tabstops have already been counted in
    " s:occurrences. 
    call s:EvaluateIndentsIntoOccurrences( s:spaces, 'spc' )
    call s:EvaluateIndentsIntoOccurrences( s:softtabstops, 'sts' )
    call s:EvaluateIndentsIntoOccurrences( s:doubtful, 'dbt' )
    " Now, the indent occurences have been consolidated into s:occurrences. 
    " It counts the actual or possible indent settings. An indent of 4 spaces is
    " counted once as 'spc4', the alternatives of 2x 'spc2' or 4x 'spc1' are
    " discarded, because only the largest possible unambiguous indent setting wins. 
    " However, an indent of 30 spaces is counted as both 'spc5' and 'spc6',
    " because the indent could result from either one. Again, 'spc3', 'spc2' and
    " 'spc1' are discarded, because they are smaller subsets. 
    " Thus, the sum of occurences can be larger than the number of actual
    " indents examined, because some indents can not unambiguously be assigned
    " to one indent setting. 
    
"****D echo 'Tabstops:     ' . string( s:tabstops )
"****D echo 'Spaces:       ' . string( s:spaces )
"****D echo 'Softtabstops: ' . string( s:softtabstops )
"****D echo 'Doubtful:     ' . string( s:doubtful )
"****D echo 'Occurrences 1:' . string( s:occurrences )
"****D echo 'Max. indent:  ' . s:indentMax

    if empty( s:occurrences )
	return -1
    endif

    call s:ApplyPrecedences()

"****D echo 'Occurrences 2:' . string( s:occurrences )
"****D echo 'This is probably a ' . string( filter( copy( s:occurrences ), 'v:val == max( s:occurrences )') )

    " This dictionary contains the incompatible indent settings for each indent
    " setting. 
    let l:incompatibles = s:EvaluateIncompatibleIndentSettings() " Key: indent setting; value: list of indent settings. 
"****D echo 'Incompatibles:' . string( l:incompatibles )

    " The s:ratings dictionary contains the final rating, a combination of high indent settings occurrence and low incompatible occurrences. 
    call s:EvaluateOccurrenceAndIncompatibleIntoRating( l:incompatibles ) " Key: indent setting; value: rating number
"****D echo 'ratings:     ' . string( s:ratings )

    call s:NormalizeRatings()
"****D echo 'nrm. ratings:' . string( s:ratings )
"****D call confirm('debug')


    " Cleanup lists and dictionaries with script-scope to free memory. 
    call filter( s:tabstops, 0 )
    call filter( s:spaces, 0 )
    call filter( s:softtabstops, 0 )
    call filter( s:doubtful, 0 )
    " Do not free s:indentMax, it is still accessed by s:IsEnoughIndentForSolidAssessment(). 

    let l:isConsistent = (count( s:ratings, 100 ) == 1)
    return l:isConsistent
endfunction


"- consistency of buffer settings functions -------------------------------{{{1
function! s:CheckBufferSettingsConsistency()
"*******************************************************************************
"* PURPOSE:
"   Checks the buffer indent settings (tabstop, softtabstop, shiftwidth,
"   expandtab) for consistency. 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   none
"* RETURN VALUES: 
"   Empty string if settings are consistent, else
"   User string describing the inconsistencies. 
"*******************************************************************************
    let l:inconsistencies = ''

    " 'shiftwidth' must be equal to 'tabstop' or 'softtabstop', except when
    " using 'smarttab'. 
    if ! &l:smarttab
	if &l:softtabstop > 0
	    if &l:softtabstop != &l:shiftwidth
		let l:inconsistencies .= "\nThe value of softtabstop (" . &l:softtabstop . ") should equal the value of shiftwidth (" . &l:shiftwidth . "). "
	    endif
	else
	    if &l:tabstop != &l:shiftwidth
		let l:inconsistencies .= "\nThe value of tabstop (" . &l:tabstop . ") should equal the value of shiftwidth (" . &l:shiftwidth . "). "
	    endif
	endif
    endif
	
    " When using 'softtabstop', 'tabstop' remains at the standard value of 8. 
    if &l:softtabstop > 0 && &l:tabstop != 8
	let l:inconsistencies .= "\nWhen using soft tabstops, tabstop (" . &l:tabstop . ") should remain at the standard value of 8. "
    endif

    if ! empty( l:inconsistencies )
	let l:inconsistencies = "\n\nThe buffer's indent settings are inconsistent:" . l:inconsistencies
    endif

    return l:inconsistencies
endfunction

function! s:IsBufferSettingsConsistent()
    return empty( s:CheckBufferSettingsConsistency() )
endfunction

function! s:GetIndentSettingForBufferSettings()
"*******************************************************************************
"* PURPOSE:
"   Translates the buffer indent settings (tabstop, softtabstop, shiftwidth,
"   expandtab) into an indent setting (e.g. 'sts4'). 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   none
"* RETURN VALUES: 
"   indent setting
"   'badset' if inconsistent buffer indent settings
"*******************************************************************************
    if ! s:IsBufferSettingsConsistent()
	return 'badset'
    endif

    if &l:expandtab
	let l:setting = 'spc'
    elseif &l:softtabstop > 0
	let l:setting = 'sts'
    else
	" No multiplier for 'tab'. 
	return 'tab'
    endif

    " We use 'shiftwidth' for the indent multiplier, because it is not only
    " easier to resolve than 'tabstop'/'softtabstop', but it is also valid when
    " 'smarttab' is set. 
    let l:multiplier = &l:shiftwidth

    return l:setting . l:multiplier
endfunction

"- consistency with buffer settings functions -----------------------------{{{1
function! s:GetCorrectTabstopSetting( indentSetting )
    if &smarttab == 1
	" When using 'smarttab', front-of-the-line indenting solely uses
	" 'shiftwidth'; 'tabstop' and 'softtabstop' are only used in other
	" places. 
	return &l:tabstop
    elseif s:GetSettingFromIndentSetting( a:indentSetting ) == 'tab'
	return &l:tabstop
    elseif s:GetSettingFromIndentSetting( a:indentSetting ) == 'sts'
	return 8
    elseif s:GetSettingFromIndentSetting( a:indentSetting ) == 'spc'
	" If tabstop=8, we prefer changing the indent via softtabstop. 
	" If tabstop!=8, we rather modify tabstop than turning on softtabstop. 
	if &l:tabstop == 8
	    return 8
	else
	    return s:GetMultiplierFromIndentSetting( a:indentSetting )
	endif
    else
	throw "assert false"
    endif
endfunction

function! s:GetCorrectSofttabstopSetting( indentSetting )
    if &smarttab == 1
	" When using 'smarttab', front-of-the-line indenting solely uses
	" 'shiftwidth'; 'tabstop' and 'softtabstop' are only used in other
	" places. 
	return &l:softtabstop
    elseif s:GetSettingFromIndentSetting( a:indentSetting ) == 'sts'
	return s:GetMultiplierFromIndentSetting( a:indentSetting )
    elseif s:GetSettingFromIndentSetting( a:indentSetting ) == 'spc'
	" If tabstop=8, we prefer changing the indent via softtabstop. 
	" If tabstop!=8, we rather modify tabstop than turning on softtabstop. 
	if &l:tabstop == 8 && s:GetMultiplierFromIndentSetting( a:indentSetting ) != 8
	    return s:GetMultiplierFromIndentSetting( a:indentSetting )
	else
	    return 0
	endif
    else
	" Prefers (ts=n sts=0 expandtab) over (ts=8 sts=n expandtab). 
	return 0
    endif
endfunction

function! s:GetCorrectShiftwidthSetting( indentSetting )
    if s:GetSettingFromIndentSetting( a:indentSetting ) == 'tab'
	return &l:tabstop
    else
	return s:GetMultiplierFromIndentSetting( a:indentSetting )
    endif
endfunction

function! s:GetCorrectExpandtabSetting( indentSetting )
    return (s:GetSettingFromIndentSetting( a:indentSetting ) == 'spc')
endfunction

function! s:CheckConsistencyWithBufferSettings( indentSetting ) " {{{2
"*******************************************************************************
"* PURPOSE:
"   Checks the consistency of the passed indent setting with the indent settings
"   of the current buffer, i.e. the 'tabstop', 'softtabstop', 'shiftwidth' and
"   'expandtab' settings. 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:indentSettings: prescribed indent setting for the buffer
"* RETURN VALUES: 
"   empty string: indent setting is consistent with buffer indent settings, else
"   user string describing the necessary changes to adapt the buffer indent
"	settings. 
"*******************************************************************************
    let l:isTabstopCorrect     = (s:GetCorrectTabstopSetting( a:indentSetting )	    == &l:tabstop)
    let l:isSofttabstopCorrect = (s:GetCorrectSofttabstopSetting( a:indentSetting ) == &l:softtabstop)
    let l:isShiftwidthCorrect  = (s:GetCorrectShiftwidthSetting( a:indentSetting )  == &l:shiftwidth)
    let l:isExpandtabCorrect   = (s:GetCorrectExpandtabSetting( a:indentSetting )   == &l:expandtab)

    if l:isTabstopCorrect && l:isSofttabstopCorrect && l:isShiftwidthCorrect && l:isExpandtabCorrect
	return ''
    else
	let l:userString = "The buffer's indent settings are " . ( s:IsEnoughIndentForSolidAssessment() ? '' : 'potentially ')
	let l:userString .= "inconsistent with the used indent '" . s:IndentSettingToUserString( a:indentSetting ) . "'; these settings must be changed: "
	if ! l:isTabstopCorrect
	    let l:userString .= "\n- tabstop from " . &l:tabstop . ' to ' . s:GetCorrectTabstopSetting( a:indentSetting )
	endif
	if ! l:isSofttabstopCorrect
	    let l:userString .= "\n- softtabstop from " . &l:softtabstop . ' to ' . s:GetCorrectSofttabstopSetting( a:indentSetting )
	endif
	if ! l:isShiftwidthCorrect
	    let l:userString .= "\n- shiftwidth from " . &l:shiftwidth . ' to ' . s:GetCorrectShiftwidthSetting( a:indentSetting )
	endif
	if ! l:isExpandtabCorrect
	    let l:userString .= "\n- expandtab from " . &l:expandtab . ' to ' . s:GetCorrectExpandtabSetting( a:indentSetting )
	endif

	let l:userString .= s:GetInsufficientIndentUserMessage()

	return l:userString
    endif
endfunction " }}}2

function! s:MakeBufferSettingsConsistentWith( indentSetting )
    let &l:tabstop    = s:GetCorrectTabstopSetting( a:indentSetting )
    let &l:softtabstop = s:GetCorrectSofttabstopSetting( a:indentSetting )
    let &l:shiftwidth = s:GetCorrectShiftwidthSetting( a:indentSetting )
    let &l:expandtab  = s:GetCorrectExpandtabSetting( a:indentSetting )
endfunction

"}}}1

"- output functions -------------------------------------------------------{{{1
function! s:EchoStartupMessage( lineCnt, scopeUserString )
    " When the IndentConsistencyCop is triggered by through autocmds
    " (IndentConsistencyCopAutoCmds.vim), the newly created buffer is not yet
    " displayed. To allow the user to see what text IndentConsistencyCop is
    " talking about, we're forcing a redraw. 
    redraw

    " For large ranges / buffers, processing may take a while. We print out an
    " informational message so that the user knows what is eating the CPU cycles
    " right now. But we only print the message for large files to avoid the
    " 'Press ENTER to continue' VIM prompt. 
    if a:lineCnt > 2000 " empirical value
	echo 'IndentConsistencyCop is investigating ' . a:scopeUserString . '...'
    endif
endfunction

function! s:EchoUserMessage( message )
    echomsg a:message
endfunction

function! s:IndentSettingToUserString( indentSetting )
"*******************************************************************************
"* PURPOSE:
"   Converts the internally used 'xxxn' indent setting into a
"   user-understandable string. 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:indentSetting: indent setting
"* RETURN VALUES: 
"   string describing the indent setting
"*******************************************************************************
    let l:userString = ''

    if a:indentSetting == 'tab' 
	let l:userString = 'tabstop'
    elseif a:indentSetting == 'badsts'
	let l:userString = 'soft tabstop with too many trailing spaces'
    elseif a:indentSetting == 'badmix'
	let l:userString = 'bad mix of spaces and tabs'
    elseif a:indentSetting == 'badset'
	let l:userString = 'inconsistent buffer indent settings'
    elseif a:indentSetting == 'notbad'
	let l:userString = 'no bad mixes or soft tabstops with too many spaces'
    else
	let l:setting = s:GetSettingFromIndentSetting( a:indentSetting )
	let l:multiplier = s:GetMultiplierFromIndentSetting( a:indentSetting )
	if l:setting == 'sts'
	    let l:userString = l:multiplier . ' characters soft tabstop' 
	elseif l:setting == 'spc'
	    let l:userString = l:multiplier . ' spaces'
	else
	    throw 'unknown indent setting "' . a:indentSetting . '"'
	endif
    endif

    return l:userString
endfunction

function! s:DictCompareDescending( i1, i2 )
    return a:i1[1] == a:i2[1] ? 0 : a:i1[1] > a:i2[1] ? -1 : 1
endfunction

function! s:RatingsToUserString( lineCnt )
"*******************************************************************************
"* PURPOSE:
"   Dresses up the ratings information into a multi-line string that can be
"   displayed to the user. The lines are ordered from high to low ratings. If
"   low ratings have been filtered out, this is reported, too. 
"* ASSUMPTIONS / PRECONDITIONS:
"   s:occurrences dictionary; key: indent setting; value: number of
"	lines that have that indent setting
"   s:ratings dictionary; key: indent setting; value: percentage 
"	rating (100: checked range is consistent; < 100: inconsistent. 
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:lineCnt:	Number of lines in the range / buffer that have been inspected. 
"* RETURN VALUES: 
"   user string describing the ratings information
"*******************************************************************************
    let l:bufferIndentSetting = s:GetIndentSettingForBufferSettings()
    let l:isBufferIndentSettingInRatings = 0
    let l:userString = ''

    " In order to output the ratings from highest to lowest, we need to
    " convert the ratings dictionary to a list and sort it with a custom
    " comparator which considers the value part of each list element. 
    " There is no built-in sort() function for dictionaries. 
    let l:ratingLists = items( s:ratings )
    call sort( l:ratingLists, "s:DictCompareDescending" )
    let l:ratingSum = 0
    for l:ratingList in l:ratingLists
	let l:indentSetting = l:ratingList[0]
	let l:userString .= "\n- " . s:IndentSettingToUserString( l:indentSetting ) . ' (' . s:occurrences[ l:indentSetting ] . ' of ' . a:lineCnt . ' lines)'
	"**** let l:rating = l:ratingLists[1] = s:ratings[ l:indentSetting ]
	if l:indentSetting == l:bufferIndentSetting
	    let l:userString .= ' <- buffer setting'
	    let l:isBufferIndentSettingInRatings = 1
	endif
	let l:ratingSum += s:ratings[ l:indentSetting ]
    endfor

    if l:ratingSum < (100 - 1) " Allow for 1% rounding error. 
	let l:userString .= "\nSome minor / inconclusive potential settings have been omitted. "
    endif

    if ! l:isBufferIndentSettingInRatings
	let l:bufferSettingsInconsistencies = s:CheckBufferSettingsConsistency()
	if empty( l:bufferSettingsInconsistencies )
	    let l:userString .= "\nThe buffer setting is " . s:IndentSettingToUserString( s:GetIndentSettingForBufferSettings() ) . '. '
	else
	    let l:userString .= l:bufferSettingsInconsistencies
	endif
    endif

    return l:userString
endfunction

function! s:PrintBufferSettings( messageIntro )
    let l:userMessage = a:messageIntro
    let l:userMessage .= 'tabstop=' . &l:tabstop . ' softtabstop=' . &l:softtabstop . ' shiftwidth=' . &l:shiftwidth
    let l:userMessage .= (&l:expandtab ? ' expandtab' : ' noexpandtab')

    call s:EchoUserMessage( l:userMessage )
endfunction

function! s:GetInsufficientIndentUserMessage()
    if s:IsEnoughIndentForSolidAssessment()
	return ''
    else
	return "\nWarning: The maximum indent of " . s:indentMax . ' is too small for a solid assessment. '
    endif
endfunction

function! s:IndentBufferConsistencyCop( scopeUserString, consistentIndentSetting, isBufferSettingsCheck ) " {{{1
"*******************************************************************************
"* PURPOSE:
"   Reports buffer consistency and (if desired) triggers the consistency check
"   with the buffer indent settings, thereby interacting with the user. 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:scopeUserString: either 'range' or 'buffer'
"   a:consistentIndentSetting: determined consistent indent setting of the
"      buffer
"   a:isBufferSettingsCheck: flag whether consistency with the buffer
"	settings should also be checked. 
"* RETURN VALUES: 
"   none
"*******************************************************************************
    let l:userMessage = ''
    if a:isBufferSettingsCheck
	let l:userMessage = s:CheckConsistencyWithBufferSettings( a:consistentIndentSetting )
	if ! empty( l:userMessage )
	    let l:userMessage .= "\nHow do you want to deal with the "
	    let l:userMessage .= ( s:IsEnoughIndentForSolidAssessment() ? '' : 'potential ')
	    let l:userMessage .= 'inconsistency?'
	    let l:actionNum = confirm( l:userMessage, "&Ignore\n&Change" )
	    if l:actionNum <= 1
		call s:PrintBufferSettings( 'The buffer settings remain inconsistent: ' )
	    elseif l:actionNum == 2
		call s:MakeBufferSettingsConsistentWith( a:consistentIndentSetting )
		call s:PrintBufferSettings( 'The buffer settings have been changed: ' )
	    endif
	endif
    endif
    if empty( l:userMessage )
	call s:EchoUserMessage( 'This ' . a:scopeUserString . " uses '" . s:IndentSettingToUserString( a:consistentIndentSetting ) . "' consistently. " )
    endif
endfunction


"- highlight functions-----------------------------------------------------{{{1
function! s:IsLineCorrect( lineNum, correctIndentSetting )
    let l:beginningWhitespace = s:GetBeginningWhitespace( a:lineNum )
    if empty( l:beginningWhitespace ) 
	return 1
    endif

    if a:correctIndentSetting == 'tab'
	return l:beginningWhitespace =~ '^\t\+$'
    elseif s:GetSettingFromIndentSetting( a:correctIndentSetting ) == 'spc'
	return l:beginningWhitespace =~ '^ \+$' && s:IsIndentProduceableWithIndentSetting( len( l:beginningWhitespace ), a:correctIndentSetting )
    elseif s:GetSettingFromIndentSetting( a:correctIndentSetting ) == 'sts'
	let l:beginningSpaces = substitute( l:beginningWhitespace, '\t', '        ', 'g' )
	return l:beginningWhitespace =~ '^\t* \{0,7}$' && s:IsIndentProduceableWithIndentSetting( len( l:beginningSpaces ), a:correctIndentSetting )
    elseif a:correctIndentSetting == 'notbad'
	return l:beginningWhitespace =~ '^\(\t\+ \{0,7}\| \+\)$'
    elseif a:correctIndentSetting == 'badsts'
	return l:beginningWhitespace =~ '^\t* \{8,}$'
    elseif a:correctIndentSetting == 'badmix'
	return l:beginningWhitespace =~ ' \t'
    elseif a:correctIndentSetting == 'badset'
	throw 'cannot evaluate lines with badset'
    else
	throw 'unknown indent setting "' . a:indentSetting . '"'
    endif
endfunction

function! IndentConsistencyCopFoldExpr( lineNum, foldContext )
    " This function must be global; I could not get either s:FoldExpr() nor
    " <SID>FoldExpr() resolved properly when setting 'foldexpr' to a
    " script-local function. 
    let l:lineCnt = a:lineNum - a:foldContext
    while l:lineCnt <= a:lineNum + a:foldContext
	if index( b:indentconsistencycop_lineNumbers, l:lineCnt ) != -1
	    return 0
	endif
	let l:lineCnt += 1
    endwhile
    return 1
endfunction

function! s:SetHighlighting( lineNumbers )
"*******************************************************************************
"* PURPOSE:
"   Highlights the incorrect lines; saves the original values if modifications
"   to buffer settings are done. 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"   Sets b:indentconsistencycop_did_highlighting = 1. 
"   Saves buffer settings in buffer-local variables if they don't already exist. 
"* INPUTS:
"   lineNumbers: List of buffer line numbers. 
"* RETURN VALUES: 
"   none
"*******************************************************************************
    " Set a buffer-scoped flag that the buffer's settings were modified for
    " highlighting, so that ClearHighlighting() is able to only undo the
    " modifications if there have been any. This is important because
    " ClearHighlighting() is also executed when the buffer is consistent, and in
    " that case we don't know whether there was any highlighting done
    " beforehand. 
    let b:indentconsistencycop_did_highlighting = 1

    " Before modifying any buffer setting, the original value is saved in a
    " buffer-local variable. ClearHighlighting() will use those to restore the
    " original buffer settings. SetHighlighting() may be invoked multiple times
    " without a corresponding ClearHighlighting() when the user performs
    " multiple :IndentConsistencyCop sequentially. Thus, the buffer settings
    " must only be saved on the first invocation, or after a
    " ClearHighlighting(), i.e. when the variables used for saving are
    " undefined. 

    if match( g:indentconsistencycop_highlighting, '[sm]' ) != -1
	let l:linePattern = ''
	for l:lineNum in a:lineNumbers
	    let l:linePattern .= '\|\%' . l:lineNum . 'l'
	endfor
	let l:linePattern = '\(' . strpart( l:linePattern, 2) . '\)\&^\s\+'

	if match( g:indentconsistencycop_highlighting, 's' ) != -1
	    let @/ = l:linePattern
	endif
	if match( g:indentconsistencycop_highlighting, 'm' ) != -1
	    execute '2match Error /' . l:linePattern . '/'
	endif

    endif

    if match( g:indentconsistencycop_highlighting, 'g' ) != -1
	let l:firstLineNum = min( a:lineNumbers )
	if l:firstLineNum > 0
	    execute 'normal ' . l:firstLineNum . 'G0'
	endif
    endif

    if match( g:indentconsistencycop_highlighting, 'l' ) != -1
	if ! exists( 'b:indentconsistencycop_save_list' )
	    let b:indentconsistencycop_save_list = &l:list
	endif
	setlocal list
    endif

    let l:foldContext = matchstr( g:indentconsistencycop_highlighting, 'f:\zs\d' )
    if ! empty( l:foldContext )
	" The list of lines to be highlighted is copied to a list with
	" buffer-scope, because the (buffer-scoped) foldexpr needs access to it. 
	let b:indentconsistencycop_lineNumbers = copy( a:lineNumbers )
	if ! exists( 'b:indentconsistencycop_save_foldexpr' )
	    let b:indentconsistencycop_save_foldexpr = &l:foldexpr
	endif
	let &l:foldexpr='IndentConsistencyCopFoldExpr(v:lnum,' . l:foldContext . ')'
	if ! exists( 'b:indentconsistencycop_save_foldmethod' )
	    let b:indentconsistencycop_save_foldmethod = &l:foldmethod
	endif
	setlocal foldmethod=expr
    endif
endfunction

function! s:ClearHighlighting()
"*******************************************************************************
"* PURPOSE:
"   Undoes the highlighting done by SetHighlighting() and restores the buffer
"   settings to its original values. 
"* ASSUMPTIONS / PRECONDITIONS:
"   b:indentconsistencycop_did_highlighting == 1 if highlighting was done
"* EFFECTS / POSTCONDITIONS:
"   Restores the buffer settings and undefines the buffer-local variables used
"   for saving. 
"* INPUTS:
"   none
"* RETURN VALUES: 
"   none
"*******************************************************************************
    if ! exists( 'b:indentconsistencycop_did_highlighting' ) || ! b:indentconsistencycop_did_highlighting 
	return
    endif
    unlet b:indentconsistencycop_did_highlighting

    if match( g:indentconsistencycop_highlighting, 's' ) != -1
	let @/ = ''
    endif
    if match( g:indentconsistencycop_highlighting, 'm' ) != -1
	2match none
    endif

    " 'g' : There's no need to undo this. 

    if match( g:indentconsistencycop_highlighting, 'l' ) != -1
	if exists( 'b:indentconsistencycop_save_list' )
	    let &l:list = b:indentconsistencycop_save_list
	    unlet b:indentconsistencycop_save_list
	endif
    endif

    if ! empty( matchstr( g:indentconsistencycop_highlighting, 'f:\zs\d' ) )
	if exists( 'b:indentconsistencycop_lineNumbers' )
	    " Just free the memory here. 
	    unlet b:indentconsistencycop_lineNumbers
	endif
	if exists( 'b:indentconsistencycop_save_foldmethod' )
	    let &l:foldmethod = b:indentconsistencycop_save_foldmethod
	    unlet b:indentconsistencycop_save_foldmethod
	endif
	if exists( 'b:indentconsistencycop_save_foldexpr' )
	    let &l:foldexpr = b:indentconsistencycop_save_foldexpr
	    unlet b:indentconsistencycop_save_foldexpr
	endif
    endif
endfunction

function! s:HighlightInconsistentIndents( startLineNum, endLineNum, correctIndentSetting )
    " Patterns for correct tabstops and space indents are easy to come up with.
    " The softtabstops of 1,2,4 are easy, too. The softtabstop indents of 3, 5,
    " 7 are very difficult to express, because you have to consider the number
    " of tabs, too. 
    " Negating this match to highlight all incorrect indents plus the possible
    " bad space-tab combinations only makes things worse. Thus, we use the brute
    " approach and examine all lines, and build the pattern with the
    " inconsistent line numbers. (Hoping that this approach scales reasonably
    " well with many inconsistent line numbers.) 
    "
    " A search pattern would then look like this:
    "\(\%4l\|\%17l\|\%23l\)\&^\s\+
    "
    " Another benefit of storing the line numbers versus creating a pattern is
    " that this allows different methods of visualization (highlighting,
    " folding, quickfix, ...).
    let l:lineNumbers = []

    let l:lineNum = a:startLineNum
    while l:lineNum <= a:endLineNum
	if ! s:IsLineCorrect( l:lineNum, a:correctIndentSetting )
	    let l:lineNumbers += [ l:lineNum ]
	endif
	let l:lineNum += 1
    endwhile
    if len( l:lineNumbers ) == 0
	" All lines are correct. 
	call s:ClearHighlighting()
	call s:EchoUserMessage("No incorrect lines found for setting '" . s:IndentSettingToUserString( a:correctIndentSetting ) . "'!")
    else
	call s:SetHighlighting( l:lineNumbers )
	call s:EchoUserMessage( 'Marked ' . len( l:lineNumbers ) . ' incorrect lines. ' )
    endif
endfunction

function! s:QueryIndentSetting()
"*******************************************************************************
"* PURPOSE:
"	? What the procedure does (not how).
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"	? Explanation of each argument that isn't obvious.
"* RETURN VALUES: 
"   Queried indent setting (e.g. 'spc4'), or empty string if user has canceled. 
"*******************************************************************************
    let l:settingNum = confirm( 'Choose the indent setting:', "&tabstop\n&soft tabstop\nspa&ces" )
    if l:settingNum <= 0
	return ''
    elseif l:settingNum >= 2
	let l:multiplier = confirm( 'Choose indent value:', "&1\n&2\n&3\n&4\n&5\n&6\n&7\n&8" )
	if l:multiplier <= 0
	    return ''
	endif
    endif

    if l:settingNum == 1
	return 'tab'
    elseif l:settingNum == 2
	return 'sts' . l:multiplier
    elseif l:settingNum == 3
	return 'spc' . l:multiplier
    else
	throw 'assert false'
    endif
endfunction

function! s:IndentBufferInconsistencyCop( startLineNum, endLineNum, inconsistentIndentationMessage ) " {{{1
"*******************************************************************************
"* PURPOSE:
"   Reports buffer inconsistency and offers steps to tackle the problem. 
"* ASSUMPTIONS / PRECONDITIONS:
"   s:occurrences dictionary; key: indent setting; value: number of
"	lines that have that indent setting
"   s:ratings dictionary; key: indent setting; value: percentage 
"	rating (100: checked range is consistent; < 100: inconsistent. 
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:startLineNum, a:endLineNum: range in the current buffer that is to be
"	checked. 
"   a:inconsistentIndentationMessage: user message about the inconsistent
"	indentation and possible conflicting indent settings
"* RETURN VALUES: 
"   none
"*******************************************************************************
    let l:actionNum = confirm( a:inconsistentIndentationMessage, "&Ignore\n&Highlight wrong indents..." )
    if l:actionNum <= 1
	" User chose to ignore the inconsistencies. 
	call s:EchoUserMessage('Be careful when modifying the inconsistent indents! ')
    elseif l:actionNum == 2
	let l:bufferIndentSetting = s:GetIndentSettingForBufferSettings()
	" The buffer indent settings may be 'badset', which cannot be
	" highlighted. So we need to suppress this option if it is bad. 
	let l:isBadBufferIndent = (s:IsBadIndentSetting( l:bufferIndentSetting ) ? 1 : 0)

	let l:isBestGuessEqualToBufferIndent = 1 " Suppress best guess option if no guess available. 
	if ! empty( s:ratings )
	    let l:ratingLists = items( s:ratings )
	    call sort( l:ratingLists, "s:DictCompareDescending" )
	    let l:bestGuessIndentSetting = l:ratingLists[0][0]
	    let l:isBestGuessEqualToBufferIndent = (l:bestGuessIndentSetting == l:bufferIndentSetting)
	endif

	let l:highlightMessage = 'What kind of inconsistent indents do you want to highlight?'
	if l:isBestGuessEqualToBufferIndent && l:isBadBufferIndent
	    let l:highlightChoices = ''
	elseif l:isBestGuessEqualToBufferIndent && ! l:isBadBufferIndent
	    let l:highlightChoices = "\nNot &buffer settings / best guess (" . l:bufferIndentSetting . ')'
	elseif ! l:isBestGuessEqualToBufferIndent && l:isBadBufferIndent
	    let l:highlightChoices = "\nNot best &guess (" . l:bestGuessIndentSetting . ')'
	else
	    let l:highlightChoices = "\nNot &buffer settings (" . l:bufferIndentSetting . ')'
	    let l:highlightChoices .= "\nNot best &guess (" . l:bestGuessIndentSetting . ')'
	endif
	let l:highlightChoices .= "\nNot &chosen setting..."
	if s:GetKeyedValue( s:occurrences, 'badmix' ) + s:GetKeyedValue( s:occurrences, 'badsts' ) > 0
	    let l:highlightChoices .= "\n&Illegal indents only"
	endif

	let l:highlightNum = confirm( l:highlightMessage, strpart( l:highlightChoices, 1 ) )
	if l:highlightNum <= 0
	    " User canceled. 
	    call s:EchoUserMessage('Be careful when modifying the inconsistent indents! ')
	elseif l:highlightNum == (1 - l:isBadBufferIndent )
	    call s:HighlightInconsistentIndents( a:startLineNum, a:endLineNum, l:bufferIndentSetting )
	elseif l:highlightNum == (2 - l:isBestGuessEqualToBufferIndent - l:isBadBufferIndent)
	    call s:HighlightInconsistentIndents( a:startLineNum, a:endLineNum, l:bestGuessIndentSetting )
	elseif l:highlightNum == (3 - l:isBestGuessEqualToBufferIndent - l:isBadBufferIndent)
	    let l:chosenIndentSetting = s:QueryIndentSetting()
	    if ! empty( l:chosenIndentSetting )
		call s:HighlightInconsistentIndents( a:startLineNum, a:endLineNum, l:chosenIndentSetting )
	    endif
	elseif l:highlightNum == (4 - l:isBestGuessEqualToBufferIndent - l:isBadBufferIndent)
	    call s:HighlightInconsistentIndents( a:startLineNum, a:endLineNum, 'notbad' )
	else
	    throw 'assert false'
	endif
    endif
endfunction

function! s:IndentConsistencyCop( startLineNum, endLineNum, isBufferSettingsCheck ) " {{{1
"*******************************************************************************
"* PURPOSE:
"   Triggers the indent consistency check and presents the results to the user. 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:startLineNum, a:endLineNum: range in the current buffer that is to be
"	checked. 
"   a:isBufferSettingsCheck: flag whether consistency with the buffer
"	settings should also be checked. 
"* RETURN VALUES: 
"   none
"*******************************************************************************
    let l:isEntireBuffer = ( a:startLineNum == 1 && a:endLineNum == line('$') )
    let l:scopeUserString = (l:isEntireBuffer ? 'buffer' : 'range')
    let l:lineCnt = a:endLineNum - a:startLineNum + 1

    call s:EchoStartupMessage( l:lineCnt, l:scopeUserString )

    let s:occurrences = {}
    let s:ratings = {}
    let l:isConsistent = s:CheckBufferConsistency( a:startLineNum, a:endLineNum )

    if l:isConsistent == -1
	call s:EchoUserMessage( 'This ' . l:scopeUserString . ' does not contain indented text. ' )
    elseif l:isConsistent == 0
	let l:inconsistentIndentationMessage = 'Found ' . ( s:IsEnoughIndentForSolidAssessment() ? '' : 'potentially ')
	let l:inconsistentIndentationMessage .= 'inconsistent indentation in this ' . l:scopeUserString . '; generated from these conflicting settings: ' 
	let l:inconsistentIndentationMessage .= s:RatingsToUserString( l:lineCnt )
	let l:inconsistentIndentationMessage .= s:GetInsufficientIndentUserMessage()
	call s:IndentBufferInconsistencyCop( a:startLineNum, a:endLineNum, l:inconsistentIndentationMessage )
    elseif l:isConsistent == 1
	call s:ClearHighlighting()

	let l:consistentIndentSetting = keys( s:ratings )[0]
	call s:IndentBufferConsistencyCop( l:scopeUserString, l:consistentIndentSetting, a:isBufferSettingsCheck )
    else
	throw "assert false"
    endif
"****D echo 'Consistent   ? ' . l:isConsistent
"****D echo 'Occurrences:   ' . string( s:occurrences )
"****D echo 'nrm. ratings:  ' . string( s:ratings )

    " Cleanup variables with script-scope. 
    call filter( s:occurrences, 0 )
    call filter( s:ratings, 0 )
endfunction

"}}}1

"- commands --------------------------------------------------------------{{{1
" Ensure indent consistency within the range / buffer, and - if achieved -, also
" check consistency with buffer indent settings. 
command! -range=% -nargs=0 IndentConsistencyCop call <SID>IndentConsistencyCop( <line1>, <line2>, 1 )

" Remove the highlighting of inconsistent lines and restore the normal view for
" this buffer. 
command! -nargs=0 IndentConsistencyCopOff call <SID>ClearHighlighting()

" Only check indent consistency within range / buffer. Don't check the
" consistency with buffer indent settings. Prefer this command to
" IndentRangeConsistencyCop if you don't want your buffer indent settings
" changed, or if you only want to check a limited range of the buffer that you
" know does not conform to the buffer indent settings. 
command! -range=% -nargs=0 IndentRangeConsistencyCop call <SID>IndentConsistencyCop( <line1>, <line2>, 0 )

" vim:ft=vim foldmethod=marker
