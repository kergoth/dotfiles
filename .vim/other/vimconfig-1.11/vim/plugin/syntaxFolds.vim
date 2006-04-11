" ==============================================================================
"        File: syntaxFolds.vim
"      Author: Srinath Avadhanula
"              ( srinath@fastmail.fm )
" Description: Emulation of the syntax folding capability of vim using manual
"              folding
"
" This script provides an emulation of the syntax folding of vim using manual
" folding. Just as in syntax folding, the folds are defined by regions. Each
" region is specified by a call to FoldRegions() which accepts 4 parameters:
"
"    call FoldRegions(startpat, endpat, startoff, endoff)
"
"    startpat: a line matching this pattern defines the beginning of a fold.
"    endpat  : a line matching this pattern defines the end of a fold.
"    startoff: this is the offset from the starting line at which folding will
"              actually start
"    endoff  : like startoff, but gives the offset of the actual fold end from
"              the line satisfying endpat.
"              startoff and endoff are necessary when the folding region does
"              not have a specific end pattern corresponding to a start
"              pattern. for example in latex,
"              \begin{section}
"              defines the beginning of a section, but its not necessary to
"              have a corresponding
"              \end{section}
"              the section is assumed to end 1 line _before_ another section
"              starts.
"    Example: A syntax fold region for a latex section is
"      startpat = "\\section{"
"      endpat   = "\\section{"
"      startoff = 0
"      endoff   = -1
"    Note that the start and end patterns are thus the same and endoff has a
"    negative value to capture the effect of a section ending one line before
"    the next starts.
"
" Each time a call is made to FoldRegions(), all the regions (which might be
" disjoint, but not nested) are folded up.
" Nested folds can be created by successive calls to FoldRegions(). The first
" call defines the region which is deepest in the folding. See MakeTexFolds()
" for an idea of how this works for latex files.

" Function: MakeSyntaxFolds(force)
" Description: This function calls FoldRegions() several times with the
"     parameters specifying various regions resulting in a nested fold
"     structure for the file.
function! MakeSyntaxFolds(force, ...)
	if exists('b:doneFolding') && a:force == 0
		return
	end
	if a:0 > 0
		let line1 = a:1
		let line2 = a:2
	else
		let line1 = 1
		let line2 = line('$')
		let r = line('.')
		let c = virtcol('.')
		
		setlocal fdm=manual
		normal! zE
	end
	
	let i = 1
	while exists('b:startPat_'.i)
		exe 'let startPat = b:startPat_'.i
		exe 'let endPat = b:endPat_'.i
		exe 'let startOff = b:startOff_'.i
		exe 'let endOff = b:endOff_'.i
		
		let skipStart = ''
		let skipEnd = ''
		if exists('b:skipStartPat_'.i)
			exe 'let skipStart = b:skipStartPat_'.i
			exe 'let skipEnd = b:skipEndPat_'.i
		end

		call FoldRegions(startPat, endPat, startOff, endOff, line1, line2, skipStart, skipEnd)

		let i = i + 1
	endwhile
	
	if a:0 == 0
		exe r
		exe "normal! ".c."|"
		if foldlevel(r) > 1
			exe "normal! ".(foldlevel(r) - 1)."zo"
		end
		let b:doneFolding = 0
	end
endfunction

" Function: FoldRegions(startpat, endpat, startoff, endoff)
" Description: See the help comments at the beginning of the file for a
"     description of how FoldRegions() uses the input arguments to fold up
"     "regions" of the file. 
function! FoldRegions(startpat, endpat, startoff, endoff, ...)
	
	" if we have been called with additional arguments, it means we have been
	" asked to restrict ourselves to a given range of lines, not the whole
	" file ....
	if a:0 > 0
		let firstLine = a:1
		let lastLine = a:2
	else
		let firstLine = 1
		let lastLine = line('$')
	end
	" even more arguments mean that a "skip" region has been specified.
	if a:0 > 2
		let skipRegionBegin = a:3
		let skipRegionEnd = a:4
	else
		let skipRegionBegin = ''
		let skipRegionEnd = ''
	end

	" by default, we dont want to skip anything. setting begin > end ensures
	" this.
	let skipLineEnd = -1
	let skipLineBegin = line('$') + 1
	" if a skip region has been specified, then try to see if it exists in our
	" range.
	let skippedRegions = ''
	if skipRegionBegin != ''
		exe firstLine
		let gotSkipBeginLine = search(skipRegionBegin, 'W')
		" if there is a skipBegin regexp in the range, then search for the
		" skip end regexp. ths is a while loop because a single range can
		" potentially have multiple skip regions specified by the same
		" pattern. make a recursive call to the MakeFolds function for every
		" such range.
		while gotSkipBeginLine > firstLine && gotSkipBeginLine < lastLine
			let skipLineBegin = line('.')
			let skipLineEnd = search(skipRegionEnd, 'W')
			if skipLineEnd == 0
				let skipLineEnd = lastLine
			end
			" call PrintError('startpat = '.a:startpat.' making recursive call in the skip region from '.skipLineBegin.' to '.skipLineEnd)
			call MakeSyntaxFolds(1, skipLineBegin, skipLineEnd)
			let skippedRegions = skippedRegions.skipLineBegin.','.skipLineEnd.'|'
			let gotSkipBeginLine = search(skipRegionBegin, 'W')
		endwhile
	end

	exe firstLine
	" need to first make a check against the current line, because search()
	" will skip a match on the current line.
	if getline('.') =~ a:startpat
		let n1 = line('.')
	else
		let n1 = search(a:startpat, 'W')
	end
	" call PrintError('strpat = '.a:startpat."\t\t\t\t\t firstLine = ".firstLine.' lastLine = '.lastLine.' n1 = '.n1.' will skip ('.skipLineBegin.','.skipLineEnd.')')

	" start searching for the pattern which defines the start of the region.
	while n1 > 0 && n1 <= lastLine
		" for each found pattern, calculate the offset to start folding from.
		let fn1 = n1 + a:startoff
		" if this match is in a closed fold, then it means that this was a
		" skipped region.... hence... skip it.
		if foldclosedend(fn1) > 0
			let fn2 = foldclosedend(fn1)
		else
			" if the beginning is not in a skipped region and is within the
			" given range, then search for the pattern which defines the end
			" of the region.
			let n2 = search(a:endpat, 'W')

			" if this line is already folded up, it means that this was in a
			" "skipped" region. therefore ignore any matches found in a closed
			" fold.
			while n2 > 0 && IsInSkippedRegion(n2, skippedRegions)
				" call PrintError('getting a match in an already folded region '.n2)
				" skip to the end of the folded region.
				if foldclosedend(n2) > 0
					let n2 = foldclosedend(n2)
				end
				" and search again.
				let n2 = search(a:endpat, 'W')
			endwhile

			" if we have come here with a positive n2, it means we have found
			" a valid region.
			if n2 > 0
				let fn2 = n2 + a:endoff
			else
			" otherwise, we didnt find an end pattern in our given range.
			" default to the last line of the range.
				let fn2 = lastLine
			end
			" fold up the region found.
			" call PrintError('folding from '.fn1.' to '.fn2)
			if fn2 > fn1
				exe fn1.','.fn2.' fold'
			end
		end
		
		" move beyond the region just processed...
		exe (fn2 + 1)
		" ... and start searching for the start pattern again.
		if getline('.') =~ a:startpat
			let n1 = line('.')
		else
			let n1 = search(a:startpat, 'W')
		end

	endwhile
endfunction

function! IsInSkippedRegion(lnum, regions)
	let i = 1
	let subset = s:Strntok(a:regions, '|', i)
	while subset != ''
		let n1 = s:Strntok(subset, ',', 1)
		let n2 = s:Strntok(subset, ',', 2)
		if a:lnum >= n1 && a:lnum <= n2
			return 1
		end

		let subset = s:Strntok(a:regions, '|', i)
		let i = i + 1
	endwhile

	return 0
endfunction

" Strntok:
" extract the n^th token from s seperated by tok. 
" example: Strntok('1,23,3', ',', 2) = 23
fun! <SID>Strntok(s, tok, n)
	return matchstr( a:s.a:tok[0], '\v(\zs([^'.a:tok.']*)\ze['.a:tok.']){'.a:n.'}')
endfun

