" Description: Keep modified[+] flag after writing to a file
" URL: http://vim.sourceforge.net/tips/tip.php?tip_id=812
" Maintainer: hari_vim@yahoo.com

if exists("loaded_bettermodified") || &cp
  finish
endif

function! SetBufWriteAuEnabled(enabled)
  aug BufWrite
  au!
  if a:enabled
    au BufWriteCmd * :call BufWrite()
  endif
  aug END
endfunction
call SetBufWriteAuEnabled(1)

function! BufWrite()
  let fileName = expand('<afile>')
  " If the filename already matches netrw's criteria, then don't do anything.
  if fileName =~ 'ftp://\|rcp://\|scp://\|dav://\|rync://\|sftp://'
    return
  endif
  let _modified = &modified
  exec 'w'.(v:cmdbang?'!':'') v:cmdarg fileName
  " This autocommand gets triggered by Vim even if the writing is happening to
  " the same file, so we don't want to modify the behavior of bare :w or :wq
  " commands.
  if expand('%') !=# fileName
    " This *is* the actual work around. Restore the 'modified' flag.
    let &modified = _modified
  endif
endfunction

let loaded_bettermodified = 1

"vim: set fenc=utf-8 sts=2 sw=2 et:
