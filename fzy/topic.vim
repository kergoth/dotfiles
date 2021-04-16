" if executable('fzy')
"   function! s:completed(winid, filename, action, ...) abort
"     bdelete!
"     call win_gotoid(a:winid)
"     if filereadable(a:filename)
"       let lines = readfile(a:filename)
"       if !empty(lines)
"         let result = substitute(lines[0], "\e\[[[:digit:];]*m", "", "g")
"         exe a:action . ' ' . result
"       endif
"       call delete(a:filename)
"     endif
"   endfunction

"   " TODO: pass in the prompt or initial query
"   function! FzyCommand(choice_command, vim_command)
"     let file = tempname()
"     let winid = win_getid()
"     let cmd = split(&shell) + split(&shellcmdflag) + [a:choice_command . ' | fzy > ' . file]

"     let F = function('s:completed', [winid, file, a:vim_command])
"     botright 10 new
"     if has('nvim')
"       call termopen(cmd, {'on_exit': F})
"     else
"       call term_start(cmd, {'exit_cb': F, 'curwin': 1})
"     endif
"     startinsert
"   endfunction

"   nnoremap <silent> <C-p> :call FzyCommand("fd -c always -t f ''", ":e")<cr>
" endif

" nnoremap <C-p> :call FzyCommand("rg . --silent -l -g ''", ":e")<cr>
"" nnoremap <leader>e :call FzyCommand("find . -type f", ":e")<cr>
"" nnoremap <leader>v :call FzyCommand("find . -type f", ":vs")<cr>
""nnoremap <silent> <C-S-\> :TmuxNavigatePrevious<cr>
"nnoremap <leader>e :call FzyCommand("ag . --silent -l -g ''", ":e")<cr>
"nnoremap <leader>v :call FzyCommand("ag . --silent -l -g ''", ":vs")<cr>
"nnoremap <leader>s :call FzyCommand("ag . --silent -l -g ''", ":sp")<cr>
"nnoremap <leader>s :call FzyCommand("find . -type f", ":sp")<cr>
"if executable('rg')
"  set grepprg=rg\ --smart-case\ --vimgrep\ $*
"  command! -bang -nargs=* Search
"    \ call FzyCommand('rg --vimgrep --smart-case --color=always ' . shellescape(<q-args>), ':e')
"elseif executable('ag')
"  set grepprg=ag\ -H\ --nocolor\ --nogroup\ --column\ $*
"  command! -bang -nargs=* Search call FzyCommand('ag -H --nocolor --nogroup --column ' . shellescape(<q-args>), ':e')
"elseif executable('ack')
"  set grepprg=ack\ -H\ --nocolor\ --nogroup\ --column\ $*
"  command! -bang -nargs=* Search
"    \ call FzyCommand('ack -H --nocolor --nogroup --column ' . shellescape(<q-args>), ':e')
"endif
