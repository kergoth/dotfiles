" Vim completion script
" Language:  C++
" Maintainer:  Vissale NEANG
" Last Change:  2006 Apr 17
" Comments:
" Version 0.11:
"   First, sorry for my bad english.... :)
"   The script is not finished yet, the todo list is:
"       -   typename resolution (with the patched ctags)
"       -   Need to improve child members completion
"       -   No completion when we have myObject.getOtherObject()->???
"       -   parse 'using namespace" declaration in the current file and also
"           in included files (depending on the vim include path value)... it
"           can be slow in big project...
"       -   Add complete_check() and complete_add()
"       -   Add member access change when there is a restricted access inheritance
"           ('protected', 'private')
"       -   Add the global namespace completion '::' (it could be slow...)
"       -   Add a 'may complete' behaviour (don't type <CTRL-X><CTRL-O>)
"       -   Add a basic macro resolution
"       -   Some changes in file cache behaviour
"       -   Add a cache for tag file and a function to check if a tag file changed
"       -   Add global variable to configure the popup menu and completion
"           behaviour
"       -   Update comments of the script
"       -   Write a documentation... :-(
"       -   Some optimizations...
"       -   Fix futur bugs...
"   Some code come from the original ccomplete.vim Bram Moolenaar's script

if v:version < 700
    echomsg "cppomnicomplete.vim: Please install vim 7.0 or higher for omni-completion"
    finish
endif

" Cache data
let s:filedate_cache = {}
let s:result_cache = {}

" Some c++ specifiers
let s:storage_class_specifier = ['auto', 'register', 'static', 'extern', 'mutable']
let s:function_specifier = ['inline', 'virtual', 'explicit']
let s:decl_specifier = ['friend', 'typedef']
let s:cv_qualifier = ['const', 'volatile']
let s:all_specifier = s:storage_class_specifier+s:function_specifier+s:decl_specifier+s:cv_qualifier

let s:default_search_query = {'class':{}, 'struct':{}, 'union':{}}

" This function is used for the 'omnifunc' option.
function! cppomnicomplete#Complete(findstart, base)
    if a:findstart
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

        " Return the column of the last word, which is going to be changed.
        " Remember the text that comes before it in s:prepended.
        if lastword == -1
            let s:prepended = ''
            return start
        endif
        let s:prepended = strpart(line, start, lastword - start)
        return lastword
    endif

    " Return list of matches.
    let base = s:prepended . a:base

    " Don't do anything for an empty base, would result in all the tags in the
    " tags file.
    if base == ''
        return []
    endif

    let tag_list = []

    " Class and namespace access with '::'
    if match(base, '::$')!=-1
        if base=='::'
            return []
        endif

        "TODO: Search 'using namespace' declarations in the file and included files
        let namespaces = ['::']
        let type_info = s:ExtractTypeFromString(base)
        let tag_list = s:GetAllMembers(namespaces, type_info, {'namespace':{}, 'class':{'static':1}, 'struct':{'static':1}, 'enum':{}})
    endif

    " Split item in words, keep empty word after "." or "->".
    " "aa" -> ['aa'], "aa." -> ['aa', ''], "aa.bb" -> ['aa', 'bb'], etc.
    " We can't use split, because we need to skip nested [...].
    let items = []
    let s = 0
    while 1
        let e = match(base, '\.\|->\|\[', s)
        if e < 0
            if s == 0 || base[s - 1] != ']'
                call add(items, strpart(base, s))
            endif
            break
        endif
        if s == 0 || base[s - 1] != ']'
            call add(items, strpart(base, s, e - s))
        endif
        if base[e] == '.'
            let s = e + 1   " skip over '.'
        elseif base[e] == '-'
            let s = e + 2   " skip over '->'
        else
            " Skip over [...].
            let n = 0
            let s = e
            let e += 1
            while e < len(base)
                if base[e] == ']'
                    if n == 0
                        break
                    endif
                    let n -= 1
                elseif base[e] == '['  " nested [...]
                    let n += 1
                endif
                let e += 1
            endwhile
            let e += 1
            call add(items, strpart(base, s, e - s))
            let s = e
        endif
    endwhile

    "TODO: Search 'using namespace' declarations in the file and included files
    ".....
    
    " Default namespace = global
    let namespaces = ['::']

    " Searching the declaration line of the variable
    if searchdecl(items[0], 0, 1) == 0
        " Line declaration found, getting the line
        let line = getline('.')

        " Get the type info from a declaration line
        " TODO: Case when the declaration is in function parameter list
        
        " The type_info can contain the global namespace or not depending on
        " the line
        let type_info = s:ExtractTypeFromDeclaration(line)

        if len(items)>2
            call remove(items, 0)
            let type_info_of_last_item = s:ResolveTypeInfoOfLastItem(namespaces, type_info, items)
            let tag_list = s:GetAllMembers(namespaces, type_info_of_last_item)
        else
            let tag_list = s:GetAllMembers(namespaces, type_info)
        endif
    endif

    return s:ConvertTagItemListToPopupItemList(tag_list)
