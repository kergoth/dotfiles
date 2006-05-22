" Vim completion script
" Language:  C++
" Maintainer:  Vissale NEANG
" Last Change:  2006 May 21
" Comments:
" Version 0.31
"   -   May complete added, please see installation notes for details.
"   -   Fixed a bug where the completion works while in a comment or in a string.
"
" Version 0.3
"   WARNING: For this release and future releases you have to build your tags 
"       database with this cmd :
"       "ctags -R --c++-kinds=+p --fields=+iaS --extra=+q ."
"       Please read installation instructions in the documentation for details
"
"   -   Documentation added.
"   -   Fixed a bug where typedefs were not correctly resolved in namespaces
"       in some cases.
"   -   Fixed a bug where the type can not be detected when we have a decl
"       like this: class A {}globalVar;
"   -   Fixed a bug in type detection where searchdecl() (gd) find
"       incorrect declaration instruction.
"   -   Global scope completion now only works with non-empty base. 
"   -   Using namespace list is now parsed in the current buffer and in
"       included files.
"   -   Fixed a bug where the completion fails in some cases when the user
"       sets the ignorecase to on
"   -   Preview window informations added
"   -   Some improvements in type detection, the type can be properly detected
"       with a declaration like this:
"       'Class1 *class1A = NULL, **class1B = NULL, class1C[9], class1D[1] = {};'
"   -   Fixed a bug where parent scopes were not displayed in the popup menu 
"       in the current scope completion mode.
"   -   Fixed a bug where an error message was displayed when the last
"       instruction was not finished.
"   -   Fixed a bug where the completion fails if a punctuator or operator was
"       immediately after the cursor.
"   -   The script can now detect parent contexts at the cursor position 
"       thanks to 'using namespace' declarations.
"       It can also detect ambiguous namespaces. They are not included in 
"       the context list.
"   -   Fixed a bug where the current scope is not properly detected when
"       a file starts with a comment
"   -   Fixed a bug where the type is not detected when we have myObject[0]
"   -   Removed the system() call in SearchMembers(), no more calls to the
"       ctags binary. The user have to build correctly his database with the cmd:
"       "ctags -R --c++-kinds=+p --fields=+iaS --extra=+q ."
"   -   File time cache removed, the user have to rebuild his data base after a
"       modification.
"
" Version 0.22
"   -   Completion of unnamed type (eg: You can complete g_Var defined like
"       this 'struct {int a; int b;}g_Var;'). It also works for a typedef of
"       an unnamed type (eg: 'typedef struct {int a; int b;}t_mytype; t_mytype
"       g_Var;').
"   -   Tag file's time cache added, if a tag file has changed the global
"       scope result cache is cleared.
"   -   Fixed a bug where the tokenization process enter in an infinite loop
"       when a file starts with '/*'.
"
" Version 0.21
"   -   Improvements on the global scope completion.
"       The user can now see the progression of the search and complete
"       matches are stored in a cache for optimization. The cache is cleared
"       when the tag env is modified.
"   -   Within a class scope when the user complete an empty word, the popup
"       menu displays the members of the class then members of the global
"       scope.
"   -   Fixed a bug where a current scope completion failed after a punctuator
"       or operator (eg: after a '=' or '!=').
"
" Version 0.2
"   -   Improvements in type detection (eg: when a variable is declared in a
"       parameter list, a catch clause, etc...)
"   -   Code tokenization => ignoring spaces, tabs, carriage returns and comments
"       You can complete a code even if the instruction has bad
"       indentation, spaces or carriage returns between words
"   -   Completion of class members added
"   -   Detection of the current scope at the cursor position.
"       If you run a completion from en empty line, members of the current
"       scope are displayed. It works on the global namespace and the current
"       class scope (but there is not the combination of the 2 for the moment)
"   -   Basic completion on the global namespace (very slow)
"   -   Completion of returned type added
"   -   this pointer completion added
"   -   Completion after a cast added (C and C++ cast)
"   -   Fixed a bug where the matches of the complete menu are not filtered
"       according to what the user typed
"   -   Change the output of the popup menu. the type of the member
"       (function, member, enum etc...) is now display as a single letter.
"       The access information is display like this : '+' for a public member
"       '#' for a protected member and '-' for a private member.
"       The last information is the class, namespace or enum where the member is define.
"
" Version 0.12:
"   -   Complete check added to the search process, you can now cancel
"       the search during a complete search.
"   
" Version 0.1:
"   -   First release

if v:version < 700
    echohl WarningMsg
    echomsg "cppomnicomplete.vim: Please install vim 7.0 or higher for omni-completion"
    echohl None
    finish
endif

" Init an int option
function! s:InitOptionInteger(szOptionName, range, default)
    let szDefaultExpr= 'let ' . a:szOptionName . ' = ' . a:default
    if !exists(a:szOptionName)
        execute szDefaultExpr
    else
        let value = eval(a:szOptionName)
        if index(a:range, value)<0
            echohl WarningMsg
            echomsg "cppomnicomplete.vim: Invalid value for " . a:szOptionName . " = " . value . ". Possible values are " . string(a:range) . ". Backing to default value = ". a:default
            echohl None
            execute 'unlet ' . a:szOptionName
            execute szDefaultExpr
        endif
    endif
endfunc

" Init a string option
function! s:InitOptionString(szOptionName, default)
    let szDefaultExpr= 'let ' . a:szOptionName . ' = ' . string(a:default)
    if !exists(a:szOptionName)
        execute szDefaultExpr
    else
        let value = eval(a:szOptionName)
        if type(value)!=1
            echohl WarningMsg
            echomsg "cppomnicomplete.vim: " . a:szOptionName . " must be a String. Backing to default value = ". string(a:default)
            echohl None
            execute 'unlet ' . a:szOptionName
            execute szDefaultExpr
        endif
    endif
endfunc

" Init a list option
function! s:InitOptionList(szOptionName, default)
    let szDefaultExpr= 'let ' . a:szOptionName . ' = ' . string(a:default)
    if !exists(a:szOptionName)
        execute szDefaultExpr
    else
        let value = eval(a:szOptionName)
        if type(value)!=3
            echohl WarningMsg
            echomsg "cppomnicomplete.vim: " . a:szOptionName . " must be a List. Backing to default value = ". string(a:default)
            echohl None
            execute 'unlet ' . a:szOptionName
            execute szDefaultExpr
        endif
    endif
endfunc

" Global scope search on/off
"   0 = disabled
"   1 = enabled
call s:InitOptionInteger('g:CppOmni_GlobalScopeSearch', range(0,1), 1)

" Sets the namespace search method
"   0 = disabled
"   1 = search namespaces in the current file
"   2 = search namespaces in the current file and included files
call s:InitOptionInteger('g:CppOmni_NamespaceSearch', range(0,2), 2)

" Set if the popup must be build on the fly
"   0 = Popup builded internally
"   1 = Popup builded on the fly
call s:InitOptionInteger('g:CppOmni_PopupRealTimeBuild', range(0,1), 0)

" Set the class scope completion mode
"   0 = auto
"   1 = show all members
call s:InitOptionInteger('g:CppOmni_ClassScopeCompletionMethod', range(0,1), 0)

" Set if the scope is displayed in the abbr column of the popup
"   0 = no
"   1 = yes
call s:InitOptionInteger('g:CppOmni_ShowScopeInAbbr', range(0,1), 0)

" Debug mode
"   0 = disabled
"   1 = enabled
call s:InitOptionInteger('g:CppOmni_Debug', range(0,1), 0)

" Reset debug trace for each completion
"   0 = debug traces are not reseted
"   1 = debug traces are reseted
call s:InitOptionInteger('g:CppOmni_DebugReset', range(0,1), 1)

" Debug file
"   default = cppomnicomplete.dbg
call s:InitOptionString('g:CppOmni_DebugFile', "cppomnicomplete.dbg")

" Set the list of default namespaces
" eg: ['std']
call s:InitOptionList('g:CppOmni_DefaultNamespaces', [])


" Cache data
let s:CACHE_DEBUG_TRACE = []
let s:CACHE_RESULT = {}
let s:CACHE_TAG_FILES = {}
let s:CACHE_TAG_ENV = ''
let s:CACHE_INCLUDE_GUARD= {}
let s:CACHE_RESOLVE_NAMESPACES = {}
let s:CACHE_FILETIME = {}
let s:CACHE_FUNCTION_TAGS = {}
let s:CACHE_GLOBAL_SCOPE_TAGS = {}
let s:CACHE_DISPLAY_POPUP = {}

" From the C++ BNF
let s:cppKeyword = ['asm', 'auto', 'bool', 'break', 'case', 'catch', 'char', 'class', 'const', 'const_cast', 'continue', 'default', 'delete', 'do', 'double', 'dynamic_cast', 'else', 'enum', 'explicit', 'export', 'extern', 'false', 'float', 'for', 'friend', 'goto', 'if', 'inline', 'int', 'long', 'mutable', 'namespace', 'new', 'operator', 'private', 'protected', 'public', 'register', 'reinterpret_cast', 'return', 'short', 'signed', 'sizeof', 'static', 'static_cast', 'struct', 'switch', 'template', 'this', 'throw', 'true', 'try', 'typedef', 'typeid', 'typename', 'union', 'unsigned', 'using', 'virtual', 'void', 'volatile', 'wchar_t', 'while', 'and', 'and_eq', 'bitand', 'bitor', 'compl', 'not', 'not_eq', 'or', 'or_eq', 'xor', 'xor_eq']

let s:reCppKeyword = '\C\<'.join(s:cppKeyword, '\>\|\<').'\>'

" The order of items in this list is very important because we use this list to build a regular
" expression (see below) for tokenization
let s:cppOperatorPunctuator = ['->*', '->', '--', '-=', '-', '!=', '!', '##', '#', '%:%:', '%=', '%>', '%:', '%', '&&', '&=', '&', '(', ')', '*=', '*', ',', '...', '.*', '.', '/=', '/', '::', ':>', ':', ';', '?', '[', ']', '^=', '^', '{', '||', '|=', '|', '}', '~', '++', '+=', '+', '<<=', '<%', '<:', '<<', '<=', '<', '==', '=', '>>=', '>>', '>=', '>']

" We build the regexp for the tokenizer
let s:reCComment = '\/\*\|\*\/'
let s:reCppComment = '\/\/'
let s:reComment = s:reCComment.'\|'.s:reCppComment
let s:reCppOperatorOrPunctuator = escape(join(s:cppOperatorPunctuator, '\|'), '*./^~[]')
let s:rePreprocIncludePart = '\C#\s*include\s*'
let s:reIncludeFilePart = '\(<\|"\)\(\f\|\s\)\+\(>\|"\)'
let s:rePreprocIncludeFile = s:rePreprocIncludePart . s:reIncludeFilePart

" Expression used to ignore comments
" Note: this expression drop drastically the performance
"let s:expIgnoreCommentForBracket = 'match(synIDattr(synID(line("."), col("."), 1), "name"), '\CcComment')!=-1'
" This one is faster but not really good for C comments
let s:expReIgnoreComment = escape('\/\/\|\/\*\|\*\/', '*/\')
let s:expIgnoreCommentForBracket = 'getline(".") =~ s:expReIgnoreComment'

" Characters to escape in a filename for vimgrep
"TODO: Find more characters to escape
let s:szEscapedCharacters = ' %#'

" Has preview window?
let s:hasPreviewWindow = match(&completeopt, 'preview')>=0

" Popup item list
let s:popupItemResultList = []

let s:szFilterGlobalScope = "!has_key(v:val, 'class') && !has_key(v:val, 'struct') && !has_key(v:val, 'union') && !has_key(v:val, 'namespace') && !has_key(v:val, 'enum')"

" May complete indicator
let s:bMayComplete = 0
let s:bCursorInCommentOrString = 0

" Start debug, clear the debug file
function! s:DebugStart()
    if g:CppOmni_Debug
        if g:CppOmni_DebugReset
            let s:CACHE_DEBUG_TRACE = []
        endif
        call extend(s:CACHE_DEBUG_TRACE, ['============ Debug Start ============'])
        call writefile(s:CACHE_DEBUG_TRACE, g:CppOmni_DebugFile)
    endif
endfunc

" End debug, write to debug file
function! s:DebugEnd()
    if g:CppOmni_Debug
        call extend(s:CACHE_DEBUG_TRACE, ["============= Debug End ============="])
        call extend(s:CACHE_DEBUG_TRACE, [""])
        call writefile(s:CACHE_DEBUG_TRACE, g:CppOmni_DebugFile)
    endif
endfunc


" Debug trace function
function! s:DebugTrace(szFuncName, ...)
    if g:CppOmni_Debug
        let szTrace = a:szFuncName
        let paramNum = a:0
        if paramNum>0
            let szTrace .= ':'
        endif
        for i in range(paramNum)
            let szTrace = szTrace .' ('. string(eval('a:'.string(i+1))).')'
        endfor
        call extend(s:CACHE_DEBUG_TRACE, [szTrace])
    endif
endfunc

" Check if a file has changed
function! s:HasFileChanged(szFilePath)
    if has_key(s:CACHE_FILETIME, a:szFilePath)
        let currentFiletime = getftime(a:szFilePath)
        if currentFiletime > s:CACHE_FILETIME[a:szFilePath]
            " The file has changed, updating the cache
            let s:CACHE_FILETIME[a:szFilePath] = currentFiletime
            return 1
        else
            return 0
        endif
    else
        " We store the time of the file
        let s:CACHE_FILETIME[a:szFilePath] = getftime(a:szFilePath)
        return 1
    endif
endfunc

" Get code without comments and with empty strings
" szSingleLine must not have carriage return
function! s:GetCodeWithoutCommentsFromSingleLine(szSingleLine)
    " We set all strings to empty strings, it's safer for 
    " the next of the process
    let szResult = substitute(a:szSingleLine, '".*"', '""', 'g')

    " Removing c++ comments, we can use the pattern ".*" because
    " we are modifying a line
    let szResult = substitute(szResult, '\/\/.*', '', 'g')

    " Now we have the entire code in one line and we can remove C comments
    return s:RemoveCComments(szResult)
endfunc

" Get a c++ code from current buffer from [lineStart, colStart] to 
" [lineEnd, colEnd] without c++ and c comments, without end of line
" and with empty strings if any
" @return a string
function! s:GetCodeWithoutComments(posStart, posEnd)
    let posStart = a:posStart
    let posEnd = a:posEnd
    if a:posStart[0]>a:posEnd[0]
        let posStart = a:posEnd
        let posEnd = a:posStart
    elseif a:posStart[0]==a:posEnd[0] && a:posStart[1]>a:posEnd[1]
        let posStart = a:posEnd
        let posEnd = a:posStart
    endif

    " Getting the lines
    let lines = getline(posStart[0], posEnd[0])
    let lenLines = len(lines)

    " Formatting the result
    let result = ''
    if lenLines==1
        let sStart = posStart[1]-1
        let sEnd = posEnd[1]-1
        let line = lines[0]
        let lenLastLine = strlen(line)
        let sEnd = (sEnd>lenLastLine)?lenLastLine : sEnd
        if sStart >= 0
            let result = s:GetCodeWithoutCommentsFromSingleLine(line[ sStart : sEnd ])
        endif
    elseif lenLines>1
        let sStart = posStart[1]-1
        let sEnd = posEnd[1]-1
        let lenLastLine = strlen(lines[-1])
        let sEnd = (sEnd>lenLastLine)?lenLastLine : sEnd
        if sStart >= 0
            let lines[0] = lines[0][ sStart : ]
            let lines[-1] = lines[-1][ : sEnd ]
            for aLine in lines
                let result = result . s:GetCodeWithoutCommentsFromSingleLine(aLine)." "
            endfor
            let result = result[:-2]
        endif
    endif

    " Now we have the entire code in one line and we can remove C comments
    return s:RemoveCComments(result)
endfunc

" Remove C comments on a line
function! s:RemoveCComments(szLine)
    let result = a:szLine

    " We have to match the first '/*' and first '*/'
    let startCmt = match(result, '\/\*')
    let endCmt = match(result, '\*\/')
    while startCmt!=-1 && endCmt!=-1 && startCmt<endCmt
        if startCmt>0
            let result = result[ : startCmt-1 ] . result[ endCmt+2 : ]
        else
            " Case where '/*' is at the start of the line
            let result = result[ endCmt+2 : ]
        endif
        let startCmt = match(result, '\/\*')
        let endCmt = match(result, '\*\/')
    endwhile
    return result
endfunc

" Tokenize a c++ code
" a token is dictionary where keys are:
"   -   kind = cppKeyword|cppWord|cppOperatorPunctuator|unknown|cComment|cppComment
"   -   value = 'something'
"   Note: a cppWord is any word that is not a cpp keyword
function! s:Tokenize(szCode)
    let result = []

    " The regexp to find a token, a token is a keyword, word or
    " c++ operator or punctuator. To work properly we have to put 
    " spaces and tabs to our regexp.
    let reTokenSearch = '\(\w\+\)\|\s\+\|'.s:reComment.'\|'.s:reCppOperatorOrPunctuator
    " eg: 'using namespace std;'
    "      ^    ^
    "  start=0 end=5
    let startPos = 0
    let endPos = matchend(a:szCode, reTokenSearch)
    let len = endPos-startPos
    while endPos!=-1
        " eg: 'using namespace std;'
        "      ^    ^
        "  start=0 end=5
        "  token = 'using'
        " We also remove space and tabs
        let token = substitute(strpart(a:szCode, startPos, len), '\s', '', 'g')

        " eg: 'using namespace std;'
        "           ^         ^
        "       start=5     end=15
        let startPos = endPos
        let endPos = matchend(a:szCode, reTokenSearch, startPos)
        let len = endPos-startPos

        " It the token is empty we continue
        if token==''
            continue
        endif

        " Building the token
        let resultToken = {'kind' : 'unknown', 'value' : token}

        " Classify the token
        if token=~'^\w\+$'
            " It's a word
            let resultToken.kind = 'cppWord'

            " But maybe it's a c++ keyword
            if match(token, s:reCppKeyword)>=0
                let resultToken.kind = 'cppKeyword'
            endif
        else
            if match(token, s:reComment)>=0
                if index(['/*','*/'],token)>=0
                    let resultToken.kind = 'cComment'
                else
                    let resultToken.kind = 'cppComment'
                endif
            else
                " It's an operator
                let resultToken.kind = 'cppOperatorPunctuator'
            endif
        endif

        " We have our token, let's add it to the result list
        call extend(result, [resultToken])
    endwhile

    return result
endfunc

" Tokenize the current instruction.
" @return list of tokens
function! s:TokenizeCurrentInstruction(...)
    let szAppendText = ''
    if a:0>0
        let szAppendText = a:1
    endif

    let startPos = searchpos('[;{}]\|\%^', 'bWn')
    let curPos = getpos('.')[1:2]
    " We don't want the character under the cursor
    let column = curPos[1]-1
    let curPos[1] = (column<1)?1:column
    return s:Tokenize(s:GetCodeWithoutComments(startPos, curPos)[1:] . szAppendText)
endfunc

" Build the item list of an instruction
" An item is an instruction between a -> or . or ->* or .*
" We can sort an item in 3 kinds:
"   - an item can be a cast
"   - a member
"   - a method
" eg: ((MyClass1*)(pObject))->_memberOfClass1.get()     ->show()
"     |        cast        |  |    member   | | method |  | method |
" @return a list of item
" an item is a dictionnary where keys are:
"   tokens = list of token
"   kind = itemVariable|itemCast|itemCppCast|itemTemplate|itemFunction|itemUnknown|itemThis|itemScope|itemNumber
function! s:GetItemsToComplete(tokens)
    let result = []
    let itemsDelimiters = ['->', '.', '->*', '.*']

    let tokens = reverse(s:BuildParenthesisGroups(a:tokens))

    " fsm states:
    "   0 = initial state
    "   TODO: add description of fsm states
    let state=0
    let item = {'tokens' : [], 'kind' : 'itemUnknown'}
    let parenGroup=-1
    for token in tokens
        if state==0
            if index(itemsDelimiters, token.value)>=0
                let item = {'tokens' : [], 'kind' : 'itemUnknown'}
                let state = 1
            elseif token.value=='::'
                let state = 9
                let item.kind = 'itemScope'
                " Maybe end of tokens
            elseif token.kind =='cppOperatorPunctuator'
                " If it's a cppOperatorPunctuator and the current token is not
                " a itemsDelimiters or '::' we can exit
                let state=-1
                break
            endif
        elseif state==1
            call insert(item.tokens, token)
            if token.kind=='cppWord'
                " It's an attribute member or a variable
                if match(token.value, '^\d')>=0
                    " eg:  0.
                    let item.kind = 'itemNumber'
                else
                    let item.kind = 'itemVariable'
                endif
                let state = 2
                " Maybe end of tokens
            elseif token.value=='this'
                let item.kind = 'itemThis'
                let state = 2
                " Maybe end of tokens
            elseif token.value==')'
                let parenGroup = token.group
                let state = 3
            elseif token.value==']'
                let parenGroup = token.group
                let state = 4
            endif
        elseif state==2
            if index(itemsDelimiters, token.value)>=0
                call insert(result, item)
                let item = {'tokens' : [], 'kind' : 'itemUnknown'}
                let state = 1
            elseif token.value == '::'
                call insert(item.tokens, token)
                " We have to get namespace or classscope
                let state = 8
                " Maybe end of tokens
            else
                call insert(result, item)
                let state=-1
                break
            endif
        elseif state==3
            call insert(item.tokens, token)
            if token.value=='(' && token.group == parenGroup
                let state = 5
                " Maybe end of tokens
            endif
        elseif state==4
            call insert(item.tokens, token)
            if token.value=='[' && token.group == parenGroup
                let state = 1
            endif
        elseif state==5
            if token.kind=='cppWord'
                " It's a function or method
                let item.kind = 'itemFunction'
                call insert(item.tokens, token)
                let state = 2
                " Maybe end of tokens
            elseif token.value == '>'
                " Maybe a cpp cast or template
                let item.kind = 'itemTemplate'
                call insert(item.tokens, token)
                let parenGroup = token.group
                let state = 6
            else
                " Perhaps it's a C cast eg: ((void*)(pData)) or a variable eg:(*pData)
                let item.kind = s:GetCastType(item.tokens)
                let state=-1
                call insert(result, item)
                break
            endif
        elseif state==6
            call insert(item.tokens, token)
            if token.value == '<' && token.group == parenGroup
                " Maybe a cpp cast or template
                let state = 7
            endif
        elseif state==7
            call insert(item.tokens, token)
            if token.kind=='cppKeyword'
                " It's a cpp cast
                let item.kind = s:GetCastType(item.tokens)
                let state=-1
                call insert(result, item)
                break
            else
                " Template ?
                let state=-1
                call insert(result, item)
                break
            endif
        elseif state==8
            if token.kind=='cppWord'
                call insert(item.tokens, token)
                let state = 2
                " Maybe end of tokens
            else
                let state=-1
                call insert(result, item)
                break
            endif
        elseif state==9
            if token.kind == 'cppWord'
                call insert(item.tokens, token)
                let state = 10
                " Maybe end of tokens
            else
                let state=-1
                call insert(result, item)
                break
            endif
        elseif state==10
            if token.value == '::'
                call insert(item.tokens, token)
                let state = 9
                " Maybe end of tokens
            else
                let state=-1
                call insert(result, item)
                break
            endif
        endif
    endfor

    if index([2, 5, 8, 9, 10], state)>=0
        if state==5
            let item.kind = s:GetCastType(item.tokens)
        endif
        call insert(result, item)
    endif

    return result
endfunc

" Remove useless parenthesis
function! s:SimplifyParenthesis(tokens)
    "Note: a:tokens is not modified
    let tokens = a:tokens
    " We remove useless parenthesis eg: (((MyClass)))
    if len(tokens)>2
        while tokens[0].value=='(' && tokens[-1].value==')' && tokens[0].group==tokens[-1].group
            let tokens = tokens[1:-2]
        endwhile
    endif
    return tokens
endfunc

" Simplify scope string, remove consecutive '::' if any
function! s:SimplifyScope(szScope)
    let szResult = substitute(a:szScope, '\(::\)\+', '::', 'g')
    if szResult=='::'
        return szResult
    else
        return substitute(szResult, '::$', '', 'g')
    endif
endfunc

" Determine if tokens represent a C cast
" @return
"   - itemCast
"   - itemCppCast
"   - itemVariable
"   - itemThis
function! s:GetCastType(tokens)
    " Note: a:tokens is not modified
    let tokens = s:SimplifyParenthesis(s:BuildParenthesisGroups(a:tokens))

    if tokens[0].value == '('
        return 'itemCast' 
    elseif index(['static_cast', 'dynamic_cast', 'reinterpret_cast', 'const_cast'], tokens[0].value)>=0
        return 'itemCppCast'
    else
        for token in tokens
            if token.value=='this'
                return 'itemThis'
            endif
        endfor
        return 'itemVariable' 
    endif
endfunc

" Resolve a cast.
" Resolve a C cast
" @param list of token. tokens must be a list that represents
" a cast expression (C cast) the function does not control
" if it's a cast or not
" eg: (MyClass*)something
" @return type tokens
function! s:ResolveCast(tokens, startChar, endChar)
    let tokens = s:BuildParenthesisGroups(a:tokens)

    " We remove useless parenthesis eg: (((MyClass)))
    let tokens = s:SimplifyParenthesis(tokens)

    let countItem=0
    let startIndex = -1
    let endIndex = -1 
    let i = 0
    for token in tokens
        if startIndex==-1
            if token.value==a:startChar
                let countItem += 1
                let startIndex = i
            endif
        else
            if token.value==a:startChar
                let countItem += 1
            elseif token.value==a:endChar
                let countItem -= 1
            endif

            if countItem==0
                let endIndex = i
                break
            endif
        endif
        let i+=1
    endfor

    return tokens[startIndex+1 : endIndex-1]
endfunc

" Build parenthesis groups
" add a new key 'group' in the token
" where value is the group number of the parenthesis
" eg: (void*)(MyClass*)
"      group1  group0
" if a parenthesis is unresolved the group id is -1      
" @return a copy of a:tokens with parenthesis group
function! s:BuildParenthesisGroups(tokens)
    let tokens = copy(a:tokens)
    let kinds = {'(': '()', ')' : '()', '[' : '[]', ']' : '[]', '<' : '<>', '>' : '<>', '{': '{}', '}': '{}'}
    let unresolved = {'()' : [], '[]': [], '<>' : [], '{}' : []}
    let groupId = 0

    " Note: we build paren group in a backward way
    " because we can often have parenthesis unbalanced
    " instruction
    " eg: doSomething(_member.get()->
    for token in reverse(tokens)
        if index([')', ']', '>', '}'], token.value)>=0
            let token['group'] = groupId
            call extend(unresolved[kinds[token.value]], [token])
            let groupId+=1
        elseif index(['(', '[', '<', '{'], token.value)>=0
            if len(unresolved[kinds[token.value]])
                let tokenResolved = remove(unresolved[kinds[token.value]], -1)
                let token['group'] = tokenResolved.group
            else
                let token['group'] = -1
            endif
        endif
    endfor

    return reverse(tokens)
endfunc

" Resolve a cast.
" Resolve a C++ cast
" @param list of token. tokens must be a list that represents
" a cast expression (C++ cast) the function does not control
" if it's a cast or not
" eg: static_cast<MyClass*>(something)
" @return type info string
function! s:ResolveCppCast(tokens)
    return s:ExtractTypeInfoFromTokens(s:ResolveCast(a:tokens, '<', '>'))
endfunc

" Resolve a cast.
" Resolve a C cast
" @param list of token. tokens must be a list that represents
" a cast expression (C cast) the function does not control
" if it's a cast or not
" eg: (MyClass*)something
" @return type info string
function! s:ResolveCCast(tokens)
    return s:ExtractTypeInfoFromTokens(s:ResolveCast(a:tokens, '(', ')'))
endfunc

" Returns the class scope at the current position of the cursor
" @return a string that represents the class scope
" eg: ::NameSpace1::Class1
" The returned string always starts with '::'
" Note: In term of performance it's the weak point of the script
function! s:GetClassScopeAtCursor()
    " We store the cursor position because searchpairpos() moves the cursor
    let originalPos = getpos('.')
    let endPos = originalPos[1:2]
    let listCode = []
    let result = {'namespaces': [], 'scope': ''}

    while endPos!=[0,0]
        let endPos = searchpairpos('{', '', '}', 'bW', s:expIgnoreCommentForBracket)
        let szReStartPos = '[;{}]\|\%^'
        let startPos = searchpairpos(szReStartPos, '', '{', 'bWn', s:expIgnoreCommentForBracket)

        " If the file starts with a comment so the startPos can be [0,0]
        " we change it to [1,1]
        if startPos==[0,0]
            let startPos = [1,1]
        endif

        " Get lines backward from cursor position to last ; or { or }
        " or when we are at the beginning of the file.
        " We store lines in listCode
        if endPos!=[0,0]
            " We remove the last character which is a '{'
            " We also remove starting { or } or ; if exits
            let szCodeWithoutComments = substitute(s:GetCodeWithoutComments(startPos, endPos)[:-2], '^[;{}]', '', 'g')
            call insert(listCode, szCodeWithoutComments)
        endif
    endwhile
    " Setting the cursor to the original position
    call setpos('.', originalPos)

    let listClassScope = []
    let szClassScope = '::'
    " Now we can check in the list of code if there is a function
    for code in listCode
        " We get the name of the namespace, class, struct or union
        " and we store it in listClassScope
        let tokens = s:Tokenize(code)
        let bContinue=0
        let bAddNamespace = 0
        let state=0
        for token in tokens
            if state==0
                if index(['namespace', 'class', 'struct', 'union'], token.value)>=0
                    if token.value == 'namespace'
                        let bAddNamespace = 1
                    endif
                    let state= 1
                    " Maybe end of tokens
                endif
            elseif state==1
                if token.kind == 'cppWord'
                    " eg: namespace MyNs { class MyCl {}; }
                    " => listClassScope = [MyNs, MyCl]
                    call extend( listClassScope , [token.value] )

                    " Add the namespace in result
                    if bAddNamespace
                        call extend(result.namespaces, [token.value])
                        let bAddNamespace = 0
                    endif

                    let bContinue=1
                    break
                endif
            endif
        endfor
        if bContinue==1
            continue
        endif

        " Simple test to check if we have a chance to find a
        " class method
        let aPos = matchend(code, '::\s*\w\+\s*(')
        if aPos ==-1
            continue
        endif

        let listTmp = []
        " eg: 'void MyNamespace::MyClass::foo('
        " => tokens = ['MyClass', '::', 'MyNamespace', 'void']
        let tokens = reverse(s:Tokenize(code[:aPos-1])[:-4])
        let state = 0
        " Reading tokens backward
        for token in tokens
            if state==0
                if token.kind=='cppWord'
                    call insert(listTmp, token.value)
                    let state=1
                endif
            elseif state==1
                if token.value=='::'
                    let state=2
                else
                    break
                endif
            elseif state==2
                if token.kind=='cppWord'
                    call insert(listTmp, token.value)
                    let state=1
                else
                    break
                endif
            endif
        endfor

        if len(listTmp)
            if len(listClassScope)
                " Merging class scopes
                " eg: current class scope = 'MyNs::MyCl1'
                " method class scope = 'MyCl1::MyCl2'
                " If we add the method class scope to current class scope
                " we'll have MyNs::MyCl1::MyCl1::MyCl2 => it's wrong
                " we want MyNs::MyCl1::MyCl2
                let index = 0
                for methodClassScope in listTmp
                    if methodClassScope==listClassScope[-1]
                        let listTmp = listTmp[index+1:]
                        break
                    else
                        let index+=1
                    endif
                endfor
            endif
            call extend(listClassScope, listTmp)
            break
        endif
    endfor

    if len(listClassScope)
        let szClassScope = szClassScope . join(listClassScope, '::')
    endif

    let result.scope = szClassScope
    return result
endfunc

" For debug purpose
function! s:TokensToString(tokens)
    let result = ''
    for token in a:tokens
        let result = result . token.value . ' '
    endfor
    return result[:-2]
endfunc

" For debug purpose
function! s:ItemToString(item)
    return s:TokensToString(a:item.tokens) . ' ' . a:item.kind
endfunc

" Find the start position of the completion
function! s:FindStartPositionOfCompletion()
    " Locate the start of the item, including ".", "->" and "[...]".
    let line = getline('.')
    let start = col('.') - 1

    let lastword = -1
    while start > 0
        if line[start - 1] =~ '\w'
            let start -= 1
        elseif line[start - 1] =~ '\.'
            " Searching for dot '.'
            if lastword == -1
                let lastword = start
            endif
            let start -= 1
        elseif start > 1 && line[start - 2] == '-' && line[start - 1] == '>'
            " Searching for '->'
            if lastword == -1
                let lastword = start
            endif
            let start -= 2
        elseif start > 1 && line[start - 2] == ':' && line[start - 1] == ':'
            " Searching for '::' for namespaces and class
            if lastword == -1
                let lastword = start
            endif
            let start -= 2
        elseif line[start - 1] == ']'
            " Skip over [...].
            let n = 0
            let start -= 1
            while start > 0
                let start -= 1
                if line[start] == '['
                    if n == 0
                        break
                    endif
                    let n -= 1
                elseif line[start] == ']'  " nested []
                    let n += 1
                endif
            endwhile
        else
            break
        endif
    endwhile
    if lastword==-1
        " For completion on the current scope
        let lastword = start
    endif
    return lastword
endfunc

" Get the using namespace list from a line
function! s:GetNamespaceListFromLine(szLine)
    let result = []
    let tokens = s:Tokenize(a:szLine)
    let szNamespace = ''
    let state = 0
    for token in tokens
        if state==0
            let szNamespace = ''
            if token.value == '/*'
                let state = 1
            elseif token.value == '//'
                " It's a comment
                let state = -1
                break
            elseif token.value == 'using'
                let state = 2
            endif
        elseif state==1
            if token.value == '*/'
                let state=0
            endif
        elseif state==2
            if token.value == 'namespace'
                let state = 3
            else
                " Error, 'using' must be followed by 'namespace'
                let state = -1
                break
            endif
        elseif state==3
            if token.value == '::'
                let szNamespace .= token.value
                let state = 4
            elseif token.kind == 'cppWord'
                let szNamespace .= token.value
                let state = 5
                " Maybe end of tokens
            endif
        elseif state==4
            if token.kind == 'cppWord'
                let szNamespace .= token.value
                let state = 5
                " Maybe end of tokens
            else
                " Error, we can't have 'using namespace Something::'
                let state = -1
                break
            endif
        elseif state==5
            if token.value == '::'
                let szNamespace .= token.value
                let state = 4
            else
                call extend(result, [szNamespace])
                let state = 0
            endif
        endif
    endfor

    if state == 5
        call extend(result, [szNamespace])
    endif

    return result
endfunc

" Get the namespace list from include file
" TODO: Add a cache here
function! s:GetNamespaceListFromBufffer(szFile, ...)
    let stopLine = -1
    if a:0>0
        let stopLine = a:1
    endif
    let result = []

    " Check if the file exists
    let listPath = split(&path, ',')
    let szResolvedFilePath = ''
    if a:szFile==getreg('%')
        let szResolvedFilePath = a:szFile
    else
        for aPath in listPath
            let szFilePath = simplify(aPath.'/'.a:szFile)
            if getftime(szFilePath)>=0
                let szResolvedFilePath = szFilePath
                break
            endif
        endfor
    endif

    " File not found
    if szResolvedFilePath==''
        return result
    endif

    " Include guard test
    if has_key(s:CACHE_INCLUDE_GUARD, szResolvedFilePath)
        return result
    else
        let s:CACHE_INCLUDE_GUARD[szResolvedFilePath] = 1
    endif

    " The file exists, we get the global namespaces in this file
    " Searching for '#include'
    let szResolvedFilePath = escape(szResolvedFilePath, s:szEscapedCharacters)
    if g:CppOmni_NamespaceSearch==2
        execute 'silent! vimgrep /\C\(^using\s\+namespace\)\|\(^'.s:rePreprocIncludeFile.'\)/gj '.szResolvedFilePath
    elseif g:CppOmni_NamespaceSearch==1
        execute 'silent! vimgrep /\C^using\s\+namespace/gj '.szResolvedFilePath
    else
        return result
    endif

    let listQuickFix = getqflist()
    for qf in listQuickFix
        if qf.lnum >= stopLine && stopLine!=-1
            break
        endif

        let szLine = qf.text
        if match(szLine, '\C^'.s:rePreprocIncludeFile)>=0
            let startPos = qf.col
            let endPos = matchend(szLine, s:reIncludeFilePart, startPos-1)
            if endPos!=-1
                let szInclusion = szLine[startPos-1:endPos-1]
                let szIncludeFile = substitute(szInclusion, '\('.s:rePreprocIncludePart.'\)\|[<>""]', '', 'g')
                let result = result + s:GetNamespaceListFromBufffer(szIncludeFile)
            endif
        else
            let startPos = qf.col
            let endPos = match(szLine, ';', startPos-1)
            let endInstruction = [qf.lnum, endPos+1]
            if endPos!=-1
                " We get the namespace list from the line
                call extend(result, s:GetNamespaceListFromLine(szLine))
            endif
        endif
    endfor
    return result
endfunc

" Get namespaces used at the cursor postion in a vim buffer
" Note: The result depends on the current cursor position
" @return
"   -   List of namespace used in the reverse order
function! s:GetUsingNamespaces()
    " We have to get local using namespace declarations
    " We need the current cursor position and the position of the start of the
    " current scope

    " We store the cursor position because searchpairpos() moves the cursor
    let result = []
    let originalPos = getpos('.')
    let origPos = originalPos[1:2]
    let lastPos = origPos
    let curPos = origPos
    while curPos !=[0,0]
        let lastPos = curPos
        let curPos = searchpairpos('{', '', '}', 'bW', s:expIgnoreCommentForBracket)
    endwhile

    " 1) We get all local using namespace declaration from cursor to the beginning
    " of the scope (first '{')
    call setpos('.', originalPos)
    let stopLine = lastPos[0]
    let curPos = origPos
    let lastLine = 0 
    let nextStopLine = origPos[0]
    while curPos !=[0,0]
        let curPos = searchpos('\C}\|\(using\s\+namespace\)', 'bW',stopLine)
        if curPos!=[0,0] && curPos[0]!=lastLine
            let lastLine = curPos[0]

            let szLine = getline('.')
            if origPos[0] == curPos[0]
                " We get the line until cursor position
                let szLine = szLine[:origPos[1]]
            endif

            let szLine = s:GetCodeWithoutCommentsFromSingleLine(szLine)
            if match(szLine, '\Cusing\s\+namespace')<0
                " We found a '}'
                let curPos = searchpairpos('{', '', '}', 'bW', s:expIgnoreCommentForBracket)
            else
                " We get the namespace list from the line
                let result = s:GetNamespaceListFromLine(szLine) + result
                let nextStopLine = curPos[0]
            endif
        endif
    endwhile

    " Setting the cursor to the original position
    call setpos('.', originalPos)

    " Reset the include guard cache
    let s:CACHE_INCLUDE_GUARD = {}

    " 2) Now we can get all global using namespace declaration from the
    " beginning of the file to nextStopLine
    let result = s:GetNamespaceListFromBufffer(getreg('%'), nextStopLine) + result

    return ['::'] + result
endfunc

" Resolve a using namespace regarding the current context
" For each namespace used:
"   -   We get all possible contexts where the namespace
"       can be define
"   -   We do a comparison test of each parent contexts with the current
"       context list
"           -   If one and only one parent context is present in the
"               current context list we add the namespace in the current
"               context
"           -   If there is more than one of parent contexts in the
"               current context the namespace is ambiguous
" @return
"   - result item
"       - kind = 0|1
"           - 0 = unresolved or error
"           - 1 = resolved
"       - value = resolved namespace
function! s:ResolveNamespace(namespace, mapCurrentContexts)
    let result = {'kind':0, 'value': ''}

    " If the namespace is already resolved we add it in the list of 
    " current contexts
    if match(a:namespace, '^::')>=0
        let result.kind = 1
        let result.value = a:namespace
        return result
    elseif match(a:namespace, '\w\+::\w\+')>=0
        let mapCurrentContextsTmp = copy(a:mapCurrentContexts) 
        let resolvedItem = {}
        for nsTmp in  split(a:namespace, '::')
            let resolvedItem = s:ResolveNamespace(nsTmp, mapCurrentContextsTmp)
            if resolvedItem.kind
                " Note: We don't extend the map
                let mapCurrentContextsTmp = {resolvedItem.value : 1}
            else
                break
            endif
        endfor
        if resolvedItem!={} && resolvedItem.kind
            let result.kind = 1
            let result.value = resolvedItem.value
        endif
        return result
    endif

    " We get all possible parent contexts of this namespace
    let listTagsOfNamespace = []
    if has_key(s:CACHE_RESOLVE_NAMESPACES, a:namespace)
        let listTagsOfNamespace = s:CACHE_RESOLVE_NAMESPACES[a:namespace]
    else
        let listTagsOfNamespace = taglist('^'.a:namespace.'$')
        let s:CACHE_RESOLVE_NAMESPACES[a:namespace] = listTagsOfNamespace
    endif

    if len(listTagsOfNamespace)==0
        return result
    endif
    call filter(listTagsOfNamespace, 'v:val.kind[0]=="n"')

    " We extract parent context from tags
    " We use a map to avoid multiple entries
    let mapContext = {}
    for tagItem in listTagsOfNamespace
        let szParentContext = s:ExtractScopeFromTag(tagItem)
        let mapContext[szParentContext] = 1
    endfor
    let listParentContext = keys(mapContext)

    " Now for each parent context we test if the context is in the current
    " contexts list
    let listResolvedNamespace = []
    for szParentContext in listParentContext
        if has_key(a:mapCurrentContexts, szParentContext)
            call extend(listResolvedNamespace, [s:SimplifyScope(szParentContext.'::'.a:namespace)])
        endif
    endfor

    " Now we know if the namespace is ambiguous or not
    let len = len(listResolvedNamespace)
    if len==1
        " Namespace resolved
        let result.kind = 1
        let result.value = listResolvedNamespace[0]
    elseif len > 1
        " Ambiguous namespace, possible matches are in listResolvedNamespace
        "call s:DebugTrace("AMBIGUOUS", listResolvedNamespace)
    else
        " Other cases
    endif
    return result
endfunc

" Resolve namespaces
"@return
"   - List of resolved namespaces
function! s:ResolveAllNamespaces(namespacesUsed)

    " We add the default context '::'
    let contextOrder = 0
    let mapCurrentContexts  = {}

    " For each namespace used:
    "   -   We get all possible contexts where the namespace
    "       can be define
    "   -   We do a comparison test of each parent contexts with the current
    "       context list
    "           -   If one and only one parent context is present in the
    "               current context list we add the namespace in the current
    "               context
    "           -   If there is more than one of parent contexts in the
    "               current context the namespace is ambiguous
    for ns in a:namespacesUsed
        let resolvedItem = s:ResolveNamespace(ns, mapCurrentContexts)
        if resolvedItem.kind
            let contextOrder+=1
            let mapCurrentContexts[resolvedItem.value] = contextOrder
        endif
    endfor

    " Build the list of current contexts from the map, we have to keep the
    " order
    let mapReorder = {}
    for key in keys(mapCurrentContexts)
        let mapReorder[mapCurrentContexts[key]] = key
    endfor
    let result = []
    for key in sort(keys(mapReorder))
        call extend(result, [mapReorder[key]])
    endfor

    return result
endfunc


" Extract type from tokens.
" eg: examples of tokens format
"   'const MyClass&'
"   'const map < int, int >&'
"   'MyNs::MyClass'
"   '::MyClass**'
"   'MyClass a, *b = NULL, c[1] = {};
"   'hello(MyClass a, MyClass* b'
" @return the type info string eg: ::std::map
" can be empty
function! s:ExtractTypeInfoFromTokens(tokens)
    let szResult = ''
    let state = 0

    let tokens = s:BuildParenthesisGroups(a:tokens)

    " If there is an unbalanced parenthesis we are in a parameter list
    let bParameterList = 0
    for token in tokens
        if token.value == '(' && token.group==-1
            let bParameterList = 1
            break
        endif
    endfor

    if bParameterList
        let tokens = reverse(tokens)
        let state = 0
        let parenGroup = -1
        for token in tokens
            if state==0
                if token.value=='>'
                    let parenGroup = token.group
                    let state=1
                elseif token.kind == 'cppWord'
                    let szResult = token.value.szResult
                    let state=2
                endif
            elseif state==1
                if token.value=='<' && token.group==parenGroup
                    let state=0
                endif
            elseif state==2
                if token.value=='::'
                    let szResult = token.value.szResult
                    let state=3
                else
                    break
                endif
            elseif state==3
                if token.kind == 'cppWord'
                    let szResult = token.value.szResult
                    let state=2
                else
                    break
                endif
            endif
        endfor
        return szResult
    endif

    for token in tokens
        if state==0
            if token.value == '::'
                let szResult .= token.value
                let state = 1
            elseif token.kind == 'cppWord'
                let szResult .= token.value
                let state = 2
                " Maybe end of token
            endif
        elseif state==1
            if token.kind == 'cppWord'
                let szResult .= token.value
                let state = 2
                " Maybe end of token
            else
                break
            endif
        elseif state==2
            if token.value == '::'
                let szResult .= token.value
                let state = 1
            else
                break
            endif
        endif
    endfor
    return szResult
endfunc

" Extract the cmd of a tag item without regexp
function! s:ExtractCmdFromTagItem(tagItem)
    let line = a:tagItem.cmd
    let re = '\(\/\^\)\|\(\$\/\)'
    if match(line, re)!=-1
        let line = substitute(line, re, '', 'g')
        return line
    else
        " TODO: the cmd is a line number
        return ''
    endif
endfunc

" Function create a type info
function! s:CreateTypeInfo(param)
    let type = type(a:param)
    return {'type': type, 'value':a:param}
endfunc

" Returns if the type info is valid
" @return
"   - 1 if valid
"   - 0 otherwise
function! s:IsTypeInfoValid(typeInfo)
    if a:typeInfo=={}
        return 0
    else
        if a:typeInfo.type == 1 && a:typeInfo.value==''
            " String case
            return 0
        elseif a:typeInfo.type == 4 && a:typeInfo.value=={}
            " Dictionary case
            return 0
        endif
    endif
    return 1
endfunc

" Search a declaration
" @return
"   - tokens of the current instruction if success
"   - empty list if failure
function! s:SearchDecl(szVariable, global, thisblock)
    let result = []
    let searchResult = searchdecl(a:szVariable, a:global, a:thisblock)
    if searchResult==0
        " searchdecl() may detect a decl if the variable is in a conditional
        " instruction (if, elseif, while etc...)
        " We have to check if the detected decl is really a decl instruction
        let result = s:TokenizeCurrentInstruction()
        for token in result
            " Simple test
            if index(['if', 'elseif', 'while', 'for', 'switch'], token.value)>=0
                " Invalid declaration instruction
                let result = []
                break
            endif
        endfor
    endif
    return result
endfunc

" Return if the tag item represent an unnamed type
function! s:IsUnnamedType(tagItem)
    let bResult = 0
    if has_key(a:tagItem, 'typename')
        if str2nr(substitute(a:tagItem.typename, '.*:', '', 'g'))!=0
            let bResult = 1
        endif
    endif
    return bResult
endfunc

" Resolve a symbol, return a tagItem
" Gets the first symbol found in the context stack
function! s:ResolveSymbol(contextStack, szSymbol, szTagFilter)
    let tagItem = {}
    for szCurrentContext in a:contextStack
        if szCurrentContext != '::'
            let szTagQuery = substitute(szCurrentContext, '^::', '', 'g').'::'.a:szSymbol
        else
            let szTagQuery = a:szSymbol
        endif

        let tagList = taglist('^'.szTagQuery.'$')
        call filter(tagList, a:szTagFilter)
        if len(tagList)
            let tagItem = tagList[0]
            break
        endif
    endfor
    return tagItem
endfunc

" Search a declaration.
" eg: std::map
" can be empty
" Note: The returned type info can be a typedef
" The typedef resolution is done later
" @return
"   - a dictionnary where keys are
"       - type: the type of value same as type()
"       - value: the value
function! s:GetTypeInfoOfVariable(contextStack, szVariable)
    let result = {}

    " Search declaration
    let tokensDecl = s:SearchDecl(a:szVariable, 0, 1)

    if len(tokensDecl)==0
        let szFilter = "index(['m', 'v'], v:val.kind[0])>=0"
        let tagItem = s:ResolveSymbol(a:contextStack, a:szVariable, szFilter)
        if tagItem=={}
            return result
        endif
        if has_key(tagItem, 'typename')
            " Maybe the variable is a global var of an
            " unnamed class, struct or union.
            " eg:
            " 1)
            " struct
            " {
            " }gVariable;
            " In this case we need the tags (the patched version)
            " Note: We can have a named type like this:
            " 2)
            " class A
            " {
            " }gVariable;
            if s:IsUnnamedType(tagItem)
                " It's an unnamed type we are in the case 1)
                let result = s:CreateTypeInfo(tagItem)
            else
                " It's not an unnamed type we are in the case 2)
                let result = s:CreateTypeInfo(substitute(tagItem.typename, '\w\+:', '', 'g'))
            endif
        else
            let szCmdWithoutVariable = substitute(s:ExtractCmdFromTagItem(tagItem), '\C\<'.a:szVariable.'\>.*', '', 'g')
            let tokens = s:Tokenize(s:GetCodeWithoutCommentsFromSingleLine(szCmdWithoutVariable))
            let result = s:CreateTypeInfo(s:ExtractTypeInfoFromTokens(tokens))
            " TODO: Namespace resolution for result
        endif
    else
        let result = s:CreateTypeInfo(s:ExtractTypeInfoFromTokens(tokensDecl))
    endif

    return result
endfunc

" Get the type info string from the returned type of function
function! s:GetTypeInfoOfReturnedType(contextStack, szFunctionName)
    let result = {}

    let szFilter = "index(['f', 'p'], v:val.kind[0])>=0"
    let tagItem = s:ResolveSymbol(a:contextStack, a:szFunctionName, szFilter)

    if tagItem != {}
        let szCmdWithoutVariable = substitute(s:ExtractCmdFromTagItem(tagItem), '\C\<'.a:szFunctionName.'\>.*', '', 'g')
        let tokens = s:Tokenize(s:GetCodeWithoutCommentsFromSingleLine(szCmdWithoutVariable))
        let result = s:CreateTypeInfo(s:ExtractTypeInfoFromTokens(tokens))
        " TODO: Namespace resolution for result
        return result
    endif
    return result
endfunc

" A resolved type info starts with '::'
" @return
"   - 1 if type info starts with '::'
"   - 0 otherwise
function! s:IsTypeInfoResolved(szTypeInfo)
    return match(a:szTypeInfo, '^::')!=-1
endfunc

" Get the string of the type info
function! s:GetTypeInfoString(typeInfo)
    if a:typeInfo.type == 1
        return a:typeInfo.value
    else
        return substitute(a:typeInfo.value.typename, '^\w\+:', '', 'g')
    endif
endfunc

" Get symbol name
function! s:GetSymbol(tokens)
    let szSymbol = ''
    let state = 0
    for token in a:tokens
        if state == 0
            if token.value == '::'
                let szSymbol .= token.value
                let state = 1
            elseif token.kind == 'cppWord'
                let szSymbol .= token.value
                let state = 2
                " Maybe end of token
            endif
        elseif state == 1
            if token.kind == 'cppWord'
                let szSymbol .= token.value
                let state = 2
                " Maybe end of token
            else
                " Error
                break
            endif
        elseif state == 2
            if token.value == '::'
                let szSymbol .= token.value
                let state = 1
            else
                break
            endif
        endif
    endfor
    return szSymbol
endfunc

" Resolve type information of items
" @param namespaces: list of namespaces used in the file
" @param szCurrentClassScope: the current class scope, only used for the first
" item to detect if this item is a class member (attribute, method)
" @param items: list of item, can be an empty list @see GetItemsToComplete
function! s:ResolveItemsTypeInfo(contextStack, items)
    " Note: kind = itemVariable|cCast|cppCast|template|function|itemUnknown|this
    " For the first item, if it's a variable we try to detect the type of the
    " variable with the function searchdecl. If it fails, thanks to the
    " current class scope, we try to detect if the variable is an attribute
    " member.
    " If the kind of the item is a function, we have to first check if the
    " function is a method of the class, if it fails we try to get a match in
    " the global namespace. After that we get the returned type of the
    " function.
    " It the kind is a C cast or C++ cast, there is no problem, it's the
    " easiest case. We just extract the type of the cast.

    let szCurrentContext = ''
    let typeInfo = {}
    for item in a:items
        let curItem = item
        if index(['itemVariable', 'itemFunction'], curItem.kind)>=0
            " Note: a variable can be : MyNs::MyClass::_var or _var or (*pVar)
            " or _var[0][0]
            let szSymbol = s:GetSymbol(curItem.tokens)

            " If we have MyNamespace::myVar
            " We add MyNamespace in the context stack set szSymbol to myVar
            if match(szSymbol, '::\w\+$') >= 0
                let szCurrentContext = substitute(szSymbol, '::\w\+$', '', 'g')
                let szSymbol = matchstr(szSymbol, '\w\+$')
            endif
            let tmpContextStack = a:contextStack
            if szCurrentContext != ''
                let tmpContextStack = [szCurrentContext] + a:contextStack
            endif

            if curItem.kind == 'itemVariable'
                let typeInfo = s:GetTypeInfoOfVariable(tmpContextStack, szSymbol)
            else
                let typeInfo = s:GetTypeInfoOfReturnedType(tmpContextStack, szSymbol)
            endif

        elseif curItem.kind == 'itemThis'
            if len(a:contextStack)
                let typeInfo = s:CreateTypeInfo(substitute(a:contextStack[0], '^::', '', 'g'))
            endif
        elseif curItem.kind == 'itemCast'
            let typeInfo = s:CreateTypeInfo(s:ResolveCCast(curItem.tokens))
        elseif curItem.kind == 'itemCppCast'
            let typeInfo = s:CreateTypeInfo(s:ResolveCppCast(curItem.tokens))
        elseif curItem.kind == 'itemScope'
            let typeInfo = s:CreateTypeInfo(substitute(s:TokensToString(curItem.tokens), '\s', '', 'g'))
        endif

        if s:IsTypeInfoValid(typeInfo)
            let szCurrentContext = s:GetTypeInfoString(typeInfo)
        endif
    endfor

    return typeInfo
endfunc

" Get the preview window string
function! s:GetPreviewWindowStringFromTagItem(tagItem)
    let szResult = ''

    let szResult .= 'name: '.a:tagItem.name."\n"
    for tagKey in keys(a:tagItem)
        if index(['name', 'static'], tagKey)>=0
            continue
        endif
        let szResult .= tagKey.': '.a:tagItem[tagKey]."\n"
    endfor

    return szResult
endfunc

" Convert a tag_item (from taglist()) to a popup item
" @return
"   - popuitem
"   - {}
function! s:ConvertTagItemToPopupItem(tagItem)
    let szItemWord = substitute(a:tagItem.name, '.*::', '', 'g')
    "let szItemWord = a:tagItem.name
    " If the tagid is a function or a prototype we add a
    " parenthesis
    " Note: tagItem values can be in single letter format so
    " we always test the first letter
    let bDuplicate = 0
    let szScopeOfTag = s:ExtractScopeFromTag(a:tagItem)
    if index(['f', 'p'], a:tagItem.kind[0])>=0
        if has_key(a:tagItem, 'signature')
            let szKeyFunc = szScopeOfTag.'::'.szItemWord.a:tagItem.signature
            " We don't want same function name with same signature
            if has_key(s:CACHE_FUNCTION_TAGS, szKeyFunc)
                return {}
            else
                let s:CACHE_FUNCTION_TAGS[szKeyFunc] = a:tagItem
            endif
        endif

        if s:hasPreviewWindow
            " We only show duplicate entries for function and prototypes,
            " thus the user can see different signature
            let bDuplicate = 1
        endif
        let szItemWord = szItemWord . '('
    endif

    " If it's a prototype then change the letter to 'f' (for function)
    let szItemKind = substitute(a:tagItem.kind[0], 'p', 'f', 'g')

    " Add the access
    let szItemMenu = ''
    let accessChar = {'public': '+','protected': '#','private': '-'}
    if has_key(a:tagItem, 'access')
        let szItemMenu = szItemMenu.accessChar[a:tagItem.access]
    else
        let szItemMenu = szItemMenu." "
    endif

    let szAbbr = ''

    " Formating optional menu string
    " We extract the scope information
    if !g:CppOmni_ShowScopeInAbbr
        let szItemMenu = szItemMenu.' '.szScopeOfTag[2:]
        let szItemMenu = substitute(szItemMenu, '\s\+$', '', 'g')
    else
        let szAbbr = a:tagItem.name
    endif

    let szItemMenu = substitute(szItemMenu, '^\s\+$', '', 'g')

    " Formating information for the preview window
    let szItemInfo = s:GetPreviewWindowStringFromTagItem(a:tagItem)

    let popupItem = {'word':szItemWord, 'abbr':szAbbr,'kind':szItemKind, 'menu':szItemMenu, 'info':szItemInfo, 'dup':bDuplicate}
    return popupItem
endfunc

" Convert a tag item list to popup item list
function! s:DisplayPopupItemList(tagList, baseFilter)
    let result = []

    let szKey = string(map(copy(a:tagList), 'v:val.name . v:val.kind . v:val.filename'))

    if !g:CppOmni_PopupRealTimeBuild
        if has_key(s:CACHE_DISPLAY_POPUP, szKey)
            let result = s:CACHE_DISPLAY_POPUP[szKey]
            call extend(s:popupItemResultList, result)
            return
        endif
    endif

    for tagItem in a:tagList
        let popupItem = s:ConvertTagItemToPopupItem(tagItem)
        if popupItem != {}
            if g:CppOmni_PopupRealTimeBuild 
                if match(popupItem.word, '^\C'.a:baseFilter)!=-1
                    call complete_add(popupItem)
                endif
            else
                call extend(result, [popupItem])
            endif
        endif
    endfor

    if !g:CppOmni_PopupRealTimeBuild
        let s:CACHE_DISPLAY_POPUP[szKey] = result
        call extend(s:popupItemResultList, result)
    endif
endfunc

" A returned type info's scope may not have the global namespace '::'
" eg: '::NameSpace1::NameSpace2::MyClass' => '::NameSpace1::NameSpace2'
" 'NameSpace1::NameSpace2::MyClass' => 'NameSpace1::NameSpace2'
function! s:ExtractScopeFromTypeInfo(szTypeInfo)
    let szScope = substitute(a:szTypeInfo, '\w\+$', '', 'g')
    if szScope =='::'
        return szScope
    else
        return substitute(szScope, '::$', '', 'g')
    endif
endfunc

" Extract the scope (context) of a tag item
" eg: ::MyNamespace
" @return a string of the scope. a scope from tag always starts with '::'
function! s:ExtractScopeFromTag(tagItem)
    let listKindScope = ['class', 'struct', 'union', 'namespace', 'enum']
    let szResult = '::'
    for scope in listKindScope
        if has_key(a:tagItem, scope)
            let szResult = szResult . a:tagItem[scope]
            break
        endif
    endfor
    return szResult
endfunc

" Extract type info from a tag item
" eg: ::MyNamespace::MyClass
function! s:ExtractTypeInfoFromTag(tagItem)
    let szTypeInfo = s:ExtractScopeFromTag(a:tagItem) . '::' . substitute(a:tagItem.name, '.*::', '', 'g')
    return s:SimplifyScope(szTypeInfo)
endfunc

" @return
"   -   the tag with the same scope
"   -   {} otherwise
function! s:GetTagOfSameScope(listTags, szScopeToMatch)
    for tagItem in a:listTags 
        let szScopeOfTag = s:ExtractScopeFromTag(tagItem)
        if szScopeOfTag == a:szScopeToMatch
            return tagItem
        endif
    endfor
    return {}
endfunc

" Search class, struct, union members.
" If the class has inherited informations we get also the inherited members
function! s:SearchAllMembers(resolvedTagItem)
    let result = []

    " Complete check
    if complete_check() || a:resolvedTagItem == {}
        return result
    endif

    call extend(result, s:SearchMembers(a:resolvedTagItem))
    if has_key(a:resolvedTagItem, 'inherits')
        " We don't forget multiple inheritance
        " Note: in the baseClassTypeInfoList there is no information
        " about the inheritance acces ('public', 'protected', 'private')
        " the only way to find it is to use the cmd info of the tag. But it's
        " not 100% fiable
        let baseClassTypeInfoList = split(a:resolvedTagItem.inherits, ',')

        " Getting members of all base classes
        for baseClassTypeInfo in baseClassTypeInfoList
            " We have to resolve the correct namespace of baseClassTypeInfo
            " we can have '::Class1' 'Class1' 'NameSpace1::NameSpace2::Class8'
            let namespaces = [s:ExtractScopeFromTag(a:resolvedTagItem), '::']
            let resolvedTagItem = s:GetResolvedTagItem(namespaces, s:CreateTypeInfo(baseClassTypeInfo))
            call extend(result, s:SearchAllMembers(resolvedTagItem))
        endfor
    endif
    return result
endfunc

" Get a tag item after a scope resolution and typedef resolution
function! s:GetResolvedTagItem(namespaces, typeInfo)
    let result = {}
    if !s:IsTypeInfoValid(a:typeInfo)
        return result
    endif

    " Unnamed type case eg: '1::2'
    if a:typeInfo.type == 4
        " Here there is no typedef or namespace to resolve, the tagInfo.value is a tag item
        " representing a variable ('v') a member ('m') or a typedef ('t') and the typename is
        " always in global scope
        return a:typeInfo.value
    endif

    " Named type case eg:  'MyNamespace::MyClass'
    let szTypeInfo = s:GetTypeInfoString(a:typeInfo)
    if szTypeInfo=='::'
        return result
    endif

    " We can only get members of class, struct, union and namespace
    let szTagFilter = "index(['c', 's', 'u', 'n', 't'], v:val.kind[0])>=0"
    let szTagQuery = szTypeInfo

    if s:IsTypeInfoResolved(szTypeInfo)
        " The type info is already resolved, we remove the starting '::'
        let szTagQuery = substitute(szTypeInfo, '^::', '', 'g')
        if len(split(szTagQuery, '::'))==1
            " eg: ::MyClass
            " Here we have to get tags that have no parent scope
            " That's why we change the szTagFilter
            let szTagFilter .= '&& '.s:szFilterGlobalScope
            let tagList = taglist('^'.szTagQuery.'$')
            call filter(tagList, szTagFilter)
            if len(tagList)
                let result = tagList[0]
            endif
        else
            " eg: ::MyNamespace::MyClass
            let tagList = taglist('^'.szTagQuery.'$')
            call filter(tagList, szTagFilter)

            if len(tagList)
                let result = tagList[0]
            endif
        endif
    else
        " The type is not resolved
        let tagList = taglist('^'.szTagQuery.'$')
        call filter(tagList, szTagFilter)

        if len(tagList)
            " Resolving scope (namespace, nested class etc...)
            let szScopeOfTypeInfo = s:ExtractScopeFromTypeInfo(szTypeInfo)
            if s:IsTypeInfoResolved(szTypeInfo)
                let result = s:GetTagOfSameScope(tagList, szScopeOfTypeInfo)
            else
                " For each namespace of the namespace list we try to get a tag
                " that can be in the same scope
                if g:CppOmni_NamespaceSearch
                    for scope in a:namespaces
                        let szTmpScope = s:SimplifyScope(scope.'::'.szScopeOfTypeInfo)
                        let result = s:GetTagOfSameScope(tagList, szTmpScope)
                        if result!={}
                            break
                        endif
                    endfor
                endif
            endif
        endif
    endif

    if result!={}
        " We have our tagItem but maybe it's a typedef or an unnamed type
        if result.kind[0]=='t'
            " Here we can have a typedef to another typedef, a class, struct, union etc
            " but we can also have a typedef to an unnamed type, in that
            " case the result contains a 'typename' key
            let namespaces = [s:ExtractScopeFromTag(result), '::']
            if has_key(result, 'typename')
                let result = s:GetResolvedTagItem(namespaces, s:CreateTypeInfo(result))
            else
                let szCmd = s:ExtractCmdFromTagItem(result)
                let szCode = substitute(s:GetCodeWithoutCommentsFromSingleLine(szCmd), '\C\<'.result.name.'\>.*', '', 'g')
                let szTypeInfo = s:ExtractTypeInfoFromTokens(s:Tokenize(szCode))
                let result = s:GetResolvedTagItem(namespaces, s:CreateTypeInfo(szTypeInfo))
                " TODO: Namespace resolution for result
            endif
        endif
    endif

    return result
endfunc

" Search class, struct, union members
" @param filename: the file name or path where the class is defined (in most
" of cast it's a file header)
" @param typeInfo: the type info string of the class eg: 'MyNs::MyClass'
" @return list of tag items
function! s:SearchMembers(tagItem)
    let result = []
    if complete_check()
        return result
    endif

    " Get type info without the starting '::'
    let szTagName = s:ExtractTypeInfoFromTag(a:tagItem)[2:]

    " Unnamed type case
    " A tag item representing an unnamed type is a variable ('v') a member
    " ('m') or a typedef ('t')
    if index(['v', 't', 'm'], a:tagItem.kind[0])>=0 && has_key(a:tagItem, 'typename')
        " We remove the 'struct:' or 'class:' etc...
        let szTagName = substitute(a:tagItem.typename, '^\w\+:', '', 'g')
    endif

    " Formatting the result key for the result cache.
    let resultKey = szTagName

    " If the file has not changed and if tag env
    " has not changed we return the stored result 
    if has_key(s:CACHE_RESULT, resultKey)
        return s:CACHE_RESULT[resultKey]
    endif

    let tagQuery = '^'.szTagName.'::\w\+$'

    " Because we want to get members we add the
    " option -c++-kinds=+p to detect function prototypes in header files.
    " To get members we need also the option : --extra=+q
    " so we can have tag item name that start with the class name eg: 'MyClass::_member'
    " we add --language-force=c++ because the tmp file has no extension
    " we need access member information : +a
    " tags database must be build with that cmd 'ctags -R --c++-kinds=+p --fields=+iaS --extra=+q -f DST_FILE SRC_DIR'
    let classMembers = taglist(tagQuery)

    let szCtorName = szTagName . '::' . matchstr(szTagName, '\w\+$')
    " We don't want ctors and dtors
    " Note: dtors are not in the classMembers list thanks to our tagQuery
    let szFilter = "(index([szCtorName], v:val.name)<0 && index(['p', 'f'], v:val.kind[0])>=0)"
    let szFilter = szFilter."|| (index(['c','e','g','m','n','s','t','u','v'], v:val.kind[0])>=0)"
    call filter(classMembers, szFilter)
    call extend(result, classMembers)

    " We store the result for optimization
    " We update the result only if the file where typeInfo is define changed
    let s:CACHE_RESULT[resultKey] = result

    return result
endfunc

" Return if the tag env has changed
function! s:HasTagEnvChanged()
    if s:CACHE_TAG_ENV == &tags
        return 0
    else
        let s:CACHE_TAG_ENV = &tags
        return 1
    endif
endfunc

" Return if a tag file has changed in tagfiles()
function! s:HasATagFileOrTagEnvChanged()
    if s:HasTagEnvChanged()
        let s:CACHE_TAG_FILES = {}
        return 1
    endif

    let result = 0
    for tagFile in tagfiles()
        if has_key(s:CACHE_TAG_FILES, tagFile)
            let currentFiletime = getftime(tagFile)
            if currentFiletime > s:CACHE_TAG_FILES[tagFile]
                " The file has changed, updating the cache
                let s:CACHE_TAG_FILES[tagFile] = currentFiletime
                let result = 1
            endif
        else
            " We store the time of the file
            let s:CACHE_TAG_FILES[tagFile] = getftime(tagFile)
            let result = 1
        endif
    endfor
    return result
endfunc
" Initialization
call s:HasATagFileOrTagEnvChanged()

" Find complete matches for a completion on the global scope
function! s:DisplayGlobalScopeMembers(base)
    if a:base!=''
        let szKey = a:base
        let bFound = 0
        while len(szKey)>0
            if has_key(s:CACHE_GLOBAL_SCOPE_TAGS, szKey) && szKey!=''
                let bFound = 1
                break
            endif
            let szKey = szKey[:-2]
        endwhile

        if bFound
            let tagList = s:CACHE_GLOBAL_SCOPE_TAGS[szKey]
        else
            let tagList = taglist('^\C'.a:base.'.*')
            call filter(tagList, s:szFilterGlobalScope)
            let s:CACHE_GLOBAL_SCOPE_TAGS[a:base] = tagList
        endif
        call s:DisplayPopupItemList(tagList, a:base)
    endif
endfunc

" Build a class inheritance list
" TODO: Verify inheritance order
function! s:GetClassInheritanceList(namespaces, typeInfo, result)
    let result = a:result
    let tagItem = s:GetResolvedTagItem(a:namespaces, a:typeInfo)

    if tagItem!={}
        call extend(result, [s:ExtractTypeInfoFromTag(tagItem)])
        if has_key(tagItem, 'inherits')
            for baseClassTypeInfo in split(tagItem.inherits, ',')
                let namespaces = [s:ExtractScopeFromTag(tagItem), '::']
                call s:GetClassInheritanceList(namespaces, s:CreateTypeInfo(baseClassTypeInfo), result)
            endfor
        endif
    endif
endfunc

" Display class members in the popup menu after a completion with -> or .
function! s:DisplayClassMembers(tagList, base)
    let szFilter = "index(['m', 'p', 'f'], v:val.kind[0])>=0 && has_key(v:val, 'access')"
    call filter(a:tagList, szFilter)
    call s:DisplayPopupItemList(a:tagList, a:base)
endfunc

" Display class scope members in the popup menu after a completion with ::
" We only display attribute and functions members that
" have an access information. We also display nested
" class, struct, union, and enums, typedefs
function! s:DisplayClassScopeMembers(tagList, base)
    let szFilter = "(index(['m', 'p', 'f'], v:val.kind[0])>=0 && has_key(v:val, 'access'))"
    let szFilter .= "|| index(['c','e','g','s','t','u'], v:val.kind[0])>=0"
    call filter(a:tagList, szFilter)
    call s:DisplayPopupItemList(a:tagList, a:base)
endfunc

" Display static class members in the popup menu
function! s:DisplayStaticClassMembers(tagList, base)
    let szFilter = "(index(['m', 'p', 'f'], v:val.kind[0])>=0 && has_key(v:val, 'access') && match(v:val.cmd, '\\Cstatic')!=-1)"
    let szFilter = szFilter . "|| index(['c','e','g','n','s','t','u','v'], v:val.kind[0])>=0"
    call filter(a:tagList, szFilter)
    call s:DisplayPopupItemList(a:tagList, a:base)
endfunc

" Display scope members in the popup menu
function! s:DisplayNamespaceScopeMembers(tagList, base)
    call s:DisplayPopupItemList(a:tagList, a:base)
endfunc

" Build the context stack
" TODO: Add CACHE
function! s:BuildContextStack(namespaces, szCurrentScope)
    let result = copy(a:namespaces)
    if a:szCurrentScope != '::'
        let tagItem = s:GetResolvedTagItem(a:namespaces, s:CreateTypeInfo(a:szCurrentScope))
        if has_key(tagItem, 'inherits')
            let listBaseClass =  []
            call s:GetClassInheritanceList(a:namespaces, s:CreateTypeInfo(a:szCurrentScope), listBaseClass)
            let result = listBaseClass + result
        elseif has_key(tagItem, 'kind') && index(['c', 's', 'u'], tagItem.kind[0])>=0
            call insert(result, s:ExtractTypeInfoFromTag(tagItem))
        endif
    endif
    return result
endfunc

" Init data at the start of completion
function! s:InitDatas()
    " Reset the popup item list
    let s:popupItemResultList = []
    let s:CACHE_FUNCTION_TAGS = {}

    " Has preview window ?
    let s:hasPreviewWindow = match(&completeopt, 'preview')>=0

    " Reset tag env or tag files dependent caches
    if s:HasATagFileOrTagEnvChanged()
        let s:CACHE_RESOLVE_NAMESPACES = {}
        let s:CACHE_RESULT = {}
        let s:CACHE_GLOBAL_SCOPE_TAGS = {}
        let s:CACHE_DISPLAY_POPUP = {}
    endif
    let s:bCursorInCommentOrString = 0
endfunc

" Check if the cursor is in comment
function! s:IsCursorInCommentOrString()
    return match(synIDattr(synID(line("."), col(".")-1, 1), "name"), '\C\<cComment\|\<cCppString\|\<cIncluded')>=0
endfunc

" May complete function for dot
function! cppomnicomplete#MayCompleteDot()
    " For C and C++ files and only if the omnifunc is cppomnicomplete#Complete
    if index(['c', 'cpp'], &filetype)>=0 && &omnifunc == 'cppomnicomplete#Complete'
        if !s:IsCursorInCommentOrString()
            let s:itemsToComplete = s:GetItemsToComplete(s:TokenizeCurrentInstruction('.'))
            if len(s:itemsToComplete) && s:itemsToComplete[-1].kind != 'itemNumber'
                let s:bMayComplete = 1
                return ".\<C-X>\<C-O>"
            endif
        endif
    endif
    return '.'
endfunc

" May complete function for arrow
function! cppomnicomplete#MayCompleteArrow()
    " For C and C++ files and only if the omnifunc is cppomnicomplete#Complete
    let index = col('.') - 2
    if index >= 0
        let char = getline('.')[index]
        if index(['c', 'cpp'], &filetype)>=0 && &omnifunc == 'cppomnicomplete#Complete' && char == '-'
            if !s:IsCursorInCommentOrString()
                let s:itemsToComplete = s:GetItemsToComplete(s:TokenizeCurrentInstruction('>'))
                if len(s:itemsToComplete) && s:itemsToComplete[-1].kind != 'itemNumber'
                    let s:bMayComplete = 1
                    return ">\<C-X>\<C-O>"
                endif
            endif
        endif
    endif
    return '>'
endfunc

" May complete function for double points
function! cppomnicomplete#MayCompleteScope()
    " For C and C++ files and only if the omnifunc is cppomnicomplete#Complete
    let index = col('.') - 2
    if index >= 0
        let char = getline('.')[index]
        if index(['c', 'cpp'], &filetype)>=0 && &omnifunc == 'cppomnicomplete#Complete' && char == ':'
            if !s:IsCursorInCommentOrString()
                let s:itemsToComplete = s:GetItemsToComplete(s:TokenizeCurrentInstruction(':'))
                if len(s:itemsToComplete)
                    if len(s:itemsToComplete[-1].tokens) && s:itemsToComplete[-1].tokens[-1].value != '::'
                        let s:bMayComplete = 1
                        return ":\<C-X>\<C-O>"
                    endif
                endif
            endif
        endif
    endif
    return ':'
endfunc

" This function is used for the 'omnifunc' option.
function! cppomnicomplete#Complete(findstart, base)

    if a:findstart
        "call s:DebugStart()

        call s:InitDatas()

        " Note: if s:bMayComplete==1 s:itemsToComplete is build by MayComplete functions
        if !s:bMayComplete
            " If the cursor is in a comment we go out
            if s:IsCursorInCommentOrString()
                " Returning -1 is not enough we have to set a variable to let
                " the second call of cppomnicomplete#Complete knows that the
                " cursor was in a comment
                " Why is there a second call when the first call returns -1 ?
                let s:bCursorInCommentOrString = 1
                return -1
            endif

            " We get items here (whend a:findstart==1) because GetItemsToComplete()
            " depends on the cursor position.
            " When a:findstart==0 the cursor position is modified
            let s:itemsToComplete = s:GetItemsToComplete(s:TokenizeCurrentInstruction())
        endif

        " Get the current class scope at the cursor, the result depend on the
        " current cursor position
        let s:scopeItem = s:GetClassScopeAtCursor()
        let s:listUsingNamespace = copy(g:CppOmni_DefaultNamespaces)
        call extend(s:listUsingNamespace, s:scopeItem.namespaces)

        if g:CppOmni_NamespaceSearch
            " Get namespaces used in the file until the cursor position
            let s:listUsingNamespace = s:GetUsingNamespaces() + s:listUsingNamespace
        endif

        " Reinit of may complete indicator
        let s:bMayComplete = 0
        return s:FindStartPositionOfCompletion()
    endif

    " If the cursor was in a comment we return an empty result
    if s:bCursorInCommentOrString
        let s:bCursorInCommentOrString = 0
        return []
    endif

    " Resolving namespaces, removing amiguous namespaces
    if g:CppOmni_NamespaceSearch
        let namespaces = s:ResolveAllNamespaces(s:listUsingNamespace)
    else
        let namespaces = ['::'] + s:listUsingNamespace
    endif

    " Reversing namespaces order
    call reverse(namespaces)

    " Building context stack from namespaces and the current class scope
    let contextStack = s:BuildContextStack(namespaces, s:scopeItem.scope)

    if len(s:itemsToComplete)==0
        " A) CURRENT_SCOPE_COMPLETION_MODE

        " 1) Displaying data of each context
        for szCurrentContext in contextStack
            if szCurrentContext == '::'
                continue
            endif

            let resolvedTagItem = s:GetResolvedTagItem(contextStack, s:CreateTypeInfo(szCurrentContext))
            if resolvedTagItem != {}
                let tagList = s:SearchAllMembers(resolvedTagItem)
                if index(['c','s'], resolvedTagItem.kind[0])>=0
                    " It's a class or struct
                    call s:DisplayClassScopeMembers(tagList, a:base)
                else
                    " It's a namespace or union, we display all members
                    call s:DisplayPopupItemList(tagList, a:base)
                endif
            endif
        endfor

        " 2) Displaying global scope members
        if g:CppOmni_GlobalScopeSearch
            call s:DisplayGlobalScopeMembers(a:base)
        endif
    else
        let typeInfo = s:ResolveItemsTypeInfo(contextStack, s:itemsToComplete)
        if typeInfo != {}
            if s:itemsToComplete[-1].kind == 'itemScope'
                " B) SCOPE_COMPLETION_MODE
                if s:GetTypeInfoString(typeInfo)==''
                    call s:DisplayGlobalScopeMembers(a:base)
                else
                    let resolvedTagItem = s:GetResolvedTagItem(contextStack, typeInfo)
                    if resolvedTagItem != {}
                        let tagList = s:SearchAllMembers(resolvedTagItem)
                        if index(['c','s'], resolvedTagItem.kind[0])>=0
                            if g:CppOmni_ClassScopeCompletionMethod==0
                                " We want to complete a class or struct
                                " If this class is a base class so we display all class members
                                if index(contextStack, s:ExtractTypeInfoFromTag(resolvedTagItem))>=0
                                    call s:DisplayClassScopeMembers(tagList, a:base)
                                else
                                    call s:DisplayStaticClassMembers(tagList, a:base)
                                endif
                            else
                                call s:DisplayClassScopeMembers(tagList, a:base)
                            endif
                        else
                            " We want to complete a namespace
                            call s:DisplayNamespaceScopeMembers(tagList, a:base)
                        endif
                    endif
                endif
            else
                " C) CLASS_MEMBERS_COMPLETION_MODE
                let resolvedTagItem = s:GetResolvedTagItem(contextStack, typeInfo)
                let tagList = s:SearchAllMembers(resolvedTagItem)
                call s:DisplayClassMembers(tagList, a:base)
            endif
        endif
    endif

    "call s:DebugEnd()

    " Note: s:popupItemResultList only used when g:CppOmni_PopupRealTimeBuild == 0
    let result = filter(copy(s:popupItemResultList), 'match(v:val.word, "\\C^".a:base)>=0')
    return result
endfunc
