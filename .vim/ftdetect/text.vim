" Set a default filetype
au BufReadPost,BufNewFile,VimEnter * if &ft == '' | setfiletype text | endif
