" Courtesy http://vim.sourceforge.net/tips/tip.php?tip_id=1161
" Just like windo but restores the current window when it's done
function! tip1161#WinDo(command)
  let currwin = winnr()
  execute 'windo ' . a:command
  execute currwin . 'wincmd w'
endfunction

" Just like bufdo but restores the current buffer when it's done
function! tip1161#BufDo(command)
  let currBuff = bufnr('%')
  execute 'bufdo ' . a:command
  execute 'buffer ' . currBuff
endfunction
