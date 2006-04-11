" Modeliner
"
" Version: 0.1.0
" Description:
"
"   Generates modeline from current settings. 
"
" Last Change: 23-Feb-2006.
" Maintainer: Shuhei Kubota <chimachima@gmail.com>
"
" Usage:
"   execute ':Modeliner'.
"   Then a modeline is appended next to the current line.
"
"   If you want to customize, modify g:Modeliner_format.

if !exists('g:Modeliner_format')
    let g:Modeliner_format = 'fenc= ts= sts= sw= et'
    " /[ ,:]/ delimited.
    "
    " if the type of a option is NOT 'boolean' (see :help 'option-name'),
    " append '=' to the end of the option.
endif

command! Modeliner  call <SID>Modeliner_Append()
command! ModelinerBefore  call <SID>Modeliner_Prepend()

function! s:Modeliner_Append()
    let _col = virtcol('.')
    let _line = line('.')
    call append(_line, s:GetContent())
    call cursor(_line, _col)
endfunction

function! s:Modeliner_Prepend()
    let _col = virtcol('.')
    let _line = line('.')
    call append(_line - 1, s:GetContent())
    call cursor(_line, _col)
endfunction

function! s:GetContent()
    let content = 'vim: set'
    let format  = g:Modeliner_format

    call s:StartParsing()
    let option = s:GetOption()
    while strlen(option)
        if stridx(option, '=') != -1
            " let  optionExpr = 'ts=' . &ts
            execute 'let optionExpr = "' . option . '" . &' . strpart(option, 0, strlen(option) - 1)
        else
            " let optionExpr = (&et ? '' : 'no') . 'et'
            execute 'let optionExpr = (&' . option . '? "" : "no") . "' . option . '"'
        endif

        let content = content . ' ' . optionExpr

        let option  = s:GetOption()
    endwhile

    let content = substitute(&commentstring, '%s', content . ':', '')
    return content
endfunction

function! s:StartParsing()
    let s:Modeliner__format = g:Modeliner_format
endfunction

function! s:GetOption()
    let format = s:Modeliner__format
    let optStart = match(format, '[^ ,:]')
    let optEnd   = match(format, '[ ,:]', optStart)
    if optEnd == -1
        let optEnd = strlen(format)
    endif

    let option = strpart(format, optStart, (optEnd - optStart))
    let s:Modeliner__format = strpart(format, optEnd + 1)

    return option
endfunction

"vim:set fenc= ts=4 sts=4 sw=4 et:
