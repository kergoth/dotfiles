" Vim completion script
" Language:  C++
" Maintainer:  Vissale NEANG
" Last Change:  2006 May 2
" Comments:
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
"   -   First realease

if v:version < 700
    echomsg "cppomnicomplete.vim: Please install vim 7.0 or higher for omni-completion"
    finish
endif

" Cache data
let s:filedateCache = {}
let s:resultCache = {}
let s:globalScopeCache = {}
let s:tagFilesCache = {}
let s:tagEnvCache = ''

" From the C++ BNF
let s:cppKeyword = ['asm', 'auto', 'bool', 'break', 'case', 'catch', 'char', 'class', 'const', 'const_cast', 'continue', 'default', 'delete', 'do', 'double', 'dynamic_cast', 'else', 'enum', 'explicit', 'export', 'extern', 'false', 'float', 'for', 'friend', 'goto', 'if', 'inline', 'int', 'long', 'mutable', 'namespace', 'new', 'operator', 'private', 'protected', 'public', 'register', 'reinterpret_cast', 'return', 'short', 'signed', 'sizeof', 'static', 'static_cast', 'struct', 'switch', 'template', 'this', 'throw', 'true', 'try', 'typedef', 'typeid', 'typename', 'union', 'unsigned', 'using', 'virtual', 'void', 'volatile', 'wchar_t', 'while', 'and', 'and_eq', 'bitand', 'bitor', 'compl', 'not', 'not_eq', 'or', 'or_eq', 'xor', 'xor_eq']

let s:reCppKeyword = '\<'.join(s:cppKeyword, '\>\|\<').'\>'

" The order of items in this list is very important because we use this list to build a regular
" expression (see below) for tokenization
let s:cppOperatorPunctuator = ['->*', '->', '--', '-=', '-', '!=', '!', '##', '#', '%:%:', '%=', '%>', '%:', '%', '&&', '&=', '&', '(', ')', '*=', '*', ',', '...', '.*', '.', '/=', '/', '::', ':>', ':', ';', '?', '[', ']', '^=', '^', '{', '||', '|=', '|', '}', '~', '++', '+=', '+', '<<=', '<%', '<:', '<<', '<=', '<', '==', '=', '>>=', '>>', '>=', '>']

" We build the regexp for the tokenizer
let s:reCppOperatorOrPunctuator = escape(join(s:cppOperatorPunctuator, '\|'), '*./^~[]')

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
    while startCmt!=-1 && endCmt!=-1
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
" the code must have no comments
" a token is dictionary where keys are:
"   -   kind = cppKeyword|cppWord|cppOperatorPunctuator|unknown
"   -   value = 'something'
"   Note: a cppWord is any word that is not a cpp keyword
function! s:Tokenize(szCodeWithoutComments)
    let result = []

    " The regexp to find a token, a token is a keyword, word or
    " c++ operator or punctuator. To work properly we have to put 
    " spaces and tabs to our regexp.
    let reTokenSearch = '\(\w\+\)\|\s\+\|'.s:reCppOperatorOrPunctuator
    " eg: 'using namespace std;'
    "      ^    ^
    "  start=0 end=5
    let startPos = 0
    let endPos = matchend(a:szCodeWithoutComments, reTokenSearch)
    let len = endPos-startPos
    while endPos!=-1
        " eg: 'using namespace std;'
        "      ^    ^
        "  start=0 end=5
        "  token = 'using'
        " We also remove space and tabs
        let token = substitute(strpart(a:szCodeWithoutComments, startPos, len), '\s', '', 'g')

        " eg: 'using namespace std;'
        "           ^         ^
        "       start=5     end=15
        let startPos = endPos
        let endPos = matchend(a:szCodeWithoutComments, reTokenSearch, startPos)
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
            if match(token, s:reCppKeyword)!=-1
                let resultToken.kind = 'cppKeyword'
            endif
        else
            " It's an operator
            let resultToken.kind = 'cppOperatorPunctuator'
        endif

        " We have our token, let's add it to the result list
        call extend(result, [resultToken])
    endwhile

    return result
endfunc

" Tokenize the current instruction.
" @return list of tokens
function! s:TokenizeCurrentInstruction()
    let startPos = searchpos('[;{}]\|\%^', 'bWn')
    let curPos = getpos('.')[1:2]
    return s:Tokenize(s:GetCodeWithoutComments(startPos, curPos)[1:])
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
"   kind = itemVariable|itemCast|itemCppCast|itemTemplate|itemFunction|itemUnknown|itemThis|itemScope
function! s:GetItemsToComplete(tokens)
    let result = []
    let tokens = reverse(s:BuildParenthesisGroups(a:tokens))
    let itemsDelimiters = ['->', '.', '->*', '.*']

    " fsm states:
    "   0 = initial state, search for -> or .
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
                let item.kind = 'itemVariable'
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
    let kinds = {'(': '()', ')' : '()', '[' : '[]', ']' : '[]', '<' : '<>', '>' : '<>'}
    let unresolved = {'()' : [], '[]': [], '<>' : []}
    let groupId = 0

    " Note: we build paren group in a backward way
    " because we can often have parenthesis unbalanced
    " instruction
    " eg: doSomething(_member.get()->
    for token in reverse(tokens)
        if index([')', ']', '>'], token.value)>=0
            let token['group'] = groupId
            call extend(unresolved[kinds[token.value]], [token])
            let groupId+=1
        elseif index(['(', '[', '<'], token.value)>=0
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
function! s:GetClassScopeAtCurrentPosition()
    " We store the cursor position because searchpairpos() moves the cursor
    let originalPos = getpos('.')
    let endPos = originalPos[1:2]
    let listCode = []

    let szBetweenPos = ''
    while endPos!=[0,0]
        " Note: We ignore matches under c and c++ comments
        " to do that we get the syntax id of the text under the cursor
        " if it contains 'cComment' or 'cCommentL' we ignore the match
        let reIgnoreComments = 'match(synIDattr(synID(line("."), col("."), 1), "name"), "cComment")!=-1'
        let endPos = searchpairpos('{', '', '}', 'bW', reIgnoreComments)
        let szReStartPos = '[;{}]\|\%^'
        let startPos = searchpairpos(szReStartPos, '', '{', 'bWn', reIgnoreComments)

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
        let state=0
        for token in tokens
            if state==0
                if index(['namespace', 'class', 'struct', 'union'], token.value)>=0
                    let state= 1
                    " Maybe end of tokens
                endif
            elseif state==1
                if token.kind == 'cppWord'
                    " eg: namespace MyNs { class MyCl {}; }
                    " => listClassScope = [MyNs, MyCl]
                    call extend( listClassScope , [token.value] )
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

    return szClassScope
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

" Parse the file and return a list of namespaces
" TODO:
function! s:GetNamespacesUsed()
    let result = ['::']
    return result
endfunc

" Extract type from tokens.
" eg: examples of tokens format
"   'const MyClass&'
"   'const map < int, int >&'
"   'MyNs::MyClass'
"   '::MyClass**'
" @return the type info string eg: ::std::map
" can be empty
function! s:ExtractTypeInfoFromTokens(tokens)
    let szResult = ''
    let tokens = reverse(s:BuildParenthesisGroups(a:tokens))

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

" Search a declaration.
" eg: std::map
" can be empty
" Note: The returned type info can be a typedef
" The typedef resolution is done later
" @return
"   - a dictionnary where keys are
"       - type: the type of value same as type()
"       - value: the value
function! s:GetTypeInfoOfVariable(namespaces, typeInfoCurrentScope, szVariable)
    let result = {}
    " Search declaration like gd
    let searchResult = searchdecl(a:szVariable, 0, 1)
    if searchResult!=0

        " Unnamed type case
        if a:typeInfoCurrentScope.type==4
            let tmpTypeInfo = a:typeInfoCurrentScope
        else
            " If the result is empty, we have to search the variable in the class
            " scope, here we need the tags
            let szClassScopeForTags = substitute(s:GetTypeInfoString(a:typeInfoCurrentScope), '^::', '', 'g')
            let tmpTypeInfo = s:CreateTypeInfo(szClassScopeForTags)
        endif

        " We want to get the type of the member a:szVariable, the search is
        " done in the class szClassScopeForTags and in base classes if any
        let tagList = s:SearchAllMembers(a:namespaces, tmpTypeInfo)

        let szFilter = "v:val.kind[0]=='m' && (match(v:val.name, '\\<'.a:szVariable.'$')!=-1)"
        call filter(tagList, szFilter)

        if len(tagList)
            if has_key(tagList[0], 'typename')
                let result = s:CreateTypeInfo(tagList[0])
            else
                " eg: 'MyClass _member' => 'MyClass'
                let szCmdWithoutVariable = substitute(s:ExtractCmdFromTagItem(tagList[0]), '\<'.a:szVariable.'\>.*', '', 'g')
                let tokens = s:Tokenize(s:GetCodeWithoutCommentsFromSingleLine(szCmdWithoutVariable))
                let result = s:CreateTypeInfo(s:ExtractTypeInfoFromTokens(tokens))
            endif
            return result
        endif

        " Search declaration like gD
        if !s:IsTypeInfoValid(result)
            let searchResult = searchdecl(a:szVariable, 1, 1)
        endif
    endif

    " Search done ?
    if searchResult==0
        " After searchdecl(), the cursor is on the first letter of the
        " variable, because we only want the type we remove this letter
        " => [:-2]
        let tokensType= s:TokenizeCurrentInstruction()[:-2]
        let result = s:CreateTypeInfo(s:ExtractTypeInfoFromTokens(tokensType))

        " If the result still empty, maybe the variable is a global var of an
        " unnamed class, struct or union.
        " eg:
        " struct
        " {
        "   int num;
        " }gVariable;
        " In this case we need the tags (the patched version)
        if !s:IsTypeInfoValid(result)
            let tagList = taglist('^'.a:szVariable.'$')
            call filter(tagList, 'has_key(v:val, "typename") && index(["v","m"], v:val.kind[0])>=0')
            if len(tagList)
                let result = s:CreateTypeInfo(tagList[0])
            endif
        endif
    endif
    return result
endfunc

" Get the type info string from the returned type of function
function! s:GetTypeInfoOfReturnedType(namespaces, typeInfoCurrentScope, szFunctionName)
    let result = {}

    " Unnamed type case
    if a:typeInfoCurrentScope.type==4
        let tmpTypeInfo = a:typeInfoCurrentScope
    else
        " If the result is empty, we have to search the variable in the class
        " scope, here we need the tags
        let szClassScopeForTags = substitute(s:GetTypeInfoString(a:typeInfoCurrentScope), '^::', '', 'g')
        let tmpTypeInfo = s:CreateTypeInfo(szClassScopeForTags)
    endif

    " The search is done in the class szClassScopeForTags and in base classes if any
    let tagList = s:SearchAllMembers(a:namespaces, tmpTypeInfo)

    let szFilter = "(v:val.kind[0]=='f' || v:val.kind[0]=='p') && (match(v:val.name, '\\<'.a:szFunctionName.'$')!=-1)"
    call filter(tagList, szFilter)

    if len(tagList)
        " eg: 'MyClass _member' => 'MyClass'
        let szCmdWithoutVariable = substitute(s:ExtractCmdFromTagItem(tagList[0]), '\<'.a:szFunctionName.'\>.*', '', 'g')
        let tokens = s:Tokenize(s:GetCodeWithoutCommentsFromSingleLine(szCmdWithoutVariable))
        let result = s:CreateTypeInfo(s:ExtractTypeInfoFromTokens(tokens))
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

" Resolve type information of items
" @param namespaces: list of namespaces used in the file
" @param szCurrentClassScope: the current class scope, only used for the first
" item to detect if this item is a class member (attribute, method)
" @param items: list of item, can be an empty list @see GetItemsToComplete
function! s:ResolveItemsTypeInfo(namespaces, szCurrentClassScope, items)
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

    let typeInfo = s:CreateTypeInfo(a:szCurrentClassScope)
    for item in a:items
        let curItem = item
        if curItem.kind=='itemVariable'
            " Note: a variable can be : MyNs::MyClass::_var or _var or (*pVar)
            let tokens = reverse(copy(curItem.tokens))
            let szVariable = curItem.tokens[-1].value
            for token in tokens
                if token.kind=='cppWord'
                    let szVariable = token.value
                    break
                endif
            endfor
            let typeInfo = s:GetTypeInfoOfVariable(a:namespaces, typeInfo, szVariable)
        elseif curItem.kind == 'itemFunction'
            let idx = 0
            for token in curItem.tokens
                if token.value=='('
                    let idx-=1
                    break
                endif
                let idx+=1
            endfor
            let szFunctionName = curItem.tokens[idx].value
            let typeInfo = s:GetTypeInfoOfReturnedType(a:namespaces, typeInfo, szFunctionName)
        elseif curItem.kind == 'itemThis'
            let typeInfo = s:CreateTypeInfo(substitute(a:szCurrentClassScope, '^::', '', 'g'))
        elseif curItem.kind == 'itemCast'
            let typeInfo = s:CreateTypeInfo(s:ResolveCCast(curItem.tokens))
        elseif curItem.kind == 'itemCppCast'
            let typeInfo = s:CreateTypeInfo(s:ResolveCppCast(curItem.tokens))
        elseif curItem.kind == 'itemScope'
            let typeInfo = s:CreateTypeInfo(substitute(s:TokensToString(curItem.tokens), '\s', '', 'g'))
        endif
    endfor

    return typeInfo
endfunc

" Check if a file has changed
function! s:HasChanged(filepath, typeInfo)
    let cacheKey = a:filepath.a:typeInfo
    if has_key(s:filedateCache, cacheKey)
        let currentFiletime = getftime(a:filepath)
        if currentFiletime > s:filedateCache[cacheKey]
            " The file has changed, updating the cache
            let s:filedateCache[cacheKey] = currentFiletime
            return 1
        else
            return 0
        endif
    else
        " We store the time of the file
        let s:filedateCache[cacheKey] = getftime(a:filepath)
        return 1
    endif
endfunc

" Convert a tag_item (from taglist()) to a popup item
function! s:ConvertTagItemToPopupItem(tagItem)
    let itemWord = substitute(a:tagItem.name, '.*::', '', 'g')
    "let itemWord = a:tagItem.name
    " If the tagid is a function or a prototype we add a
    " parenthesis
    " Note: tagItem values can be in single letter format so
    " we always test the first letter
    if index(['f', 'p'], a:tagItem.kind[0])>=0
        let itemWord = itemWord . '('
    endif

    " If it's a prototype then change the letter to 'f' (for function)
    let itemKind = substitute(a:tagItem.kind[0], 'p', 'f', 'g')

    " Add the access
    let itemMenu = ''
    let accessChar = {'public':'+','protected':'#','private':'-'}
    if has_key(a:tagItem, 'access')
        let itemMenu = itemMenu.accessChar[a:tagItem.access]
    else
        let itemMenu = itemMenu." "
    endif

    " Formating optional menu string
    let allTagKey = ['class', 'struct', 'union', 'enum']
    for tagKey in allTagKey
        if has_key(a:tagItem, tagKey)
            let itemMenu = itemMenu."\t".a:tagItem[tagKey]
        endif
    endfor

    let popupItem = {'word':itemWord, 'kind':itemKind, 'menu':itemMenu}
    return popupItem
endfunc

" Convert a tag item list to popup item list
function! s:ConvertTagItemListToPopupItemList(tagList, baseFilter)
    for tagItem in a:tagList
        if match(substitute(tagItem.name, '.*::', '', 'g'), '^'.a:baseFilter)!=-1
            call complete_add(s:ConvertTagItemToPopupItem(tagItem))
        endif
    endfor
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
    let listKindScope = ['class', 'struct', 'union', 'namespace']
    let szResult = '::'
    for scope in listKindScope
        if has_key(a:tagItem, scope)
            let szResult = szResult . a:tagItem[scope]
            break
        endif
    endfor
    return szResult
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
function! s:SearchAllMembers(namespaces, typeInfo)
    let result = []

    " Complete check
    if complete_check() || !s:IsTypeInfoValid(a:typeInfo)
        return result
    endif

    let tagItem = s:GetResolvedTagItem(a:namespaces, a:typeInfo)

    if tagItem!={}
        call extend(result, s:SearchMembers(tagItem))
        if has_key(tagItem, 'inherits')
            " We don't forget multiple inheritance
            " Note: in the baseClassTypeInfoList there is no information
            " about the inheritance acces ('public', 'protected', 'private')
            " the only way to find it is to use the cmd info of the tag. But it's
            " not 100% fiable
            let baseClassTypeInfoList = split(tagItem.inherits, ',')

            " Getting members of all base classes
            for baseClassTypeInfo in baseClassTypeInfoList
                " We have to resolve the correct namespace of baseClassTypeInfo
                " we can have '::Class1' 'Class1' 'NameSpace1::NameSpace2::Class8'
                "TODO: Search 'using namespace' declarations in the file and included files
                let namespaces = ['::']
                let namespaces = [s:ExtractScopeFromTag(tagItem)] + namespaces
                call extend(result, s:SearchAllMembers(namespaces, s:CreateTypeInfo(baseClassTypeInfo)))
            endfor
        endif
    endif
    return result
endfunc

" Get a tag item after a scope resolution and typedef resolution
function! s:GetResolvedTagItem(namespaces, typeInfo)
    let result = {}

    " Unnamed type case eg: '1::2'
    if a:typeInfo.type == 4
        " Here there is no typedef or namespace to resolve, the tagInfo.value is a tag item
        " representing a variable ('v') a member ('m') or a typedef ('t') and the typename is
        " always in global scope
        return a:typeInfo.value
    endif

    " Named type case eg:  'MyNamespace::MyClass'
    let szTypeInfo = s:GetTypeInfoString(a:typeInfo)
    let listClassName = split(szTypeInfo, '::')
    if len(listClassName)==0
        return result
    endif

    let szClassName = listClassName[-1]
    let tagList = taglist('^'.szClassName.'$')
    " We can only get members of class, struct, union and namespace
    let szFilter = "index(['c', 's', 'u', 'n', 't'], v:val.kind[0])>=0"
    call filter(tagList, szFilter)

    if len(tagList)
        " Resolving scope (namespace, nested class etc...)
        let szScopeOfTypeInfo = s:ExtractScopeFromTypeInfo(szTypeInfo)
        if s:IsTypeInfoResolved(szTypeInfo)
            let result = s:GetTagOfSameScope(tagList, szScopeOfTypeInfo)
        else
            " For each namespace of the namespace list we try to get a tag
            " that can be in the same scope
            for scope in a:namespaces
                let szTmpScope = s:SimplifyScope(scope.'::'.szScopeOfTypeInfo)
                let result = s:GetTagOfSameScope(tagList, szTmpScope)
                if result!={}
                    break
                endif
            endfor
        endif
    endif

    if result!={}
        " We have our tagItem but maybe it's a typedef or an unnamed
        " type
        if result.kind[0]=='t'
            " Here we can have a typedef to another typedef, a class, struct, union etc
            " but we can also have a typedef to an unnamed type, in that
            " case the result contains a 'typename' key
            if has_key(result, 'typename')
                let result = s:GetResolvedTagItem(a:namespaces, s:CreateTypeInfo(result))
            else
                let szCmd = s:ExtractCmdFromTagItem(result)
                let szCode = substitute(s:GetCodeWithoutCommentsFromSingleLine(szCmd), result.name.'.*', '', 'g')
                let szTypeInfo = s:ExtractTypeInfoFromTokens(s:Tokenize(szCode))
                let result = s:GetResolvedTagItem(a:namespaces, s:CreateTypeInfo(szTypeInfo))
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

    let szFilePath = a:tagItem.filename
    let fixedTypeInfo = s:ExtractScopeFromTag(a:tagItem)[2:] . '::' . a:tagItem.name
    let fixedTypeInfo = substitute(fixedTypeInfo, '^::', '', 'g')

    " Unnamed type case
    " A tag item representing an unnamed type is a variable ('v') a member
    " ('m') or a typedef ('t')
    if index(['v', 't', 'm'], a:tagItem.kind[0])>=0 && has_key(a:tagItem, 'typename')
        " We remove the 'struct:' or 'class:' etc...
        let fixedTypeInfo = substitute(a:tagItem.typename, '^\w\+:', '', 'g')
    endif

    " Formatting the result key for the result cache.
    let resultKey = szFilePath . fixedTypeInfo

    " If the file has not changed we return the stored result
    if s:HasChanged(szFilePath, fixedTypeInfo)==0 && has_key(s:resultCache, resultKey)
        return s:resultCache[resultKey]
    endif

    let tagQuery = '^'.fixedTypeInfo.'::\w\+$'

    " To get the members we have to run ctags on the file header or
    " source then we store all tagid of our class (or struct, union etc...)
    let tmpFile = tempname()

    " Storing the vim env 'tags'
    let tagsEnvOriginal = &tags

    " Building the ctags command, because we want to get members we add the
    " option -c++-kinds=+p to detect function prototypes in header files.
    " To get members we need also the option : --extra=+q
    " so we can have tag item name that start with the class name eg: 'MyClass::_member'
    " we add --language-force=c++ because the tmp file has no extension
    " we need access member information : +a
    " Note: we don't need inheritance information for searching members
    " In the futur we'll need the signature of a routine (+S) but there is a
    " bug in the taglist() function in some cases so we don't add it
    let tagCmd = 'ctags --language-force=c++ --c++-kinds=+p --fields=+a --extra=+q -f "'.tmpFile.'" "'.szFilePath.'"'
    call system(tagCmd)

    " Sets the tags vim variable so that the function taglist() can work
    " faster
    exe "set tags=".tmpFile
    let classMembers = taglist(tagQuery)

    let szCtorName = fixedTypeInfo . '::' . a:tagItem.name
    let szDtorName = fixedTypeInfo . '::~' . a:tagItem.name
    " We don't want ctors and dtors
    let szFilter = "(index([szCtorName, szDtorName], v:val.name)<0 && index(['p', 'f'], v:val.kind[0])>=0)"
    let szFilter = szFilter."|| (index(['m', 'c', 's', 'u', 'e', 'n','t','v'], v:val.kind[0])>=0)"
    call filter(classMembers, szFilter)

    call extend(result, classMembers)

    " Restoring the old tags value
    exe "set tags=".tagsEnvOriginal

    " We store the result for optimization
    " We update the result only if the file where typeInfo is define changed
    let s:resultCache[resultKey] = result

    return result
