"------------------------------------------------------------------------------
" This plugin enables easy integration with quilt, to push/pop/refresh patch   
"                                                                              
" Author:     Florian Delizy <florian.delizy@unfreeze.net>                     
" Maintainer: Florian Delizy <florian.delizy@unfreeze.net>                     
"                                                                              
" Install:                                                                     
" uncompress in your .vim/ directory, then :helptag ~/.vim/doc to get the help 
"                                                                              
" Usage:                                                                       
" :help quilt-usage                                                            
"                                                                              
"------------------------------------------------------------------------------
" ChangeLog:                                                                   
" :help quilt-changelog                                                        
"                                                                              
" License:                                                                     
" This code is GPL v2.0, please go to www.gnu.org to get a full copy of the GPL
"                                                                              
"------------------------------------------------------------------------------
"                                                                              
" TODO:                                                                        
"                                                                              
" * an interface showing the current patch on the bottom                       
"   - allow fold/unfold to see what files are included                         
" * auto add the currently modified file                                       
" * auto refresh on change                                                     
" * add an indication to know if the patch needs refresh or not                
" * prevent the writing if the file is in no patch (without the ! option)      
" * add an info to show to which patch belong a chunk                          
" * quilt merge, import ... and stuffs (is somebody using it ??)               


"------------------------------------------------------------------------------
" Commands definition                                                          
"------------------------------------------------------------------------------
let cpocopy=&cpo | set cpo-=C

command! QuiltCheckRej call <SID>QuiltCheckRej()
command! QuiltStatus call <SID>QuiltStatus()

autocmd! BufNewFile,BufReadPost,FileReadPost * QuiltStatus
autocmd! BufReadPost,FileReadPost * QuiltCheckRej

autocmd BufNewFile,BufReadPost * QuiltStatus
autocmd BufReadPost * QuiltCheckRej

command! -nargs=? -complete=custom,QuiltCompleteInPatch
       \ QuiltPatchEdit call <SID>QuiltPatchEdit( <f-args> )

command! -nargs=? -bang -complete=custom,QuiltCompleteInAppliedPatch   
       \ QuiltPop  call <SID>QuiltPop("<bang>", <f-args>)
command! -bang QuiltPopAll call <SID>QuiltPopAll( "<bang>" )
command! -nargs=? -bang -complete=custom,QuiltCompleteInUnAppliedPatch 
       \ QuiltPush call <SID>QuiltPush("<bang>", <f-args>)
command! -bang QuiltPushAll call <SID>QuiltPushAll( "<bang>" )
command! -nargs=? -bang -complete=custom,QuiltCompleteInPatch          
       \ QuiltGoTo call <SID>QuiltGoTo("<bang>", <f-args>)

command! -nargs=* -complete=custom,QuiltCompleteForAdd
       \ QuiltAdd call <SID>QuiltAdd(<f-args>)
command! -nargs=? -complete=custom,QuiltCompleteInFiles                
       \ QuiltRemove call <SID>QuiltRemove(<f-args>)
command! -nargs=+ -complete=custom,QuiltCompleteForRemoveFrom
       \ QuiltRemoveFrom call <SID>QuiltRemoveFrom(<f-args>)

command! -nargs=? -bang -complete=custom,QuiltCompleteInPatch          
       \ QuiltRefresh call <SID>QuiltRefresh("<bang>", <f-args> )

command! -range -nargs=1 -bang -complete=custom,QuiltCompleteInPatch   
       \ QuiltMoveTo <line1>,<line2>call <SID>QuiltMoveTo( "<bang>", <f-args> )
command! -bang QuiltFinishMove call <SID>QuiltFinishMove( "<bang>" )

command! -nargs=1 -complete=dir -bang                                  
       \ QuiltSetup call <SID>QuiltSetup( "<bang>", <f-args> )

command! -nargs=+ -bang -complete=custom,QuiltCompleteInPatchesDir
       \ QuiltNew call <SID>QuiltNew( "<bang>", <f-args> )

command! -nargs=? -bang -complete=custom,QuiltCompleteInPatch
       \ QuiltDelete call <SID>QuiltDelete( "<bang>", <f-args> )


command! -nargs=? -complete=custom,QuiltCompleteInPatch
       \ QuiltFiles call <SID>QuiltFiles( <f-args> )
command! -nargs=? -complete=file QuiltPatches call <SID>QuiltPatches(<f-args>)

command! -nargs=+ -complete=custom,QuiltCompleteForMail
       \ QuiltMail call <SID>QuiltMail( <f-args> )

command! -nargs=+ -complete=custom,QuiltCompleteInPatch
       \ QuiltRename call <SID>QuiltRename( <f-args> )

command! -nargs=? -complete=custom,QuiltCompleteInPatch
       \ QuiltHeader call <SID>QuiltHeader( <f-args> )

command! -nargs=? -complete=file -bang
       \ QuiltAnnotate call <SID>QuiltAnnotate( "<bang>", <f-args> )

" Provide defaults for variables

if !exists( "g:QuiltSubject" )
    let g:QuiltSubject = '[patch @num@/@total@] @name@'
endif

if !exists( "g:QuiltMailSleep" )
    let g:QuiltMailSleep = 1
endif

if !exists( "g:QuiltLang" )
    let g:QuiltLang = 'en_us'
endif

if !exists( "g:QuiltMailAddresses" )
    let g:QuiltMailAddresses = [ 'test@localhost.com' ]
endif

if !exists( "g:QuiltAnnotateFollowLine" )
    let g:QuiltAnnotateFollowLine = 1
endif

if !exists( "g:QuiltThunderbirdCmd" )
    let g:QuiltThunderbirdCmd = "thunderbird"
endif
" Opens an interface with the quilt annotate informations :

function! <SID>QuiltAnnotate( bang, ... )
    let currentLine = line( "." )

    let DoCursor = 0
    if exists( "g:QuiltAnnotateFollowLine" ) && g:QuiltAnnotateFollowLine 
	let DoCursor = 1
    endif

    let cmd = "quilt annotate "

    if 0 == a:0
	if ""== expand( "%" )
	    echohl ErrorMsg
	    echo "No file specified, and no file opened ... sorry "
	    echohl none
	    return 
	endif
	let cmd = cmd . expand( "%" )
    else
	if a:bang != "!" && &modified
	    echohl ErrorMsg
	    echo "Current file not saved, use ! to force"
	    echohl none
	    return
	endif
	let cmd = cmd . a:1
	edit a:1
    endif


    let out = system( cmd )

    if 0 != v:shell_error
	echohl ErrorMsg
	echo out
	echohl None
	return
    endif

    0

    " Create the patch number window
    vnew
    setlocal wiw=3
    wincmd H
    wincmd l
    wincmd |
    wincmd h
    autocmd BufUnload <buffer> call <SID>QuitAnnotateJ()

    " Create the patch name window
    new
    wincmd J
    wincmd k
    wincmd _
    wincmd j
    autocmd BufUnload <buffer> call <SID>QuitAnnotateH()

    " Parse the result

    let lines = split( out, '\n' )
    let numbers = []
    let patches = []

    " retreive line numbers
    for i in range(0, len(lines) - 1)
	if empty(lines[i])
	    break
	endif
	call add( numbers, substitute(substitute( lines[i], '^\([0-9]\+\|\t\).*$', '\1', 'g' ), '\t', ' ', 'g' ) )
    endfor
    
    " now retreive patch names
    let i = i + 1
    for i in range( i, len(lines) - 1)
	call add( patches, lines[i] )
    endfor

    " Append the result ... 

    wincmd j

    call append( 0, patches )
    setlocal nomodified
    setlocal nomodifiable
    set noscrollbind
    if DoCursor
        setlocal cursorline
    endif
    0
    resize 5

    wincmd k
    wincmd h

    call append( 0, numbers )
    setlocal nomodified
    setlocal nomodifiable
    0
    set scrollbind

    if DoCursor
        setlocal cursorline
    endif

    wincmd l
    set scrollbind

    exec currentLine
    
    redraw!
    if DoCursor
	setlocal cursorline
        autocmd CursorMoved <buffer>  call <SID>FollowCursorLine()
    endif

endfunction


" Autocmd used to follow the cursor

function! <SID>FollowCursorLine()
    let ln = line( "." )
    wincmd h
    exec ln
    let ln = getline( "." )
    wincmd j
    exec ln
    redraw
    wincmd k
    wincmd l
    redraw!
endfunction

" used to quit the buffer annotate mode

function! <SID>QuitAnnotateJ()
    wincmd j
    quit
    wincmd k
    wincmd l
    autocmd! CursorMoved <buffer> 
    setlocal nocursorline

function! <SID>QuitAnnotateH()
    wincmd k
    quit
    wincmd l
    autocmd! CursorMoved <buffer> 
    setlocal nocursorline

endfunction
endfunction

" Open the patch in a new tab regarding it's name

function! <SID>QuiltPatchEdit( ... )

    if !<SID>IsQuiltDirectory() 
	return
    endif

    if 1 == a:0
	let patch = "patches/" . a:1
    else
	let patch = "patches/" . g:QuiltCurrentPatch 
    endif

    exec "tabedit ". patch
endfunction


" Create the header view window ... (tabedit)
function! <SID>QuiltHeader( ... )
    let cmd = "quilt header "
    if 1 == a:0
	let cmd = cmd . a:1
    endif

    " Get the header

    let header = system( cmd )
    if ( v:shell_error != 0 )
	echohl ErrorMsg
	echo substitute( ret . "\n$", "", "" )
	echohl none
	return
    endif

    tabedit

    call <SID>QuiltStatus()


    " Add a default subject line

    if "" == header
	let header = "Subject: " . g:QuiltSubject . "[Enter your subject line here]\n"
    endif

    
    " Print the header in the buffer
    
    call append( 0, split( header, "\n" ) )

    setlocal nomodified
    exec "setlocal spell spelllang=".g:QuiltLang

    if 1 == a:0
	let b:QuiltHeaderName = a:1
    else
	let b:QuiltHeaderName = g:QuiltCurrentPatch
    endif

    setlocal statusline=%0.70(%{b:QuiltHeaderName}\ hdr%m\ :w=:QuiltW%)\ %=%0.10(%l,%c\ %P%)

    

    command! -buffer QuiltWriteHeader call <SID>QuiltWriteHeader()
    redraw
    echohl MoreMsg
    echo "Now, just :QuiltWriteHeader to write the header"
    echohl none
    

endfunction


" This function is the counter part of the :QuiltHeader cmd
function! <SID>QuiltWriteHeader()
    let cmd = "quilt header -r "
    if "" != b:QuiltHeaderName 
	let cmd = cmd . b:QuiltHeaderName
    endif

    $
    let end = winline()

    let theFile = substitute( join( getline( 0, end ), "\n" ), '"', '\"', "g" )

    let theCmd = 'echo "' . theFile . '" | ' . cmd

    setlocal nomodified
    call <SID>DoSystem( theCmd )

endfunction



" Execute the command and output its result with correct colouring 

function! <SID>DoSystem( cmd )

    let ret = system( a:cmd . " 2>&1" )
    if v:shell_error != 0
        echohl ErrorMsg
    else
        echohl MoreMsg
    endif
    echo substitute( ret, "\n$", "", "" )
    echohl none

endfunction


" Rename a patch 
function! <SID>QuiltRename( ... )

    let cmd = "quilt rename "
    if a:0 == 2
	let cmd = cmd . "-P " . a:1 . " " . a:2
    else
	let cmd = cmd . a:1
    endif

    call <SID>DoSystem( cmd )
    call <SID>QuiltStatus()

endfunction



" Prepare a mail with the given patches

function! <SID>QuiltMail( dest, ... )

    if a:dest !~ '@'
	echohl ErrorMsg
	echo 'First argument must be an email address'
	echohl none
	return 0
    endif

    let allpatches = split( <SID>ListAllPatches(), "\n" )

    " filter patches

    if a:0 > 0
        
        " if only one argument, send only one patch ... 
        if a:0 == 1

            let i = index( allpatches, a:1 )

            if -1 == i
                echohl ErrorMsg
                echo "Can't find " . a:1 . " in the patch list"
                echohl none
                return 0
            endif
            
            let firstPatch = i
            let lastPatch = i

        else
        " else send a range of patches
            
            " find the first patch
            let firstPatch =  index( allpatches, a:1 )

            if -1 == firstPatch
                echohl ErrorMsg
                echo "Can't find " . a:1 . " in the patch list"
                echohl none
                return 0
            endif

            " get the last patch

            let lastPatch =  index( allpatches, a:2 )

            if -1 == lastPatch
                echohl ErrorMsg
                echo "Can't find " . a:2 . " in the patch list"
                echohl none
                return 0
            endif

            " check the range
            
            if firstPatch > lastPatch
                echohl WarningMsg
                echo a:1 . " is applied after " . a:2 . " => reverting order"
                echohl none

                let tmp = lastPatch
                let firstPatch = lastPatch
                let lastPatch = tmp
            endif

        endif

    else
        " No argument, send them all
        
        let firstPatch = 0
        let lastPatch = len( allpatches ) - 1
    endif

    " Filter with first and last patch

    let filteredPatches = []

    for idx in range( firstPatch, lastPatch )
        call add( filteredPatches, allpatches[idx] )
    endfor

    " Now for each mail, open a thunderbird window : (open it in reverse order
    " so that the first on the screen is the first patch                      

    for idx in range( len( filteredPatches ) - 1, 0, -1)
	let headers = system( "quilt header " . filteredPatches[ idx ] )
	
	let headers = substitute( headers,'@num@',idx + 1, 'g' )
	let headers = substitute( headers,'@total@',len( filteredPatches),'g')
	let headers = substitute( headers,'@name@',filteredPatches[idx],'g')

	if headers =~ '\<Subject:'
	    let subject = substitute( headers, '.*\<Subject:', '', '')
	    let subject = substitute( subject, '\n.*', '', '')
	    let headers = substitute( headers, "Subject:[^\n]*\n", '', '' )
	else
	    let subject = g:QuiltSubject
	    let subject = substitute( subject,'@num@',idx + 1, 'g' )
	    let subject = substitute( subject,'@total@',len( filteredPatches),'g')
	    let subject = substitute( subject,'@name@',filteredPatches[idx],'g')
	endif


	call <SID>ThunderBirdMail( a:dest, subject, headers, 'patches/' 
		  \	         . filteredPatches[idx] )
	exec 'sleep ' . g:QuiltMailSleep
    endfor


    " Now create a mail for each of those guys

endfunction


function! <SID>ThunderBirdMail( dest, subject, body, ... )

    let attachment = ''

    if a:0 > 0
	for x in range( 1, a:0 )

	    if a:{x} =~ '^/'
		let filename = a:{x}
	    else
		let filename = getcwd() . '/' . a:{x}
	    endif

	    let attachment = attachment . ',attachment=file://' . filename

	endfor

    endif


    let cmd = g:QuiltThunderbirdCmd . ' -compose '

    let cmd = cmd . "'"

    let cmd = cmd . 'to=' . <SID>TBEscapeStr( a:dest )
    let cmd = cmd . ',subject=' . <SID>TBEscapeStr( a:subject )
    let cmd = cmd . ',body=' . <SID>TBEscapeStr( a:body )
    
    let cmd = cmd . attachment

    let cmd = cmd . "'"

    if has('unix')
	let cmd = cmd . ' &'
    endif

    call system( cmd )

