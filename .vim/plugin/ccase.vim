" rc file for VIM, clearcase extensions {{{
" Author:               Douglas L. Potts
" Created:              17-Feb-2000
" Last Modified:        30-Aug-2004 10:46
"
" GetLatestVimScripts: 15 1 ccase.vim
"
" $Id: ccase.vim,v 1.38 2004/09/03 20:26:10 dp Exp $ }}}
"
" Modifications: {{{
" $Revision: 1.38 $
" $Log: ccase.vim,v $
" Revision 1.38  2004/09/03 20:26:10  dp
" Added Change comment command, and added line for GetLatestVimScripts.
"
" Revision 1.37  2004/01/19 20:32:34  dp
" added Revision keyword to header comment
"
" Revision 1.36ingo 12-Dec-2003 Ingo Karkat
" - Fixed missing enclosing double quotes at :ctcmt command
" - Modified :Ctci :Ctco :Ctcou :Ctmk commands which take an optional argument
"   representing the comment. Corresponding s:Ct...() functions got an
"   additional argument. 
" - Had to remove some ':exec' at ':exec call "..."' command definitions,
"   because the surrounding double quotes clashed with <f-args>; commands work
"   without exec, anyway. Proably, ':exec' can be removed before all ':call'? 
" - Added EscapeComments() function, which adds escaping of % and # characters
"   to the already filtered | and !
" - BF: changed s:comments to l:comments in CtCheckin()
"
" Revision 1.36  2003/12/09 16:14:26  dp
" My changes:
" Add User commands for all the regular cabbrevs used, so that diff
" commands and others may be issued on the command line with '-c'.
"
" Changes from Gary Johnson and WEN Guopeng:
" Addition of a diff with first version on this branch.
"
" Stefan Berglund and WEN Guopeng:
" Alter 'ctpwv' to not use the $view variable, and instead get it from the system.
"
" Changes from WEN Guopeng:
" Changes to embed the ccase.vim documentation in the .vim file, and automatically
" install on startup, diff with merged version, and other wonderful addititions
" that I'm probably forgetting.
"
" Revision 1.35  2003/08/12 19:34:16  dp
" - Added variable for listing checkouts by anyone, or just 'me'.
" - Added save of comment text into global var so it is accessable across
"   starts and stops of vim.
" - Replaces some echo's with echomsg's so they are saved in vim err list.
" - Moved autocmds around, so buffer-local kemaps aren't lost by the
"   autocmds which automatically refresh the listing upon BufEnter.
" - Added uncheckout functionality into Vim function instead of relying on
"   shell to do it.
" - MakeActiv now prompts for an activity comment.
" - Activity functions no show the activity comment, including the
"   activity list window.
" - For the activity and checkout list windows, open new files below and
"   to the right of the originating list window.
" - Added check for maps of <unique><script> already being there so
"   resourcing the plugin doesn't give errors.
"
" Revision 1.34  2003/04/03 19:48:05  dp
" Cleanup from last checkin, and Guillaume Lafage's
" change for link resolution.
"
" Revision 1.33  2003/04/03 18:12:09  dp
" - Added menu item and function to open the ClearTool Project Explorer
"   (clearprojexp).
" - Put text coloring on for display of the current activity.
" - Added 'Enter' key equivalent buffer-local mappings for the activity and
"   checkout list windows (equivalent operation to that of Double-click
"   '<2-Leftmouse>' in vim-ese).
" - Also fixed problem with initial opening of the 'list' windows where they
"   would have the initial data, and the autocmd would kick in appending the
"   "updated" data, so multiple listing of the same file would occur.
"
" Revision 1.32  2002/10/21 12:22:11  dp
" added "show comment" command to menu and a "cabbrev" ctcmt, and
" changed autocmd for activity list so that if an activity is chosen via a double
" click on the mouse, that the window goes away (I think this is the desired
" behavior).
"
" Revision 1.31  2002/10/21 12:01:25  dp
" fix from Gary Johnson on cleartool describe, used to determine predecessor
" version for ctpdif, escaping missing on space in filename, seen on Windows.
"
" Revision 1.30  2002/09/25 17:06:46  dp
" Added buffer local settings to set the current activity, and update the
" checkout list window on BufEnter.  Also added ability to create an UCM
" activity (mkactiv).  See updates to the documentation (:h ccase-plugin).
"
" Revision 1.29  2002/09/11 18:58:29  dp
" Corrected my misuse of 's:vars' as local, when I really was using
" 'l:vars' (local to the function, and the 'l:' not required).
"
" Implemented suggestion by Gary Johnson for the console diff
" function.  When used from a version tree or file browser,
" ccase would only append the version qualifier without
" checking that the filename given didn't already have one.
" Now works for fully qualified ClearCase filename with version
" (ex. filename@@/main/foo/1).
"
" Revision 1.28  2002/08/26 12:35:12  dp
" merged changes from 1.26 to provide a scratch buffer name to CtCmd and the
" string escape from Ingo Karkat (made to 1.25)
"
" Revision 1.27  2002/08/26 12:24:42  dp
" fixed brackets in bufname problem, as was discovered in version 1.25 on
" vim.sf.net
"
" Revision 1.26  2002/08/14 11:37:59  dp
" modified CtCmd function to take an optional parameter, the name for the
" results window
"
" Revision 1.25  2002/08/13 13:39:13  dp
" added results buffer capability similar to VTreeExplorer and other recent
" plugins, eliminates possible naming collisions between multiple users of the
" plugin on a shared system (ie. Unix/Linux).
"
" Revision 1.24  2002/08/08 20:11:38  dp
" *** empty log message ***
"
" Revision 1.23  2002/04/08 14:52:34  dp
" Added checkout unreserved, menus, mappings, etc.
"
" Revision 1.22  2002/04/05 21:43:02  dp
" Added capability to checkout a file unreserved, either via 'cab' command line,
" or menu.
"
" Revision 1.21  2002/01/18 16:13:48  dp
" *** empty log message ***
"
" Revision 1.20  2002/01/16 18:00:01  dp
" Revised setactivity and lsactivity handling.
"
" Revision 1.19  2002/01/15 15:22:27  dp
" Fixed bug with normal mode mappings, used in conjunction with file checkout
" listings.
"
" Revision 1.16  2002/01/04 20:36:51  dp
" Added echohl for prompts and error messages.
"
" Revision 1.14  2001/11/01 21:50:00  dp
" Added options to mkelem function, fixed bug with autoloading directory.
"
" Revision 1.13  2001/11/01 16:53:44  dp
" Lots of modifications for using prompt box commenting, enhancements to diff
" functionality, menus.
"
" Revision 1.11  2001/10/30 18:43:29  dp
" Added new prompt functionality for checkin and checkout.
"
" Revision 1.7  2001/10/01 17:31:16  dp
"  Added full mkelem functionality and cleaned up header comments some.
"
" Revision 1.4  2001/09/07 13:56:39  dp
" Removed '-nc' so that user will now be prompted for checkin and checkout
" comments.  Also removed common directory shortcuts since I don't use
" them anyway, but left in example for other users.
"
" 08-Jun-2001 pottsdl   Versioned this script for upload to vim-online.
" 18-Jan-2001 pottsdl   Put this file on my vim macros page.
" 09-Mar-2000 pottsdl   Changed so checkout will allow for changes made before
"                       checkout command was given, but still does the e! so
"                       that no warning message come up.
"                       Added ctver to give version.
" 09-Mar-2000 pottsdl   Added Clearcase menu definition here.
"                       Made Menus use these mappings for ease of use.
" 17-Feb-2000 pottsdl   Created from .unixrc mappings
"
" DONE:  Revise output capture method to use redir to put shell output into a
"        register, and open an unmodifiable buffer to put it in.
"        - Output is redirected to a temp file, then read into an unmodifiable
"        buffer.
" TODO:  Find a way to wrap up checkin/checkout operations with the file
"        explorer plugin.
" TODO:  Allow visual selections in results windows to be piped into requested
"        command. (ie on a list of checkouts, select multiple files to check
"        back in).
" DONE:  Intelligently escape quotes in comments inputted, so it doesn't confuse
"        ClearCase when the shell command is run.   (18-Jan-2002)
"
" DONE:  Maybe write up some documentation.     (12-Jan-2002)
" DONE:  Work in using this mapping for the results window if window has the
"        list of activities in it. (17-Sep-2002)
" DONE:  If in a listing of checkouts, allow double-click to split-open
"        the file under the cursor. 17-Sep-2002)
" DONE:  Use the following autocmd local to the buffer for the checkouts result
"        buffer, so that when user re-enters the window that it is updated.
"        (17-Sep-2002)
"
" }}}

if exists('g:loaded_ccase') | finish | endif
let g:loaded_ccase = 1

" ===========================================================================
"                           Setup Default Behaviors
" ===========================================================================
"{{{

" If using compatible, get out of here
if &cp
  echohl Error
  echomsg "Cannot load ccase.vim with 'compatible' option set!"
  echohl None
  finish
endif

augroup ccase
  au!

  " NOTE:  Put the reload stuff first, otherwise the buffer-local mappings will
  "        be lost.
  "
  " Checkout List window, update listing of checkouts when window is re-entered
  au BufEnter *checkouts_recurse* silent exe
        \ "if exists('b:ccaseUsed') == 1|
        \ bd\|
        \ let s:listStr = '!cleartool lsco -short -cview -recurse' |
        \ if g:ccaseJustMe == 1 |
        \   let s:listStr = s:listStr.' -me' |
        \ endif |
        \ call s:CtCmd(s:listStr, 'checkouts_recurse') |
        \ endif"
  au BufEnter *checkouts_allvobs* silent exe
        \ "if exists('b:ccaseUsed') == 1|
        \ bd\|
        \ let s:listStr = '!cleartool lsco -short -cview -avobs' |
        \ if g:ccaseJustMe == 1 |
        \   let s:listStr = s:listStr.' -me' |
        \ endif |
        \ call s:CtCmd(s:listStr, 'checkouts_allvobs') |
        \ endif"

  " Activity List window mappings
  " Conconction is because I'm listing the activity comments in addition to the
  " activity tags
  au BufNewFile,BufEnter *activity_list* nmap <buffer> <2-leftmouse> :call <SID>CtChangeActiv()<cr><cr>
  au BufNewFile,BufEnter *activity_list* nmap <buffer> <CR>          :call <SID>CtChangeActiv()<cr><cr>
  au BufNewFile,BufEnter *activity_list* nmap <buffer> O             :call <SID>CtShowActiv()<cr><cr>

  " Checkout List window mappings
  " - Double-click split-opens file under cursor
  " - Enter on filename split-opens file under cursor
  au BufNewFile,BufRead,BufEnter *checkouts* nmap <buffer> <2-Leftmouse> :call <SID>OpenInNewWin("<c-r>=expand("<cfile>")<cr>")<cr>
  "au BufNewFile *checkouts* nnoremap <buffer> <CR> <c-w>f
  au BufNewFile,BufRead,BufEnter *checkouts* nmap <buffer> <cr> :call <SID>OpenInNewWin("<c-r>=expand("<cfile>")<cr>")<cr>

augroup END

" If the *GUI* is running, either use the dialog box or regular prompt
if !exists("g:ccaseUseDialog")
  " If GUI is compiled in, default to use the dialog box
  if has("gui")
    let g:ccaseUseDialog = 1
  else
    " If no GUI compiled in, default to no dialog box
    let g:ccaseUseDialog = 0
  endif
endif

" Allow user to skip being prompted for comments all the time
if !exists("g:ccaseNoComment")
  let g:ccaseNoComment = 0      " Default is to ask for comments
endif

" Allow user to specify diffsplit of horiz. or vert.
if !exists("g:ccaseDiffVertSplit")
  let g:ccaseDiffVertSplit = 1  " Default to split for diff vertically
endif

" Allow user to specify automatically reloading file after checking in or
" checking out.
if !exists("g:ccaseAutoLoad")
  let g:ccaseAutoLoad = 1       " Default to reload file after ci/co operations
endif

" Allow for new elements to remained checked out
if !exists("g:ccaseMkelemCheckedout")
  let g:ccaseMkelemCheckedout = 0 " Default is to check them in upon creation
endif

" Allow for leaving directory checked out on Mkelem
if !exists("g:ccaseLeaveDirCO")
  let g:ccaseLeaveDirCO = 0     " Default is to prompt to check dir back in
endif

" Upon making a new clearcase activity, default behavior is to change the
" current activiy to the newly created activity.
if !exists("g:ccaseSetNewActiv")
  let g:ccaseSetNewActiv = 1    " Default is to set to new activity
endif

" Do checkout listings for only the current user
if !exists("g:ccaseJustMe")
  let g:ccaseJustMe      = 1    " Default is to list for only the current user
endif

" On uncheckouts prompt for what to do
if !exists("g:ccaseAutoRemoveCheckout")
  let g:ccaseAutoRemoveCheckout = 0 " Default is to prompt the user
endif

" Enable UCM support. UCM support is enabled by default:
if !exists("g:ccaseEnableUCM")
  let g:ccaseEnableUCM = 1      " Default is to enable UCM
endif

" Setup statusline to show current view, if your environment sets the
" $view variable when inside a view.
if exists("$view")
  set statusline=%<%f%h%m%r%=%{$view}\ %{&ff}\ %l,%c%V\ %P
endif

" Use a global var here to keep comments across restarts
if !exists("g:ccaseSaveComment")
  let g:ccaseSaveComment = ""
endif
"}}}

" ===========================================================================
"                      Beginning of Function Definitions
" ===========================================================================
" {{{

" ===========================================================================
function! s:CtShowViewName()
" Show the name of the current clearcase view.
" ---------------------------------------------------------------------------

  " Get current clearcase view name:
  "let l:ccase_viewname = system("cleartool pwv -s")
  let l:ccase_viewname = system("cleartool pwv")
  "let l:ccase_viewname = substitute(l:ccase_viewname, "[\r\n]", "", "g")
  let l:dirview = substitute(l:ccase_viewname,
        \ "^Working directory view: \\(.\\{-}\\)\\n.*", "\\1", "")
  let l:setview = substitute(l:ccase_viewname,
        \ ".*Set view: \\(.\\{-}\\)\\n", "\\1", "")

  " Show the view name:
  echohl Question
  echo "Set view: ".l:setview.".   Directory view: ".l:dirview
  echohl None

  return 0
endfunction

" ===========================================================================
function! s:CtAnnotate( fname )
" Clearcase annotate the specified/active clearcase element. The reault will
" be captured in a buffer named "cleartool_annotate".
" ---------------------------------------------------------------------------

  " Determine full path name of the clearcase element:
  if a:fname == ""
    let l:fname = resolve (expand("%:p"))
  else
    let l:fname = resolve (a:fname)
  endif

  " Check if the file is a clearcase element or not:
  let l:fname_and_ver = system('cleartool des -s -cview "'.l:fname.'"')
  if l:fname_and_ver !~ '@@'
    echohl Error
    echo "This buffer does not contain clearcase element."
    echohl None

    return 1
  endif

  " Execute clearcase annotate command, capture output in the
  " "cleartool_annotate" buffer. The '%' symbol should be carefully escaped
  " here, otherwise it will be expanded to the active filename, and mess up
  " the format string totally.
  call s:CtCmd("!cleartool annotate -nco -out - -fmt '\\%-8.8u \\%-16.16Vn | ' " . l:fname,
    \ 'cleartool_annotate')

  return 0
endfunction

" ===========================================================================
function! s:CtConsoleDiff( fname, diff_version )
" Requires: +diff
" Do a diff of the given filename with its cleartool predecessor or user
" specified version. The version to compare with is determined by
" diff_version:
"   If diff_version begins with '/' or '\', take it as targer version.
"   0: Ask user which version to compare with.
"   1: Compare with the previous version.
"   2: Compare with first version on the current branch.
"   3: Compare with the closest common ancestor with /main/LATEST. This should
"      contain changes made on private branch that have not been merged into
"      the main branch.
" ---------------------------------------------------------------------------

  if !has("diff")
    echohl Error
    echo "Unable to use console diff function.  Requires +diff compiled in"
    echohl None

    return 1
  endif

  " Determine full path name of the clearcase element:
  if a:fname == ""
    let l:fname = resolve (expand("%:p"))
  else
    let l:fname = resolve (a:fname)
  endif

  let l:splittype = ""
  if g:ccaseDiffVertSplit == 1
    let l:splittype=":vert diffsplit "
  else
    let l:splittype=":diffsplit "
  endif

  " Determine root of the filename.  Necessary when the file we are editting
  " already as an '@@' version qualifier.
  let l:fname_and_ver = system('cleartool des -s -cview "' . l:fname . '"')
  let l:fname_and_ver = substitute(l:fname_and_ver, "\n", "", "g")

  " Check if the file is a clearcase element or not:
  if l:fname_and_ver !~ '@@'
    echohl Error
    echo "This buffer does not contain clearcase element."
    echohl None

    return 1
  endif

  " Determine version of the source file:
  let l:cmp_from_ver  = substitute(l:fname_and_ver, "^[^@]*@@", "", "")

  if (a:diff_version =~ '^[/\\]')
    " The version begins with '/' or '\', take it as target version literally:
    let l:cmp_to_ver = a:diff_version
    echo "Comparing to version: " . l:cmp_to_ver

  elseif (a:diff_version == 0)
    let l:cmp_to_ver = ""
    let l:prompt_text = "Give version to compare to: "

    " While we aren't getting anything, keep prompting
    echohl Question
    while (l:cmp_to_ver == "")
      if g:ccaseUseDialog == 1
        let l:cmp_to_ver = inputdialog(l:prompt_text, "", "")
      else
        let l:cmp_to_ver = input(l:prompt_text)
        echo "\n"
      endif
    endwhile
    echohl None

    " Give user a chance to abort: A version will not likely to be a <ESC>
    " character. <ESC> character means user press "Cancel":
    if l:cmp_to_ver == ""
      echohl WarningMsg
      echomsg "CCASE diff operation canceled!"
      echohl None
      return 1
    endif

    " If they change their mind and want predecessor, allow that
    if l:cmp_to_ver =~ "pred"
      let l:cmp_to_ver = system('cleartool des -s -pre "' . l:fname_and_ver . '"')
    endif

  elseif (a:diff_version == 1)
    echo "Comparing to predecessor..."
    let l:cmp_to_ver = system('cleartool des -s -pre "' . l:fname_and_ver . '"')

    echo "Predecessor version: ". l:cmp_to_ver

  elseif (a:diff_version == 2)
    echo "Comparing to first version on the current branch ..."

    " Determine first version on the current branch. As both '/' and '\' can
    " not be used in clearcase version label, we can just remove the last part
    " of the version label without knowing the current system is Windows or
    " UNIX. The first version on the branch should be '<branch>/0':
    let l:cmp_to_ver = substitute(l:cmp_from_ver, '[^/\\]*$', '', '') . '0'

    echo "First version on current branch: ". l:cmp_to_ver

  elseif (a:diff_version == 3)
    echo "Comparing to the closest common ancestor with main branch ..."

    " Find out the closest common ancestor with the /main/LATEST:
    let l:cmp_to_ver = system('cleartool des -s -ancestor -cview "' .
                              \ l:fname . '" "' . l:fname .
                              \ '@@/main/LATEST' . '"')
    let l:cmp_to_ver = substitute(l:cmp_to_ver, "\n", "", "g")
    let l:cmp_to_ver = substitute(l:cmp_to_ver, "^[^@]*@@", "", "")

    echo "The closest common ancestor with main branch: " . l:cmp_to_ver

  else
    echohl Error
    echomsg "Cannot determine which version to compare to!"
    echohl None

    return 1
  endif

  " Sanity check: Make sure we are not comparing to the same version.
  " I'm not sure whether we should ignore case or not:
  if l:cmp_from_ver ==? l:cmp_to_ver
    echohl WarningMsg
    echomsg "CCASE diff: Compare to the same version, abort!"
    echohl None

    return 1
  endif

  " Strip the file version information out
  let l:fname = substitute(l:fname_and_ver, "@@[^@]*$", "", "")

  " For the :diffsplit command, enclosing the filename in double quotes does
  " not work. Thus, the filename's spaces are escaped with \.
  " On Windows, this is not necessary; but it only works with escaped spaces
  " on Unix.
  let l:fname_escaped = escape(l:fname, ' ')
  exe l:splittype . l:fname_escaped . '@@' . l:cmp_to_ver

  return 0
endfunction

" ===========================================================================
function! s:IsCheckedout( filename )
" Determine if the given filename (could be a directory) is currently
" checked out.
" Return 1 if checked out, 0 otherwise
" ===========================================================================
  let l:ischeckedout = system('cleartool describe -short "'.a:filename.'"')

  if l:ischeckedout =~ "CHECKEDOUT"
    return 1
  endif
  return 0
endfunction " s:IsCheckedout

" ===========================================================================
function! s:GetComment(text)
" Prompt use for checkin/checkout comment. The last entered comment will be
" the default. User enter comment will be recorded in a global vim variable
" (g:ccaseSaveComment) so that it will persist across vim starts and stops.
" The return value of this function is:
"   0 - If user enter a valid comment.
"   1 - If user want to abort the opertion.
" ===========================================================================
  echohl Question
  if has("gui_running") &&
        \ exists("g:ccaseUseDialog") &&
        \ g:ccaseUseDialog == 1
    let l:comment = inputdialog(a:text, g:ccaseSaveComment, "")
  else
    let l:comment = input(a:text, g:ccaseSaveComment)
    echo "\n"
  endif
  echohl None

  " If the entered comment is a <ESC>, inform the caller to abort operation.
  " It should be impossible for one to use a <ESC> character as checkin /
  " checkout comment, so we're safe here:
  if l:comment == ""
    return 1
  else
    let s:comment = s:EscapeComments(l:comment)

    " Save the unescaped text
    let g:ccaseSaveComment = l:comment
  endif

  return 0
endfunction " s:GetComment

" ===========================================================================
function! s:CtMkelem(filename, ...)
" Make the current file an element of the current directory.
" ===========================================================================
  let l:retVal = 0
  let l:elem_basename = fnamemodify(a:filename,":p:h")
  echo "elem_basename: ".l:elem_basename

  " Is directory checked out?  If no, ask to check it out.
  let l:isCheckedOut = s:IsCheckedout(elem_basename)
  if l:isCheckedOut == 0
    echohl WarningMsg
    echo "WARNING!  Current directory is not checked out."
    echohl Question
    let l:checkoutdir =
          \ input("Would you like to checkout the current directory (y/n): ")
    while l:checkoutdir !~ '[Yy]\|[Nn]'
      echo "\n"
      let l:checkoutdir = input("Input 'y' for yes, or 'n' for no: ")
    endwhile
    echohl None

    " No, don't checkout the directory
    if l:checkoutdir =~ '[Nn]'
      echohl Error
      echomsg "\nERROR:  Unable to make file an element!\n"
      echohl None
      return 1
    else " Else, Yes, checkout the directory
      " Checkout the directory
      if s:CtCheckout(elem_basename,"r") == 0
        " Check that directory actually got checked out
        let l:isCheckedOut = s:IsCheckedout(elem_basename)
        if l:isCheckedOut == 0
          echohl Error
          echo "\n"
          echomsg "ERROR!  Exitting, unable to checkout directory."
          echo "\n"
          echohl None
          return 1
        endif
      else
        echohl Error
        echo "\n"
        echomsg "Canceling make elem operation too!"
        echo "\n"
        echohl None
        return 1
      endif
    endif
  endif

  let l:comment = ""
  if a:0 == 1
      let l:comment = s:EscapeComments(a:1)
  elseif a:0 > 1
      echohl Error
      echomsg "This command requires either none or one argument!"
      echohl None
      return 1
  endif
  if (g:ccaseNoComment == 0) && (l:comment == "")
    " Make the file an element, ClearCase will prompt for comment
    if s:GetComment('Enter element creation comment: ') == 0
      let l:comment = s:comment
    else
      echohl WarningMsg
      echomsg "Make element canceled!"
      echohl None

      return 1
    endif
  endif

  if g:ccaseMkelemCheckedout == 0
    let l:CheckinElem = "-ci"
  else
    let l:CheckinElem = ""
  endif

  " Allow to use the default or no comment
  if l:comment =~ "-nc" || l:comment == "" || l:comment == "."
    let l:ccase_command = "!cleartool mkelem " . l:CheckinElem . " -nc \"" .
                          \ a:filename . '"'
  else
    let l:ccase_command = "!cleartool mkelem " . l:CheckinElem . " -c \"" .
                          \ l:comment . "\" \"" . a:filename . '"'
  endif

  " Execute clearcase mkelem command:
  exe l:ccase_command

  " Check error status of the command and log result to message history:
  if (v:shell_error)
    echohl Error
    echomsg "CCASE mkelem failed: " . l:ccase_command
    echohl None
  else
    echomsg "CCASE mkelem done: " . l:ccase_command
  endif

  " Reload the buffer if required:
  if g:ccaseAutoLoad == 1
    exe "e! " . '"' . a:filename . '"'
  endif

  if g:ccaseLeaveDirCO == 0
    echohl Question
    let l:checkoutdir =
          \ input("Would you like to checkin the current directory (y/n): ")
    while l:checkoutdir !~ '[Yy]\|[Nn]'
      echo "\n"
      let l:checkoutdir = input("Input 'y' for yes, or 'n' for no: ")
    endwhile
    echohl None

    " Check the directory back in, ClearCase will prompt for comment
    if l:checkoutdir =~ '[Yy]'
      " Don't reload the directory upon checking it back in
      let l:tempAutoLoad = g:ccaseAutoLoad
      let g:ccaseAutoLoad = 0

      if s:CtCheckin(elem_basename) == 1
        let l:retVal = 1
        echohl WarningMsg
        echomsg "Checkin canceled!"
        echohl None
      endif

      let g:ccaseAutoLoad = l:tempAutoLoad
    else
      echo "\n"
      echomsg "CCASE mkelem: Not checking directory back in."
    endif
  else
      echo "\n"
      echomsg "CCASE mkelem: Not checking directory back in."
  endif

  return l:retVal
endfunction " s:CtMkelem

" ===========================================================================
function! s:CtChangeCmt(file)
" Allow user to modify element comment (checkout or checkin, whichever is most
" recent.
" ===========================================================================
  let l:retVal = 0

  if a:file == ""
    let l:file = resolve (expand("%:p"))
  else
    let l:file = resolve (a:file)
  endif

  let l:comment = ""
  if a:0 == 1
      let l:comment = s:EscapeComments(a:1)
  elseif a:0 > 1
      echohl Error
      echomsg "This command requires either none or one argument!"
      echohl None
      return 1
  endif
  if (g:ccaseNoComment == 0) && (l:comment == "")
    if s:GetComment("Enter changed comment: ") == 0
      let l:comment = s:comment
    else
      echohl WarningMsg
      echomsg "Change comment canceled!"
      echohl None
      return 1
    endif
  endif
  "
  " Allow to use the default or no comment
  if l:comment =~ "-nc" || l:comment == "" || l:comment == "."
    let l:comment_flag = "-nc"
  else
    let l:comment_flag = "-c \"" . l:comment . "\""
  endif

  " Execute change command:
  let l:ccase_command = "!cleartool chevent " . l:comment_flag . " \"" . l:file . '"'
  exe l:ccase_command

  " Check error status of the command and log result to message history:
  if (v:shell_error)
    echohl Error
    echomsg "CCASE change comment failed: " . l:ccase_command
    echohl None

    return 1
  else
    echomsg "CCASE changed comment."
  endif

  return 0
endfunction " s:CtChangeCmt

" ===========================================================================
function! s:CtCheckout(file, reserved, ...)
" Function to perform a clearcase checkout for the current file
" Return 0 if OK, 1 if failed.
"
" TODO:  use range availability, a:firstline a:lastline, and a substitute()
" command to build the file list to do in one checkout.  Maybe have option to
" ask if all should be checked out under the same comment or not.  Will have to
" add a vmap down to the section that uses mapleader to call this.  Would have
" to add 'range' to end of function definition.
" - Could also add to CtCheckin
" ===========================================================================
  if a:file == ""
    let l:file = resolve (expand("%:p"))
  else
    let l:file = resolve (a:file)
  endif

  let l:comment = ""
  if a:0 == 1
      let l:comment = s:EscapeComments(a:1)
  elseif a:0 > 1
      echohl Error
      echomsg "This command requires either none or one argument!"
      echohl None
      return 1
  endif
  if (g:ccaseNoComment == 0) && (l:comment == "")
    if s:GetComment("Enter checkout comment: ") == 0
      let l:comment = s:comment
    else
      echohl WarningMsg
      echomsg "Checkout canceled!"
      echohl None
      return 1
    endif
  endif

  " Default is checkout reserved, if specified unreserved, then put in
  " appropriate switch
  if a:reserved == "u"
    let l:reserved_flag = "-unreserved"
  else
    let l:reserved_flag = ""
  endif

  " Allow to use the default or no comment
  if l:comment =~ "-nc" || l:comment == "" || l:comment == "."
    let l:comment_flag = "-nc"
  else
    let l:comment_flag = "-c \"" . l:comment . "\""
  endif

  " Execute clearcase checkout command:
  let l:ccase_command = "!cleartool co " . l:reserved_flag . " " .
                        \ l:comment_flag . " \"" . l:file . '"'
  exe l:ccase_command

  " Check error status of the command and log result to message history:
  if (v:shell_error)
    echohl Error
    echomsg "CCASE checkout failed: " . l:ccase_command
    echohl None

    return 1
  else
    echomsg "CCASE checkout done: " . l:ccase_command
  endif

  " Reload the buffer if required:
  if g:ccaseAutoLoad == 1
    if &modified == 1
      echohl WarningMsg
      echo "ccase: File modified before checkout, not doing autoload"
      echo "       to prevent losing changes."
      echohl None
    else
      exe "e! " . '"' . l:file . '"'
    endif
  endif

  return 0
endfunction " s:CtCheckout()

" ===========================================================================
function! s:CtCheckin(file, ...)
" Function to perform a clearcase checkin for the current file
" Return 0 if OK, return 1 if failed.
" ===========================================================================
  if a:file == ""
    let l:file = resolve (expand("%:p"))
  else
    let l:file = resolve (a:file)
  endif

  let l:comment = ""
  if a:0 == 1
      let l:comment = s:EscapeComments(a:1)
  elseif a:0 > 1
      echohl Error
      echomsg "This command requires either none or one argument!"
      echohl None
      return 1
  endif
  if (g:ccaseNoComment == 0) && (l:comment == "")
    if s:GetComment("Enter checkin comment: ") == 0
      let l:comment = s:comment
    else
      echohl WarningMsg
      echomsg "Checkout canceled!"
      echohl None
      return 1
    endif
  endif

  " Allow to use the default or no comment
  if l:comment =~ "-nc" || l:comment == "" || l:comment == "."
    let l:ccase_command = "!cleartool ci -nc \"" . l:file . '"'
  else
    let l:ccase_command = "!cleartool ci -c \"" . l:comment .
                          \ "\" \"" . l:file . '"'
  endif

  "DEBUG echo l:ccase_command

  " Execute clearcase checkin command:
  exe l:ccase_command

  " Check error status of the command and log result to message history:
  if (v:shell_error)
    echohl Error
    echomsg "CCASE checkin failed: " . l:ccase_command
    echohl None

    return 1
  else
    echomsg "CCASE checkin done: " . l:ccase_command
  endif

  " Reload the buffer if required:
  if g:ccaseAutoLoad == 1
    exe "e! " . '"' . l:file . '"'
  endif

  return 0
endfunction " s:CtCheckin()

" ===========================================================================
function! s:CtUncheckout(file)
" Function to perform a clearcase uncheckout
" Return 0 if succeed, return 1 if failed.
" ===========================================================================

  if a:file == ""
    let l:file = resolve (expand("%:p"))
  else
    let l:file = resolve (a:file)
  endif

  " Execute clearcase uncheckout command:
  if g:ccaseAutoRemoveCheckout == 1
    let l:ccase_command = "!cleartool unco -rm \"" . l:file . '"'
  else
    let l:ccase_command = "!cleartool unco \"" . l:file . '"'
  endif

  exe l:ccase_command

  " Check error status of the command and log result to message history:
  if (v:shell_error)
    echohl Error
    echomsg "CCASE uncheckout failed: " . l:ccase_command
    echohl None

    return 1
  else
    echomsg "CCASE uncheckout done: " . l:ccase_command
  endif

  if g:ccaseAutoLoad == 1
    exe "e! " . '"' . a:file . '"'
  endif

  return 0
endfunction " s:CtUncheckout

" ===========================================================================
fun! s:MakeActiv()
"     Create a clearcase activity
" ===========================================================================
  echohl Question
  let l:new_activity = input ("Enter new activity tag: ")
  echo "\n"
  echohl None

  let l:comment = ""
  if s:GetComment("Enter activity comment: ") == 0
    let l:comment = s:comment
  else
    echohl WarningMsg
    echomsg "Make Activity canceled!"
    echohl None
    return 1
  endif

  if l:new_activity != ""
    if g:ccaseSetNewActiv == 0
      let l:set_activity = "-nset"
    else
      let l:set_activity = ""
    endif

    " Allow to use the default or no comment
    if l:comment =~ "-nc" || l:comment == "" || l:comment == "."
      exe "!cleartool mkactiv ".l:set_activity." -nc ".l:new_activity
    else
      exe "!cleartool mkactiv ".l:set_activity." -c \"".l:comment."\" ".
            \ l:new_activity
    endif
  else
    echohl Error
    echomsg "No activity tag entered.  Command aborted."
    echohl None
  endif
endfun " s:MakeActiv
com! -nargs=0 -complete=command Ctmka call <SID>MakeActiv()
cab  ctmka  Ctmka

" ===========================================================================
fun! s:ListActiv(current_act)
"     List current clearcase activity
" ===========================================================================
  if a:current_act == "current"
    silent let @"=system("cleartool lsactiv -cact -fmt \'\%n\t\%c\'")
    let l:tmp = substitute(@", "\n", "", "g")
    echohl Question
    echo l:tmp
    echohl None
  else " List all actvities
    call s:CtCmd("!cleartool lsactiv -fmt \'\\%n\t\\%c\'", "activity_list")
  endif
endfun " s:ListActiv
com! -nargs=0 -complete=command Ctlsa call <SID>ListActiv("")
com! -nargs=0 -complete=command Ctlsc call <SID>ListActiv("current")
cab ctlsa  Ctlsa
cab ctlsc  Ctlsc

" ===========================================================================
fun! s:SetActiv(activity)
"     Set current activity
" ===========================================================================
  " If NULL activity is passed in, then prompt for it.
  if a:activity == ""
    let l:activity = input("Enter activity code to change to: ")
    echo "\n"
  else
    let l:activity = a:activity
  endif

  if l:activity != ""
    exe "!cleartool setactiv ".l:activity
  else
    echohl Error
    echomsg "Not changing activity!"
    echohl None
  endif
endfun " s:SetActiv
com! -nargs=0 -complete=command Ctsta call <SID>SetActiv("")
cab  ctsta Ctsta

" ===========================================================================
fun! s:CtShowActiv()
"     Function to show detailed info on the activity tag in the current line
"     of the activity_list window.
" ===========================================================================
  let l:activity=substitute(getline('.'), '^\(.\+\)\t.*$', '\1', 'g')
  call s:CtCmd("!cleartool lsactiv -l ".l:activity, "activity_details")
endfun " s:CtShowActiv

" ===========================================================================
fun! s:CtOpenProjExp()
"     Function to open the UCM ClearCase Project Explorer.  Mainly checks
"     that executable is there and runs it if it is, otherwise it echoes an
"     error saying that you don't have it.
" ===========================================================================
  if executable('clearprojexp')
    silent exe "!clearprojexp &"
  else
    echohl Error
    echomsg "The ClearCase UCM Project Explorer executable does not exist"
    " Purposely left next line off of the 'echomsg'
    echo "or is not in your path."
    echohl None
  endif
endfun " s:CtOpenProjExp
com! -nargs=0 -complete=command Ctexp call <SID>CtOpenProjExp()
cab ctexp Ctexp

" ===========================================================================
fun! s:CtMeStr()
" Return the string '-me' if the ccaseJustMe variable exists and is set.
" Used for checkout listings to limit checkouts to just the current user, or to
" any user with checkouts in the current view.
" ===========================================================================
  if g:ccaseJustMe == 1
    return '-me'
  else
    return ''
  endif
  return ''
endfun " s:CtMeStr

" ===========================================================================
fun! s:CtCmd(cmd_string, ...)
" Execute ClearCase 'cleartool' command, and put the output into a results
" buffer.
"
" cmd_string - clearcase shell command to execute, and capture output for
" ...        - optional scratch buffer name string
" ===========================================================================
  if a:cmd_string != ""
    let l:tmpFile = tempname()

    " Capture output in a generated temp file
    exe a:cmd_string." > ".l:tmpFile

    let l:results_name = "ccase_results"

    " If name is passed in, overwrite our setting
    if a:0 > 0 && a:1 != ""
      let l:results_name = a:1
    endif

    " Now see if a results window is already there
    let l:results_bufno = bufnr(l:results_name)
    if l:results_bufno > 0
      exe "bw! " . l:results_bufno
    endif

    " Open a new results buffer, brackets are added here so that no false
    " positives match in trying to determine l:results_bufno above.
    " silent exe "topleft new [".l:results_name."]"
    " exe "topleft new [".l:results_name."]"
    exe "split new [" . l:results_name . "]"

    setlocal modifiable
    " Read in the output from our command
    " silent exe "0r ".l:tmpFile
    exe "0r ".l:tmpFile

    " Setup the buffer to be a "special buffer"
    " thanks to T. Scott Urban here, I modeled my settings here off of his code
    " for VTreeExplorer
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete " d
    let      b:ccaseUsed=1    " Keep from loading data twice the first time
    setlocal nomodifiable

    " Get rid of temp file
    if has('unix')
      silent exe "!rm ".l:tmpFile
    else
      silent exe "!del ".l:tmpFile
    endif

  endif
endfun " s:CtCmd

" ===========================================================================
fu! s:CtChangeActiv()
" Do the operations for a change in activity from the [activity_list] buffer
" ===========================================================================
  let l:activity = substitute(getline("."), '^\(\S\+\)\s.*$', '\1', '')
  call s:SetActiv(l:activity)
  bd
endfun " s:CtChangeActiv

" ===========================================================================
fu! s:EscapeComments(comment)
" Escape harmful characters in the entered comments, so that they can be
" passed to the shell cleartool command. 
" ===========================================================================
  " Double quotes in comment must be escaped, because of the cleartool
  " invocation via: 
  " cleartool checkout -c "<comment_text>"
  " Single quotes are OK, since the checkout shell command uses double quotes
  " to surround the comment text.
  let l:comment = substitute(a:comment, '"\|!', '\\\0', "g")
  " Escape special Ex characters # and % (cp. :help cmdline-special)
  " let l:comment = substitute(l:comment, '\(^\|[^\\]\)\&\([%#]\)', '\\\2', "g" )
  let l:comment = escape(l:comment, '%#')
  return l:comment
endfun " s:EscapeComments

" ===========================================================================
function! s:OpenInNewWin(filename)
" Since checkouts buffer and activity buffer are opened at topleft, we want
" to open new files as bottomright.  This function will do that, while saving
" user settings, and restoring those settings after opening the new window.
" ===========================================================================
  let l:saveSplitBelow = &splitbelow
  let l:saveSplitRight = &splitright

  set splitbelow
  set splitright
  exe "split "a:filename

  let &splitbelow = l:saveSplitBelow
  let &splitright = l:saveSplitRight
endfun " s:OpenInNewWin

" ===========================================================================
fun! s:InstallDocumentation(full_name, revision)
" Install help documentation.
" Arguments:
"   full_name: Full name of this vim plugin script, including path name.
"   revision:  Revision of the vim script. #version# mark in the document file
"              will be replaced with this string with 'v' prefix.
" Return:
"   0 if new document installed, 1 otherwise.
" ===========================================================================
  " Name of the document path based on the system we use:
  if (has("unix"))
    " On UNIX like system, using forward slash:
    let l:slash_char = '/'
    let l:mkdir_cmd  = ':silent !mkdir -p '
  else
    " On M$ system, use backslash. Also mkdir syntax is different.
    " This should only work on W2K and up.
    let l:slash_char = '\'
    let l:mkdir_cmd  = ':silent !mkdir '
  endif

  let l:doc_path = l:slash_char . 'doc'
  let l:doc_home = l:slash_char . '.vim' . l:slash_char . 'doc'

  " Figure out document path based on full name of this script:
  let l:vim_plugin_path = fnamemodify(a:full_name, ':h')
  let l:vim_doc_path    = fnamemodify(a:full_name, ':h:h') . l:doc_path
  if (!(filewritable(l:vim_doc_path) == 2))
    echomsg "Doc path: " . l:vim_doc_path
    execute l:mkdir_cmd . l:vim_doc_path
    if (!(filewritable(l:vim_doc_path) == 2))
      " Try a default configuration in user home:
      let l:vim_doc_path = expand("~") . l:doc_home
      if (!(filewritable(l:vim_doc_path) == 2))
        execute l:mkdir_cmd . l:vim_doc_path
        if (!(filewritable(l:vim_doc_path) == 2))
          " Put a warning:
          echomsg "Unable to open documentation directory"
          echomsg " type :help add-local-help for more informations."
          return 1
        endif
      endif
    endif
  endif

  " Exit if we have problem to access the document directory:
  if (!isdirectory(l:vim_plugin_path)
        \ || !isdirectory(l:vim_doc_path)
        \ || filewritable(l:vim_doc_path) != 2)
    return 1
  endif

  " Full name of script and documentation file:
  let l:script_name = fnamemodify(a:full_name, ':t')
  let l:doc_name    = fnamemodify(a:full_name, ':t:r') . '.txt'
  let l:plugin_file = l:vim_plugin_path . l:slash_char . l:script_name
  let l:doc_file    = l:vim_doc_path    . l:slash_char . l:doc_name

  " Bail out if document file is still up to date:
  if (filereadable(l:doc_file)  &&
        \ getftime(l:plugin_file) < getftime(l:doc_file))
    return 1
  endif

  " Prepare window position restoring command:
  if (strlen(@%))
    let l:go_back = 'b ' . bufnr("%")
  else
    let l:go_back = 'enew!'
  endif

  " Create a new buffer & read in the plugin file (me):
  setl nomodeline
  exe 'enew!'
  exe 'r ' . l:plugin_file

  setl modeline
  let l:buf = bufnr("%")
  setl noswapfile modifiable

  norm zR
  norm gg

  " Delete from first line to a line starts with
  " === START_DOC
  1,/^=\{3,}\s\+START_DOC\C/ d

  " Delete from a line starts with
  " === END_DOC
  " to the end of the documents:
  /^=\{3,}\s\+END_DOC\C/,$ d

  " Remove fold marks:
  % s/{\{3}[1-9]/    /

  " Add modeline for help doc: the modeline string is mangled intentionally
  " to avoid it be recognized by VIM:
  call append(line('$'), '')
  call append(line('$'), ' v' . 'im:tw=78:ts=8:ft=help:norl:')

  " Replace revision:
  exe "normal :1s/#version#/ v" . a:revision . "/\<CR>"

  " Save the help document:
  exe 'w! ' . l:doc_file
  exe l:go_back
  exe 'bw ' . l:buf

  " Build help tags:
  exe 'helptags ' . l:vim_doc_path

  return 0
endfun " s:InstallDocumentation

" }}}
" ===========================================================================
"                         End of Function Definitions
" ===========================================================================

" ===========================================================================
"                   Beginning of Command line Abbreviations
" ===========================================================================
" {{{
"     Make current file an element in the vob
cab  ctmk   call <SID>CtMkelem(expand("%"))
com! -nargs=? -complete=command Ctmk call <SID>CtMkelem(expand("%"), <f-args>)

"     Abbreviate cleartool
cab  ct     !cleartool
"     check-out buffer (w/ edit afterwards to get rid of RO property)
cab  ctco   call <SID>CtCheckout('', "r")
com! -nargs=? -complete=command Ctco call <SID>CtCheckout('', "r", <f-args>)
"     check-out buffer (...) unreserved
cab  ctcou  call <SID>CtCheckout('', "u")
com! -nargs=? -complete=command Ctcou call <SID>CtCheckout('', "u", <f-args>)
"     check-in buffer (w/ edit afterwards to get RO property)
cab  ctci   call <SID>CtCheckin('')
com! -nargs=? -complete=command Ctci call <SID>CtCheckin('', <f-args>)
"     uncheckout buffer (w/ edit afterwards to get RO property)
cab  ctunco call <SID>CtUncheckout('')
com! -nargs=0 -complete=command Ctunco call <SID>CtUncheckout('')
"     Diff buffer with predecessor version
cab  ctpdif call <SID>CtConsoleDiff('', 1)<cr>
com! -nargs=0 -complete=command Ctpdif call <SID>CtConsoleDiff('', 1)
"     Diff buffer with the first version on the current branch:
com! -nargs=0 -complete=command Ct0dif call <SID>CtConsoleDiff('', 2)
cab  ct0dif Ct0dif
cab  ctbdif Ct0dif
"     Diff buffer with the closest common ancestor version with main branch:
cab  ctmdif call <SID>CtConsoleDiff('', 3)<cr>
com! -nargs=0 -complete=command Ctmdif call <SID>CtConsoleDiff('', 3)
"     Diff buffer with queried version
cab  ctqdif call <SID>CtConsoleDiff('', 0)<cr>
com! -nargs=0 -complete=command Ctqdif call <SID>CtConsoleDiff('', 0)
"     describe buffer
cab  ctdesc !cleartool describe "%"
com! -nargs=0 -complete=command Ctdesc exec "!cleartool describe ".expand("%")
"     give version of buffer
cab  ctver  !cleartool describe -aattr version "%"
com! -nargs=0 -complete=command Ctver exec 
      \ "!cleartool describe -aattr version ".expand("%")

"     List my checkouts in the current view and directory
cab  ctcoc  !cleartool lsco -cview -short <c-r>=<SID>CtMeStr()<cr>
com! -nargs=0 -complete=command Ctcoc exec
      \ "!cleartool lsco -cview -short ".<SID>CtMeStr()
"     List my checkouts in the current view and directory, and it's sub-dir's
cab  ctcor  call <SID>CtCmd("!cleartool lsco -short -cview ".
      \ <SID>CtMeStr()." -recurse", "checkouts_recurse")<CR>
com! -nargs=0 -complete=command Ctcor exec 
      \ "call <SID>CtCmd(\"!cleartool lsco -short -cview \".
      \ <SID>CtMeStr().\" -recurse\", \"checkouts_recurse\")"
"     List all my checkouts in the current view (ALL VOBS)
cab  ctcov  call <SID>CtCmd("!cleartool lsco -short -cview ".
      \ <SID>CtMeStr()." -avob", "checkouts_allvobs")<CR>
com! -nargs=0 -complete=command Ctcov exec 
      \ "call <SID>CtCmd(\"!cleartool lsco -short -cview \".
      \ <SID>CtMeStr().\" -avob\", \"checkouts_allvobs\")"
cab  ctcmt  !cleartool describe -fmt "Comment:\n'\%c'" "%"
com! -nargs=0 -complete=command Ctcmt exec
      \ "!cleartool describe -fmt \"Comment:\\n'\\%c'\" ".expand("%")
cab  ctchc call <SID>CtChangeCmt('')
com! -nargs=? -complete=command Ctchc call <SID>CtChangeCmt ('', <f-args>)
cab  ctann  call <SID>CtAnnotate('')
com! -nargs=0 -complete=command Ctann call <SID>CtAnnotate('')

"       These commands don't work the same on UNIX vs. WinDoze
if has("unix")
  com! -nargs=0 -complete=command Ctldif exec
        \ "call <SID>CtConsoleDiff('', '/main/LATEST')"
  com! -nargs=0 -complete=command Cttree exec
        \ "call <SID>CtCmd(\"!cleartool lsvtree -all -merge ".expand("%")."\")"
  com! -nargs=0 -complete=command Cthist exec
        \ "call <SID>CtCmd(\"!cleartool lshistory ".expand("%")."\")"
  com! -nargs=0 -complete=command Ctxlsv exec "!xlsvtree ".expand("%")." &"
  com! -nargs=0 -complete=command Ctdiff exec
        \ "!cleartool diff -graphical -pred ".expand("%")." &"

else
  "     Diff buffer with the latest version on the main branch:
  "cab  ctldif call <SID>CtConsoleDiff('', '\main\LATEST')<cr>
  com! -nargs=0 -complete=command Ctldif exec
        \ "call <SID>CtConsoleDiff('', '\main\LATEST')"
  "     buffer text version tree
  "cab  cttree call <SID>CtCmd("!cleartool lsvtree -all -merge \"".expand("%").'"')<CR>
  com! -nargs=0 -complete=command Cttree exec
        \ "call <SID>CtCmd(\"!cleartool lsvtree -all -merge \"".expand("%")."\"\")"
  "     buffer history
  "cab  cthist call <SID>CtCmd("!cleartool lshistory \"".expand("%").'"')<CR>
  com! -nargs=0 -complete=command Cthist exec
        \ "call <SID>CtCmd(\"!cleartool lshistory \"".expand("%")."\"\")"
  "     xlsvtree on buffer
  "cab  ctxlsv !start clearvtree.exe "%"<cr>
  com! -nargs=0 -complete=command Ctxlsv exec 
        \ "!start clearvtree.exe ".expand("%")
  "     xdiff with predecessor
  "cab  ctdiff !start cleartool diff -graphical -pred "%"<CR>
  com! -nargs=0 -complete=command Ctdiff exec
        \ "!start cleartool diff -graphical -pred \"".expand("%")."\""
endif


"     Diff buffer with the latest version on the main branch:
"cab  ctldif call <SID>CtConsoleDiff('', '/main/LATEST')<cr>
cab  ctldif Ctldif
"     buffer text version tree
"cab  cttree call <SID>CtCmd("!cleartool lsvtree -all -merge \"".expand("%").'"')<CR>
cab  cttree Cttree
"     buffer history
"cab  cthist call <SID>CtCmd("!cleartool lshistory \"".expand("%").'"')<CR>
cab  cthist Cthist
"     xlsvtree on buffer
"cab  ctxlsv !xlsvtree "%" &<CR>
cab  ctxlsv Ctxlsv
"     xdiff with predecessor
"cab  ctdiff !cleartool diff -graphical -pred "%" &<CR>
cab  ctdiff Ctdiff
"     Give the current viewname
"cab  ctpwv call <SID>CtShowViewName()<CR>
com! -nargs=0 -complete=command Ctpwv call <SID>CtShowViewName()
cab  ctpwv Ctpwv

" }}}
" ===========================================================================
"                              Beginning of Maps
" ===========================================================================
" {{{
" ===========================================================================
" Public Interface:
" ===========================================================================
if !hasmapto('<Plug>CleartoolCI')
  nmap <unique> <Leader>ctci <Plug>CleartoolCI
endif
if !hasmapto('<Plug>CleartoolCO')
  nmap <unique> <Leader>ctco <Plug>CleartoolCO
endif
if !hasmapto('<Plug>CleartoolCOUnres')
  nmap <unique> <Leader>ctcou <Plug>CleartoolCOUnres
endif
if !hasmapto('<Plug>CleartoolUnCheckout')
  nmap <unique> <Leader>ctunco <Plug>CleartoolUnCheckout
endif
if !hasmapto('<Plug>CleartoolListHistory')
  nmap <unique> <Leader>cthist <Plug>CleartoolListHistory
endif
if !hasmapto('<Plug>CleartoolGraphVerTree')
  nmap <unique> <Leader>ctxl <Plug>CleartoolGraphVerTree
endif
if !hasmapto('<Plug>CleartoolConsolePredDiff')
  nmap <unique> <Leader>ctpdif <Plug>CleartoolConsolePredDiff
endif
if !hasmapto('<Plug>CleartoolConsoleBranch0Diff')
  nmap <unique> <Leader>ct0dif <Plug>CleartoolConsoleBranch0Diff
endif
if !hasmapto('<Plug>CleartoolConsoleBranchMergeDiff')
  nmap <unique> <Leader>ctmdif <Plug>CleartoolConsoleBranchMergeDiff
endif
if !hasmapto('<Plug>CleartoolConsoleLatestDiff')
  nmap <unique> <Leader>ctldif <Plug>CleartoolConsoleLatestDiff
endif
if !hasmapto('<Plug>CleartoolConsoleBranchDiff')
  nmap <unique> <Leader>ctbdif <Plug>CleartoolConsoleBranch0Diff
endif
if !hasmapto('<Plug>CleartoolConsoleQueryDiff')
  nmap <unique> <Leader>ctqdif <Plug>CleartoolConsoleQueryDiff
endif
if !hasmapto('<Plug>CleartoolSetActiv')
  nmap <unique> <Leader>ctsta <Plug>CleartoolSetActiv
endif

" ===========================================================================
" Global Maps:
"       For use on a file that has filenames in it:
"       just put the cursor on the filename and use the map sequence.
" ===========================================================================
if !hasmapto('<Plug>CleartoolCI')
  map <unique> <script> <Plug>CleartoolCI
        \ :call <SID>CtCheckin('<c-r>=expand("<cfile>")<cr>')<cr>
endif

if !hasmapto('<Plug>CleartoolCO')
  map <unique> <script> <Plug>CleartoolCO
        \ :call <SID>CtCheckout('<c-r>=expand("<cfile>", "r")<cr>')<cr>
endif

if !hasmapto('<Plug>CleartoolCOUnres')
  map <unique> <script> <Plug>CleartoolCOUnres
        \ :call <SID>CtCheckout('<c-r>=expand("<cfile>", "u")<cr>')<cr>
endif

if !hasmapto('<Plug>CleartoolUnCheckout')
  map <unique> <script> <Plug>CleartoolUnCheckout
        \ :!cleartool unco -rm <c-r>=expand("<cfile>")<cr>
endif

if !hasmapto('<Plug>CleartoolListHistory')
  map <unique> <script> <Plug>CleartoolListHistory
        \ :call <SID>CtCmd("!cleartool lshistory ".expand("<cfile>"))<cr>
endif

if !hasmapto('<Plug>CleartoolConsolePredDiff')
  map <unique> <script> <Plug>CleartoolConsolePredDiff
        \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 1)<cr>
endif

if !hasmapto('<Plug>CleartoolConsoleBranch0Diff')
  map <unique> <script> <Plug>CleartoolConsoleBranch0Diff
        \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 2)<cr>
endif

if !hasmapto('<Plug>CleartoolConsoleBranchMergeDiff')
  map <unique> <script> <Plug>CleartoolConsoleBranchMergeDiff
        \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 3)<cr>
endif

if !hasmapto('<Plug>CleartoolConsoleQueryDiff')
  map <unique> <script> <Plug>CleartoolConsoleQueryDiff
        \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', 0)<cr>
endif

if !hasmapto('<Plug>CleartoolSetActiv')
  map <unique> <script> <Plug>CleartoolSetActiv
        \ :call <SID>SetActiv('<c-r>=expand("<cfile>")<cr>')<cr>
endif

if has("unix")
  if !hasmapto('<Plug>CleartoolConsoleLatestDiff')
    map <unique> <script> <Plug>CleartoolConsoleLatestDiff
          \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', '/main/LATEST')<cr>
  endif

  if !hasmapto('<Plug>CleartoolGraphVerTree')
    map <unique> <script> <Plug>CleartoolGraphVerTree
          \ :!xlsvtree <c-r>=expand("<cfile>")<cr> &
  endif
else
  if !hasmapto('<Plug>CleartoolConsoleLatestDiff')
    map <unique> <script> <Plug>CleartoolConsoleLatestDiff
          \ :call <SID>CtConsoleDiff('<c-r>=expand("<cfile>")<cr>', '\main\LATEST')<cr>
  endif

  if !hasmapto('<Plug>CleartoolGraphVerTree')
    map <unique> <script> <Plug>CleartoolGraphVerTree
          \ :!start clearvtree.exe <c-r>=expand("<cfile>")<cr>
  endif
endif
" }}}
" ===========================================================================
"                                 End of Maps
" ===========================================================================

"       On UNIX the vob prefix for directories is different from WinDoze.
" if has("unix")
"   let vob_prfx="/vobs/"
" else
"   let vob_prfx="./"
" endif

" Shortcuts for common directories
" cab  vabc    <c-r>=vob_prfx<cr>abc_directory

