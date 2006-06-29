" FileType specific spellfile

if exists('g:loaded_ftspell') || ! has('autocmd') || v:version < 700
  if &verbose
    echo 'Not loading ftspell.'
  endif
  finish
endif
let g:loaded_ftspell = 1
let s:keepcpo = &cpo
set cpo&vim


function! <SID>AddFileTypeSpellFile()
    if !has("spell")
        return
    endif
    let amatch = expand('<amatch>')
    if &spellfile !~ '\<' . amatch . '\>'
        if &spellfile
            let l:spell=amatch . '.' . &enc . '.add,' . &spellfile
        else
            let l:spell=amatch . '.' . &enc . '.add'
        endif

        let path = finddir('spell', &rtp)
        if path != ''
            let path = fnamemodify(path, ':h')
            exe 'setl spellfile+=' . path . '/spell/' . l:spell
        endif
    endif
endfunction

autocmd FileType * call <SID>AddFileTypeSpellFile()


let &cpo= s:keepcpo

" vim: set fenc=utf-8 sts=2 sw=2 et:
