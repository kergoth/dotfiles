"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" svndiff 2.0 (C) 2007 Ico Doornekamp
"
" Introduction
" ------------
"
" NOTE: This plugin is unix-only!
"
" An small vim 7.0 plugin for showing svn diff information in a file while
" editing. This plugin runs a diff between the current buffer and the original
" subversion file, and shows coloured tags indicating where the buffer differs
" from the original file from the subversion repository. The original text is
" not shown, only signs are used to indicate where changes were made.
"
" The following symbols and syntax highlight groups are used for the tags:
"
"   > DiffAdd:    Newly added lines. (default=blue)
"
"   ! DiffChange: Lines which are changed from the original. (default=cyan)
"
"   < DiffDel:    Applied to the lines directly above and below a deleted block
"                 (default=magenta)
" Usage
" -----
"
" The plugin defines one function: Svndiff(). This function figures out the
" difference between the current file and it's subversion original, and adds
" the tags at the places where the buffer differs from the original file from
" subversion. You'll need to call this function after making changes to update
" the highlighting.
"
"
" The function takes an optional argument specifying an additional action to
" perform:
"
"   "prev"  : jump to the previous different block 
"   "next"  : jump to the next different block
"   "clear" : clean up all tags
"
" You might want to map some keys to run the Svndiff function. For
" example, add to your .vimrc:
"
"   noremap <F3> :call Svndiff("prev")<CR> 
"   noremap <F4> :call Svndiff("next")<CR>
"   noremap <F5> :call Svndiff("clear")<CR>
"
" Colors
" ------
"
" Personally, I find the following colours more intuitive for diff colours:
" red=deleted, green=added, yellow=changed. If you want to use these colours,
" try adding the following lines to your .vimrc
"
" hi DiffAdd      ctermfg=0 ctermbg=2 guibg='green'
" hi DiffDelete   ctermfg=0 ctermbg=1 guibg='red'
" hi DiffChange   ctermfg=0 ctermbg=3 guibg='yellow'
"
" Changelog
" ---------
"
" 1.0 2007-04-02	Initial version
"
" 1.1 2007-04-02	Added goto prev/next diffblock commands
"
" 1.2 2007-06-14  Updated diff arguments from -u0 (obsolete) to -U0
"
" 2.0 2007-08-16  Changed from syntax highlighting to using tags, thanks
"                 to Noah Spurrier for the idea. NOTE: the name of the
"                 function changed from Svndiff_show() to Svndiff(), so
"                 you might need to update your .vimrc mappings!
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


function! Svndiff(...)

	let cmd = exists("a:1") ? a:1 : ''
	let fname = bufname("%")
	let jump_to = 0


	" Check if this file is managed by subversion, exit otherwise
	
	let info = system("svn info " . fname)
	if match(info, "Path") == -1
		echom "Svndiff: Warning, file " . fname . " is not managed by subversion, or error running svn."
		return
	end


	" Remove all signs. If the cmd is 'clear', return right away. NOTE: this
	" command removes all signs from the file, also if they were not placed by
	" the this plugin. If this bothers your, tell me and I'll fix it.

	sign unplace *

	if cmd == 'clear'
		return
	endif


	" Define sign characters and colors
	
	sign define svnadd    text=>  texthl=diffAdd
	sign define svndelete text=<  texthl=diffDelete
	sign define svnchange text=!  texthl=diffChange


	" This is where the magic happens: pipe the current buffer contents to a
	" shell command calculating the diff in a friendly parsable format.

	let contents = join(getbufline("%", 1, "$"), "\n")
	let diff = system("diff -U0 <(svn cat " . fname . ") <(cat;echo)", contents)


	" Parse the output of the diff command and put signs at changed, added and
	" removed lines

	for line in split(diff, '\n')
		
    let part = matchlist(line, '@@ -\([0-9]*\),*\([0-9]*\) +\([0-9]*\),*\([0-9]*\) @@')

		if ! empty(part)
			let old_from  = part[1]
			let old_count = part[2] == '' ? 1 : part[2]
			let new_from  = part[3]
			let new_count = part[4] == '' ? 1 : part[4]

			" Figure out if text was added, removed or changed.
			
			if old_count == 0
				let from  = new_from
				let to    = new_from + new_count - 1
				let name  = 'svnadd'
			elseif new_count == 0
				let from  = new_from
				let to    = new_from + 1
				let name  = 'svndelete'
			else
				let from  = new_from
				let to    = new_from + new_count - 1
				let name  = 'svnchange'
			endif


			" Add signs to mark the changed lines 
			
			let line = from
			while line <= to
				exec 'sign place ' . from . ' line=' . line . ' name=' . name . ' file=' . fname
				let line = line + 1
			endwhile


			" Check if we need to jump to prev/next diff block

			if cmd == 'prev'
				if from < line(".")
					let jump_to = from 
				endif
			endif

			if cmd == 'next' 
				if from > line(".") 
					if jump_to == 0 
						let jump_to = from 
					endif
				endif
			endif

		endif

	endfor


	" Set the cursor to the new position, if requested

	if jump_to > 0
		call setpos(".", [ 0, jump_to, 1, 0 ])
	endif

endfunction


" vi: ts=2 sw=2

