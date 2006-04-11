"        File: imaps.vim
"      Author: Srinath Avadhanula
"              ( srinath@fastmail.fm )
"         WWW: http://robotics.eecs.berkeley.edu/~srinath
" Description: insert mode template expander with cursor placement
"              while preserving filetype indentation.
" Last Change: Thu Mar 21 05:00 AM 2002 PST
" 
" Documentation: {{{
" TODO: This documentation is obsolete right now!!
" this script provides a way to generate insert mode mappings which do not
" suffer from some of the problem of mappings and abbreviations while allowing
" cursor placement after the expansion. It can alternatively be thought of as
" a template expander. 
"
" Consider an example. If you do
"
" imap lhs something
"
" then a mapping is set up. However, there will be the following problems:
" 1. the 'ttimeout' option will generally limit how easily you can type the
"    lhs. if you type the left hand side too slowly, then the mapping will not
"    be activated.
" 2. if you mistype one of the letters of the lhs, then the mapping is
"    deactivated as soon as you backspace to correct the mistake.
"
" If, in order to take care of the above problems, you do instead
"
" iab lhs something
"
" then the timeout problem is solved and so is the problem of mistyping.
" however, abbreviations are only expanded after typing a non-word character.
" which causes problems of cursor placement after the expansion and invariably
" spurious spaces are inserted.
"
" this script attempts to solve all these problems by providing an emulation
" of imaps wchich does not suffer from its attendant problems. Because maps
" are activated without having to press additional characters, therefore
" cursor placement is possible. furthermore, file-type specific indentation is
" preserved, because the rhs is expanded as if the rhs is typed in literally
" by the user.
"  
" The script already provides some default mappings. each "mapping" is of the
" form:
"
" let s:<filetype>_<lhs> = "rhs"
"
" Consider a working example:
"
" let s:tex_bit  = "\\begin{itemize}\<cr>\\item ää\<cr>\\end{itemize}"
" 
" This effectively sets up the map
" 
" imap bit<leader>
"
" whenever you edit a latex file. i.e, if you type the leader character ('\'
" by default), after the word 'bit', then its expanded as follows:
"
" \begin{itemize}
" \item *
" \end{itemize}
"
" where * shows the cursor position. The special characters "ää" (typed as
" CTRL-K + a + :) decides the cursor placement after the expansion. If there
" is no "ää", then the cursor is left at the end.
"
" however, unlike in mappings, it is not necessary to enter the keys
" b,i,t,<leader> in quick succession. this works by just mapping the last
" character, which is chosen to be <leader> instead of all the characters. a
" check is then made to see if the characters entered before match the total
" LHS of the required mapping.
" 
" NOTE: some functions may confuse user. Therefore if exists variable
" "g:disable_imap" or "b:disable_imap" and is set to ":let g:disable_imap=1",
" all functions returns ASAP. This feature was added by Lubomir Host 'rajo'
" <rajo AT platon.sk>
" 
" NOTE: There are other plugins out there which do the same thing. For
" example, Dr. Chip's Cabbr script at 
"    http://users.erols.com/astronaut/vim/index.html#CAbbrv
" However, this script is a bit more general in that mappings for various file
" types can be put in the same place and also, instead of having to extend a
" function by putting additional 'if ...' lines, you directly type in
" additional mappings as variables.
" 
"--------------------------------------%<--------------------------------------
" Bonus: This script also provides a command Snip which puts tearoff strings,
" '----%<----' above and below the visually selected range of lines. The
" length of the string is chosen to be equal to the longest line in the range.
"--------------------------------------%<--------------------------------------
" }}}

" Only do this when not done yet
" This plugin is (must be) sourced by ~/.vimrc, because 
" many ftplugins are using function IMAP()
if exists("b:did_imap_plugin")
  finish
endif
let b:did_imap_plugin = 1

" IMAP: Adds a "fake" insert mode mapping. {{{
"       For example, doing
"           IMAP('abc', 'def') 
"       will mean that if the letters abc are pressed in insert mode, then
"       they will be replaced by def. however, it has a few changes
"       (improvements ?) over simply doing:
"           imap abc def
"       1. with imap, if you begin typing abc, the cursor will not advance and
"          long as there is a possible completion, the letters a, b, c will be
"          displayed on top of the other. using this function avoids that.
"       2. with imap, if a backspace or arrow key is pressed before completing
"          the word, then the mapping is lost. this function allows movement. 
"          (this ofcourse means that this function is only limited to
"          left-hand-sides which do not have movement keys or unprintable
"          characters)
"       It works by only mapping the last character of the left-hand side.
"       when this character is typed in, then a reverse lookup is done and if
"       the previous characters consititute the left hand side of the mapping,
"       the previously typed characters and erased and the right hand side is
"       inserted.
function! IMAP(lhs, rhs, ft)
	if exists("g:disable_imap")
		if g:disable_imap == 1
			return
		endif
	endif
	if exists("b:disable_imap")
		if b:disable_imap == 1
			return
		endif
	endif
	let lastLHSChar = a:lhs[strlen(a:lhs)-1]
	" s:charLens_<ft>_<char> contains the lengths of the left hand sides of
	" the various mappings for filetype <ft> which end in <char>. its a comma
	" seperated list of numbers.
	" for example if we want to create 2 mappings
	"   ab  --> cd
	"   lbb --> haha
	" for tex type files, then the variable will be:
	"   s:charLens_tex_b = '2,3,'
	let charLenHash = 's:charLens_' . a:ft . '_' . char2nr(lastLHSChar)

	" if this variable doesnt exist before, initialize...
	if !exists(charLenHash)
		exe 'let ' . charLenHash . ' = ""'
	end
	" get the value of the variable.
	exe "let charLens = ".charLenHash
	" check to see if this length is already there...
	if matchstr(charLens, '\(^\|,\)' . strlen(a:lhs) . ',') == ''
		" ... if not append.
		" but carefully. sort the charLens array in decreasing order. this way
		" the longest lhs is checked first. i.e if the user has 2 maps
		" ab    --> rhs1
		" csdfb --> rhs2
		" i.e 2 mappings ending in b, then check to see if the longer mapping
		" is satisfied first.
		" TODO: possible bug. what if the user has a mapping with lhs more
		" than 9 chars? (highly improbable).
		" largest element which is just smaller than the present length
		let idx = match(charLens, '[1-' . strlen(a:lhs) . '],')
		if idx == -1
			let new = charLens.strlen(a:lhs) . ','
		else
			let left = strpart(charLens, 0, idx)
			let right = strpart(charLens, idx, 1000)
			let new = left . strlen(a:lhs) . ',' . right
		end

		let charLens = new
		exe "let " . charLenHash . " = charLens"
	end
	
	" create a variable corresponding to the lhs. convert all non-word
	" characters into their ascii codes so that a vim variable with that name
	" can be created.  this is a way to create hashes in vim.
	let lhsHash = 's:Map_' . a:ft . '_'
				\ . substitute(a:lhs, '\(\W\)', '\="_".char2nr(submatch(1))."_"', 'g')
	" store the value of the right-hand side of the mapping in this newly
	" created variable.
	exe "let " . lhsHash . " = a:rhs"
	
	" store a token string of this length. this is helpful later for erasing
	" the left-hand side before inserting the right-hand side.
	let tokenLenHash = 's:LenStr_' . strlen(a:lhs)
	exe "let " . tokenLenHash . " = a:lhs"

	" map only the last character of the left-hand side.
	exe 'inoremap ' . escape(lastLHSChar, '|')
				\ . ' <C-r>=<SID>LookupCharacter("'
				\ . escape(lastLHSChar, '\|') . '")<CR>'
endfunction

" }}}
" LookupCharacter: inserts mapping corresponding to this character {{{
"
" This function performs a reverse lookup when this character is typed in. It
" loops over all the possible left-hand side variables ending in this
" character and then if a possible match exists, ereases the left-hand side
" and inserts the right hand side instead.
silent! function! <SID>LookupCharacter(char)
	if exists("b:disable_imap")
		if b:disable_imap == 1
			"echo "LookupCharacter(\"" . a:char . "\") - disabled (b:disabled=1)"
			" here we must return parameter 
			return a:char
		endif
	endif
	if exists("b:disabled_imap_syntax_items")
		let currentSyntaxItem = synIDattr(synID(line("."), col(".") - 1, 1), "name")
		if match(currentSyntaxItem, b:disabled_imap_syntax_items) != -1
			echo "IMAP mappings are disabled here"
			return a:char
		endif
	endif
	"echo "currentSyntaxItem = " . synIDattr(synID(line("."), col(".") - 1, 1), "name")
				\ 'line = ' . line(".")
				\ 'col  = ' .col(".")
	echo "LookupCharacter(\"" . a:char . "\") - enabled (b:disabled=0)"
	let charHash = char2nr(a:char)

	if !exists('s:charLens_' . &ft . '_' . charHash)
				\ && !exists('s:charLens__' . charHash)
		return a:char
	end
	" get the lengths of the left-hand side mappings which end in this
	" character. if no mappings ended in this character, the previous if
	" statement would have exited.
	silent! exe 'let lens = s:charLens_' . &ft . '_' . charHash

	let i = 1
	while 1
		" get the i^th length. 
		silent! let numchars = s:Strntok(lens, ',', i)
		silent! if numchars == ''
			return a:char
		end
		if col('.') < numchars
			let i = i + 1
			continue
		end
		
		" get the corresponding text from before the text. append the present
		" char to complete the (possible) LHS
		let text = strpart(getline('.'), col('.') - numchars, numchars - 1) . a:char
	    let lhsHashFT = 's:Map_' . &ft . '_'
					\ . substitute(text, '\(\W\)', '\="_".char2nr(submatch(1))."_"', 'g')
	    let lhsHashNoFT = 's:Map__'
					\ . substitute(text, '\(\W\)', '\="_".char2nr(submatch(1))."_"', 'g')

		" if there is no mapping of this length which satisfies the previously
		" typed in characters, then proceed to the next length group...
		if exists(lhsHashFT)
			let lhsHash = lhsHashFT
		elseif exists(lhsHashNoFT)
			let lhsHash = lhsHashNoFT
		else
			let i = i + 1
			continue
		end

		"  ... otherwise insert the corresponding RHS
		" first generate the required number of back-spaces to erase the
		" previously typed in characters.
		exe "let tokLHS = s:LenStr_".numchars
		let bkspc = substitute(tokLHS, '.$', '', '')
		let bkspc = substitute(bkspc, '.', "\<bs>", "g")

		" get the corresponding RHS
		exe "let ret = " . lhsHash
		
		return bkspc . IMAP_PutTextWithMovement(ret)

	endwhile
endfunction

" }}}
" IMAP_PutTextWithMovement: appends movement commands to a text  {{{
" 		This enables which cursor placement.
function! IMAP_PutTextWithMovement(text)
	if exists("g:disable_imap")
		if g:disable_imap == 1
			return
		endif
	endif
	if exists("b:disable_imap")
		if b:disable_imap == 1
			return
		endif
	endif
			
	" if the text contains a ä or a «label», then get to the first one of
	" those. 
	let fc = match(a:text, 'ää\|«[^»]*»')
	if fc < 0
		let initial = ""
		let movement = ""
	" if the place to go to is at the very beginning, then a simple back
	" search will do...
	elseif fc == 0
		let initial = ""
		let movement = "\<esc>?ää\<cr>:call SAImaps_RemoveLastHistoryItem()\<cr>s"
	" however, if its somewhere in the middle, then we need to go back to the
	" beginning of the pattern and then do a forward lookup from that point.
	else
		" hopefully ¡¡Start!! is rare enough. prepend that to the text.
		let initial = "¡¡Start!!"
		" and then do a backwards lookup. this takes us to the beginning. then
		" delete that dummy part. we are left at the very beginning.
		let movement = "\<esc>?¡¡Start!!\<cr>v8l\"_x"
		" now proceed with the forward search for cursor placement
		let movement = movement."/ää\\|«[^»]*»\<cr>"
		" we needed 2 searches to get here. remove them from the search
		" history.
		let movement = movement.":call SAImaps_RemoveLastHistoryItem()\<cr>"
		let movement = movement.":call SAImaps_RemoveLastHistoryItem()\<cr>"
		" if its a ä or «», then just delete it
		if strpart(a:text, fc, 2) == 'ää'
			let movement = movement . "\"_2s"
		elseif strpart(a:text, fc, 2) == '«»'
			let movement = movement . "\"_2s"
		" otherwise enter select mode...
		else
			let movement = movement . "vf»\<C-g>"
		end
	end
	return initial.a:text.movement
endfunction 

" }}}
" Strntok: extract the n^th token from a list {{{
" example: Strntok('1,23,3', ',', 2) = 23
function! <SID>Strntok(s, tok, n)
	if exists("g:disable_imap")
		if g:disable_imap == 1
			return
		endif
	endif
	if exists("b:disable_imap")
		if b:disable_imap == 1
			return
		endif
	endif
	return matchstr( a:s . a:tok[0],
				\ '\v(\zs([^' . a:tok . ']*)\ze[' . a:tok . ']){' . a:n . '}')
endfunction

" }}}
" extract the leader character. the mappings need to go *after* the functio
" IMAP() is defined.
let s:ml = exists('g:mapleader') ? g:mapleader : '\'
" these are mappings which were originally in imaps.vim. ideally they should
" be in the corresponding ftplugin/<ft>.vim directory.
 
" General purpose mappings {{{
"call IMAP ('date'   . s:ml, "\<c-r>=strftime('%b %d %Y')\<cr>", '')
"call IMAP ('stamp'  . s:ml, "Last Change: \<c-r>=strftime('%a %b %d %I:00 %p %Y PST')\<cr>", '')
"call IMAP ('winm'   . s:ml, "http://robotics.eecs.berkeley.edu/~srinath/vim/winmanager-2.0.htm", '')
"call IMAP ('latexs' . s:ml, "http://robotics.eecs.berkeley.edu/~srinath/vim/latexSuite.zip", '')
"call IMAP ('homep'  . s:ml, "http://robotics.eecs.berkeley.edu/~srinath", '')
" End general purpose mappings }}}
" Vim Mappings {{{
"call IMAP ('while' . s:ml,
"			\ "let i = ää\<cr>while i <= \<cr>\<cr>\tlet i = i + 1\<cr>\<bs>endwhile", 'vim')
"call IMAP ('fdesc'. s:ml, "\"Description: ", 'vim')
" end vim mappings }}}