endfunction

"                                                                              
" Escape a string to fit the Thundebird command line                           
"                                                                              
function! <SID>TBEscapeStr( str )

    let result = a:str
    let result = substitute( result, ',',  '%2c', 'g' )
    let result = substitute( result, '"',  '%22', 'g' )
    let result = substitute( result, "'",  '%27', 'g' )
    let result = substitute( result, "&",  '%26', 'g' )
    let result = substitute( result, "?",  '%3f', 'g' )
    return result

endfunction


"                                                                              
" List files contained in a patch                                              
"                                                                              

function! <SID>QuiltFiles( ... )
    if <SID>IsQuiltDirectory() == 0 
        return 0
    endif

    let cmd= "quilt files "

    if a:0 == 1

        let cmd = cmd . a:1

    endif

    let fileList = split( system( cmd . " 2>&1" ), "\n" )
    let cexprList = []
    let i = 0
    while i < len( fileList )

	if "" != glob( fileList[i] . ".rej" )
	    call add( cexprList, fileList[i] . ':0: error: is included in the patch but has a .rej' )
	else
	    call add( cexprList, fileList[i] . ':0: is included in the patch ' )
	endif

        let i = i + 1
    endwhile

    cexpr cexprList
 
endfunction

"                                                                              
" List all patches modifying the file                                          
"                                                                              

function! <SID>QuiltPatches( ... )

    let patches = split( <SID>ListAllPatches(), "\n" )

    let i = 0

    if a:0 == 1
        let thefile = a:1    
    else 
        let thefile = expand( "%" )
    endif

    if thefile == ''
        echohl ErrorMsg
        echo "No file specified, and no file opened ..."
        echohl none
        return 0
    endif

    while i < len( patches )
        if <SID>ListAllFiles( patches[i] ) =~ thefile
            echo patches[i]
        endif

        let i = i + 1
    endwhile

endfunction

"                                                                              
" Create a new patch on the top of the patch stack                             
" ! create the directory if not existing                                       
"                                                                              

function! <SID>QuiltNew( bang,  patch )

    if <SID>ListAllPatches() =~ a:patch
       echohl ErrorMsg
       echo "there is already a patch called " . a:patch
       echohl none
       return 0
    endif

   " Make sure that the directory exists ... 
 
   if a:patch =~ "/$"
       echohl ErrorMsg
       echo "the patch name can not end with a /"
       echohl none
   endif

   if a:patch =~ "/"

       let dir = substitute( a:patch, "/[^/]*$", "", "g" )

       if isdirectory( "patches/" . dir ) == 0

           if a:bang == "!"

               echo "Creating " . dir "/"
               call mkdir( "patches/" . dir , "p" )

           else

               echohl ErrorMsg
               echo "Directory " . dir . " does not exists, use ! to create it"
               echohl none
               return 0
           endif
    

       endif

   endif

   call system ( "quilt new " . a:patch )

   call <SID>QuiltStatus()

endfunction

"                                                                               
" Create a new patch on the top of the patch stack                              
" ! : remove the file on the patch directory as well (-r)                       
"                                                                               

function! <SID>QuiltDelete( bang, ... )

    let cmd = "quilt delete "

    if a:bang == "!"

        let cmd = cmd  . " -r "

    endif

    if a:0 == 1

        call <SID>QuiltCurrent()
        if g:QuiltCurrentPatch != a:1 && <SID>ListUnAppliedPatches() !~ a:1

            echohl ErrorMsg
            echo "quilt only knows how to delete the topmost patch or an "
               \ . "unapplied patch ... fist unapply the patch before deleting"
               \ . " it "
            echohl none

        endif

        let cmd = cmd . a:1

    endif
 
    call <SID>DoSystem( cmd )
    call <SID>QuiltStatus()

endfunction

"                                                                              
" Setup a link to the patch directory, supplied as argument                    
" check that the 'series file exist, and try to find it, if found,             
" link it into the patch directory as well                                     
" <bang> is erase previous patches/series files before proceeding              
" if not found, the series file is created empty                               
"                                                                              

function! <SID>QuiltSetup( bang, patchdir )

    if <SID>IsQuiltOK() && a:bang != "!"

        echohl WarningMsg
        echo "This is already a valid quilt sandbox, use ! to recreate it"
        echohl none
        return

    endif
    " Cleanup an already existing

    if a:bang == "!"

        if   <SID>FileExists( "patches" )
        \ && system( "file patches 2>&1" ) =~ "symbolic link"

            echo "Removing existing patches link"
            call delete( "patches" )

        endif

    endif

    if <SID>FileExists( "patches" )

        echohl ErrorMsg
        echo "Can't remove an existing file, use ! to override"
        echohl none
        return 0

    endif

    " Check if the directory argument exists ?

    if   <SID>FileExists( a:patchdir ) == 0

        if a:bang == "!"

            call mkdir( a:patchdir )

        else

            echohl ErrorMsg
            echo a:patchdir . " Does not exists ... use ! to create it too"
            echohl none
            return 0

        endif

    endif

    call system( "ln -s " . a:patchdir . " patches" )

    if   filereadable( "series" ) == 0
    \ && filereadable( "patches/series" ) == 0
    \ && filereadable( ".pc/series" ) == 0
        
        " Series file does not exists ?? => create it
 
        let series = 
          \ [ '# quilt series files, automatically created by quilt.vim plugin'
          \ , '# Created on the ' . strftime( "%c" ) ]

        call writefile( series, "patches/series" )

    endif

endfunction


"                                                                              
" Pop the current patch                                                        
"                                                                              

function! <SID>QuiltPop( bang, ... )
    
    if <SID>IsQuiltDirectory() == 0 
        return 0
    endif


    let cmd= "quilt pop "

    if a:0 == 1
        let cmd = cmd . a:1
    endif

    if a:bang == "!"
        let cmd = cmd . " -f "
    endif
    
    if a:bang != '!'
	let ret = system( cmd )
	let lines =  split( ret, "\n" )
	let lastLine = lines[ len(lines) - 1 ]
	call remove( lines, len(lines) - 1 )
	echo join( lines, "\n" )
	
	if v:shell_error != 0
	    echohl ErrorMsg
	    let lastLine = lastLine . " (:QuiltPop! to force)" 
	else
	    echohl MoreMsg
	endif
	echo lastLine 
	
	echohl none
    else
	let ret = system( cmd )
	if ret =~ "FAILED"
	    call <SID>CreatePushPopWarning( ret )
	    echohl WarningMsg
	else
	    echohl MoreMsg
	endif

	let lines =  split( ret, "\n" )
	echo lines[ len(lines) - 1 ]
	echohl none
    endif


    call <SID>QuiltStatus()

endfunction


"                                                                              
" Pushes all patches of the current stack                                      
"                                                                              

function! <SID>QuiltPushAll( bang )

    if <SID>IsQuiltDirectory() == 0
	return 0
    endif

    let cmd = "!quilt push -a "

    if a:bang == "!"
        let cmd = cmd . " -f "
    endif

    exec cmd

    call <SID>QuiltStatus()

endfunction

"                                                                              
" Pop all patches of the series                                                
"                                                                              
function! <SID>QuiltPopAll( bang )

    if <SID>IsQuiltDirectory() == 0
	return 0
    endif

    let cmd = "!quilt pop -a "

    if a:bang == "!"
        let cmd = cmd . " -f "
    endif

    exec cmd

    call <SID>QuiltStatus()

endfunction

"                                                                              
" Push to the next patch                                                       

function! <SID>QuiltPush( bang, ... )

    if <SID>IsQuiltDirectory() == 0 
        return 0
    endif

    let cmd= "quilt push "

    if a:0 == 1
        let cmd = cmd . a:1
    endif

    if a:bang == "!"
        let cmd = cmd . " -f "
    endif

    if a:bang != '!'
	let ret = system( cmd )
	let lines =  split( ret, "\n" )
	let lastLine = lines[ len(lines) - 1 ]
	call remove( lines, len(lines) - 1 )
	echo join( lines, "\n" )
	
	if v:shell_error != 0
	    echohl ErrorMsg
	    let lastLine = lastLine . " (:QuiltPush! to force)" 
	else
	    echohl MoreMsg
	endif
	echo lastLine
	
	echohl none
    else
	let ret = system( cmd )
	if ret =~ "FAILED"
	    call <SID>CreatePushPopWarning( ret )
	    echohl WarningMsg
	else
	    echohl MoreMsg
	endif

	let lines =  split( ret, "\n" )
	echo lines[ len(lines) - 1 ]
	echohl none
    endif

    call <SID>QuiltStatus()

endfunction

"                                                                              
" Add the file to the current Quilt patch                                      
"                                                                              
function! <SID>QuiltAdd( ... )

    if <SID>IsQuiltDirectory() == 0 
        return 0
    endif

    let cmd= "quilt add "

    if a:0 >= 1
        let cmd = cmd . a:1
    else 
        let cmd = cmd . expand( "%" )

        if expand( '%' ) == '' 
            echohl ErrorMsg
            echo "No file specified, and no file opened ..."
            return 0
            echohl none
        endif
    endif

    if 2 == a:0
	let cmd = cmd . " -P " . a:2
    endif

    call <SID>DoSystem( cmd )
    call <SID>QuiltStatus()

endfunction

"                                                                              
" Remove the file from the current patch                                       
"                                                                              

function! <SID>QuiltRemove( ... )

    if <SID>IsQuiltDirectory() == 0 
        return 0
    endif

    let cmd= "quilt remove "

    if a:0 == 1
        let cmd = cmd . a:1
    else 
        let cmd = cmd . expand( "%" )

        if expand( '%' ) == '' 
            echohl ErrorMsg
            echo "No file specified, and no file opened ..."
            return 0
            echohl none
        endif

    endif

    call <SID>DoSystem( cmd )
    call <SID>QuiltStatus()
endfunction

"                                                                              
" Remove the file from the a:1 patch                                           
"                                                                              

function! <SID>QuiltRemoveFrom( ... )

    if <SID>IsQuiltDirectory() == 0 
        return 0
    endif

    if a:0 < 1
	echohl ErrorMsg
	echo "Not enough parameters ... :help :QuiltRemoveFrom"
	echohl none
	return 0
    endif

    let cmd= "quilt remove -P " . a:1 . " "

    if a:0 == 1
        let cmd = cmd . a:1
    else 
        let cmd = cmd . expand( "%" )

        if expand( '%' ) == '' 
            echohl ErrorMsg
            echo "No file specified, and no file opened ..."
            return 0
            echohl none
        endif

    endif

    call <SID>DoSystem( cmd )
    call <SID>QuiltStatus()
endfunction

"                                                                              
" refresh the current patch or patch passed as a:1 arg                         
"                                                                              
function! <SID>QuiltRefresh( bang, ... )

    if <SID>IsQuiltDirectory() == 0 
        return 0
    endif

    let cmd= "quilt refresh "

    if a:0 == 1
        let cmd = cmd . a:1
    endif

    if a:bang == "!"
        let cmd = cmd . " -f "
    endif

    let ret = system( cmd )

    if v:shell_error == 0
        if ret =~ 'Warning:'

        call <SID>CreateRefreshWarningList( ret )

        endif

        echohl MoreMsg
    else
        echohl ErrorMsg
    endif
    
    let lines =  split( ret, "\n" )
    echo lines[ len(lines) - 1 ]
    echohl none

    call <SID>QuiltStatus()

endfunction

"                                                                              
" Builds the cclist (warning list)                                             
"                                                                              

function! <SID>CreateRefreshWarningList( output )
    
    let warnings = split( a:output, "\n" )
    let i = 0

    call filter( warnings, 'v:val =~ "Warning:"' )

    let msgs  = []

    while i < len( warnings )


        let file = substitute( warnings[ i ], '.*of \(.*\)$', '\1', '' )
        let message = substitute( warnings[ i ], 'Warning: \(.*\) in line.*', '\1', '' )
        
        while warnings[ i ] =~ 'in line.*[[:digit:]]\+'
            
            let line = substitute( matchstr( warnings[ i ], 'in line[^[:digit:]]*[[:digit:]]\+' ), '[^[:digit:]]', '', 'g' )
            let warnings[i] = substitute( warnings[ i ], 'in line[^[:digit:]]*[[:digit:]]\+', 'in line ', '')
    
            call add( msgs, file . ':' . line . ': Quilt Warning: ' . message )

        endwhile

        let i = i + 1

    endwhile

    cexpr msgs

endfunction

"                                                                              
" Builds the cclist (warning list) for push/pop commands                       
"                                                                              

function! <SID>CreatePushPopWarning( output )

    if a:output =~ "Hunk.*FAILED" 
	let lines = split( a:output, '\n' )
	let file= ""

	let msgs = []

	for i in range( 0, len( lines ) - 1 )

	    if lines[i] =~ "^patching file"
		let file = substitute( lines[i], '^patching file \(.*\)$', '\1', "g")
	    endif

	    if lines[i] =~ "^Hunk.*FAILED"
		let lineNb = substitute( lines[i], '^Hunk #\([0-9]\+\) FAILED at \([0-9]\+\)\.$', '\2', "g" )
		call add( msgs, file . ":" . lineNb . ": " . lines[i] )
	    else
		call add( msgs, lines[i] )
	    endif

	endfor

	cexpr msgs

    endif
endfunction

"                                                                              
" Print the current patch level and set the global variable for the statusline 
"                                                                              
function! <SID>QuiltCurrent()


    let g:QuiltCurrentPatch = system ("quilt applied | tail -n 1")
    let g:QuiltCurrentPatch = substitute( g:QuiltCurrentPatch, "\n", '', '' )
    
"    echo "The last patch is " . g:QuiltCurrentPatch

endfunction

"                                                                               
" Quilt Status : refresh all screen quilt info                                  
"                                                                               

function! <SID>QuiltStatus()

    if <SID>IsQuiltOK() == 0 
        return 0
    endif

    call <SID>QuiltCurrent()

    " Set the status line :

    if <SID>ListAllFiles() =~ expand( "%" )
        setlocal statusline=%0.28(%f\ %m%h%r%)\ [%{g:QuiltCurrentPatch}][+in]\ %=%0.10(%l,%c\ %P%)
    else
        setlocal statusline=%0.28(%f\ %m%h%r%)\ [%{g:QuiltCurrentPatch}][!in]\ %=%0.10(%l,%c\ %P%)
    endif
    setlocal laststatus=2

    checktime

endfunction


function! <SID>QuiltCheckRej()
    if <SID>IsQuiltOK()


	if "" != glob( expand ("%") . ".rej" )

	    let b:QuiltRejOpened = 1
	    echohl WarningMsg
	    echo expand( "%" ) . " has a .rej file, you need to manually fix it" 
	    echohl none
	    vsplit %.rej
	    set syntax=diff
	    wincmd L
	    copen
	    wincmd J
	endif

    endif

