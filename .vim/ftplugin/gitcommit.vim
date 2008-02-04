if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

setlocal nowarn nowb

"{{{ function Git_diff_windows

function! Git_diff_windows(vertsplit, auto)
    let i = 0
    let list_of_files = ''

    " drop everything until '#  (will commit)' and the next empty line
    while i <= line('$')
        let line = getline(i)
        if line == '# Changes to be committed:'
            let i = i + 3
            break
        endif

        let i = i + 1
    endwhile

    " read file names until we have EOF or an empty line
    while i <= line('$')
        let line = getline(i)
        if line =~ '^#\s*[a-z ]*:.*->.*$'
            let file = substitute(line, '^#[^:]*:.*->\s*\(.*\)\s*$', '\1', '')
            let list_of_files = list_of_files . ' '.file
            let file = substitute(line, '^#[^:]*:\s*\(.*\)\s*->.*$', '\1', '')
            let list_of_files = list_of_files . ' '.file
        elseif line =~ '^#\s*[a-z ]*:'
            let file = substitute(line, '^#[^:]*:\s*\(.*\)\s*$', '\1', '')
            let list_of_files = list_of_files . ' '.file
        elseif line =~ '^#\s*$'
            break
        endif

        let i = i + 1
    endwhile

    if list_of_files == ""
        return
    endif

    if a:vertsplit
        rightbelow vnew
    else
        rightbelow new
    endif
    silent! setlocal ft=diff previewwindow bufhidden=delete nobackup noswf nobuflisted nowrap buftype=nofile
    let gitDir = system('git rev-parse --git-dir 2>/dev/null')
    let gitDir = substitute(gitDir, '.git\n', '', '')
    let wd = getcwd()
    if gitDir != ''
        exe 'cd '.gitDir
    endif
    exe 'normal :r!LANG=C git diff HEAD -- ' . list_of_files . "\n1Gdd"
    exe 'normal :r!LANG=C git diff --stat HEAD -- ' . list_of_files . "\no\<esc>1GddO\<esc>"
    exe 'cd '.wd
    setlocal nomodifiable
    noremap <buffer> q :bw<cr>
    if a:auto
        redraw!
        wincmd p
        redraw!
    endif
endfunction

"}}}

noremap <buffer> <Leader>gd :call Git_diff_windows(0, 0)<cr>
noremap <buffer> <Leader>ghd :call Git_diff_windows(0, 0)<cr>
noremap <buffer> <Leader>gvd :call Git_diff_windows(1, 0)<cr>

if g:git_diff_spawn_mode == 1
    call Git_diff_windows(0, 1)
elseif g:git_diff_spawn_mode == 2
    call Git_diff_windows(1, 1)
endif
