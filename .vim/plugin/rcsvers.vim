"------------------------------------------------------------------------------
" Name Of File: rcsvers.vim
"
"  Description: Vim plugin to automatically save backup versions in RCS
"               whenever a file is saved.
"
"       Author: Roger Pilkey (rpilkey at gmail.com)
"   Maintainer: Juan Frias (whiteravenwolf at gmail.com)
"
"  Last Change: $Date: 2005/12/24 21:04:02 $
"      Version: $Revision: 1.25 $
"
"    Copyright: Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this header
"               is included with it.
"
"               This script is to be distributed freely in the hope that it
"               will be useful, but is provided 'as is' and without warranties
"               as to performance of merchantability or any other warranties
"               whether expressed or implied. Because of the various hardware
"               and software environments into which this script may be put,
"               no warranty of fitness for a particular purpose is offered.
"
"               GOOD DATA PROCESSING PROCEDURE DICTATES THAT ANY SCRIPT BE
"               THOROUGHLY TESTED WITH NON-CRITICAL DATA BEFORE RELYING ON IT.
"
"               THE USER MUST ASSUME THE ENTIRE RISK OF USING THE SCRIPT.
"
"               The author and maintainer do not retain any liability on any
"               damage caused through the use of this script.
"
"      Install: 1. Read the section titled 'User Options'
"               2. Setup any variables you need in your vimrc file
"               3. Copy 'rcsvers.vim' to your plugin directory.
"
"  Mapped Keys: <Leader>rlog, or \rlog
"                               To access the saved revisions log.  This works as
"                               toggle to quit the revision windows too.
"
"               <enter>         This will compare the current file to the
"                               revision under the cursor (works only in
"                               the revision log window)
"
"               <Leader>rci, or \rci
"                               This will create an initial RCS file. Only
"                               necessary when you have the script set to
"                               save only when a previous RCS file exists.
"
"               <Leader>older, or \older   
"                               does a diff with the previous version
"
"               <Leader>newer, or \newer
"                               does a diff with the next version
"
" You probably want to map these in your vimrc file to something easier to type,
" like a function key.  Do it like this:
"
"   "re-map rcsvers.vim keys
"   map <F8> \rlog
"   map <F5> \older
"   map <F6> \newer
"
" You may need to set the following shell or environment variables:
"
" User name:
"        LOGNAME=myusername
"
" Time zone:  
"        TZ=EST5EDT
" or (in .vimrc)
" let $TZ = 'EST5EDT'
" 
"
"------------------------------------------------------------------------------
" Please send me any bugs you find, so I can keep the script up to date.
"------------------------------------------------------------------------------
"
"" GetLatestVimScripts: 563 1 rcsvers.vim
" Additional Information: {{{1
"------------------------------------------------------------------------------
" Vim plugin for automatically saving backup versions in rcs whenever a file
" is saved.
"
" What's RCS? It's a set of programs used for version control of files.
" See http://www.gnu.org/software/rcs/rcs.html
"
" The rcs programs are freely available at http://www.cs.purdue.edu/homes/trinkle/RCS/
"
" Be careful if you really use RCS as your production file control, it will
" add versions like crazy. See options below for work arounds.
"
" rcs-menu.vim by Jeff Lanzarotta is handy to have along with this
" (vimscript #41).
"
" History: {{{1
"------------------------------------------------------------------------------
" 1.25  Fix for Windows if you don't have the TZ variable set, and fix how it
"       works when saving a file to another name.
"
" 1.24  RCS sets the executable bit on the checked-out file to be the same as 
"       the rcs archive file.  So if that property changes after you did your 
"       first checkin, your checked-out file will maintain the original setting.
"       So now we change the executable mode of the rcs archive file to align
"       with the current setting of the checked-out copy.
"       Thanks to Ben Bernard.
"
" 1.23  Added an option to fix the path on Cygwin systems.  
"       See g:rvUseCygPathFiltering  
"       Thanks to Simon Johann-Günter 
"
" 1.22  some re-factoring, and add the option to leave RCS files unlocked when
"       saving, which is handy for multiple users of the same RCS file.
"       See g:rvLeaveRcsUnlocked. (from Roger Pilkey)
"
" 1.21  Remember the last position in the rlog window. Rename
"       RevisionLog window to avoid collisions. (from Roger Pilkey)
"
" 1.20  Added a mapping to create an initial RCS file. Useful when the script
"       is set to save only when a previous RCS file exists. see
"       rvSaveIfPreviousRCSFileExists (thanks to Steven Michalske for the
"       suggestion) Added <silent> to the default mappings to keep the status
"       bar clean.
"
" 1.19  Added the option to prompt the user for file and check-in message on
"       every save. See rvDescMsgPrompt option for details. Thanks to Kevin
"       Stegemoller for the suggestion. Also \rlog will now display the
"       check-in message in the pick list for easier identification.
"
" 1.18  Added the option to save an RCS version only if the RCS file already
"       exists (No new RCS files will be created). (from Marc Schoechlin)
"       See rvSaveIfPreviousRCSFileExists option.
"
" 1.17  Added the option to save an RCS version only when there is an RCS
"       directory in the files directory. See rvSaveIfRCSExists option.
"       (from Camillo Särs)
"
" 1.16  Save some settings that "set diff" mangles, and different check for
"       &cp
"
" 1.15  Add functions to go back and forth between versions (mapped to \older
"       and \newer). It's kind of jerky, but comes in handy sometimes. Also
"       fixed a few bugs with quotes.
"
" 1.14  Add option to set 'rlog' command-line options.  fix rlog display,
"       which would crash once in a while saying stuff like "10,10d invalid
"       range". When creating a new RCS file on an existing text file, save a
"       version before adding the new revision.
"
" 1.13  A g:rvFileQuote fix, suggested by Wiktor Niesiobedzki.  Add the
"       ability to use the current instance of vim for the diff, which is now
"       the default.  Change the name of the diff temp file to include the
"       version.  Make \rlog a toggle (on/off)
"
" 1.12  Script will not load if the 'cp' flag is set. Added the option to
"       use an exclude expression, and include expression. Fixed yet more bugs
"       thanks to Roger for all the beta testing.
"
" 1.11  Minor bug fix, when using spaces in the description. Also added some
"       error detection code to check and see that RCS and CI where
"       successful. And removed requirements for SED and GREP, script will no
"       longer need these to display the log.
"
" 1.10  Fixed some major bugs with files with long filenames and spaces
"       Win/Dos systems. Added a variable to pass additional options to the
"       initial RCS check in. Fixed some documentation typos.
"
" 1.9   Added even more options, the ability to set your own description and
"       pass additional options to CI command. Dos/Win Temp directory is taken
"       from the $TEMP environment variable, and quote file names when using
"       diff program to prevent errors with long filenames with spaces. Also
"       removed confirm box from script.
"
" 1.8   Fixed minor Prefix bug,
"
" 1.7   Will not alter the $xx$ tags when automatically checking in files.
"       (Thanks to Engelbert Gruber). Added option to save under the current
"       directory with no RCS sub directory. Also added the option to choose
"       your own suffixes.
"
" 1.6   Complete script re-write. added ability to set user options by vimrc
"       and will now allow you to compare to older revision if you have grep
"       and sed installed.
"
" 1.5   add l:skipfilename to allow exclusion of directories from versioning.
"       and FIX for editing in current directory with local RCS directory.
"
" 1.4   FIX editing files not in current directory.
"
" 1.3   option to select the rcs directory,
"       and better comments thanks to Juan Frias
"
" User Options: {{{1
"------------------------------------------------------------------------------
"
" <Leader>rlog i.e. \rlog
"       This is the default key map to display the revision log. Search
"       for 'key' to override this key.
"
" <Leader>rci i.e. \rci
"       This is the default key map to create an initial RCS file. Search
"       for 'key' to override this key.
"
" <Leader>older i.e. \older
"       This is the default key map to display the previous revision. Search
"       for 'key' to override this key.
"
" <Leader>newer i.e. \newer
"       This is the default key map to display the next revision. Search
"       for 'key' to override this key.
"
" g:rvCompareProgram
"       This is the program that will be called to compare two files,
"       the temporary file created by the revision log and the current
"       file. The default program is vimdiff in the current instance of vim.
"       To override use:
"           let g:rvCompareProgram = <your compare program>
"       in your vimrc file. Win32 users you may want to use:
"           let g:rvCompareProgram = start <your program>
"       for an asynchronous run, type :help :!start for details.
"       example:
"           let g:rvCompareProgram = 'start\ C:\\Vim\\vim61\\gvim.exe\ -d\ -R\ --noplugin\ '
"
"       To open the diff within the current instance of vim, use 'This'
"       (default)
"
" g:rvFileQuote
"       This is the character used to enclose filenames when calling the
"       compare program. By default it is '"' (double-quote).
"       To override this use:
"           let g:rvFileQuote = <quote char>
"       in your vimrc file.
"
" g:rvDirSeparator
"       Separator to use between paths, the script will try to auto detect
"       this but to override use:
"           let g:rvDirSeparator = <separator>
"       in your vimrc file.
"
" g:rvTempDir
"       This is the temporary directory to create an old revision file to
"       compare it to the current file. The default is $temp for Dos/win
"       systems and <g:rvDirSeparator>temp for all other systems. The
"       script will automatically append the directory separator to the
"       end, so do not include this. To override defaults use:
"           let g:rvTempDir = <your directory>
"       in your vimrc file.
"
" g:rvSkipVimRcsFileName
"       This is the name of the file the script will look for, if it's found
"       in the directory the file is being edited the RCS file will not
"       be written. By default the name is _novimrcs for Dos/win systems
"       and .novimrcs for all other. To override use:
"           let  g:rvSkipVimRcsFileName = <filename>
"       in your vimrc file.
"
" g:rvSaveDirectoryType
"       This specifies how the script will save the RCS files. By default
"       they will be saved under the current directory (under RCS). To
"       override use:
"           let g:rvSaveDirectoryType = 1
"       in your vimrc file, options are as follows:
"           0 = Save in current directory (under RCS)
"           1 = Single directory for all files
"           2 = Save in current directory (same as the original file)
"
"       Note: If using g:rvSaveDirectoryType = 2 make sure you use
"             a suffix (see g:rvSaveSuffixType) or the script might overwrite
"             your file.
"
" g:rvSaveIfPreviousRCSFileExists
"       This specifies that RCS files will only be saved if the a previous
"       RCS file is present for the file being edited. If the RCS file
"       doesn't exist then the 'backup' will not be created.
"           0 = Create new RCS file when needed
"           1 = Only save RCS files if the RCS file already exists.
"
" g:rvSaveIfRCSExists
"       This specifies that RCS files will only be saved if the RCS directory
"       (in the current directory) already exists.  This prevents new RCS
"       directories from being created.
"           0 = Create new RCS directories when needed
"           1 = Only save RCS files if the RCS directory already exists.
"
"       Note: If using g:rvSaveDirectoryType = 2 or 1, this setting has no
"             effect.
"
" g:rvSaveDirectoryName
"       This specifies the name of the directory where the RCS files will
"       be saved. By default if g:rvSaveDirectoryType = 0 (saving to
"       the current directory) the script will use RCS. If
"       g:rvSaveDirectoryType = 1 (saving all files in a single
"       directory) the script will save them to $VIM/RCSFiles. To override
"       the default name use:
"           let g:rvSaveDirectoryName = <my directory name>
"       in your vimrc file.
"
" g:rvSaveSuffixType
"       This specifies what the script uses as a suffix, when saving the
"       RCS files. The default is ',v' suffix when using rvSaveDirectoryType
"       number 0 (current directory under RCS), and unique suffix when using
"       rvSaveDirectoryType number 1. (single directory for all files). To
"       override the defaults use:
"           let g:rvSaveSuffixType = x
"       where 'x' is one of the following
"           0 = No suffix.
"           1 = Use the standard ',v' suffix
"           2 = Use a unique suffix (take the full path and changes the
"               directory separators to underscores)
"           3 = use a unique suffix with a ',v' appended to the end.
"           4 = User defined suffix.
"       If you select type number 4 the default is ',v'. To override use:
"           let g:rvSaveSuffix = 'xxx'
"       where 'xxx' is your user defined suffix.
"
" g:rvCiOptions
"       This specifies additional options to send to CI (check in program)
"       by default this is blank. Refer to RCS documentation for additional
"       options to pass. To override use:
"           let g:rvCiOptions = <options>
"       in your vimrc file.
"
" g:rvRcsOptions
"       This specifies additional options to send to RCS (program that
"       creates the initial RCS file) by default this is set to '-ko' to
"       prevent $xx$ tags from being altered. Refer to RCS documentation
"       for additional options to pass. To override use:
"           let g:rvRcsOptions = <options>
"       in your vimrc file.
"
" g:rvRlogOptions
"       This specifies additional options to send to rlog (history displaying
"       program). By default this is set to '' to avoid surprising you.
"       Refer to RCS documentation for additional options to pass.
"       To override use:
"           let g:rvRlogOptions = <options>
"       in your vimrc file.
"       e.g.
"           " show the log using the local timezone
"           let g:rvRlogOptions = '-zLT'
"
" g:rvLeaveRcsUnlocked
"       This will leave the RCS file unlocked when saving, so that more than one
"       user can use the same RCS backup file. By default, this is off, because
"       it adds two more system commands on every save, which is slower, and you
"       probably want to protect your backups from modification by other users
"       by default, and you shouldn't be using this script for more than personal
"       backups anyway, kids.  This is useful though, if for example you want
"       to use rcsvers.vim in a global settings file to track file changes.
"       Warning: once you turn this option on and save a file, you will lose
"       your lock on the RCS file.  So if you turn it off later, rcsvers.vim
"       won't be able to save any more versions until you get a lock again.
"       e.g.
"          "unlock RCS backup files when done
"          let g:rvLeaveRcsUnlocked = 1
"
" g:rvShowUser
"       Show the user in the rlog window, handy if more than one user is using
"       the same RCS backup file. off by default
"       e.g.
"          "show user in RCS log window
"          let g:rvShowUser = 1
"
" g:rvDescription
"       This allows you to set your initial description and version
"       message. The default value is 'vim'. To override use:
"           let g:rvDescription = <description>
"       in your vimrc file.
"
" g:rvDescMsgPrompt
"       This determines if you will be prompted for a description or a checkin
"       message when you save the file. Default is no prompt. To have the
"       script prompt, set this to a non-zero value in your vimrc file.
"       e.g.
"           " prompt on every save
"           let g:rvDescMsgPrompt = 1
"
" g:rvExcludeExpression
"       This expression is evaluated with the function 'match'. The script
"       tests the expression against the full file name and path of the file
"       being saved. If the expression is found in the file name then the
"       script will NOT create an RCS file for it. The default is an empty
"       string, in which case no checking is done. To override use:
"           let g:rvExcludeExpression = <your expression>
"       in your vimrc file.
"
"       Example: The expression below will exclude files containing .usr and
"       .tmp in their file names. The '\c' is used to ignore case. Note that
"       this is evaluated against the full file name and path so if you have
"       the file '/home/joe/.tmp/hi.txt' the script will not generate an RCS
"       file since '.tmp' is found in the path.
"
"           let g:rvExcludeExpression = '\c\.usr\|\c\.tmp'
"
"       Type ':help match' for help on how to setup an expression. In this
"       script {exp} will be the file name and path, and {pat} will be the
"       expression you provide.
"
" g:rvIncludeExpression
"       This expression is evaluated with the function 'match'. The script
"       tests the expression against the full file name and path of the file
"       being saved. If the expression is found in the file name, then the
"       script will create an RCS file for it, but if it's not found it will
"       NOT. The default is an empty string, in which case no checking is done
"       and all files will generate an RCS file except if an exclude
"       expression is present, see g:rvExcludeExpression for a sample
"       expression.
"
" g:rvUseCygPathFiltering
"       This switch is used to convert the command to use a cygwin rcs
"       implementation.
"           0 = Call rcs with native vim filename (default)
"           1 = Filter filename through cygpath in order to be able to call
"               cygwin installation of rcs.
"

" Global variables: {{{1
"------------------------------------------------------------------------------

" Load script once
"------------------------------------------------------------------------------
if exists("loaded_rcsvers")
    finish
endif
let loaded_rcsvers = 1

let s:save_cpo = &cpo
set cpo&vim

" Set additional RCS options
"------------------------------------------------------------------------------
if !exists('g:rvRcsOptions')
    let g:rvRcsOptions = "-ko"
endif

" Set additional ci options
"------------------------------------------------------------------------------
if !exists('g:rvCiOptions')
    let g:rvCiOptions = ""
endif

" Set TZ to something if it isn't set. Otherwise the rcs commands error out
" cryptically. This helps in making a plug and play install on Windows
"------------------------------------------------------------------------------
if $TZ == '' && ( has("win32") || has("win16") || has("dos32") )
    " put a copy of this line with your timezone setting into your .vimrc to
    " localize your rlog times
    "let $TZ = 'EST5EDT'
    let $TZ = 'GMT'
endif
"
" Set additional rlog options
"------------------------------------------------------------------------------
if !exists('g:rvRlogOptions')
    let g:rvRlogOptions = ""
endif

" leave RCS file unlocked
"------------------------------------------------------------------------------
if !exists('g:rvLeaveRcsUnlocked')
    let g:rvLeaveRcsUnlocked = 0
endif

" show User in rlog
"------------------------------------------------------------------------------
if !exists('g:rvShowUser')
    let g:rvShowUser = 0
endif

" Set initial description and version message
"------------------------------------------------------------------------------
if !exists('g:rvDescription')
    let g:rvDescription = "vim"
else
    "quote out any quote chars in the description
    let g:rvDescription= substitute(g:rvDescription,'"','\\"',"g")
endif

" Set default for description/message prompt
"------------------------------------------------------------------------------
if !exists('g:rvDescMsgPrompt')
    let g:rvDescMsgPrompt = 0
endif

" Set the compare program
"------------------------------------------------------------------------------
if !exists('g:rvCompareProgram')
    let g:rvCompareProgram = "This"
endif

" Set the directory separator
"------------------------------------------------------------------------------
if !exists('g:rvDirSeparator')
    if has("win32") || has("win16") || has("dos32")
                \ || has("dos16") || has("os2")
        let g:rvDirSeparator = "\\"

    elseif has("mac")
        let g:rvDirSeparator = ":"

    else " *nix systems
        let g:rvDirSeparator = "\/"
    endif
endif

" Set file name quoting
"------------------------------------------------------------------------------
if !exists('g:rvFileQuote')
    let g:rvFileQuote = '"'
endif

" Set the temp directory
"------------------------------------------------------------------------------
if !exists('g:rvTempDir')
    if has("win32") || has("win16") || has("dos32")
                \ || has("dos16") || has("os2")
        let g:rvTempDir = expand("$temp")
    else
        let g:rvTempDir = g:rvDirSeparator."tmp"
    endif
endif

" Set the skip vimrcs file name
"------------------------------------------------------------------------------
if !exists('g:rvSkipVimRcsFileName')
    if has("win32") || has("win16") || has("dos32")
                \ || has("dos16") || has("os2")
        let g:rvSkipVimRcsFileName = "_novimrcs"
    else
        let g:rvSkipVimRcsFileName = ".novimrcs"
    endif
endif

" Set where the files are saved
"------------------------------------------------------------------------------
if !exists('g:rvSaveDirectoryType')
"   0 = Save in current directory (under RCS)
    let g:rvSaveDirectoryType = 0
endif

" Only save if RCS file already exists
" -----------------------------------------------------------------------------
if !exists('g:rvSaveIfPreviousRCSFileExists')
    let g:rvSaveIfPreviousRCSFileExists = 0
endif

" Only save if RCS already exists
" -----------------------------------------------------------------------------
if !exists('g:rvSaveIfRCSExists')
    let g:rvSaveIfRCSExists = 0
endif

" Set the suffix type
"------------------------------------------------------------------------------
if !exists('g:rvSaveSuffixType')
"   0 = Save in current directory (under RCS)
    if g:rvSaveDirectoryType == 0
"       1 = Use the standard ',v' suffix
        let g:rvSaveSuffixType = 1
    else
"           2 = Use a unique suffix (take the full path and changes the
"               directory separators to underscores)
        let g:rvSaveSuffixType = 2
    endif
endif

" Set default user defined suffix
"------------------------------------------------------------------------------
if (g:rvSaveSuffixType == 4) && (!exists('g:rvSaveSuffix'))
    let g:rvSaveSuffix = ",v"
endif

" Set the default Exclude expression
"------------------------------------------------------------------------------
if !exists('g:rvExcludeExpression')
    let g:rvExcludeExpression = ""
endif

" Set the default Include expression
"------------------------------------------------------------------------------
if !exists('g:rvIncludeExpression')
    let g:rvIncludeExpression = ""
endif

" Set the default for cygpath filtering
"------------------------------------------------------------------------------
if !exists('g:rvUseCygPathFiltering')
    let g:rvUseCygPathFiltering = 0
endif

" Hook the RCS function to the Save events {{{1
"------------------------------------------------------------------------------
augroup rcsvers
   au!
   let s:types = "*"
   exe "au BufWritePost,FileWritePost,FileAppendPost ".
               \ s:types." call s:rcsvers(\"post\")"
   exe "au BufWritePre,FileWritePre,FileAppendPre ".
               \ s:types." call s:rcsvers(\"pre\")"
augroup END

augroup rcsvers
   au BufUnload * call s:bufunload()
augroup END

" Function: Autocommand for buffer unload to clean up after ourselves {{{1
"------------------------------------------------------------------------------
function! s:bufunload()
    "turn off the diff settings in the original file when you kill the child
    "buffer
    if exists("s:child_bufnr") && s:child_bufnr ==  expand("<abuf>")
        sil! exec bufwinnr(s:parent_bufnr) . " wincmd w"
        set nodiff

        if s:save_scrollbind == 0
            silent exec ":set noscrollbind"
        else
            silent exec ":set scrollbind"
        endif
        silent exec ":set scrollopt=" . s:save_scrollopt
        if s:save_wrap == 0
            silent exec ":set nowrap"
        else
            silent exec ":set wrap"
        endif
        silent exec ":set foldmethod=" . s:save_foldmethod
        silent exec ":set foldcolumn=" . s:save_foldcolumn
        let @"=s:save_unnamed_reg
        unlet! s:child_bufnr s:parent_bufnr s:revision
    endif
endfunction

" Function: run a system command, print errors {{{1
"------------------------------------------------------------------------------
function! s:RunCmd(cmd)
        let l:output = system(a:cmd)
        if ( v:shell_error != 0 )
            echo "(rcsvers.vim) *** Error executing command."
            echo "Command was:"
            echo "--- begin ---"
            echo a:cmd
            echo "--- end ---"
            echo "Output:"
            echo "--- begin ---"
            echo l:output
            echo "--- end ---"
            return "error"
        endif
        return l:output
endfunction

" Function: save settings that get mangled {{{1
"------------------------------------------------------------------------------
function! s:RcsVersSaveSettings()
    if (!exists("s:child_bufnr"))
        "save some options that "set diff" mucks with
        let s:save_scrollbind=&scrollbind
        let s:save_scrollopt=&scrollopt
        let s:save_wrap=&wrap
        let s:save_foldmethod=&foldmethod
        let s:save_foldcolumn=&foldcolumn

        "save unnamed register from getting clobbered
        let s:save_unnamed_reg=@"
    endif
endfunction

" Function: Set the name of the directory to save RCS files to {{{1
"------------------------------------------------------------------------------
function! s:GetSaveDirectoryName(filename)
    if !exists('g:rvSaveDirectoryName')
        if g:rvSaveDirectoryType == 0
           " 0 = Save in current directory (under RCS)
            let l:SaveDirectoryName = expand(fnamemodify(a:filename, ":p:h")).g:rvDirSeparator."RCS".g:rvDirSeparator

        elseif g:rvSaveDirectoryType == 1
           " 1 = Single directory for all files
            let l:SaveDirectoryName = $VIM.g:rvDirSeparator."RCSFiles".g:rvDirSeparator

        else 
            " Type 2, save right here in the same directory (make sure you set
            "g:rvSaveSuffixType, or you will overwrite your file!)
            let l:SaveDirectoryName = expand(fnamemodify(a:filename, ":p:h")).g:rvDirSeparator
        endif
    else
        return expand(g:rvSaveDirectoryName)
    endif

    return l:SaveDirectoryName
endfunction

" Function: Generate suffix {{{1
"------------------------------------------------------------------------------
function! s:CreateSuffix(filename)
    if g:rvSaveSuffixType == 0
        return ""

    elseif g:rvSaveSuffixType == 1
        "1 = Use the standard ',v' suffix
        return ",v"

    elseif g:rvSaveSuffixType == 2
        "2 = Use a unique suffix
        return ",".expand(fnamemodify(a:filename, ":p:h:gs?\[:/ \\\\]?_?"))

    elseif g:rvSaveSuffixType == 3
        "3 = use a unique suffix with a ',v' appended to the end.
        return ",".expand(fnamemodify(a:filename, ":p:h:gs?\[:/ \\\\]?_?")).",v"

    elseif g:rvSaveSuffixType == 4
        "4 = User defined
        return g:rvSaveSuffix
    else
        echo "(rcsvers.vim) Error: unknown suffix type: ".g:rvSaveSuffixType
    endif
endfunction

" Function: Write the RCS {{{1
"------------------------------------------------------------------------------
function! s:rcsvers(type)

    " If this is a new file that hasn't been saved then we
    " can't create a check in entry.
    if a:type =="init" && !filereadable( expand("<afile>:p")) && !exists("modified")
        echo "(rcsvers.vim) You need to save the file first!"
        return
    endif

    " If this is a new file that hasn't been saved then we
    " can't create a previous entry so just exit.
    if a:type == "pre" && !filereadable( expand("<afile>:p")) && !exists("modified")
        return
    endif

    " Exclude directories from versioning, by putting skip file there.
    if filereadable( expand("<afile>:p:h").g:rvDirSeparator.g:rvSkipVimRcsFileName )
        return
    endif

    " Exclude file from versioning if it matches the exclude expression.
    if 0 != strlen(g:rvExcludeExpression) &&
            \ -1 != match(expand("<afile>:p"), g:rvExcludeExpression)
        return
    endif

    " Include file for versioning if it matches the include expression.
    if 0 != strlen(g:rvIncludeExpression) &&
            \ -1 == match(expand("<afile>:p"), g:rvIncludeExpression)
        return
    endif

    let l:suffix = s:CreateSuffix(expand("<afile>:p"))

    let l:SaveDirectoryName = s:GetSaveDirectoryName(expand("<afile>:p"))

    " Should we only save if RCS directory exists?
    if (g:rvSaveIfRCSExists == 1) && (g:rvSaveDirectoryType != 1) &&
     \ (g:rvSaveDirectoryType != 2) && (!isdirectory(l:SaveDirectoryName))
        return
    endif

    " Create RCS dir if it doesn't exist
    if (g:rvSaveDirectoryType != 2) && (!isdirectory(l:SaveDirectoryName))
        let l:returnval = s:RunCmd("mkdir ".g:rvFileQuote.l:SaveDirectoryName.g:rvFileQuote)
        if ( l:returnval == "error" )
            return
        endif
    endif

    " Generate name of RCS file
    let l:rcsfile = l:SaveDirectoryName.expand("<afile>:t").l:suffix

    " Should we only save if RCS file exists?
    if a:type != "init" && (g:rvSaveIfPreviousRCSFileExists == 1) && (getfsize(l:rcsfile) == -1)
        return
    endif

    " Handle description/message prompts
    if (g:rvDescMsgPrompt != 0)

        " If RCS file doesn't exist ask for description.
        if (getfsize(l:rcsfile) == -1)
            let l:description = input("(rcsvers.vim) Description for this file: ")
            "quote out any quote chars in the description
            let l:description = substitute(l:description,'"','\\"',"g")
            if (l:description == "")
                let l:description = g:rvDescription
            endif
        endif

        " Ask for the message for this version.
        if (a:type == "post")
            let l:message = input("(rcsvers.vim) Check-in message for this version: ")
            "quote out any quote chars in the message
            let l:message = substitute(l:message,'"','\\"',"g")
            if (l:message == "")
                let l:message = g:rvDescription
            endif
        else
            " Don't ask for message on "pre" or we'll get doubly prompted.
            let l:message = g:rvDescription
        endif
    else
        let l:description = g:rvDescription
        let l:message = g:rvDescription
    endif

    " ci options are as follows:
    " -i        Initial check in
    " -l        Check out and lock file after check in.
    " -t-       File description at initial check in.
    " -x        Suffix to use for rcs files.
    " -m        Log message
    "
    " Build the command options manually, s:GetCommonCmdOpts() isn't quite
    " right

    if (g:rvSaveSuffixType != 0)
        let l:cmdopts = " -x".l:suffix
    endif

    let l:editedfilename = expand("<afile>:p")
    if (g:rvUseCygPathFiltering != 0)
        let l:editedfilename = substitute(system("cygpath \"".l:editedfilename."\""),"\\n","","g")
    endif
    let l:cmdopts = l:cmdopts." ".g:rvFileQuote.l:editedfilename.g:rvFileQuote

    if (g:rvSaveSuffixType != 0)
        if (g:rvUseCygPathFiltering != 0)
            let l:cygpathrcsfile = substitute(system("cygpath \"".substitute(l:rcsfile,"\\\\","\\\\\\\\","g")."\""),"\\n","","g")
            let l:cmdopts = l:cmdopts." ".g:rvFileQuote.l:cygpathrcsfile.g:rvFileQuote
        else
            let l:cmdopts = l:cmdopts." ".g:rvFileQuote.l:rcsfile.g:rvFileQuote
        endif
    endif

    if (getfsize(l:rcsfile) == -1)
        " Initial check-in, create an empty RCS file
        let l:cmd = "rcs -i -t-\"".l:description."\" ".g:rvRcsOptions.l:cmdopts
        call s:RunCmd(l:cmd)
    else
        " We only need to do a pre-save if the RCS file
        " does not exist.
        if a:type == "pre"
            return
        endif
    endif

    "check permission changes
    if has("macunix") || has("unix") || has("win32unix")
        let l:fullpath = expand("<afile>:p")
        " Executable file
        if (executable(l:fullpath) == 1)
            if (executable(l:rcsfile) == 0)
                call s:RunCmd("chmod +x " . l:rcsfile)
            endif
        else "file has no executable bit
            if (executable(l:rcsfile) == 1)
                call s:RunCmd("chmod -x " . l:rcsfile)
            endif
        endif
    endif

    "lock RCS file if the option is set
    if (g:rvLeaveRcsUnlocked != 0)
        "-l locks the RCS file
        let l:cmd = "rcs -l ".g:rvRcsOptions.l:cmdopts
        call s:RunCmd(l:cmd)
    endif

    "do the checkin
    let l:cmd = "ci -l -m\"".l:message."\" ".g:rvCiOptions.l:cmdopts
    call s:RunCmd(l:cmd)

    "leave RCS file unlocked if the option is set
    if (g:rvLeaveRcsUnlocked != 0)
        "-u breaks the lock on the RCS file
        let l:cmd = "rcs -u ".g:rvRcsOptions.l:cmdopts
        call s:RunCmd(l:cmd)
    endif

endfunction

" Function: Display the revision log {{{1
"------------------------------------------------------------------------------
function! s:DisplayLog()
    " get the position in the rlog window, get it from a buffer-level variable
    if !exists("b:rvlastlogpos")
        "if no b:lastlogpos, use the current revision
        let b:rvlastlogpos = 0
    endif
    let l:rvlastlogpos = b:rvlastlogpos

    call s:RcsVersSaveSettings()

    "if the log or a version diff is already displayed, delete it and quit
    "(so that this function will work as a toggle)
    if (exists("s:child_bufnr"))
        if (match(bufname(s:child_bufnr),"rcsversRevisionLog")!=-1)
            "get the revision from the rlog window
            exec bufwinnr(s:child_bufnr) . "wincmd w"
            let l:rvlastlogpos = substitute(getline("."),
                \"^\\([.0-9]\\+\\).\\+", "\\1", "g")
        else
            "get the revision from the buffer-variable in the parent
            sil! exec bufwinnr(s:parent_bufnr) . "wincmd w"
            let l:rvlastlogpos = b:rvlastlogpos
        endif
        silent exec "bd! " . s:child_bufnr
        "remember the current position in the rlog window for each buffer
        let b:rvlastlogpos = l:rvlastlogpos
        return
    endif

    "save the current directory, in case they automatically change dir when opening files
    let l:savedir = expand("%:p:h")

    " Create the command
    let l:cmdopts = s:GetCommonCmdOpts(expand("%:p"))
    if (l:cmdopts == "error")
        return
    endif

    " Create the command
    let l:cmd = "rlog ".g:rvRlogOptions.l:cmdopts

    " This is the name of the buffer that holds the revision log list.
    let l:bufferName = g:rvTempDir.g:rvDirSeparator."rcsversRevisionLog"

    " If a buffer with the name rcsversRevisionLog exists, delete it.
    if bufexists("l:bufferName")
    silent exe 'bd! "'.l:bufferName.'"'
    endif

    " Create a new buffer (vertical split).
    sil exe 'vnew ' l:bufferName
    sil exe 'vertical resize 35'
    let s:child_bufnr =  bufnr("%")

    " Map <enter> to compare current file to that version
    nnoremap <buffer> <CR> :call <SID>RlogCompareFiles()<CR>

    "change dir to the original file dir, in case they auto change dir
    "when opening files
    sil exec "cd ".g:rvFileQuote. l:savedir.g:rvFileQuote

    " Execute the command.
    sil exe 'r!' l:cmd

    let l:lines = line("$")

    " If there is less than 10 lines then there was
    " probably an error.
    if l:lines > 10

        " Add the comment to the end of date so we save them
        sil exe ":%s/^date: .*$/\\0\\~/"
        sil exe ":g/^date: /j"
        " Remove any line not matching 'date' or 'revision'
        sil exe ":g!/^revision\\|^date/d"
        sil exe "normal 1G"
        " Format date and revision into a single line.
        let l:lines = line("$")
        let l:curr_line = 0

        while l:curr_line <= l:lines
            " Join the revision to the date...
            normal Jj
            let l:curr_line = l:curr_line + 2
        endwhile

        if (g:rvShowUser !=0)
            " format as: 'revision: date time author'
            sil! exe ":%s/revision\\s\\+\\([0-9.]\\+\\).\*".
                    \"date:\\([^;]\\+\\).\*".
                    \"author:\\([^;]\\+\\)".
                    \"[^~]\\+./".
                    \"\\1:\\2\\3/g"
        else
            " format as: 'revision: date time '
            sil! exe ":%s/revision\\s\\+\\([0-9.]\\+\\).\*".
                    \"date:\\([^;]\\+\\)".
                    \"[^~]\\+./".
                    \"\\1:\\2/g"
        endif

        " Remove default "vim" descriptions or rvDescription
        sil! exe ":%s/\\s".g:rvDescription."$//g"

        " Go to the remembered position in the rlog window.
        sil! exe "normal 1G"
        sil! exe "/^".l:rvlastlogpos.":"

    endif

    " Make it so that the file can't be edited.
    setlocal nomodified
    setlocal noswapfile
    setlocal nomodifiable
    setlocal readonly
    setlocal nowrap

endfunction

" Function: Compare the current file to the selected revision from rlog {{{1
"------------------------------------------------------------------------------
function! s:RlogCompareFiles()

    " Get just the revision number
    let l:revision = substitute(getline("."),
                \"^\\([.0-9]\\+\\).\\+", "\\1", "g")

    " Close the revision log, This will send us back to the original file.
    silent exe "bd!"

    call s:CompareFiles(l:revision)

endfunction

" Function: Compare the current file to the next revision ("older" or "newer") {{{1
"------------------------------------------------------------------------------
function! s:NextCompareFiles(direction)
    call s:RcsVersSaveSettings()

    "start off in the parent window
    if (exists("s:parent_bufnr"))
        sil exec bufwinnr(s:parent_bufnr) . "wincmd w"
    endif

    if (!exists("s:revision"))
        "no revision available, get the number of the head
        " Create the command
       let l:cmdopts = s:GetCommonCmdOpts(expand("%:p"))
       if (l:cmdopts == "error")
           return
       endif
       let l:cmd = "rlog -r. ".g:rvRlogOptions.l:cmdopts

       " Execute the command.
       let s:revision = s:RunCmd(l:cmd)

       "get the 'head:' line
       let s:revision = matchstr(s:revision,'head.\{-}\n')
       "get rid of the 'head:'
       let s:revision = substitute(s:revision,'^head: ',"","")
       "get rid of nl
       let s:revision = substitute(s:revision,'\n',"","")
    endif

    "if the version is x.y , the head is x. and the tail is y
    let l:head = matchstr(s:revision,'^.*\.')
    let l:tail = matchstr(s:revision,'\d*.$')

    "add or subtract from the tail to get the desired revision
    if (a:direction == "older")
        let l:tail = l:tail - 1
    elseif (a:direction == "newer")
        let l:tail = l:tail + 1
    else
        echo "(rcsvers.vim) Error: Bad arg to s:NextCompareFiles() : a:direction"
    endif

    "put together the whole revision
    let s:revision = l:head . l:tail

    call s:CompareFiles(s:revision)