endfunction


"                                                                               
" Start the Quilt interface                                                     
"                                                                               

function! <SID>QuiltInterface()

    " List all patches 
    new
    silent %!quilt applied 
    $
    silent .!quilt unapplied

endfunction


"
" returns 1 if the current directory is quilt enabled 
" returns 0 if not
"
function! <SID>IsQuiltOK()

    if <SID>FileExists( "patches" ) 

        " Must find a series file somewhere
        if    <SID>FileExists( "series" ) || <SID>FileExists( "patches/series" ) || <SID>FileExists( ".pc/series" ) 
           return 1
        endif

    endif

    return 0

endfunction

"                                                                               
" return 0/1 if it is a quilt directory, and error if not                       
"                                                                               
function! <SID>IsQuiltDirectory()

    " Must find the patches directory

    let r = <SID>IsQuiltOK()
    
    if r == 0 
        echohl ErrorMsg
        echo "This is not a quilt directory ... sorry"
        echohl none
    endif

    return r
endfunction

"                                                                               
" QuiltGoTo : Push or Pop to a defined patch                                    
"                                                                               

function! <SID>QuiltGoTo( bang, patch )

    call <SID>QuiltCurrent()

    if a:patch == g:QuiltCurrentPatch 
        echohl WarningMsg
        echo "already at " . a:patch . " level"
        echohl none
        return 
    endif

    if <SID>ListAppliedPatches() =~ a:patch
        call <SID>QuiltPop( a:bang, a:patch )
    else

        if <SID>ListUnAppliedPatches() =~ a:patch
            call <SID>QuiltPush( a:bang, a:patch )

        else
            echohl ErrorMsg
            echo "Can't go to a non existing patch, sorry"
            echohl none
        endif

    endif

endfunction


"                                                                               
" Move the selected modifications to the specified patch                        
"                                                                               

function! <SID>QuiltMoveTo( bang,  patch ) range

    echo "startpoint is " . a:firstline
    echo "endpoint is " . a:lastline

"    if bang != "!" 
"       if <SID>ListAppliedPatches() =~ patch
"           echohl ErrorMsg
"           echo "Can't move a a chunk to an applied patch, you can only move a chunk from a patch to a non applied one, use ! to force"
"           echohl none
"       endif
"    endif
    
    " First create a directory structure

    let tmpdir1 = tempname()

    call mkdir( tmpdir1 )

    let basesrc = expand( "%:h" )

    if basesrc != ""
        call mkdir( tmpdir1 . "/a/" . basesrc, "p")
        call mkdir( tmpdir1 . "/b/" . basesrc, "p" )
    else
        call mkdir( tmpdir1 . "/a" )
        call mkdir( tmpdir1 . "/b" )
    endif

    " save the dest file (with the current block) in tmpdir1/b/
    
    exec "write " . tmpdir1 . "/b/%"

    " then delete the block and save the 'original file'
    exec a:firstline . "," . a:lastline . "delete"
    exec "write " . tmpdir1 . "/a/%"

    let cmd = "cd " . tmpdir1 .  " && diff -urN  a b > patch"

    echo cmd
    call system( cmd )

    " Now start to refresh the patch...    

    call <SID>QuiltCurrent()
    let g:QuiltFormerPatch = g:QuiltCurrentPatch
    let g:QuiltMoveFileName = expand( "%" )
        
    write
    call <SID>QuiltRefresh( a:bang )
    call <SID>QuiltGoTo( a:bang, a:patch )
    edit
    exec "vert diffpatch " . tmpdir1 . "/patch"

    if a:bang != "!"
        echo "Please Review modifications in this file, and do :QuiltFinishMove in the "
        \ . expand( "%.new" ) . " file buffer"
    else
        call <sid>QuiltFinishMove( bang )
    endif

endfunction

"                                                                               
" Finish a move                                                                 
"                                                                               

function! <SID>QuiltFinishMove( bang )

    if   g:QuiltFormerPatch != ""
    \ && g:QuiltMoveFileName != ""
        %y
        quit!
        %d _
        put
        write!
        call <SID>QuiltRefresh( a:bang )
        call <SID>QuiltGoTo( a:bang, g:QuiltFormerPatch )
        unlet g:QuiltFormerPatch
        unlet g:QuiltMoveFileName
    else
        echohl ErrorMsg
        echo "No move was initiated, can't finish it"
        echohl none
    endif

endfunction

"                                                                               
" returns true if the specified file or directory exists                        
" Warning: this is very bash dependant for now ...                              
"                                                                               
function! <SID>FileExists( filename )
    return system( ' [ -e ' . a:filename . ' ] && echo 1 || echo 0 ' )
endfunction

"                                                                               
" List all patches availables as a string list (one line per patch)             
" Warning: bash dependent !                                                     
"                                                                               
function! <SID>ListAllPatches()
    return system('quilt applied 2>/dev/null ; quilt unapplied 2>/dev/null')
endfunction

function! <SID>ListAppliedPatches()
    return system('quilt applied 2>/dev/null')
endfunction

