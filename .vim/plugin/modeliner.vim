" Modeliner
"
" Version: 0.2.0
" Description:
"
"   Generates a modeline from current settings. 
"
" Last Change: 04-Oct-2007.
" Maintainer: Shuhei Kubota <chimachima@gmail.com>
"
" Usage:
"   execute ':Modeliner'.
"   Then a modeline is generated.
"
"   The modeline will either be appended next to the current line or replace
"   the existing one.
"
"   If you want to customize option, modify g:Modeliner_format.

if !exists('g:Modeliner_format')
    let g:Modeliner_format = 'fenc= ts= sts= sw= et'
    " /[ ,:]/ delimited.
    "
    " if the type of a option is NOT 'boolean' (see :help 'option-name'),
    " append '=' to the end of each option.
endif

command! Modeliner  call <SID>Modeliner_exec()

function! s:Modeliner_exec()
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

    let content = substitute(&commentstring, '%s', ' ' . content . ' : ', '')

    "search a modeline
    let modelineNumber = s:GetExistingModeLineNumber()

    if modelineNumber != 0
        "modeline FOUND -> replace the modeline

        "show the existing modeline
        let orgLine = line('.')
        let orgCol  = col('.')
        call cursor(modelineNumber, 1)
        normal V
        redraw

        "confirm
        "if confirm('Are you sure to overwrite this existing modeline?', "&Yes\n&No", 1) == 1
        echo 'Are you sure to overwrite this existing modeline? [Y/n]'
        if char2nr(tolower(nr2char(getchar()))) == char2nr('y')
            call setline(modelineNumber, content)

            "show the modeline being changed
            if (modelineNumber != line('.')) && (modelineNumber != line('.') + 1)
                redraw
                sleep 1
            endif
        endif

        "back to the previous position
        echo
        execute "normal \<ESC>"
        call cursor(orgLine, orgCol)
    else
        "modeline NOT found -> append new modeline
        call append('.', content)
    endif
endfunction

function! s:GetExistingModeLineNumber()
    let pattern = '\svi:\|vim:\|ex:'

    "cursor position
    if match(getline('.'), pattern) != -1
        return line('.')
    endif

    "cursor position (user may position the cursor to previous line...)
    if match(getline(line('.') + 1), pattern) != -1
        return line('.') + 1
    endif

    "header
    let lineNumber = 1
    let cnt = 0
    while cnt < &modelines
        if match(getline(lineNumber), pattern) != -1
            return lineNumber
        endif
        let lineNumber = lineNumber + 1
        let cnt = cnt + 1
    endwhile

    "footer
    let lineNumber = line('$')
    let cnt = 0
    while cnt < &modelines
        if match(getline(lineNumber), pattern) != -1
            return lineNumber
        endif
        let lineNumber = lineNumber - 1
        let cnt = cnt + 1
    endwhile

    return 0
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

" vim: set fenc= ts=4 sts=4 sw=4 et : 