endfunction

" Function: Compare the current file to a revision {{{1
"------------------------------------------------------------------------------
function! s:CompareFiles(revision)

    "save the current directory, in case they automatically change dir when opening files
    let l:savedir = expand("%:p:h")

    " Build the co command
    "
    " co options are as follows:
    " -p        Print the revision rather than storing in a file.
    "             This allows us to capture it with the r! command.
    " -r        Revision number to check out.

    let l:cmdopts = s:GetCommonCmdOpts(expand("%:p"))
    if (l:cmdopts == "error")
        return
    endif
    let l:cmd = "co -p -r".a:revision.l:cmdopts

    " Create a new buffer to place the co output
    let l:tmpfile = g:rvTempDir.g:rvDirSeparator."_".expand("%:p:t").".".a:revision

    "save the buffer number of the original file
    let l:parent_bufnr = bufnr("%")

    " ditch any existing child buffer
    if (exists("s:child_bufnr"))
        sil exec bufwinnr(s:child_bufnr) . "wincmd w"
        sil exe "bd!"
    endif

    "create a new buffer
    sil exe "vnew ".l:tmpfile

    "save the buffer number of the revision file
    let l:child_bufnr = bufnr("%")

    " Delete the contents if it's not empty
    sil exe "1,$d"

    "change dir to the original file dir, in case they auto change dir
    "when opening files
    exec "cd ".g:rvFileQuote.l:savedir.g:rvFileQuote

    " Run the co command and capture the output
    sil exe "sil! 0r!".l:cmd
    setlocal noswapfile
    setlocal nomodified

    " Execute the outside compare program.
    if (g:rvCompareProgram !=? "This")
    " Write the file and quit it
        sil exe "w!"
        sil exe "bd!"

    sil exe "!".g:rvCompareProgram." " g:rvFileQuote.l:tmpfile.
                \g:rvFileQuote.' '.g:rvFileQuote.bufname("%").g:rvFileQuote
    else
    " or do a diff in the current instance of vim
        diffthis
        sil exec bufwinnr(l:parent_bufnr) . "wincmd w"
        diffthis

        "set session variables in the parent buffer which indicate parent buffer
        "number, child buffer number, and the revision that is
        "currently showing
        let s:parent_bufnr = l:parent_bufnr
        let s:child_bufnr = l:child_bufnr
        let s:revision = a:revision

        "remember the current position in the rlog window for each buffer
        let b:rvlastlogpos = s:revision

    endif

endfunction
"}}}
" Function: set up the common commandline options {{{1
function! s:GetCommonCmdOpts(filename)
    " Build the command options
    let l:suffix = s:CreateSuffix(expand(a:filename))
    
    let l:rcsfile = s:GetSaveDirectoryName(fnamemodify(a:filename, ":p")).fnamemodify(a:filename, ":t").l:suffix

    " Check for an RCS file
    if (getfsize(l:rcsfile) == -1)
        echo "(rcsvers.vim) Error: No RCS file found! (".l:rcsfile.")"
        return "error"
    endif

    " -x   Suffix to use for rcs files.
    if (g:rvSaveSuffixType != 0)
        let l:cmdopts = " -x".l:suffix
    endif

    "some rcs implementations accept two filenames on co (editedfilename +
    "rcsfilename), some (cygwin) don't.  So only use the rcsfilename.
    "however, you do need it above for the rcs and ci commands

    "RCS filename
    if (g:rvSaveSuffixType != 0)
        if (g:rvUseCygPathFiltering != 0)
            let l:cygpathrcsfile = substitute(system("cygpath \"".substitute(l:rcsfile,"\\\\","\\\\\\\\","g")."\""),"\\n","","g")
            let l:cmdopts = l:cmdopts." ".g:rvFileQuote.l:cygpathrcsfile.g:rvFileQuote
        else
            let l:cmdopts = l:cmdopts." ".g:rvFileQuote.l:rcsfile.g:rvFileQuote
        endif
    endif

    " -q   Keep quiet ( no messages )
    let l:cmdopts = " -q ".l:cmdopts

    return l:cmdopts

endfunction
"}}}1

" Default key mappings to generate a revision log, and diff with adjacent
" versions.
"------------------------------------------------------------------------------
nnoremap <silent> <Leader>rlog  :call <SID>DisplayLog()<cr>
nnoremap <silent> <Leader>rci   :call <SID>rcsvers("init")<cr>

nnoremap <silent> <Leader>older :call <SID>NextCompareFiles("older")<cr>
nnoremap <silent> <Leader>newer :call <SID>NextCompareFiles("newer")<cr>

let &cpo = s:save_cpo
" vim600:textwidth=78:foldmethod=marker:fileformat=unix:expandtab:tabstop=4:shiftwidth=4
