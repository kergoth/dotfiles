" Modeliner
"
" Version: 0.3.0
" Description:
"
"   Generates a modeline from current settings. 
"
" Last Change: 27-Jun-2008.
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
    let g:Modeliner_format = 'et ff= fenc= sts= sw= ts='
    " /[ ,:]/ delimited.
    "
    " if the type of a option is NOT 'boolean' (see :help 'option-name'),
    " append '=' to the end of each option.
endif


"[text] vi: tw=80 noai
"[text]	vim:tw=80 noai
" ex:tw=80 : noai:
"
"[text] vim: set tw=80 noai:[text]
"[text] vim: se tw=80 noai:[text]
"[text] vim:set tw=80 noai:[text]
" vim: set tw=80 noai: [text]
" vim:se tw=80 noai:


command! Modeliner  call <SID>Modeliner_execute()


" to retrieve the position
let s:Modeline_SEARCH_PATTERN = '\svi:\|vim:\|ex:'
" to extract options from existing modeline
let s:Modeline_EXTRACT_PATTERN = '\v(.*)\s+(vi|vim|ex):\s*(set?\s+)?(.+)' " very magic
" first form
"let s:Modeline_EXTRACT_OPTPATTERN1 = '\v(.+)' " very magic
" second form
let s:Modeline_EXTRACT_OPTPATTERN2 = '\v(.+):(.*)' " very magic


function! s:Modeliner_execute()
    let options = []

    " find existing modeline, and determine the insert position
    let info = s:SearchExistingModeline()

    " parse g:Modeliner_format and join options with them
    let extractedOptStr = g:Modeliner_format . ' ' . info.optStr
    let extractedOptStr = substitute(extractedOptStr, '[ ,:]\+', ' ', 'g')
    let extractedOptStr = substitute(extractedOptStr, '=\S*', '=', 'g')
    let extractedOptStr = substitute(extractedOptStr, 'no\(.\+\)', '\1', 'g')
    let opts = sort(split(extractedOptStr))
    "echom 'opt(list): ' . join(opts, ', ')

    let optStr = ''
    let prevO = ''
    for o in opts
        if o == prevO | continue | endif
        let prevO = o

        if stridx(o, '=') != -1
            " let optExpr = 'ts=' . &ts
            execute 'let optExpr = "' . o . '" . &' . strpart(o, 0, strlen(o) - 1)
        else
            " let optExpr = (&et ? '' : 'no') . 'et'
            execute 'let optExpr = (&' . o . '? "" : "no") . "' . o . '"'
        endif

        let optStr = optStr . ' ' . optExpr
    endfor

    if info.lineNum == 0
        let modeline = s:Commentify(optStr)
    else
        let modeline = info.firstText . ' vim: set' . optStr . ' :' . info.lastText
    endif


    " insert new modeline 
    if info.lineNum != 0
        "modeline FOUND -> replace the modeline

        "show the existing modeline
        let orgLine = line('.')
        let orgCol  = col('.')
        call cursor(info.lineNum, 1)
        normal V
        redraw

        "confirm
        "if confirm('Are you sure to overwrite this existing modeline?', "&Yes\n&No", 1) == 1
        echo 'Are you sure to overwrite this existing modeline? [y/N]'
        if char2nr(tolower(nr2char(getchar()))) == char2nr('y')
            call setline(info.lineNum, modeline)

            "show the modeline being changed
            if (info.lineNum != line('.')) && (info.lineNum != line('.') + 1)
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
        call append('.', modeline)
    endif

endfunction


function! s:Commentify(s)
    if exists('g:NERDMapleader') " NERDCommenter
        let result = b:left . ' vim: set' . a:s . ' : ' . b:right
    else
        let result = substitute(&commentstring, '%s', ' vim: set' . a:s . ' : ', '')
    endif

    return result
endfunction


function! s:SearchExistingModeline()
    let info = {'lineNum':0, 'text':'', 'firstText':'', 'lastText':'', 'optStr':''}

    let candidates = []

    " cursor position?
    call add(candidates, line('.'))
    " user may position the cursor to previous line...
    call add(candidates, line('.') + 1)
    let cnt = 0
    while cnt < &modelines
    " header?
        call add(candidates, cnt + 1)
    " footer?
        call add(candidates, line('$') - cnt)
        let cnt = cnt + 1
    endwhile

    " search
    for i in candidates
        let lineNum = i
        let text = getline(lineNum)

        if match(text, s:Modeline_SEARCH_PATTERN) != -1
            let info.lineNum = lineNum
            let info.text = text
            break
        endif
    endfor

    " extract texts
    if info.lineNum != 0
        "echom 'modeline: ' info.lineNum . ' ' . info.text

        let info.firstText = substitute(info.text, s:Modeline_EXTRACT_PATTERN, '\1', '')

        let isSecondForm = (strlen(substitute(info.text, s:Modeline_EXTRACT_PATTERN, '\3', '')) != 0)
        "echom 'form : ' . string(isSecondForm + 1)
        if isSecondForm == 0
            let info.lastText = ''
            let info.optStr = substitute(info.text, s:Modeline_EXTRACT_PATTERN, '\4', '')
        else
            let info.lastText = substitute(
                            \ substitute(info.text, s:Modeline_EXTRACT_PATTERN, '\4', ''),
                            \ s:Modeline_EXTRACT_OPTPATTERN2,
                            \ '\2',
                            \ '')
            let info.optStr = substitute(
                                \ substitute(info.text, s:Modeline_EXTRACT_PATTERN, '\4', ''),
                                \ s:Modeline_EXTRACT_OPTPATTERN2,
                                \ '\1',
                                \ '')
        endif
    endif

    "echom 'firstText: ' . info.firstText
    "echom 'lastText: ' . info.lastText
    "echom 'optStr: ' . info.optStr

    return info
endfunction


function! s:ExtractOptionStringFromModeline(text)
    let info = {}

    let info.firstText = substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\1', '')

    let isSecondForm = (strlen(substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\3', '') != 0)
    if isSecondForm == 0
        let info.lastText = ''
        let info.optStr = substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\2', '')
    else
        let info.lastText = substitute(
                        \ substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\4', ''),
                        \ s:Modeline_EXTRACT_OPTPATTERN2,
                        \ '\2',
                        \ '')
        let info.optStr = substitute(
                            \ substitute(a:text, s:Modeline_EXTRACT_PATTERN, '\4', ''),
                            \ s:Modeline_EXTRACT_OPTPATTERN2,
                            \ '\1',
                            \ '')
    endif

    return info
endfunction

" vim: set et fenc=utf-8 ff=unix sts=4 sw=4 ts=4 : 