endfunc

" Returns the type info of the last item in fifo_items
function! s:ResolveTypeInfoOfLastItem(namespaces, type_info, fifo_items)
    if len(a:fifo_items)>0
        " We only want the member a:fifo_items[0], don't need to get all
        " members
        let tag_query = '^'.a:fifo_items[0].'$'
        let tag_list = s:GetAllMembers(a:namespaces, a:type_info, s:default_search_query, tag_query)

        " TODO: len(tag_list) > 1 ?
        if len(tag_list)
            " Now we know the type info of item
            " TODO: improve ExtractTypeFromTagItemCmd(). Don't work for lots
            " of case
            let type_info = s:ExtractTypeFromTagItemCmd(tag_list[0])

            " TODO: namespace resolution of the type_info
            let resolved_type_info = type_info

            call remove(a:fifo_items, 0)

            " If the last item is '' it's the end
            if a:fifo_items[0]==''
                return type_info
            else
                return s:ResolveTypeInfoOfLastItem(a:namespaces, resolved_type_info, a:fifo_items)
            endif
        endif
    endif
    return ''
endfunc

" Get all members of a class, struct, union.
" for class and struct, get also the inherited members
function! s:GetAllMembers(namespaces, type_info, ...)
    let search_query = s:default_search_query
    let tag_query = '.*'

    " Getting optional argument
    if a:0==1
        let search_query = a:1
    elseif a:0==2 
        let search_query = a:1
        let tag_query = a:2
    endif

    let result = []
    
    " Get the tag list of the class name without his namespace,
    " GetTagList() resolve the first typedef
    let type_info_typedef_resolved = a:type_info
    let [tag_list, type_info_typedef_resolved] = s:GetTagList(a:type_info)

    " Get the correct tag item that match our type_info_typedef_resolved (namespace+classname)
    let [tag_item, resolved_type_info] = s:ResolveTag(a:namespaces, type_info_typedef_resolved, tag_list)

    " Exit if tag not found
    if tag_item=={}
        return result
    endif

    if has_key(tag_item, 'inherits')
        " We don't forget multiple inheritance
        " Note: in the base_class_type_info_list there is no information
        " about the inheritance acces ('public', 'protected', 'private') and
        " also the 'virtual' information
        let base_class_type_info_list = split(tag_item['inherits'], ',')

        " Getting members of all base classes
        for base_class_type_info in base_class_type_info_list
            " We have to resolve the correct namespace of base_class_type_info
            " we can have '::Class1' 'Class1' 'NameSpace1::NameSpace2::Class8'
            "TODO: Search 'using namespace' declarations in the file and included files
            let namespaces = ['::']
            let namespaces = [s:ExtractNamespaceFromTypeInfo(resolved_type_info)] + namespaces
            let result = s:GetAllMembers(namespaces, base_class_type_info, search_query, tag_query) + result
        endfor
    endif

    let result = s:SearchMembers(tag_item.filename, resolved_type_info, search_query, tag_query) + result

    return result
endfunc