endfunc

" Get the filter for a completion on the global namespace
function! s:GetGlobalScopeFilter()
    let szFilter = "(index(['c', 's', 'u', 'e', 'n', 't', 'v'], v:val.kind[0])>=0"
    let szFilter = szFilter."||(index(['f', 'p'], v:val.kind[0])>=0 && match(v:val.cmd, 'static')!=-1))"
    let szFilter = szFilter . " && !has_key(v:val, 'class') && !has_key(v:val, 'struct') && !has_key(v:val, 'union') && !has_key(v:val, 'namespace') && !has_key(v:val, 'enum')"
    return szFilter
endfunc

" Return if the tag env has changed
function! s:HasTagEnvChanged()
    if s:tagEnvCache == &tags
        return 0
    else
        let s:tagEnvCache = &tags
        return 1
    endif
endfunc

" Return if a tag file has changed in tagfiles()
function! s:HasTagFileChanged()
    if s:HasTagEnvChanged()
        let s:tagFilesCache = {}
        return 1
    endif

    let tagFiles = map(tagfiles(), 'escape(v:val, " ")')
    let result = 0
    for tagFile in tagFiles
        if has_key(s:tagFilesCache, tagFile)
            let currentFiletime = getftime(tagFile)
            if currentFiletime > s:tagFilesCache[tagFile]
                " The file has changed, updating the cache
                let s:tagFilesCache[tagFile] = currentFiletime
                let result = 1
            endif
        else
            " We store the time of the file
            let s:tagFilesCache[tagFile] = getftime(tagFile)
            let result = 1
        endif
    endfor
    return result
endfunc

" Find complete matches for a completion on the global scope
function! s:SearchGlobalScopeMembers(base)
    " Because the completion on global scope can take lot of time
    " to let the user see the progression of the search
    " we call taglist() for each letter of the alphabet
    let listChar = map(range(char2nr('a'),char2nr('z')), 'nr2char(v:val)') + ['_']
    let szFilter = s:GetGlobalScopeFilter()

    " Clear the globalScopeCache if tag env has changed
    if s:HasTagFileChanged()
        let s:globalScopeCache = {}
    endif

    for char in listChar
        let szReTag = '^\c['.char.'].*'
        if has_key(s:globalScopeCache, char)
            if a:base!='' && match(a:base, szReTag)<0
                continue
            endif

            let tagList = s:globalScopeCache[char]

            call s:ConvertTagItemListToPopupItemList(tagList, a:base)
            if complete_check()
                break
            endif
        else
            if a:base!='' && match(a:base, szReTag)<0
                continue
            endif
            let tagList = taglist(szReTag)
            call filter(tagList, szFilter)

            call s:ConvertTagItemListToPopupItemList(tagList, a:base)
            if complete_check()
                break
            else
                " Store the result in the cache
                let s:globalScopeCache[char] = tagList
            endif
        endif
    endfor
endfunc

" This function is used for the 'omnifunc' option.
function! cppomnicomplete#Complete(findstart, base)
    if a:findstart
        " We get items here (whend a:findstart==1) because GetItemsToComplete()
        " depends on the cursor position.
        " When a:findstart==0 the cursor position is modified
        let s:itemsToComplete = s:GetItemsToComplete(s:TokenizeCurrentInstruction())

        " Get the current class scope at the cursor, the result depend on the
        " current cursor position
        let s:szClassScope = s:GetClassScopeAtCurrentPosition()

        return s:FindStartPositionOfCompletion()
    endif

    " Get namespaces used in the file
    let namespaces = s:GetNamespacesUsed()
    let typeInfo = s:ResolveItemsTypeInfo(namespaces, s:szClassScope, s:itemsToComplete)
    let tagList = s:SearchAllMembers(namespaces, typeInfo)

    if len(s:itemsToComplete)==0
        " Current scope completion
        if s:GetTypeInfoString(typeInfo)=='::'
            " Global scope completion
            call s:SearchGlobalScopeMembers(a:base)
        else
            let szFilter = "(index(['m', 'p', 'f'], v:val.kind[0])>=0 && has_key(v:val, 'access'))"
            let szFilter = szFilter . "|| index(['c', 's', 'u', 'e', 'n', 't', 'v'], v:val.kind[0])>=0"
            call filter(tagList, szFilter)

            " First we display class members
            call s:ConvertTagItemListToPopupItemList(tagList, a:base)

            " Then we display global scope members
            call s:SearchGlobalScopeMembers(a:base)
        endif
    elseif s:itemsToComplete[-1].kind == 'itemScope'
        " Completion after a '::'
        if s:GetTypeInfoString(typeInfo)==''
            " Global scope completion
            call s:SearchGlobalScopeMembers(a:base)
        else
            let szFilter = "(index(['m', 'p', 'f'], v:val.kind[0])>=0 && has_key(v:val, 'access') && match(v:val.cmd, 'static')!=-1)"
            let szFilter = szFilter . "|| index(['c', 's', 'u', 'e', 'n', 't', 'v'], v:val.kind[0])>=0"
            call filter(tagList, szFilter)
            call s:ConvertTagItemListToPopupItemList(tagList, a:base)
        endif
    else
        " Completion after a '->' or '.'
        let szFilter = "index(['m', 'p', 'f', 't'], v:val.kind[0])>=0 && has_key(v:val, 'access')"
        call filter(tagList, szFilter)
        call s:ConvertTagItemListToPopupItemList(tagList, a:base)
    endif

    return []
endfunc