" ===========================================================================
"                                 Setup Menus
" ===========================================================================
" {{{
" Add Menus if available
if (has("gui_running") && &guioptions !~# "M") ||
  \ &wildmenu

  " These use the mappings defined above to accomplish the same means.
  " It saves on space and makes things easier to maintain.

  " Clearcase menu
  " Hint: Using <Tab> makes alignment easy (Menus can have non-fixed
  "       width fonts, so just spaces are out of the question.
  amenu 60.300 &Clearcase.Check&out\ (Reserved)<Tab>:ctco
        \ :ctco<cr>
  amenu 60.310 &Clearcase.Check&out\ Unreserved<Tab>:ctcou
        \ :ctcou<cr>
  amenu 60.320 &Clearcase.Check&in<Tab>:ctci
        \ :ctci<cr>
  amenu 60.330 &Clearcase.&Uncheckout<Tab>:ctunco
        \ :ctunco<cr>
  amenu 60.340 &Clearcase.&Make\ Element<Tab>:ctmk
        \ :ctmk<cr>

  amenu 60.400 &Clearcase.-SEP1-        :

  amenu 60.410 &Clearcase.&History<Tab>:cthist
        \ :cthist<cr>
  amenu 60.420 &Clearcase.&Describe<Tab>:ctdesc
        \ :ctdesc<cr>
  amenu 60.421 &Clearcase.&Current\ View<Tab>:ctpwv
        \ :ctpwv<cr>
  amenu 60.422 &Clearcase.&Show\ Comment<Tab>:ctcmt
        \ :ctcmt<cr>
  amenu 60.423 &Clearcase.&Change\ Comment<Tab>:ctchc
        \ :ctchc<cr>
  amenu 60.424 &Clearcase.&Annotate<Tab>:ctann
        \ :ctann<cr>
  amenu 60.430 &Clearcase.&Version\ Tree<Tab>:ctxlsv
        \ :ctxlsv<cr>

  if g:ccaseEnableUCM

    amenu 60.435 &Clearcase.-SEP2-        :

    amenu 60.440 &Clearcase.&List\ Current\ Activity<Tab>:ctlsc
          \ :ctlsc<cr>
    amenu 60.450 &Clearcase.&List\ Activities<Tab>:ctlsa
          \ :ctlsa<cr>
    amenu 60.460 &Clearcase.&Set\ Current\ Activity<Tab>:ctsta
          \ :ctsta<cr>
    amenu 60.470 &Clearcase.&Create\ New\ Activity<Tab>:ctmka
          \ :ctmka<cr>
    amenu 60.480 &Clearcase.&Open\ Clearprojexp :call <SID>CtOpenProjExp()<cr>
  endif

  amenu 60.500 &Clearcase.-SEP3-        :

  amenu 60.510 &Clearcase.Di&ff<Tab>:ctdiff
        \ :ctdiff<cr>
  amenu 60.511 &Clearcase.Diff\ this\ with\ &Pred<Tab>:ctpdif
        \ :ctpdif<cr>
  amenu 60.512 &Clearcase.Diff\ this\ with\ ver&0\ on\ branch<Tab>:ct0dif
        \ :ct0dif<cr>
  amenu 60.513 &Clearcase.Diff\ this\ with\ /main/&LATEST<Tab>:ctldif
        \ :ctldif<cr>
  amenu 60.514 &Clearcase.Diff:\ Changes\ need\ merge<Tab>:ctmdif
        \ :ctmdif<cr>
  amenu 60.515 &Clearcase.Diff\ this\ with\ &Queried\ Version<Tab>:ctqdif
        \ :ctqdif<cr>

  amenu 60.530 &Clearcase.-SEP4-        :

  amenu 60.540 &Clearcase.List\ Checkouts\ in\ this\ dir<Tab>:ctcoc
        \ :ctcoc<cr>
  amenu 60.550 &Clearcase.List\ Checkouts\ recurse\ dir<Tab>:ctcor
        \ :ctcor<cr>
  amenu 60.560 &Clearcase.List\ Checkouts\ in\ VOB<Tab>:ctcov
        \ :ctcov<cr>

  amenu 60.600 &Clearcase.-SEP5-        :

  amenu 60.600 &Clearcase.&Help<Tab>:h\ ccase :h ccase<cr>
endif
" }}}

" ===========================================================================
"                              Install Document
" ===========================================================================
" {{{
" Current revision:
let s:revision =
  \ substitute("$Revision: 1.38 $",'\$\S*: \([.0-9]\+\) \$','\1','')

" Install the document:
" NOTE: We must detect script name here. In a function, <sfile> will be
"       expanded to the function name instead!
silent! let s:install_status =
    \ s:InstallDocumentation(expand('<sfile>:p'), s:revision)

if (s:install_status == 0)
    echomsg expand("<sfile>:t:r") . ' v' . s:revision .
               \ ': Help-documentation installed.'
endif
" }}}

" ===========================================================================
"                      Beginning of Embedding Document
" ===========================================================================
" {{{
finish

=== START_DOC
*ccase.txt*	For Vim version 6.0 and up                           #version#
             LAST MODIFICATION: "Fri, 03 Sep 2004 16:25:08 (dp)"


		  VIM REFERENCE MANUAL    by Douglas Potts
Author:  Douglas L. Potts <pottsdl@NnetOzerSo.nPeAtM>
	  (remove NOSPAM from email first)

==============================================================================

Contents:
  |ccase-overview|      1. Overview
  |ccase-commands|      2. Commands
  |ccase-maps|          3. Normal Mode maps
  |ccase-menus|         4. Menus
  |ccase-options|       5. Options
  |ccase-thanks|        6. Recognition

==============================================================================

1. Overview			       *ccase-overview* *ccase-plugin* *ccase*

Similar to the various RCS and CVS menu plugins available on
http://vim.sourceforge.net, this plugin deals with version control.
Specifically it is written to interact with Rational's ClearCase version
control product (not a plug, it is just what I've been using for my last two
places of employment).

There are three parts to this plugin:
  1. Command Mode abbreviations (see also |:cabbrev|)
  2. Normal Mode mappings       (see also |:nmap|)
  3. Menus for commands

The functionality mentioned here is a plugin, see |add-plugin|.  This plugin
is only available if 'compatible' is not set.  You can avoid loading this
plugin by setting the "loaded_ccase" variable in your |vimrc| file: >
	:let loaded_ccase = 1

{Vi does not have any of this}

==============================================================================
2. Commands                                                   *ccase-commands*

Common Commands:~
                                                                       *:ctco*
Checkout out the current file (default is checkout reserved).  This will
prompt for a checkout comment depending on the value of |g:ccaseNoComment|.

                                                                      *:ctcou*
Checkout out the current file unreserved.  This will prompt for a checkout
comment depending on the value of |g:ccaseNoComment|.

                                                                       *:ctci*
Check in the current file.  This will prompt for a checkin comment depending
on the value of |g:ccaseNoComment|.

                                                                       *:ctmk*
Make the current file a VOB element.  This will, depending on the value of
|g:ccaseNoComment|, prompt for a checkout comment (for the directory of the
new element, if the directory has not already been checked out), a element
creation comment for the file, and prompt for a directory checkin comment
depending on the value of |g:ccaseLeaveDirCO|.

                                                                     *:ctunco*
Un-checkout the current file.  Utilizes the behavior of the ClearCase(R)
"cleartool uncheckout" command to prompt the user for whether or not to copy
the view private version to a .keep file.

                                                                     *:ctcoc*
List the checkouts for the current user, for this view, in the current working
directory.

                                                                      *:ctcor*
List the checkouts for the current user, for this view, in the current working
directory, and all of it's subdirectories.  This redirects the output from the
"cleartool lsco" command to a results file, and splits the window, and opens
the results file in that new window.  The results will be in a special,
non-modifiable buffer named '[checkouts_recurse]'.  While this buffer is open,
the |BufEnter| |autocmd| will cause the window to update for any check in/out
activity that has occurred (within its scope), since it was opened.
This autocmd update mechanism will be a part of the ccase |augroup|.

                                                                      *:ctcov*
List the checkouts for the current user, for this view, in any VOB.  This
redirects the output from the "cleartool lsco" command to a results file, and
splits the window, and opens the results file in that new window.  The results
will be in a special, non-modifiable buffer named '[checkouts_allvobs]'.  While
this buffer is open, the |BufEnter| |autocmd| will cause the window to update
for any check in/out activity that has occurred (within its scope), since it
was opened.
This autocmd update mechanism will be a part of the ccase |augroup|.



Uncommon Commands:~
                                                                     *:cthist*
List the version history for the current file.  This redirects the output from
the "cleartool lshist" command to a results file, and splits the window, and
opens the results file in that new window.

                                                                     *:ctdesc*
Lists the element description for the current file.  This redirects the output
from the "cleartool describe" command to a results file, and splits the
window, and opens the results file in that new window.

                                                                      *:ctpwv*
Echo the current working view to the status line.

                                                                      *:ctcmt*
Show comment for the current file.

                                                                      *:ctann*
This command lists the contents of the current file, annotating each line to
indicate which developer added that line, and in which version the line was
added. A summary of each version of the file will also be included.

                                                                     *:ctxlsv*
Spawn off the ClearCase(R) xlsvtree (graphical version tree viewer) for the
current file.

                                                                     *:ctdiff*
Spawn off the clearcase graphical diff tool to display differences between the
current file and its immediate predecessor.

                                                                     *:ctpdif*
Compare the current file to its predecessor version using |:diffsplit|.
Depending on the value of |g:ccaseDiffVertSplit|, the split will be vertical
or horizontal.

                                                                     *:ct0dif*
Compare the current file to its first version on the same branch using
|:diffsplit|. Depending on the value of |g:ccaseDiffVertSplit|, the split will
be vertical or horizontal.

                                                                     *:ctldif*
Compare the current file to its "/main/LATEST" version using |:diffsplit|.
Depending on the value of |g:ccaseDiffVertSplit|, the split will be vertical
or horizontal.

                                                                     *:ctmdif*
Compare the current file to its closest common ancestor version with
"/main/LATEST" using |:diffsplit|. This should contain changes made on the
current branch that have not been merged to the main branch.

This command is used to support the concurrent development model where
developers made changes on their private branches. Those changes will been
merged back into the main branch after unit testing. This command will show
latest changes you made on your private branch that has not been merged back
into the main branch.

Depending on the value of |g:ccaseDiffVertSplit|, the split will be vertical
or horizontal.

                                                                     *:ctqdif*
Perform a |:diffsplit| on a queried predecessor version of the current file.
Depending on the value of |g:ccaseDiffVertSplit|, the split will be vertical
or horizontal.


                                                                   *ccase-UCM*
ClearCase(R) Unified Change Management extensions (UCM)~
ClearCase(R) has a software extension called UCM that assists in the creation
of version branches, version synchronization, and program baselining.

                                                                      *:ctlsc*
Echo the current working/default UCM activity to the status line.

                                                                      *:ctlsa*
List all of the UCM activities for this view.  This redirects the output from
the "cleartool lsactivty" command to a results file, and splits open a new
window containing these results.  It is then possible to double click (or do
|<Leader>ctsta| on one of the activities to set the current activity.

                                                                      *:ctsta*
Set the current working/default UCM activity.

                                                                      *:ctmka*
Make a new UCM activity, prompting the user for the activity identifier.
And depending on the value of |g:ccaseSetNewActiv|, will set the current
activity to the newly created one.

==============================================================================

3. Normal Mode maps                                               *ccase-maps*

The Normal Mode maps utilize the |<Leader>| character for maps which provide
provide the same functionality as their Command equivalents, except that they
take the filename under the cursor as the file that they operate on.  This is
very useful if you do a checkout listing that returns a text file list.  You
can then put the cursor on one of the filenames in the list, and perform a
check in operation on that file.

                                                                *<Leader>ctci*
Performs a check in operation on the filename under the cursor.  See |:ctci|
for the operational details of what the |ccase-plugin| does for a file check
in.

                                                               *<Leader>ctcor*
Performs a reserved check out operation on the filename under the cursor.  See
|:ctco| for the operational details of what the |ccase-plugin| does for a file
check out.

                                                               *<Leader>ctcou*
Performs an unreserved check out operation on the filename under the cursor.
See |:ctcou| for the operational details of what the |ccase-plugin| does for a
file check out.

                                                              *<Leader>ctunco*
Performs an uncheckout operation on the filename under the cursor.  See
|:ctunco| for the operational details of what the |ccase-plugin| does for a
unchecking out a file.

                                                              *<Leader>cthist*
Performs a list history operation on the filename under the cursor.  See
|:cthist| for the operational details of what the |ccase-plugin| does for a
listing of version history.

                                                                *<Leader>ctxl*
Performs a open element version tree  operation on the filename under the
cursor.  See |:ctxlsv| for the operational details of what the |ccase-plugin|
does for a version tree listing of version history.

                                                              *<Leader>ctpdif*
Performs a "diff with previous version" operation on the filename under the
cursor.  See |:ctpdif| for the operational details of what the |ccase-plugin|
does for diff'ing against the file's predecessor version.

                                                              *<Leader>ct0dif*
Performs a "diff with first version on the same branch" operation on the
filename under the cursor.  See |:ct0dif| for the operational detail.

                                                              *<Leader>ctldif*
Performs a "diff with /main/LATEST" operation on the filename under the
cursor.  See |:ctldif| for the operational detail.

                                                              *<Leader>ctmdif*
Performs a "show changes need merge" operation on the filename under the
cursor.  See |:ctmdif| for the operational detail.

                                                              *<Leader>ctqdif*
Performs a diff with queried operation on the filename under the cursor.  See
|:ctqdif| for the operational details of what the |ccase-plugin| does for
diff'ing against a queried predecessor to the file.

                                                               *<Leader>ctsta*
Set the working UCM activity to be the activity currently under the cursor.
See |:ctsta| for the operational details of what the |ccase-plugin| does for
setting a ClearCase activity.

==============================================================================

4. Menus                                                         *ccase-menus*

All of the commands listed in Section 2, are available via the Clearcase menu
which is added to the main menu line.  They are available on the GUI enabled
versions (obviously) and on console versions via |:emenu| and |'wildmenu'|.

==============================================================================

5. Options						       *ccase-options*

The ccase-plugin provides several variables that modify the behavior of the
plugin.  Each option has a default value provided within the plugin, for use
if the user has not provided a value in his or her |vimrc| file.  Below is a
listing of these options with their default values, and a short description of
what they do.  The format for changing the behavior from the default is: >
  <your .vimrc>
  .
  .
  let g:ccaseUseDialog=0	" Don't use dialog boxes
  .
  .

Or for a temporary change, from the command line: >
  :let ccaseUseDialog=0
~
                                                              *g:ccaseTmpFile*
String         		(Unix default:          "/tmp/results.txt"
			 Windows/DOS default:   "c:\temp\results.txt")

As of version 1.25, this setting is obsolete.  The plugin now uses the
built-in Vim function tempname to generate the name for the output capture
file, and that is now read into a "ccase_results" special buffer.

                                                            *g:ccaseUseDialog*
Integer boolean		(default for gvim:  1=Use a dialog box for input,
			 default for vim:   0=Use other input method)

If you are running the graphical version of VIM, You have the option of
getting a graphical dialog box for interactions with the plugin.  Mainly for
the purpose of querying about checkout or checkin comments.  Don't worry if
you are running the console version as you are still prompted, just not via a
dialog box.  In fact, with the non-dialog box you can use the arrow keys to go
back in the input history to reuse earlier entries.

                                                            *g:ccaseNoComment*
Integer boolean		(default:  0=Ask for comments)

ClearCase allow for providing checkout and checkin comments per file.  If you
don't use this comment functionality, and don't want to be prompted for it
upon file checkout or checkin, then set g:ccaseNoComment=1.

                                                        *g:ccaseDiffVertSplit*
Integer boolean		(default:  1=Split window vertically for diffs)

When performing a diff with another version, it is possible to split the
window vertically or horizontally.  The default is to split the window
vertically in two and diff the two files.

                                                             *g:ccaseAutoLoad*
Integer boolean		(default:  1=Automatically reload file upon checkin or
				     checkout)

Upon checkout or checkin, the permissions on the file that you are working on
change.  With g:ccaseAutoLoad=1, the file is reloaded after the checkin or
checkout operation completes.  If you do not want to reload the file upon
checkout or checkin, set g:ccaseAutoLoad=0.

                                                     *g:ccaseMkelemCheckedout*
Integer boolean		(default:  0=Make an element, and don't check them out)

When editting a file, and then making that file a ClearCase(R) element, it is
possible to create the element (which is then considered checked in), or have
the element checked out once it has been added as an element.

                                                           *g:ccaseLeaveDirCO*
Integer boolean		(default:  0=When checking out a directory to add an
                                   element to, don't check the directory back
                                   in)

When making an existing file an element, the directory, in which it is been
made an element of, must be checked out.  The plugin checks to see whether or
not the directory is in fact checked out, and if it is not checkout out,
prompts the user to check out the directory.  After the file has been made an
element, the directory can remain checked out (to add other elements) or
checked back in.  If g:ccaseLeaveDirCO=0, the user will be prompted whether or
not the directory should be checked back in.  When g:ccaseLeaveDirCO=1, the
user is not prompted to check the directory back in.

                                                          *g:ccaseSetNewActiv*
Integer boolean		(default:  1=When making an new activity, set the
                                   current activity to be the newly made one.)

When using the make activity function, the default ClearCase behavior (which
is also the default for ccase.vim) is to change the current working activity
to the newly made activity.  This option determines whether or not you want to
automatically switch to the newly created activity, or that you have to do the
switch manually.

                                                               *g:ccaseJustMe*
Integer boolean		(default:  1=List checkout for the current user only.)

When listing checkout elements, you can use this option to control whether
list checkouts for the current user only (g:ccaseJustMe = 1), or list
checkouts for all users (g:ccaseJustMe = 0).

                                                   *g:ccaseAutoRemoveCheckout*
Integer boolean		(default:  0=Prompt the user whether to remove the
                                   checkout file or not.)

When unchecking out a file, the default ClearCase behavior is to ask user
whether removing the checked out file or not. This option determines whether
you want to remove the checked out automatically or not. If it is set to 1,
the checked out file will be automatically removed.

                                                            *g:ccaseEnableUCM*
Integer boolean		(default:  1=Enable UCM support.)

Set this to 0 if your clearcase installation has no UCM support. This will
take out a few UCM related menu items to make the menu shorter.

==============================================================================

6. Recognition                                                  *ccase-thanks*

I just wanted to say thanks to several Vimmers who have contributed to this
script, either via script code I've re-used from their scripts, those who use
and have given suggestions for improvement to the ccase.vim script, and those
who have actually gone so far as to actually give a good hack at it and send
me patches, I truly appreciate all of your help, and look forward to your
future comments and assistance.

There have been many, so if I've forgotten your contribution, it isn't meant
as a slight, just let remind me and I'll add you to the list.

Bram Moolenaar          - First and foremost, the vimboss himself.
Benji Fisher            - For a lot of help during my early vim days.
Dr. Charles Campbell,Jr.- For endless inspiration in the multitude of Vim
                          uses.
Barry Nisly             - Patch for having an unreserved checkout menu item
                          and map.
Gerard van Wageningen   - Suggestions on the 'compatible' settings for
                          ccase.vim, and on using /tmp as the tempfile
                          directory, as well as use of the GUI prompt box for
                          check in/out comments.
Gary Johnson            - Patches fixing filename escaping for spaces and
                          mechanism to determine the filetype for a file
                          opened as a specific clearcase version (ie. with the
                          @@ specifier).
                          Many other good ideas on allowing a editted file
                          based check in/out comment source, and changes to
                          allow checkout of a file after you have already
                          started editting it WITHOUT the warnings.
Jan Schiefer            - Suggestions to accomodate users with 'Snapshot'
                          views.  I'm still working on this one Jan. :)
Guillaume Lafage        - for patches allowing sym-linked and Windows shortcut
                          linked file resolution.

And many others...

==============================================================================
=== END_DOC
" }}}
" ===========================================================================
"                         End of Embedding Document
"                       NOTE: NO CODE AFTER THIS LINE
" ===========================================================================

" Mode line for embeding documents & code:
" v im:tw=78 ts=8 ft=help fdm=marker norl:
" vim:tw=78 nowrap fdm=marker shiftwidth=2 softtabstop=2 smartindent smarttab :
