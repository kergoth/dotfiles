function! GetHighlightLine(group)
  " Redirect the output of the "hi" command into a variable
  " and find the highlighting
  redir => GroupDetails
  exe 'silent hi ' . a:group
  redir END

  " Resolve linked groups to find the root highlighting scheme
  while GroupDetails =~# 'links to'
    let index = stridx(GroupDetails, 'links to') + len('links to')
    let LinkedGroup =  strpart(GroupDetails, index + 1)
    redir => GroupDetails
    exe 'silent hi ' . LinkedGroup
    redir END
  endwhile

  " Extract the highlighting details (the bit after "xxx")
  let MatchGroups = matchlist(GroupDetails, '\<xxx\>\s\+\(.*\)')
  let ExistingHighlight = MatchGroups[1]
  return ExistingHighlight
endfunction

function! GetHighlightInfo(group) abort
  let ExistingHighlight = GetHighlightLine(a:group)
  redir => output
  exe 'silent hi ' . a:group
  redir END
  let list = split(output, '\s\+')
  let dict = {}
  for item in list
    if match(item, '=') > 0
      let splited = split(item, '=')
      let dict[splited[0]] = splited[1]
    endif
  endfor
  return dict
endfunction

function! ToHighlight(hidict) abort
  let entries = []
  for item in items(a:hidict)
    let entries += [join(item, '=')]
  endfor
  return join(entries)
endfunction

function! CopyItems(from, to, ...) abort
  for term in a:000
    if has_key(a:from, term)
      let a:to[term] = a:from[term]
    endif
  endfor
endfunction

function! NewStatuslineGroup() abort
  let new_highlight_group = {}
  call CopyItems(s:statusline, new_highlight_group, 'ctermbg', 'guibg')
  return new_highlight_group
endfunction

function! SetStatuslineColors() abort
  let s:statusline = GetHighlightInfo('StatusLine')

  " Use Comment and Number fg as bg, with legible text
  exe 'hi User1 ' . GetHighlightLine('Comment') . ' gui=reverse cterm=reverse guibg=white ctermbg=white'
  exe 'hi User2 ' . GetHighlightLine('Number') . ' gui=reverse cterm=reverse guibg=black ctermbg=black'

  " Use Identifier's fg on Statusline's bg
  let user3 = NewStatuslineGroup()
  let identifier = GetHighlightInfo('Identifier')
  call CopyItems(identifier, user3, 'ctermfg', 'guifg')
  exe 'hi User3 ' . ToHighlight(user3)
endfunction

function! Statusline_Filename_Modified()
  " Avoid the component separator between filename and modified indicator
  let filename = expand('%')
  if filename ==# ''
    return '[No Name]'
  elseif &filetype ==# 'help'
    return fnamemodify(filename, ':t')
  endif

  try
    let filename = pathshorten(fnamemodify(filename, ':~:.'))
  catch
    let filename = fnamemodify(filename, ':t')
  endtry
  let modified = &modified ? '+' : ''
  return filename . modified
endfunction

function! Statusline_Readonly()
  return &readonly && &filetype !=# 'help' ? 'RO' : ''
endfunction


set statusline=
set statusline+=%2*%(\ %{&paste?'PASTE':''}\ %)%*
set statusline+=%3*
set statusline+=%(\ %{Statusline_Filename_Modified()}\ %)        " filename
set statusline+=%*
set statusline+=%(%{Statusline_Readonly()}\ %)                   " read only flag

set statusline+=%=                                               " left/right separator

set statusline+=%(%{&ft}\ %)                                        " file type
set statusline+=%*%1*                                               " highlight with User1
set statusline+=%6(\ %p%%\ %)                                       " file position
set statusline+=%#warningmsg#                                       " highlight with WarningMsg
set statusline+=%(\ %{exists('#Statusline_Gutentags')?Statusline_Gutentags():''}\ %)                 " gutentags status
set statusline+=%(\ %{&fileformat!=#'unix'?&fileformat:''}\ %)        " file format
set statusline+=%(\ %{&fileencoding!=#'utf-8'?&fileencoding:''}\ %)   " file encoding

let g:statusline_quickfix = "%t%{exists('w:quickfix_title')?' '.w:quickfix_title:''}"

augroup vimrc_statusline
  au!
  " Remove the position info from the quickfix statusline
  au BufWinEnter quickfix if exists('g:statusline_quickfix') | let &l:statusline = g:statusline_quickfix | endif
  " Set User colors based on the color scheme
  au ColorScheme call SetStatuslineColors()
augroup END

call SetStatuslineColors()