" Search class, struct, union members
" ex: if type_info represents a class 'MyClass' then
"   -   search_query must contain at least 'class' so we search only tag_item
"       that match 'class:MyClass'
"   -  tag_query: This is a regexp for the taglist() function
"       -  To get all MyClass members 
"         => tag_query='.*'
"       -  To only get the member MyClass::_iAmAMember
"         => tag_query='^_iAmAMember$'
"  return a list of tag_item
function! s:SearchMembers(filename, type_info, search_query, tag_query)
    let result = []

    " Formatting the result key for the result cache. Keys must contain the
    " filename, the type_info and the search request
    let result_key = a:filename.'::'.a:type_info.'::'.string(a:search_query).'::'.a:tag_query

    " If the file has not changed we return the stored result
    if s:HasChanged(a:filename, a:type_info)==0 && has_key(s:result_cache, result_key)
        return s:result_cache[result_key]
    endif

    " To get the members we have to run ctags on the file header or
    " source then we store all tagid of our class (or struct, union etc...)
    let tmpfile_tag_file = tempname()

    " Storing the vim env 'tags'
    let tags_env_orig = &tags

    " Building the ctags command, because we want to get members we add the
    " option -c++-kinds=+p for function prototypes.
    let tag_cmd = "ctags --language-force=c++ --c++-kinds=+p --fields=+amikKlnsStz-f -f ".tmpfile_tag_file.' "'.a:filename.'"'

    call system(tag_cmd)

    " Sets the tags vim variable so that the function taglist() can work
    " faster
    exe "set tags=".tmpfile_tag_file

    let tag_list = taglist(a:tag_query)

    let type_info_list = split(a:type_info, '::')
    let type_name = type_info_list[-1]

    " Note: tag_item keys and search_query keys are always in full name format
    for tag_item in tag_list 
        for kind_query in keys(a:search_query)
            " Ignoring ctor and dtor for class and struct
            if kind_query=='class' || kind_query=='struct'
                if tag_item['name'] == type_name || tag_item['name'] == '~'.type_name
                    continue
                endif
            endif

            " Note: tag_item keys and kind are always in full name format
            if has_key(tag_item, kind_query)
                " Enum fix
                " We can have in the tag file 'enum:ns1::ns2::MyClass::2'
                " we don't want '::2'
                let value_enum_fix = substitute(tag_item[kind_query], '::[0-9]\+$', '', 'g')

                let type_info_whithout_global_namespace = substitute(a:type_info, '^::', '', 'g')
                if value_enum_fix==type_info_whithout_global_namespace
                    " Case where the search request is to get static members
                    if has_key(a:search_query[kind_query], 'static')
                        " We have to get static members only
                        " Is the current member static ?
                        if match(tag_item.cmd, '\<static\>')==-1
                            " This member is not static ... continue
                            continue
                        endif
                    endif
                    call add(result, tag_item)
                endif
            endif
        endfor
    endfor

    " Restoring the old tags value
    exe "set tags=".tags_env_orig

    " We store the result for optimization
    " We update the result only if the file where type_info is define changed
    let s:result_cache[result_key] = result
    return result
endfunc

" Convert a tag_item (from taglist()) to a popup item
function! s:ConvertTagItemToPopupItem(tag_item)
    let item_word = a:tag_item['name']
    " If the tagid is a function or a prototype we add a
    " parenthesis
    " Note: tag_item values can be in single letter format so
    " we always test the first letter
    if index(['f', 'p'], a:tag_item.kind[0])>=0
        let item_word = item_word . '('
    endif
    let item_kind = "\t\t" . a:tag_item['kind']

    " Formating optional menu string
    let item_menu = ''
    let all_tag_key = ['access', 'class', 'struct', 'union', 'enum']
    for tag_key in all_tag_key
        if has_key(a:tag_item, tag_key)
            let item_menu = item_menu."\t".a:tag_item[tag_key]
        endif
    endfor

    let popup_item = {'word':item_word, 'kind':item_kind, 'menu':item_menu}
    return popup_item
endfunc

" Convert a tag item list to popup item list
function! s:ConvertTagItemListToPopupItemList(tag_list)
    let result = []
    for tag_item in a:tag_list
        call extend(result, [s:ConvertTagItemToPopupItem(tag_item)])
    endfor
    return result
endfunc


" Check if a file has changed
function! s:HasChanged(filepath, type_info)
    let cache_key = a:filepath.'['.a:type_info.']'
    if has_key(s:filedate_cache, cache_key)
        let current_filetime = getftime(a:filepath)
        if current_filetime > s:filedate_cache[cache_key]
            " The file has changed, updating the cache
            let s:filedate_cache[cache_key] = current_filetime
            return 1
        else
            return 0
        endif
    else
        " We store the time of the file
        let s:filedate_cache[cache_key] = getftime(a:filepath)
        return 1
    endif
endfunc

" Extract the cmd of a tag item without regexp
function! s:ExtractCmdFromTagItem(tag_item)
    let line = a:tag_item.cmd
    let re = '\(\/\^\)\|\(\$\/\)'
    if match(line, re)!=-1
        let line = substitute(line, re, '', 'g')
        return line
    else
        " TODO: the cmd is a line number
        return ''
    endif
endfunc

function! s:ExtractTypeFromTagItemCmd(tag_item)
    return s:ExtractTypeFromDeclaration(s:ExtractCmdFromTagItem(a:tag_item))
endfunc

" The returned namespace may not have the global namespace
" ex: '::NameSpace1::NameSpace2::MyClass' => '::NameSpace1::NameSpace2::'
" 'NameSpace1::NameSpace2::MyClass' => 'NameSpace1::NameSpace2::'
function! s:ExtractNamespaceFromTypeInfo(type_info)
    return substitute(a:type_info, '\w\+$', '', 'g')
endfunc

" Simplify namespace string, remove consecutive '::' if any
function! s:SimplifyNamespace(namespace)
    return substitute(a:namespace, '\(::\)\+', '::', 'g')
endfunc

" Get the tag info string from a tag item
" the type info string use the tag_item.name and ta_item.namespace (if
" exists)
" The global namespace is always add
function! s:ExtractTypeFromTagItem(tag_item)
    " We add the global namespace
    let result = '::'.a:tag_item.name

    " The key 'namespace' may not exist
    " Note: in tag file tag_item.namespace never contains an ending '::'
    if has_key(a:tag_item, 'namespace')
        let result = '::'.a:tag_item.namespace . result
    endif
    return result
endfunc

" Sometimes we need to remove specifier that are useless for
" the process
function! s:RemoveCppSpecifiers(string, specifier_list)
    let specifier_regex = ''
    for specifier in a:specifier_list
        let specifier_regex = specifier_regex. '\<'. specifier .'\>\|'
    endfor
    let specifier_regex = specifier_regex[:-3]
    return substitute(a:string, specifier_regex,'','g')
endfunc

" Remove template parameter
" ex: vector<int> => vector
" map < vector < int >, map < int, int > > => map
function! s:RemoveTemplateParams(string)
    return substitute(a:string, '<.*>', '', 'g')
endfunc

" Returns the type info ex: 'NameSpace1::NameSpace2::MyClass::MyNestedClass'
" or 'MyClass'
" Note: We remove starting '::' and ending '::' if any
" ex: 'const std::map<int, int, blablablaAllocator >&' => std::map
function! s:ExtractTypeFromString(string)
    " We remove 'const', 'static', 'volatile' etc...
    " We also remove template parameter list
    " and ctor parameter list
    " ex:'< vector<int>, std::map<int, int> >'
    " Then we remove pointer and reference (*,&)
    " We finally remove space and tab
    let result = s:RemoveCppSpecifiers(a:string, s:all_specifier)
    let result = s:RemoveTemplateParams(result)
    let result = substitute(result, '[*&]\|[[:blank:]]','','g')

    " We remove starting '::' and ending '::' if any
    return substitute(result, '\(^::\)\|\(::$\)', '', 'g')
endfunc

" ex: 'MyClass myObject("Hello World", 2006)'
function! s:ExtractTypeFromDeclaration(decl)
    let decl = substitute(a:decl, '(.*)', '', 'g')
    " Removing the last word
    let decl = substitute(decl, '\w\+[[:blank:]]*[;\n]', '', 'g')
    return s:ExtractTypeFromString(decl)
endfunc

" Get the tag list and try to resolve typedef if any
function! s:GetTagList(type_info)
    let type_info_typedef_resolved = a:type_info
    let tag_list = taglist('^'.split(a:type_info, '::')[-1].'$')

    if len(tag_list)
        let [tag_list, type_info_typedef_resolved] = s:ResolveTypedef(tag_list, type_info_typedef_resolved)
    endif

    return [tag_list, type_info_typedef_resolved]
endfunc

" Get the best tag entry from the tag list that match our type info
" ex:
"   Our type info is  NameSpace1::NameSpace2::MyClass
"   In tag file we have multiple tag name 'MyClass' : our class, the ctor, and
"   another class 'MyClass' from the namespace NameSpace3. To get the correct
"   tag entry we have to check :
"       -   The namespace (we eliminate the NameSpace3::MyClass)
"       -   The kind (to eliminate the ctor MyClass())
"   type_info's namespace can be unresolved at entry
"   if ResolveTag() success the type_info's namespace is resolve and the
"   resolved type info is return. A resolved type info always begin with '::'
"   ex:
"       If we have 'Class1' (we don't know his namespace, maybe global maybe not..)
"       The result can be '::Class1' or '::Namespace1::Class1'
"   @return a list of 2 item:
"       -   [tag item, resolved type info] if success
"       -   [{}, a:type_info] if fails
function! s:ResolveTag(namespaces, type_info, tag_list)
    let garbage = []
    let resolved_type_info = a:type_info

    " The tag list contains all tag entries of MyClass
    for tag_item in a:tag_list
        " Resolving namespaces
        " If this tag entry has a namespace and our type info has one we can
        " test the namespaces strings
        let tag_item_type_info = s:ExtractTypeFromTagItem(tag_item)

        " tag_item_namespace can be '::NameSpace1::NameSpace2::' or '::'
        let tag_item_namespace = s:ExtractNamespaceFromTypeInfo(tag_item_type_info)

        " our_namespace can be 'NameSpace1::NameSpace2' or '' or '::NameSpace1::NameSpace2::' or '::'
        let our_namespace = s:ExtractNamespaceFromTypeInfo(a:type_info)

        " If a:type_info starts with :: (global namespace) so it's already resolve
        if match(our_namespace, '^::')!=-1
            if our_namespace == tag_item_namespace
                " function and prototype or not the priority it can be a problem
                " if the ctor of our class MyClass is return
                if index(['f', 'p'], tag_item.kind[0])>=0
                    " You can have the ctor MyClass but maybe the tag item of
                    " class MyClass comes after, we add the item in
                    " the garbage list
                    call extend(garbage, [tag_item])
                else
                    " Fixing the type_info namespace
                    let resolved_type_info = s:SimplifyNamespace(tag_item_namespace.'::'.split(a:type_info, '::')[-1])
                    return [tag_item, resolved_type_info]
                endif
            endif
        else
            " To resolve namespace for each namespace in a:namespaces we
            " concatenate namespace::our_namespace and test if
            " tag_item_namespace == namespace::our_namespace
            for namespace in a:namespaces
                let test_namespace = s:SimplifyNamespace(namespace.'::'.our_namespace)
                if test_namespace == tag_item_namespace
                    " function and prototype or not the priority it can be a problem
                    " if the ctor of our class MyClass is return
                    if index(['f', 'p'], tag_item.kind[0])>=0
                        " You can have the ctor MyClass but maybe the tag item of
                        " class MyClass comes after, we add the item in
                        " the garbage list
                        call extend(garbage, [tag_item])
                    else
                        " Fixing the type_info namespace
                        let resolved_type_info = s:SimplifyNamespace(tag_item_namespace.'::'.split(a:type_info, '::')[-1])
                        return [tag_item, resolved_type_info]
                    endif
                endif
            endfor
        endif
    endfor

    return [get(garbage, 0, {}), resolved_type_info]
endfunc

" Resolve a typedef recursively
function! s:ResolveTypedef(tag_list, type_info)
    let result = [a:tag_list, a:type_info]
    " Try to resolve a typedef only for the first item
    " TODO: Is it possible to have multiple typedef in the tag list for a
    " class name ?
    let tag_item = a:tag_list[0]
    if tag_item.kind[0]=='t'
        " line = 'typedef Class1 MY_CLASS; typedef MY_CLASS MyClass;'
        let line = s:ExtractCmdFromTagItem(tag_item)
        let lines = s:ExtractDeclarationLines(line)

        " Try to find the declaration of tag_item
        let declaration = ''
        for decl in lines
            if match(decl, '\<'.tag_item.name.'\>')!=-1
                let declaration = decl
                break
            endif
        endfor

        if declaration!=''
            " We have our declaration, now we can work properly
            " the declaration is in the format 'typedef const Class1< blabla >& MY_CLASS'
            let declaration = substitute(declaration, '\<'.tag_item.name.'\>', '', 'g')
            let type_info = s:ExtractTypeFromDeclaration(declaration)
            " TODO: namespace resolution
            let result = s:GetTagList(type_info)
        endif
    endif
    return result
endfunc

" Split a line into line declaration
" ex: if we have this line
" typedef Class1 MY_CLASS; typedef MY_CLASS MyClass;
"  =>['typedef Class1 MY_CLASS', 'typedef MY_CLASS MyClass']
function! s:ExtractDeclarationLines(line)
    return split(a:line, ';')
endfunc
