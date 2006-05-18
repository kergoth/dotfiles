" Based on ctab.vim, the majority of this is under the copyright of the
" original author.  Modified here to fix a couple bugs I noticed in the
" behavior. --Kergoth

if exists("g:loaded_tabspace") || &cp
  finish
endif
let g:loaded_tabspace = 1

if !exists('g:tabspace_nomap')
    let g:tabspace_nomap = 0
endif
if !exists('g:tabspace_nofdlmagic')
    let g:tabspace_nofdlmagic = 0
endif

fun! <SID>InsertSmartTab()
  if (&fdm == 'syntax') &&
     \ g:tabspace_nofdlmagic == 0
      let l:level = foldlevel(line('.'))
      let l:ind = 0
      if &smarttab == 1
          let l:ind = &sw
      else
          let l:ind = &sts != 0 ? &sts : &ts
      endif

      let l:column = virtcol('.')
      if l:column >= l:level * l:ind
          " If we're past the expected indentation level, fall through to the
          " code that uses spaces only.
      else
          return "\<Tab>"
      endif
  else
      if strpart(getline('.'),0,col('.')-1) =~'^\s*$' | return "\<Tab>" | endif
  endif

  let sts=exists("b:insidetabs")?(b:insidetabs):((&sts==0)?&ts:&sts)
  let sp=(virtcol('.') % sts)
  if sp==0 | let sp=sts | endif
  return strpart("                  ",0,1+sts-sp)
endfun

fun! <SID>DoSmartDelete()
  if &sts != 0 | return '' | endif
  let uptohere=strpart(getline('.'),0,col('.')-1)
  " If at the first part of the line, fall back on defaults... or if the
  " preceding character is a <TAB>, then similarly fall back on defaults.
  "
  let lastchar=matchstr(uptohere,'.$')
  if lastchar == "\<tab>" || uptohere =~ '^\s*$' | return '' | endif        " Simple cases
  if lastchar != ' ' | return ((&digraph)?("\<BS>".lastchar): '')  | endif  " Delete non space at end / Maintain digraphs

  let sts=(exists("b:insidetabs")?(b:insidetabs):((&sts==0)?(&ts):(&sts)))

  let ovc=virtcol('.')-1              " Find where we are
  let sp=(ovc % sts)                " How many virtual characters to delete
  if sp==0 | let sp=sts | endif     " At least delete a whole tabstop
  let vc=ovc-sp                     " Work out the new virtual column
  " Find how many characters we need to delete (using \%v to do virtual column
  " matching, and making sure we don't pass an invalid value to vc)
  let uthlen=strlen(uptohere)
  let bs= uthlen-((vc<1)?0:(  match(uptohere,'\%'.(vc).'v')))
  let uthlen=uthlen-bs
  " echomsg 'ovc = '.ovc.' sp = '.sp.' vc = '.vc.' bs = '.bs.' uthlen='.uthlen
  if bs <= 0 | return  '' | endif
  " Delete the specifed number of whitespace characters up to the first non-whitespace
  let ret=''
  let bs=bs-1
  if uptohere[uthlen+bs] !~ '\s'| return '' | endif
  while bs>1
    let bs=bs-1
    if uptohere[uthlen+bs] !~ '\s' | break | endif
    let ret=ret."\<BS>"
  endwhile
  return ret
endfun

if g:tabspace_nomap == 0
    imap <silent> <tab> <c-r>=<SID>InsertSmartTab()<cr>
    inoremap <silent> <BS> <c-r>=<SID>DoSmartDelete()<cr><BS>
endif
