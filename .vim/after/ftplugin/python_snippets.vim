if !exists('loaded_snippet') || &cp
    finish
endif

function! PyInit(text)
    if a:text != "args"
        return ', '.a:text
    else
        return ''
    endif
endfunction

function! PyRemDefVal(text)
    return substitute(a:text,'=.*','','g')
endfunction

function! PyInitVars(text)
    if a:text != "args"
        let text = substitute(a:text,'=.\{-},','','g')
        let text = substitute(text,'=.\{-}$','','g')
        let text = substitute(text,',','','g')
        let ret = ''
        let tabs = indent(".")/&tabstop
        let tab_text = ''
        for i in range(tabs)
            let tab_text = tab_text.'\t'
        endfor
        for Arg in split(text, ' ')
            let ret = ret.'self.'.Arg.' = '.Arg.'\n'.tab_text
        endfor
        return ret
    else
        return "pass"
    endif
endfunction

function! Count(haystack, needle)
    let counter = 0
    let index = match(a:haystack, a:needle)
    while index > -1
        let counter = counter + 1
        let index = match(a:haystack, a:needle, index+1)
    endwhile
    return counter
endfunction

function! PyArgList(count)
    " This needs to be Python specific as print expects a
    " tuple and an empty tuple looks like this (,) so we'll need to make a
    " special case for it
    let st = g:snip_start_tag
    let et = g:snip_end_tag

    if a:count == 0
        return "()"
    else
        return '('.repeat(st.et.', ', a:count).')'
    endif
endfunction

let st = g:snip_start_tag
let et = g:snip_end_tag
let cd = g:snip_elem_delim

" Note to users: The following method of defininf snippets is to allow for
" changes to the default tags.
" Feel free to define your own as so:
"    Snippet mysnip This is the expansion text.<{}>
" There is no need to use exec if you are happy to hardcode your own start and
" end tags

exec "Snippet pf print \"".st."s".et."\" % ".st."s:PyArgList(Count(@z, '%[^%]'))".et."<CR>".st.et
exec "Snippet get def get".st."name".et."(self): return self._".st."name".et."<CR>".st.et
exec "Snippet classi class ".st."ClassName".et." (".st."object".et."):<CR><CR><Tab>def __init__(self".st."args:PyInit(@z)".et."):<CR>".st."args:PyInitVars(@z)".et."<CR><CR>".st.et
exec "Snippet set def set".st."name".et."(self, ".st."newValue".et."):<CR>self._".st."name".et." = ".st."newValue:PyRemDefVal(@z)".et."<CR>".st.et
exec "Snippet . self.".st.et
exec "Snippet def def ".st."fname".et."(".st."self".et."):<CR><Tab>".st."pass".et."<CR>".st.et
" Contributed by Panos
exec "Snippet ifn if __name__ == '__main__':<CR><Tab>".st.et
" Contributed by Kib2
exec "Snippet bc \"\"\"".st."description".et."\"\"\"<CR>".st.et
exec "Snippet lc # ".st."linecomment".et."<CR>".st.et
exec "Snippet sbl1 #!/usr/bin/env python<CR># -*- coding: Latin-1 -*-<CR>".st.et
exec "Snippet kfor for ".st."variable".et." in ".st."ensemble".et.":<CR><Tab>".st."pass".et."<CR>".st.et
exec "Snippet cm ".st."class".et." = classmethod(".st."class".et.")<CR>".st.et