function! <SID>ListUnAppliedPatches()
    return system('quilt unapplied 2>/dev/null')
endfunction
"                                                                               
" List all files included in the current patch                                  
"                                                                               
function! <SID>ListAllFiles( ... )
    let cmd = "quilt files " 
    
    if a:0 == 1 
        let cmd = cmd . " " . a:1
    endif

    return system( cmd . ' 2>/dev/null')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Completion part (used for commands)                                           
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""



"                                                                               
" Complete in the patch list :                                                  
"                                                                               
function! QuiltCompleteInPatch( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 
        return <SID>ListAllPatches()
    endif

    return ""

endfunction

"                                                                               
" Complete in the applied patch list :                                          
"                                                                               
function! QuiltCompleteInAppliedPatch( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 
        return <SID>ListAppliedPatches()
    endif

    return ""

endfunction

"                                                                               
" Complete in the unapplied patch list :                                        
"                                                                               

function! QuiltCompleteInUnAppliedPatch( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 
        return <SID>ListUnAppliedPatches()
    endif

    return ""

endfunction

"                                                                               
" Return the number of the argument to be completed                             
"                                                                               
function! <SID>CurrentArgNumber( CmdLine, CursorPos )
    
    let theCmd = strpart( a:CmdLine, 0, a:CursorPos )


    let spaceIdx = stridx( theCmd, ' ' )
    let argNb = -1

    while spaceIdx != -1 
	let argNb = argNb + 1
	let spaceIdx = stridx( theCmd, ' ', spaceIdx + 1)
    endwhile

    return argNb
endfunction


"                                                                               
" Complete in files included in the current patch                               
"                                                                               

function! QuiltCompleteInFiles( ArgLead, CmdLine, CursorPos )

    if ( <SID>IsQuiltDirectory() ) 
        return <SID>ListAllFiles()
    endif

    return ""

endfunction


"                                                                               
" Complete first on the files then on the patches                               
"                                                                               
function! QuiltCompleteFilesPatch( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 

        " first arg is in the files, second is in the patches
        
        echo a:CmdLine
        if a:CmdLine =~ "[^[:blank:]][^[:blank:]]* [^[:blank:]][^[:blank:]]* "
            return <SID>ListAppliedPatches()
        endif

        return <SID>ListAllFiles()

    endif

    return ""

endfunction

"                                                                               
" Used to complete in patch directories, return the matching directory          
" list for the "ArgLead" parameter ...                                          
"                                                                               

function! QuiltCompleteInPatchesDir( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 
	return <SID>ListDirectories( "patches/", a:ArgLead, "patches/" )
    endif

    return ""

endfunction


"                                                                               
" List all directories starting in 'root' starting by 'start' and strip         
" '^strip' from the result                                                      
"                                                                               

function! <SID>ListDirectories( root, start, strip )

    if "" == a:root || isdirectory( a:root )

	let fileList = split( glob( a:root . a:start . "*" ), "\n" )
	if !empty(fileList)

	    let dirList = []

	    for x in fileList
		
		if isdirectory( x )
		    let dirList = add( dirList, substitute( x, "^" . a:strip , "", "" ) . "/" )
		endif

	    endfor

	    return join( dirList, "\n" )
	endif

    endif
    return ""

endfunction

"                                                                               
" List files in root starting by start                                          
"                                                                               

function! <SID>ListFiles( root, start)

    if "" == a:root || isdirectory( a:root )

	return glob( a:root . a:start . "*" ) 

    endif
    return ""

endfunction

"                                                                               
" Completion for Add (file, then patch )                                        
"                                                                               
function! QuiltCompleteForAdd( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 
	let argn = <SID>CurrentArgNumber( a:CmdLine, a:CursorPos )

	if 0 == argn
	    return <SID>ListFiles( "", a:ArgLead )
	endif

	if 1 == argn
	    return QuiltCompleteInPatch( a:ArgLead, a:CmdLine, a:CursorPos )
	endif

    endif

    return ""
endfunction


"                                                                               
" Completion for RemoveFrom ( patch, then included files )                      
"                                                                               
function! QuiltCompleteForRemoveFrom( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 
	let argn = <SID>CurrentArgNumber( a:CmdLine, a:CursorPos )

	if 0 == argn
	    return QuiltCompleteInPatch( a:ArgLead, a:CmdLine, a:CursorPos )
	endif

	if 1 == argn
	    let patch = substitute( a:CmdLine, '^QuiltRemoveFrom \([^[:blank:]]*\) .*$', '\1', '' )

	    return <SID>ListAllFiles( patch )
	endif

    endif

    return ""
endfunction

"                                                                               
" Completion for Add (file, then patch )                                        
"                                                                               
function! QuiltCompleteForMail( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 
	let argn = <SID>CurrentArgNumber( a:CmdLine, a:CursorPos )

	if 0 == argn
	    return join( g:QuiltMailAddresses, "\n" )
	endif

	if 1 == argn || 2 == argn
	    return QuiltCompleteInPatch( a:ArgLead, a:CmdLine, a:CursorPos )
	endif

    endif

    return ""
endfunction

let &cpo = cpocopy
