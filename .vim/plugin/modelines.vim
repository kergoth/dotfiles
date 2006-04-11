"-------------------------------------------------------------------------------

"------------------------------------------------------------------------------
"
" Remove traces
" 
:function! <SID>Modelines_Insert ()

    :let l:l = line (".") 
    :call append (l:l + 0, "vim: textwidth="   . &textwidth            .
                             \ (&wrap ? " " : " no") . "wrap"          .
                             \ " tabstop="     . &tabstop              .
                             \ " shiftwidth="  . &shiftwidth           .
                             \ " softtabstop=" . &softtabstop          .
                             \ (&expandtab ? " " : " no") . "expandtab")
    :call append (l:l + 1, "vim: filetype="    . &filetype   . 
                             \ " encoding="    . &encoding   .
                             \ " fileformat="  . &fileformat )
    normal j\ccj\cc
:endfunction


"vim: textwidth=0 tabstop=8 shiftwidth=4 softtabstop=4 expandtab
"vim: filetype=vim encoding=latin1 fileformat=unix softtabstop=4

:command! ModelinesInsert           call <SID>Modelines_Insert ()

:nnoremap <silent> <Leader>im :ModelinesInsert<CR>

:47menu <silent> Plugin.Insert.Modelines<Tab>\\im  :ModelinesInsert<CR>


"-------------------------------------------------------------------------------
" vim: textwidth=0 nowrap tabstop=8 shiftwidth=4 softtabstop=4 expandtab
" vim: filetype=vim encoding=latin1 fileformat=unix