" Snip: puts a scissor string above and below block of text {{{
" Desciption:
"-------------------------------------%<-------------------------------------
"   this puts a the string "--------%<---------" above and below the visually
"   selected block of lines. the length of the 'tearoff' string depends on the
"   maximum string length in the selected range. this is an aesthetically more
"   pleasing alternative instead of hardcoding a length.
"-------------------------------------%<-------------------------------------
function! <SID>Snip() range
	if exists("g:disable_imap")
		if g:disable_imap == 1
			return
		endif
	endif
	if exists("b:disable_imap")
		if b:disable_imap == 1
			return
		endif
	endif
	let i = a:firstline
	let maxlen = -2
	" find out the maximum virtual length of each line.
	while i <= a:lastline
		exe i
		let length = virtcol('$')
		let maxlen = (length > maxlen ? length : maxlen)
		let i = i + 1
	endwhile
	let maxlen = (maxlen > &tw && &tw != 0 ? &tw : maxlen)
	let half = maxlen/2
	exe a:lastline
	" put a string below
	exe "norm! o\<esc>".(half - 1)."a-\<esc>A%<\<esc>".(half - 1)."a-"
	" and above. its necessary to put the string below the block of lines
	" first because that way the first line number doesnt change...
	exe a:firstline
	exe "norm! O\<esc>".(half - 1)."a-\<esc>A%<\<esc>".(half - 1)."a-"
endfunction

command! -nargs=0 -range Snip :<line1>,<line2>call <SID>Snip()
" }}}
" CleanUpHistory: removes last search item from search history {{{
" Description: This function needs to be globally visible because its
"              called from outside the script during expansion.
function! SAImaps_RemoveLastHistoryItem()
	if exists("g:disable_imap")
		if g:disable_imap == 1
			return
		endif
	endif
	if exists("b:disable_imap")
		if b:disable_imap == 1
			return
		endif
	endif
	call histdel("/", -1)
	let @/ = histget("/", -1)
endfunction
" }}}
" IMAP_Jumpfunc: takes user to next «place-holder» {{{
"        Author: Gergeley Kontra
"                taken from mu-template.vim by him. This idea is originally
"                from Stephen Riehm's bracketing system.
function! IMAP_Jumpfunc()
	if exists("g:disable_imap")
		if g:disable_imap == 1
			return
		endif
	endif
	if exists("b:disable_imap")
		if b:disable_imap == 1
			return
		endif
	endif
	if !search('«.\{-}»','W') "no more marks
		return "\<CR>"
	else
		if getline('.')[col('.')]=="»"
			return "\<Del>\<Del>"
		else
			return "\<Esc>lvf»\<C-g>"
		endif
	endif
endfunction
" map only if there is no mapping already. allows for user customization.
if !hasmapto('IMAP_Jumpfunc')
	inoremap <C-J> <c-r>=IMAP_Jumpfunc()<CR>
	nmap <C-J> i<C-J>
end
" }}}

" vim6:fdm=marker:nowrap
