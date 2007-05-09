"   Copyright (c) 2006, Michael Shvarts <shvarts@akmosoft.com>
"
"{{{-----------License:
"   ScreenShot.vim is free software; you can redistribute it and/or modify it under
"   the terms of the GNU General Public License as published by the Free
"   Software Foundation; either version 2, or (at your option) any later
"   version.
"
"   ScreenShot.vim is distributed in the hope that it will be useful, but WITHOUT ANY
"   WARRANTY; without even the implied warranty of MERCHANTABILITY or
"   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
"   for more details.
"
"   You should have received a copy of the GNU General Public License along
"   with ScreenShot.vim; see the file COPYING.  If not, write to the Free Software
"   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.
"}}}
"{{{-----------Info:
" Version: 0.8
" Description:
"  Generates screenshot of your current VIM session as HTML code 
"
"  FEEDBACK PLEASE
"
" Installation: Drop it into your plugin directory
"
" History:
"    0.7: Initial upload
"    0.8: 
"    Added:
"       a) Full 'nowrap' option support
"       b) Non-printable characters support
"       c) 'showbreak' option support
"       d) 'display' option support (lastline and uhex both)
"       e) 'list' option support
"    0.9:
"    Added:
"        a)Custom statusline (i.e. 'stl' option support)
"        b)Tabline bar(only for console or if 'guioptions' does not contain 'e'). Custom tabline also supported
"        c)Title bar with VIM logo (can be disabled). Custom title(i.e. option 'titlestring') also supported
"        d)Credits in right bottom corner(can be disabled)
"    1.0:
"    Added:
"        a)Diff mode support
"        b)New command Diff2Html
"    1.01:
"    Fixed: 
"        1. Italic, bold and underline was broken in 1.0 version, now repaired
"        2. Proper highligting of number of buffers in tabline
"        3. Proper rendering of too long tabline or too long titleline
"        4. Proper title for 'nofile' current buffer 
"    1.02:
"    Fixed: 
"        Reverse attribute improper handling in some cases
"    1.03: A few bugfixes by Cyril Slobin <slobin@ice.ru>
"    Fixed:
"        1. Unqualified variables in statusline are treated as global now
"        3. When encoding is set to utf-8, non-ASCII letters are displayed now
"        4. Flag options like [+] long ago haven't space before them, fixea
"    Fixed: (by MS)
"    	 5. Incorrect highlighting in the case when foreground set and
"    	 background unset and reverse attribute set
"    	 6. Incorrect HTML when vim compiled with gui but running in terminal
"    Added:
"    	 7. Support for 256-color xterm added
"    1.04: 
"    Fixed:
"        1. Proper colors for DOS and win32 console versions(suggestion by Cyril Slobin <slobin@ice.ru>)
"        2. Black color is now default for background in console, even if no
"        "reverse" attribute set, because it is typical behaviour of terminals.
"    Added:
"        3. 'force_background' option added to g:ScreenShot dictionary to enable
"        user to adjust HTML-generation to terminal behaviour distinct from typical.
"        (color should be specified as a string in HTML format #RRGGBB)
"    1.05: 
"    Added:
"    	 Good multibyte support(thanks Cyril Slobin <slobin@ice.ru> for suggestion)
"    1.06:
"    Fixed:
"    	 1. Folds are displayed correctly now(was broken in 1.05)
"    	 2. Unprintable unicode chracters are displayed correctly now
"    1.07:
"        Html size optimized
"    Fixed:
"        1. Status line %V item
"        2. Proper embedding in HTML page with defined default color
"
""
" TODO:
"   1.Very small windows proper rendering
"   2.Linebreak option support
"   }}}
"{{{-----------Status Line
function! s:Dump(var,...)
    let indent = a:0?(a:1):0
    if type(a:var) == type({})
        return "\n".repeat(' ',indent)."{\n".repeat(' ',indent).join(map(copy(items(a:var)),'string(v:val[0]).": ".Dump(v:val[1],indent + 4)'), ',')."\n".repeat(' ',indent)."}\n"
    elseif type(a:var) == type([])
        return "\n".repeat(' ',indent)."[\n".repeat(' ',indent).join(map(copy(a:var),'Dump(v:val,indent + 4)'),', ')."\n".repeat(' ',indent)."]\n"
    else
        return string(a:var)
    endif

endf
function! s:Sum(array)
    return len(a:array)?eval(join(map(copy(a:array),'strlen(v:val.value)'),' + ')):0
endf

let s:PrintfNode = {'type': ''}
function! s:PrintfNode.Value()
    if self.name == ''
        return ''
    elseif has_key(self,'expr')
        return eval(self.expr)
    endif
    return '[unimplemented]'
endf
function! s:PrintfNode.Render(hi,lasttype,fillchar,invischar)
    let res = self.Value()
    if self.type == 'flag' && (res =~ '^,' && a:lasttype == 'plain' || res =~ '^ ' && a:lasttype == 'flag' || a:lasttype == 'start')
        let res = strpart(res, 1)
    endif
    if strlen(self.minwid)&& strlen(res) < self.minwid
        if self.left 
            let res .= repeat(a:fillchar, self.minwid - strlen(res))
        else
            let res = repeat(self.type=='num'&&self.zeropad?'0': a:fillchar, self.minwid - strlen(res)).res
        endif
    elseif strlen(self.maxwid) && strlen(res) > self.maxwid
        let res = strpart(a:invischar.strpart(res,strlen(res) - self.maxwid + strlen(a:invischar)),0, self.maxwid)
    endif
    return [{'value': res,'hi': a:hi,'lasttype': (strlen(res)?(self.type):(a:lasttype))}]
endf
function! CopyArgs(args,...)
    return filter((a:0)?extend(copy(a:args),map(eval('{'.join(map(items(filter(deepcopy(a:),'has_key(a:args,v:key)&&type(v:val) == type("")')),'string(v:val[1]).":".string(v:val[0])'),',').'}'), 'a:args[v:val[0]]')):copy(a:args),'v:key !~ "\\v^(\\d+|firstline|lastline)$"')
endf
function! s:PrintfNode.New(name,left,zeropad,minwid,maxwid,...)
    return map(extend(has_key(s:Nodes,a:name)?(deepcopy(s:Nodes[a:name])):deepcopy(self),CopyArgs(a:,'value','root')), "v:key == 'minwid'&& a:0 < 2 && v:val > 50?50:(v:val)")
endf
let s:StringNode = extend({'type': 'str'},s:PrintfNode,'keep')
let s:NumericNode = extend({'type': 'num'},s:PrintfNode,'keep')
let s:FlagNode = extend({'type': 'flag'},s:StringNode,'keep')

unlet s:FlagNode.Value
function! s:FlagNode.Value()
    if has_key(self,'expr')
        let res = eval(self.expr)
        if type(res) == type(1)
            let res = res?(self.on):self.off
        endif
        return !strlen(res)?'':self.name =~ '\U'?' ['.res.']': ','.res
    endif
    return '[unimplemented]'
endf

let s:Nodes = {'f': copy(s:StringNode), 
            \'F': copy(s:StringNode), 
            \'t': copy(s:StringNode), 
            \'m': extend({'name': 'm','expr': '&modified','on': '+','off': '-'}            ,s:FlagNode),        
            \'M': extend({'name': 'M','expr': '&modified','on': '+','off': '-'}            ,s:FlagNode),          
            \'r': extend({'name': 'r','expr': '&readonly','on': 'RO','off': ''}            ,s:FlagNode),         
            \'R': extend({'name': 'R','expr': '&readonly','on': 'RO','off': ''}            ,s:FlagNode),         
            \'h': extend({'name': 'h','expr': '&buftype == "help"','on': 'help','off': ''} ,s:FlagNode),         
            \'H': extend({'name': 'H','expr': '&buftype == "help"','on': 'HLP','off': ''}  ,s:FlagNode),        
            \'w': extend({'name': 'w','expr': '&previewwindow','on': 'Preview','off': ''}  ,s:FlagNode),          
            \'W': extend({'name': 'W','expr': '&previewwindow','on': 'PRV','off': ''}      ,s:FlagNode),          
            \'y': extend({'name': 'y','expr': '&filetype'                                } ,s:FlagNode),          
            \'Y': extend({'name': 'Y','expr': 'toupper(&filetype)'}                      ,s:FlagNode),        
            \'k': extend({'expr': '""'}, s:StringNode ),
            \'n': extend({'expr': 'bufnr("%")'}, s:NumericNode), 
            \'b': copy(s:NumericNode), 
            \'B': copy(s:NumericNode), 
            \'o': copy(s:NumericNode), 
            \'O': copy(s:NumericNode), 
            \'N': copy(s:NumericNode), 
            \'l': extend({'expr': "line('.')"        }, s:NumericNode), 
            \'L': extend({'expr': "line('$')"        }, s:NumericNode), 
            \'c': extend({'expr': "col('$') - 1?col('.'):0"         }, s:NumericNode), 
            \'v': extend({'expr': "virtcol('.')"     }, s:NumericNode),  
            \'V': copy(s:StringNode), 
            \'p': copy(s:NumericNode), 
            \'P': copy(s:StringNode), 
            \'a': copy(s:StringNode), 
            \'{': copy(s:StringNode), 
            \'(': copy(s:PrintfNode),     
            \')': copy(s:PrintfNode),      
            \'T': copy(s:PrintfNode), 
            \'X': copy(s:NumericNode), 
            \'<': copy(s:PrintfNode),         
            \'=': copy(s:PrintfNode),         
            \'#': extend(copy(s:PrintfNode),{'type': 'hi'}),         
            \'*': extend(copy(s:PrintfNode),{'type': 'hi'})}
unlet s:Nodes.T.Render
function! s:Nodes.T.Render(hi,lasttype,fillchar,invischar)
    return [{'value': '', 'hi': a:hi,'lasttype': a:lasttype}]
endf
unlet s:Nodes.M.Value
function! s:Nodes.M.Value()
    if !eval(self.expr) && !strlen(&buftype)
        return ''
    endif
    return call(s:FlagNode.Value, [], self)
endf
let s:Nodes.m.Value = s:Nodes.M.Value
unlet s:Nodes.f.Value
function! s:Nodes.f.Value() "    Path to the file in the buffer, relative to current directory. 
    return strlen(bufname('%'))?fnamemodify(bufname('%'),':.'): '[No Name]'
endf
unlet s:Nodes.F.Value
function! s:Nodes.F.Value() "    Full path to the file in the buffer. 
    return strlen(bufname('%'))?fnamemodify(bufname('%'),':p'): '[No Name]'
endf
unlet s:Nodes.t.Value
function! s:Nodes.t.Value() "    File name (tail) of file in the buffer. 
    return strlen(bufname('%'))?fnamemodify(bufname('%'),':t'): '[No Name]'
endf
unlet s:Nodes.k.Value
function! s:Nodes.k.Value() "    Value of \"b:keymap_name\" or 'keymap' when |:lmap| mappings are	      being used: \"<keymap>\" 
    return
endf
unlet s:Nodes.n.Value
function! s:Nodes.n.Value() "    Buffer number. 
    return bufnr('%')
endf
unlet s:Nodes.b.Value
function! s:Nodes.b.Value() "    Value of byte under cursor. 
    return char2nr(strpart(getline('.'),col('.')-1,1))
endf
unlet s:Nodes.B.Value
function! s:Nodes.B.Value() "    As above, in hexadecimal. 
    return printf('%x',s:Nodes.b.Value())
endf
unlet s:Nodes.o.Value
function! s:Nodes.o.Value() "    Byte number in file of byte under cursor, first byte is 1.      Mnemonic: Offset from start of file (with one added)	      {not available when compiled without |+byte_offset| feature} 
    return line2byte('.') + col('.')
endf
unlet s:Nodes.O.Value
function! s:Nodes.O.Value() "    As above, in hexadecimal. 
    return printf('%x',s:Nodes.o.Value())
endf
unlet s:Nodes.N.Value
function! s:Nodes.N.Value() "    Printer page number.  (Only works in the 'printheader' option.) 
    return
endf
unlet s:Nodes.V.Value
function! s:Nodes.V.Value() "    Virtual column number as -{num}.  Not displayed if equal to 'c'. 
    return col('.') == virtcol('.')?'': '-'.virtcol('.')
endf
unlet s:Nodes.p.Value
function! s:Nodes.p.Value() "    Percentage through file in lines as in |CTRL-G|. 
    return line('.') * 100 / line('$')
endf
unlet s:Nodes.P.Value
function! s:Nodes.P.Value() "    Percentage through file of displayed window.  This is like the	      percentage described for 'ruler'.  Always 3 in length. 
    return line('w0') == 1?(line('$') == line('w$')?'All': 'Top'):line('w$') == line('$')?'Bot': printf('%02s',line('w0')*100/(line('$') - line('w$') + line('w0'))).'%'
endf
unlet s:Nodes.a.Value
function! s:Nodes.a.Value() "    Argument list status as in default title.  ({current} of {max})	      Empty if the argument file count is zero or one. 
    return
endf
unlet s:Nodes['{'].Value
function! s:Nodes['{'].Value() " F  Evaluate expression between '%{' and '}' and substitute result.	      Note that there is no '%' before the closing '}'. 
    for s:var in keys(g:)
        execute "let " . s:var . " = g:" . s:var
    endfor
    let s:res = eval(self.value)
    if type(s:res) == type("")
        return s:res
    else
        return string(s:res)
    endif
endf
function! s:TruncateArray(array,maxwid,left,invischar)
    let array = a:left?(a:array):reverse(a:array)
    let i = len(array)
    let w = 0
    while i > 0
        let i -= 1
        let w += strlen(array[i].value)
        if w + strlen(a:invischar) >= a:maxwid 
            let array = array[(i):]
            if a:left
                let array[0].value = a:invischar.strpart(array[0].value,w - a:maxwid + strlen(a:invischar))
                return array
            else
                let array[0].value = strpart(array[0].value, 0, strlen(array[0].value) - w + a:maxwid - strlen(a:invischar)).a:invischar
                return reverse(array)
            endif
        endif

    endwhile
endf
unlet s:Nodes['('].Render
function! s:Nodes['('].Render(hi,lasttype,fillchar,invischar) "    Start of item group.  Can be used for setting the width and	      alignment of a section.  Must be followed by %) somewhere. 
    let [hi, lasttype] = [a:hi, a:lasttype]
    let array = []
    let i = 0
    let lt = 0 
    for node in self.value
        if type(node) == type({})
            let res = node.Render(hi,lasttype,a:fillchar,'<')
            if node.name == '='
                let eq = res[0] 
            elseif node.name == '<'
                let lt = i
            endif
        else
            let res = strlen(node)?[{'value': node, 'hi': hi, 'lasttype': 'plain'}]:[]
        endif
        let array += res
        let hi = array[len(array) - 1].hi
        let lasttype = array[len(array) - 1].lasttype
        unlet node
        let i += 1
    endfor
    let width = s:Sum(array)
    if strlen(self.minwid) && width < self.minwid
        let space = repeat(a:fillchar, self.minwid - width)
        if exists('eq')
            call extend(eq, {'value': space})
        elseif self.left 
            let array += [{'value': space, 'hi': array[len(array) - 1].hi,'lasttype': lasttype}]
        else
            let array = [{'value': space, 'hi': a:hi,'lasttype': a:lasttype}] + array
        endif
    elseif strlen(self.maxwid) && width > self.maxwid
        if !lt && get(array[0],'lasttype','') != 'plain'
            let part1 = [] 
        else
            let part1 = array[:lt]
        endif
        let maxwid = self.maxwid - s:Sum(part1)
        if maxwid >= 0
            let array = part1 + s:TruncateArray(array,maxwid,1,a:invischar)
        else
            let array = s:TruncateArray(part1,self.maxwid,0,a:invischar)
        endif
    endif
    return array
endf
unlet s:Nodes[')'].Value
function! s:Nodes[')'].Value() "    End of item group.  No width fields allowed. 
    return
endf
unlet s:Nodes.T.Value
function! s:Nodes.T.Value() "    For 'tabline': start of tab page N label.  Use %T after the last	      label.  This information is used for mouse clicks. 
    return ""
endf
unlet s:Nodes.X.Value
function! s:Nodes.X.Value() "    For 'tabline': start of close tab N label.  Use %X after the	      label, e.g.: %3Xclose%X.  Use %999X for a \"close current tab\"	      mark.  This information is used for mouse clicks. 
    return ""
endf
unlet s:Nodes['<'].Value
function! s:Nodes['<'].Value() "    Where to truncate line if too long.  Default is at the start.	      No width fields allowed. 
    return ""
endf
unlet s:Nodes['='].Value
function! s:Nodes['='].Value() "    Separation point between left and right aligned items.	      No width fields allowed. 
    return ""
endf
unlet s:Nodes['#'].Render
function! s:Nodes['#'].Render(hi,lasttype,fillchar,invischar) "    Set highlight group.  The name must follow and then a # again.	      Thus use %#HLname# for highlight group HLname.  The same	      highlighting is used, also for the statusline of non-current	      windows. 
    return [{'value': '', 'hi': self.value,'lasttype': a:lasttype}]
endf
unlet s:Nodes['*'].Render
function! s:Nodes['*'].Render(hi,lasttype,fillchar,invischar) "    Set highlight group to User{N}, where {N} is taken from the minwid field, e.g. %1*.  Restore normal highlight with %* or %0*.	      The difference between User{N} and StatusLine  will be applied	      to StatusLineNC for the statusline of non-current windows.	      The number N must be between 1 and 9.  See |hl-User1..9|
    if !strlen(self.minwid) || !self.minwid
        return [{'value': '', 'hi': '','lasttype': a:lasttype}]
    endif
    return [{'value': '', 'hi': 'User'.self.minwid,'lasttype': a:lasttype}]
endf
function! s:StlPrintf(expr,width,fillchar,invischar,hi)
    let expr = a:expr =~ '^%!'?eval(strpart(a:expr,2)):a:expr

    let str = 's:Nodes["("].New("(",1,0,'.a:width.','.a:width.',['.substitute(expr,'\([^%]*\)\%(%\(-\)\?\(0\)\?\([1-9]\d*\)\?\%(\.\(\d*\)\)\?\([a-zA-Z<=*()]\|{\([^}]*\)}\|#\([^#]*\)#\)\|$\)','\=
                \(submatch(1) != ""?string(submatch(1)).",": "").
                \(
                \       submatch(6) == ")"?"]),": " get(s:Nodes,".string(strpart(submatch(6),0,1)).", s:PrintfNode".
                \   ").New(".
                \               string(strpart(submatch(6),0,1)).", ".strlen(submatch(2)).", ".strlen(submatch(3)).", ".string(submatch(4)).", ".string(submatch(5)).
                \                (submatch(6)=="("?", [":
                \                        strlen(submatch(7))?", ".string(submatch(7))."),":
                \                        strlen(submatch(8))?", ".string(submatch(8))."),": 
                \       "),"
                \                )
                \)','g').'], 1)'
    "echo str
    let tree = eval(str)
    "echo Dump(tree)
    let array = tree.Render('','start',a:fillchar,a:invischar)
    let res = s:SynIdStart(hlID(a:hi))
    let id = a:hi 
    let type = 'start'
    "echo Dump(array)
    for node in array
        if node.hi == ''
            let node.hi = a:hi
        endif
        if node.hi != id && node.hi != 'TabLineTitle666'
            let res .= s:SynIdEnd(hlID(id=='TabLineTitle666'?'Title':id)).s:SynIdStart(hlID(node.hi=='TabLineTitle666'?'Title':node.hi))
            let id = node.hi
        endif
        if node.hi=='TabLineTitle666' " Dirty hack to provide non-standard tabline digit highlighting
            let res .= '<font color='.s:GetColor(hlID('Title'),1).'>'.s:HtmlEscape(node.value).'</font>'
        else
            let res .= s:HtmlEscape(node.value)
        endif
    endfor 
    let res .= s:SynIdEnd(hlID(id))
    return res
endf
function! s:Bufname(nr)
    let name = bufname(a:nr)
    if name == ''
        let name = '[No name]'
    endif
    if strlen(getbufvar(a:nr,'&buftype'))
        let name = fnamemodify(name,':t')
    endif
    return name
endf
function! s:TabTitle(nr)
    let maxLen = (&columns - 1)*9/(9*tabpagenr('$') + 1) - 4 
    let title = substitute(s:Bufname(tabpagebuflist(a:nr)[tabpagewinnr(a:nr)-1]),'\([^\\]\)[^\\]*\\', '\1\\','g')
    if strlen(title) > maxLen
        return strpart(title, strlen(title) - maxLen)
    endif
    return title
endf
function! s:DefaultTabLine()
    let sel = "v:val+1==tabpagenr()?'%#TabLineSel#':'%#TabLine#'"
    let bufNum = 'len(tabpagebuflist(v:val+1))'
    let isModified = "eval(join(map(tabpagebuflist(v:val+1),'getbufvar(v:'.'val,\"&modified\")'),'||'))"
    return join(map(range(tabpagenr('$')),"eval(sel).(eval(bufNum) > 1 || eval(isModified)?' %#'.(v:val+1==tabpagenr()?'Title':'TabLineTitle666').'#'.(eval(bufNum) > 1?eval(bufNum):'').'%'.(v:val+1).'T'.eval(sel).repeat('+',eval(isModified)).'%*'.eval(sel).'\ ':'').s:TabTitle(v:val + 1).' '"),'').'%#TabLineFill#%T%=%#TabLine#%XX'
endf
function! GetTabLine()
    if tabpagenr('$') > 1 && &showtabline == 1 || &showtabline == 2 && (!has('gui_running') || stridx(&guioptions,'e') == -1)
        return s:StlPrintf(strlen(&tabline)?&tabline: s:DefaultTabLine(), &columns,' ','<','')
    endif
    return ''
endf
function! s:GetTitle()
    if !&title
        let title = 'VIM'
    else
        let VIM = get(v:,'servername','')
        if VIM == ''
            let VIM = has('gui_running')?'GVIM': 'VIM'
        endif
        let bufName = &buftype == 'help'?'help':fnamemodify(fnamemodify(fnamemodify(bufname("%"),":p"),":~"),":h")
        if strlen(bufName) > 3
            let partLen = 3 
            let bufName = strpart(bufName, 0, partLen).'%<'.strpart(bufName,partLen)
        endif
        if strlen(bufName)
            let bufName = '('.bufName.')'
        endif
        let args = argc() <= 1?'': ' ('.(argv(argidx()) == bufname('%')?argidx() + 1: '('.(argidx() + 1).')').' of '.argc().')'
        let titlestring = strlen(&titlestring)?&titlestring: '%t %M '.bufName.args.' - '.VIM
        let title = substitute(s:StlPrintf(titlestring,(strlen(&titlestring)? &titlelen?&titlelen:&columns: 1000) - 1,' ','..',''),'\s*$','','')
        if !strlen(&titlestring) && strlen(title) > &columns - 5
            let title = title[0:(&columns - 5)/2 - 1 ].'...'.title[strlen(title) - (&columns - 5)/2 + 1:strlen(title)]
        endif
        let title = substitute(title, ' ', '\&nbsp;', 'g')
    endif
    if g:ScreenShot.Icon
        return  '<table align=left style="color:white;background:blue"><tr><th>'.s:ParseXpm(s:VimLogoXpm).'</th><th>'.title.'</th></tr></table>'
    else 
        return title 
    endif
endf
function! s:SplitWithSpan(hi,str)
    return eval(join(map(split(a:str,' '),"'s:SynIdWrap(a:hi,\"'.v:val.'\")'"), ".' '."))
endf
function! s:GetCredits()
    return s:SynIdWrap('Question','Code syntax highlighting by ').'<a '.s:SynIdStyle(s:GetDefaultHlVect()).' href=http://www.vim.org><u>'.s:SynIdWrap('ModeMsg','VIM').'</u></a>'.s:SynIdWrap('Question',' captured with ').'<a '.s:SynIdStyle(s:GetDefaultHlVect()).'  href=http://www.vim.org/scripts/script.php?script_id=1552><u>'.s:SynIdWrap('ModeMsg','ScreenShot').'</u></a>'.s:SynIdWrap('Question','  script ')
endf
"}}}
"{{{-----------Menus
function! s:GetMenu(mode,name)
    redir => src
    exec a:mode.'menu '.a:name
    redir END
    return src
endf

"}}}
"{{{-----------Xpm
function! s:ParseXpm(src)
    let [all,comment,name,content;rest] = matchlist(tr(a:src,"\n"," "),'/\*\([^*]*\|\*[^/]\)\*/\s*static\s\+char\s*\*\s*\(\w*\)\[\]\s*=\s*{\(.*\)}')
    let lines = eval('['.content.']')	
    let [width, height, colors_count, charwid; rest] = split(lines[0], '\s\+')
    "echo l:
    let colors = {}
    for id in range(colors_count+1)[1:]
        let [all, chars, key, color; rest] = matchlist(lines[id],'^\(.\{'.charwid.'\}\)\s\+\(.\)\s\+\(.*\)')
        let colors[chars] = {'color': color, 'key': key}
    endfor
    "echo colors
    let doc = '<table width='.width.' height='.height.' cellspacing=0 cellpadding=0>'
    for num in range(height + colors_count + 1)[colors_count + 1:]
        let doc .= '<tr>'
        for i in range(width)
            let col =get(colors,strpart(lines[num],i*charwid, charwid),{})
            let doc .= '<td'.((has_key(col, 'color') && col.color !~? '^\(None\|\)$')?(' bgcolor='.col.color): '').'></td>'
        endfor	
        let doc .= '</tr>'
    endfor
    return doc.'</table>'
endf
let s:VimLogoXpm = "/* XPM */
            \static char * vim16x16[] = {
            \'16 16 8 1',
            \' 	c None',
            \'.	c #000000',
            \'+	c #000080',
            \'@	c #008000',
            \'#	c #00FF00',
            \'$	c #808080',
            \'%	c #C0C0C0',
            \'&	c #FFFFFF',
            \'  .....#. ....  ',
            \' .&&&&&.@.&&&&. ',
            \' .%%%%%$..%%%%$.',
            \'  .%%%$.@.&%%$. ',
            \'  .%%%$..&%%$.  ',
            \'  .%%%$.&%%$..  ',
            \' #.%%%$&%%$.@@. ',
            \'#@.%%%&%%$.@@@@.',
            \'.@.%%%%%..@@@@+ ',
            \' ..%%%%.%...@.  ',
            \'  .%%%%...%%.%. ',
            \'  .%%%.%%.%%%%%.',
            \'  .%%$..%.%.%.%.',
            \'  .%$.@.%.%.%.%.',
            \'   .. .%%.%.%.%.',
            \'       .. . . . '};"

"}}}
"{{{-----------Window's layout recognition functions
function! s:Window_New(window,num)
    call extend(a:window,{'num':a:num,'size': [winwidth(a:num),winheight(a:num)]})
endf
function! s:Window_TryMerge(self,new)
    if has_key(a:self,'prev')
        if a:self.size[!a:self.prevdir] == a:self.prev.size[!a:self.prevdir]
            if !has_key(a:self.prev, 'dir')
                let a:self.prev.dir = a:self.prevdir
            endif
            if a:self.prev.dir == a:self.prevdir && !has_key(a:self.prev, 'num')
                call s:Container_Add(a:self.prev,a:self)
            else
                call s:Container_New(a:new,a:self.prev,a:self)
            endif
            return 1
        endif	
    endif
    return 0
endf
function! s:Window_DelParent(self)
    if has_key(a:self,'parent')
        call remove(a:self,'parent')
    endif
    if has_key(a:self,'prev')
        call remove(a:self,'prev')
    endif
    for entry in items(a:self)
        if type(entry[1]) == 2
            unlet a:self[entry[0]]
        endif
    endfor
    if !has_key(a:self, 'childs')
        return
    endif
    for C in a:self.childs
        call s:Window_DelParent(C)
    endfor

endf
function! s:Window_IsTop(self,top)
    let res = a:self
    while has_key(res,'parent')
        let res = res.parent
    endwhile
    return res is a:top
endf
function! s:Container_New(container,child1,child2)
    call extend(a:container,{'dir':a:child2.prevdir,'childs':[], 'size': [0,0]})
    let a:container.size[!a:container.dir] = a:child2.size[!a:container.dir]
    call s:Container_Add(a:container,a:child1, a:child2)
    if has_key(a:child1, 'prev')
        let a:container.prev = a:child1.prev
    endif
    if has_key(a:child1, 'prevdir')
        let a:container.prevdir = a:child1.prevdir
    endif
endf
function! s:Container_Add(self,...)
    for child in a:000
        let a:self.size[a:self.dir] += child.size[a:self.dir] + (len(a:self.childs) != 0) 
        call add(a:self.childs,child)
        let child.parent = a:self
    endfor
endf
function! s:EnumWindows()
    let ei_save = &ei
    let winnr_save = winnr()
    set ei=all
    let windows=[]
    let i = 1
    while winwidth(i) > 0
        let window = {'active': i == winnr_save}
        call s:Window_New(window, i)
        call add(windows, window)
        let i += 1
    endwhile
    1wincmd w
    let i = 1
    let cur = {}

    while i == winnr() 


        let window = windows[i - 1]
        let window.pos = {'line':line('.'),'col':col('.'),'virtcol':virtcol('.'),'topline':line('w0'),'bottomline':line('w$'),'lastline':line('$')}
        if i - 1
            let window.prev = cur
            wincmd k 
            if !s:Window_IsTop(windows[winnr() - 1],cur) 
                exec i.'wincmd w'
                wincmd h 
                if !s:Window_IsTop(windows[winnr() - 1],cur)
                    echoerr 'Can not enum window!'
                    return 0
                endif
                let window.prevdir = 0 
            else
                let window.prevdir = 1
            endif
            exec i.'wincmd w'
            let new={}
            while s:Window_TryMerge(window,new) && has_key(window,'prev')
                if len(new)
                    let window = new
                    let new = {}
                else
                    let window = window.prev
                endif
            endwhile
        endif
        let cur = window
        let i += 1
        wincmd w
    endwhile
    "	call s:Window_DelParent(cur)
    let &ei = ei_save
    exec winnr_save.'wincmd w'
    return cur

endf
"}}}
"{{{-----------Html generation functions
if has('gui_running')
    function! s:GetColor(id,type)
        return synIDattr(a:id,a:type?'fg#': 'bg#')
    endf
else
    if &t_Co == 8
        if has('win32') || has('dos32') || has('dos16')
            let s:Colors = ['#000000', '#0000ff', '#00ff00', '#00ffff', '#ff0000', '#ff00ff', '#ffff00', '#ffffff']
        else
            let s:Colors = ['#000000', '#ff0000', '#00ff00', '#ffff00', '#0000ff', '#ff00ff', '#00ffff', '#ffffff']
        endif
    else
        if has('win32') || has('dos32') || has('dos16')
            let s:Colors = ['#000000', '#0000c0', '#008000', '#008080', '#c00000', '#c000c0', '#808000', '#c0c0c0', '#808080', '#6060ff', '#00ff00', '#00ffff', '#ff8080', '#ff40ff', '#ffff00', '#ffffff']
        else
            let s:Colors = ['#000000', '#c00000', '#008000', '#808000', '#0000c0', '#c000c0', '#008080', '#c0c0c0', '#808080', '#ff6060', '#00ff00', '#ffff00', '#8080ff', '#ff40ff', '#00ffff', '#ffffff']
        endif
    endif	
    let s:valuerange = [0x00, 0x5F, 0x87, 0xAF, 0xD7, 0xFF] 
    function! s:GetColor(id,type)
        let c = synIDattr(a:id,a:type?'fg#': 'bg#')
        if c == '-1' || c == ''
            return ''
        endif
        let cc = eval(c)
        if &t_Co != 256 || cc < 0x10
            return s:Colors[cc]
        else
            let cc = cc - 16
            return '#'.(cc <= 216?(printf('%.2x',s:valuerange[(cc/36)%6]).printf('%.2x',s:valuerange[(cc/6)%6]).printf('%.2x',s:valuerange[cc%6])):repeat(printf('%.2x',8 + (cc - 216)*0x0a),3))
        endif
    endf
endif
function! s:GetHlVect(id)
    if type(a:id) != type([])
        let id = synIDtrans((type(a:id) == type(1))?(a:id):hlID(a:id))
        let reverse = synIDattr(id,'reverse') == '1' "&& id != hlID('Normal')
        if id == hlID('Normal') && !reverse
            return ['','','','','']
"            return s:GetDefaultHlVect()
        endif
        let color = s:GetColor(id,!reverse) 
        let background = s:GetColor(id,reverse) 
        if (color == '' || background == '') && reverse
            if reverse 
                let style = s:GetDefaultHlVect()
                let [color, background] = [color != ''?color : style[1] != ''?style[1] : '#ffffff', background != ''?background : style[0] != ''? style[0] : '#000000']
            endif
        endif
        return [color, background, synIDattr(id, 'bold'), synIDattr(id, 'italic'), synIDattr(id, 'underline')]
    else
        let vec = s:GetHlVect(a:id[0])
        let vecDiff = s:GetHlVect(a:id[1])
        return [vec[0], vecDiff[1], vecDiff[2]||vec[2], vecDiff[3]||vec[3], vecDiff[4]||vec[4]]
    endif
endf
function! s:GetDefaultHlVect()
    let id = hlID('Normal')
    let color = s:GetColor(id,1) 
    let background = s:GetColor(id,0) 
    let background = has_key(g:ScreenShot, 'force_background')?g:ScreenShot.force_background : background != ''? background : has('gui_running') ?'#ffffff' : '#000000'
    let color = color != ''?color : has('gui_running') || has_key(g:ScreenShot, 'force_background')?'#000000' : '#ffffff'
    return [color, background, synIDattr(id, 'bold'), synIDattr(id, 'italic'), synIDattr(id, 'underline')]
endf
function! s:DiffSynId(y,x,fl)
    return [synID(a:y,a:x,a:fl), diff_hlID(a:y,a:x)]
endf
function! s:SynIdStyle(id)
    return (a:id[0] == '' && a:id[1] == '')?'' : 'style="'.(strlen(a:id[0])?'color:'.a:id[0].';': '').(strlen(a:id[1])?'background:'.a:id[1] : '').'"'
endf
function! s:SynIdStart(id)
    let vec = s:GetHlVect(a:id)
    return (vec[1] != ''? '<span style="'.(strlen(vec[0])?'color:'.vec[0].';': '').(strlen(vec[1])?'background:'.vec[1] : '').'">' : vec[0] != ''? '<font color='.vec[0].'>': '').(vec[2]?'<b>': '').(vec[3]?'<i>': '').(vec[4]?'<u>': '')
endf
function! s:SynIdEnd(id)
    let vec = s:GetHlVect(a:id)
    return (vec[4]?'</u>': '').(vec[3]?'</i>': '').(vec[2]?'</b>': '').(vec[1] != ''?'</span>': vec[0] != ''? '</font>': '')
endf
function! s:SynIdWrap(id,text)
    return s:SynIdStart(a:id).a:text.s:SynIdEnd(a:id)
endf

function! s:GetLinePrefix(y,numWidth,width,wrapped)
    let prefix = ''
    let closed = foldclosed(a:y) != -1
    if &foldcolumn
        let level = foldlevel(a:y) - closed 
        if level || closed
            if &foldcolumn > 1
                if level < &foldcolumn
                    let prefix = repeat('|',level)

                else
                    let i = level - &foldcolumn + 2
                    while i <= level
                        let prefix .= i < 10? i : '>'
                        let i += 1	
                    endw
                endif
                if closed 
                    let prefix .= '+'.repeat(' ',&foldcolumn - level - 1)
                elseif 	level > foldlevel(a:y - 1)
                    let prefix = strpart(prefix,0,strlen(prefix) - 1).'-'
                endif
                let prefix .= repeat(' ', &foldcolumn - strlen(prefix))
            else
                if level == 1
                    let prefix = '|'
                else
                    let prefix = level < 10?level : '>'
                endif
                if closed 
                    let prefix = '+'
                elseif 	level > foldlevel(a:y - 1)
                    let prefix = '-'
                endif
            endif
        else 
            let prefix = repeat(' ',&foldcolumn)
        endif
        let prefix = s:SynIdWrap('FoldColumn',strpart(prefix,0,a:width))
    endif
    if &number && a:y <= line('$')
        if a:wrapped 
            let prefix .= s:SynIdWrap(a:wrapped?'LineNr': 'NonText',strpart(repeat(' ',a:numWidth),0,a:width - &foldcolumn))
        else
            let prefix .= s:SynIdWrap(closed?'Folded': 'LineNr',strpart(repeat(' ',a:numWidth - 1 - strlen(a:y)).a:y.' ',0,a:width - &foldcolumn))
        endif
    endif
    return prefix
endf
function! s:HtmlEscape(text)
    return substitute(a:text,'[<>&]','\={"<": "&lt;",">": "&gt;","&": "&amp;"}[submatch(0)]','g')
endf
function! s:HtmlDecode(text)
    return substitute(a:text,'&\([^;]*\);','\={"lt":"<","gt":">","amp":"&"}[submatch(1)]','g')
endf
function! s:Opt2Dict(opt)
    return eval('{'.substitute(a:opt,'\(\w\+\):\([^,]*\)\(,\|$\)',"'\\1':'\\2'\\3", 'g').'}')
endf
function! s:GetFillChars()
    return extend({"fold": "-",'vert': '|','stl': ' ','stlnc': ' ','diff': '-'},s:Opt2Dict(&fillchars))
endf
function! s:synIDSpec(y,x,normal)
    return !&diff?(a:normal):diff_hlID(a:y,a:x)?(s:DiffSynId(a:y,a:x,0)): [a:normal, 0]
endf
function! s:GetColoredText(lines,start,finish,height,topfill,lineEnd)
    let y = a:start 
    let s:synIDfn = &diff? function('s:DiffSynId'): function('synID')
    let realWidth = winwidth(winnr())
    let foldWidth = &foldcolumn 
    let numWidth = &number?max([&numberwidth,strlen(line('$'))+1]):0
    let width = realWidth - numWidth - foldWidth 
    let fillChars = s:GetFillChars()
    let listChars = s:Opt2Dict(&listchars)
    let expandTab = !&list || has_key(listChars, 'tab')
    if !&list
        let listChars.tab = '  '
    endif
    let fill_screen = strlen(a:lineEnd) || get(g:ScreenShot, 'fill_screen', 0)
    let d_opts = split(&display,',')
    let [uhex, lastline] = [0, 0]
    for d_opt in d_opts
        if d_opt == 'uhex'
            let uhex = 1
        elseif d_opt == 'lastline'
            let lastline = 1
        endif
    endfor
    let realX = 0 
    let view = winsaveview() 
    let topfill = a:topfill == -1?view.topfill : a:topfill
    if a:height&&topfill
        let inc = a:height?min([topfill,a:height]):topfill
        for dd in range(inc)
            call add(a:lines,s:GetLinePrefix(y - 1,numWidth,realWidth,0).s:SynIdWrap('DiffDelete',s:HtmlEscape(repeat(fillChars.diff,width))).a:lineEnd)
        endfor
    endif
    let yReal = topfill 
    let skip = view.leftcol + (view.skipcol?(view.skipcol + strlen(&showbreak)):0)
    let maxRealX = width + view.leftcol + view.skipcol
    if width <= 0
        let [width , maxRealX] = [0, 0]
    endif
    let cond = ((!a:height || !lastline))?((a:start == a:finish && a:height)?'yReal < a:height && y == a:start || y < a:finish': 'y <= a:finish'): 'yReal < a:height'
    while eval(cond) && y <= line('$')
        let x = 1
        let xx = 0
        let str = getline(y)
        let chunk = '' 
        let xmax = len(str) + &list		
        let prefix = s:GetLinePrefix(y,numWidth,realWidth,0)
        let realX = 0 
        let [oldId, oldId1] = &diff?[[0,0],[0, 0]] :[0, 0]
        let folded = foldclosed(y)
        if x > xmax
            call add(a:lines, s:SynIdWrap(diff_hlID(y,x),prefix.(fill_screen || diff_hlID(y, x)?repeat(' ', width): '')).a:lineEnd)
        elseif folded != -1
            let text = matchstr(foldtextresult(y), '.'.'\{,'.width.'\}', 0)
            call add(a:lines,prefix.s:SynIdWrap('Folded',s:HtmlEscape(text).repeat(fillChars.fold,width - strlen(substitute(text, ".", "x", "g"))).a:lineEnd))
            let y = foldclosedend(y) 
        else
            let tab = ''
            let realX = 0 
            let eol = 0
            if view.skipcol
                let [oldId, oldId1, tab] = [&diff?[hlID('NonText'), 0] :hlID('NonText'), 0, s:SynIdStart(hlID('NonText')).s:HtmlEscape(&showbreak)]
            endif
            while x <= xmax && eval(cond)
                let newLine = ((xx<maxRealX)?(prefix):s:GetLinePrefix(y,numWidth,realWidth,1)).tab
                while realX < maxRealX
                    let [whole, char, str; dummy]  = matchlist(str, '^\(.\=\)\(.*\)$')
                    let diffX = len(char)?len(char):1
                    if char == ''
                        if eol || !&list || !has_key(listChars,'eol')
                            let diff = maxRealX - realX 
                            let char = fill_screen || diff_hlID(y, x)?repeat(' ',diff): ' '
                            let id = s:synIDSpec(y,x,0)
                        else
                            let id = s:synIDSpec(y,x,hlID('NonText'))
                            let diff = 1
                            let char = listChars.eol
                            let eol = 1
                        endif
                    elseif (char < ' ' || char > '~') && char !~ '\p'
                        if char == "\t" && expandTab
                            let id = s:synIDSpec(y,x,&list?hlID('SpecialKey'):synIDtrans(synID(y, x, 0)))
                            let diff = &tabstop - xx%&tabstop
                            let char = strpart(listChars.tab,0,1).repeat(strpart(listChars.tab,1),diff-1)
                        else 
                            let id = s:synIDSpec(y,x,hlID('SpecialKey'))
                            if char2nr(char) < 0x100
                                if uhex
                                    let diff = 4
                                    let char = char == "\n"?'<00>':printf('<%02x>',char2nr(char))
                                else
                                    let diff = 2
                                    let charnr =  char2nr(char)
                                    if charnr == 10
                                        let char = '^@'
                                    elseif charnr  < 32
                                        let char = '^'.nr2char(64 + charnr)
                                    elseif charnr == 127
                                        let char = '^?'
                                    elseif charnr < 160
                                        let char = '~'.nr2char(64 + charnr - 128)
                                    elseif charnr == 255
                                        let char = '~?'
                                    else
                                        let char = '|'.nr2char(32 + charnr - 160)
                                    endif
                                endif
                            else
                                let diff = 6
                                let char = printf('<%04x>',char2nr(char))
                            endif
                        endif
                    else
                        let diff = 1
                        let id = s:synIDfn(y,x,0) 
                    endif
                    if id != oldId
                        if chunk != ''
                            let newLine .= s:SynIdEnd(oldId1).s:SynIdStart(oldId).s:HtmlEscape(chunk) 
                        endif
                        let [chunk, oldId, oldId1] = ['', id, oldId]
                    endif
                    if realX >= skip 
                        let chunk .= char
                    elseif realX + strlen(substitute(char, ".", "x", "g")) >= skip 
                        let chunk .= matchstr(char,'.*',skip - realX) 
                    endif
                    let realX += diff 
                    let xx += diff
                    let x += diffX 
                endwhile
                if chunk != ''
                    let newLine .= s:SynIdEnd(oldId1).s:SynIdStart(oldId).s:HtmlEscape(chunk)    
                    let [chunk, oldId, oldId1] = ['', id, oldId]
                endif
                let save_id = oldId
                if realX > maxRealX 
                    let realX   = realX - maxRealX
                    let [all, newLine, chunk; rest] = matchlist(newLine,'\(.*\)\(\%([^<>&;]\|&[^;]*;\)\{'.realX.'\}\)$')
                    let chunk = s:HtmlDecode(chunk)
                else
                    let [chunk, realX] = ['', 0]
                endif
                let oldId1 = &diff?[0,0]: 0
                if &showbreak != ''
                    let xx += strlen(&showbreak)
                    let tab = s:SynIdWrap('NonText',s:HtmlEscape(&showbreak))
                    let realX += strlen(&showbreak)
                else
                    let tab = ''
                endif
                call add(a:lines, newLine.s:SynIdEnd(save_id).a:lineEnd)
                if chunk == ''
                    let oldId = &diff?[0,0]: 0
                endif
                let yReal += 1
                if !&wrap
                    break
                endif
                if view.skipcol
                    let maxRealX -= view.skipcol 
                    let view.skipcol = 0
                    let skip = 0
                endif
            endw
            let yReal -= 1
        endif
        let yReal += 1
        let y += 1
        if diff_filler(y)
            let inc = a:height?min([diff_filler(y),a:height - yReal]):diff_filler(y)
            for dd in range(inc)
                call add(a:lines,prefix.s:SynIdWrap('DiffDelete',s:HtmlEscape(repeat(fillChars.diff,width))).a:lineEnd)
            endfor
            let yReal += inc 
        endif
    endw
    while yReal < a:height
        let prefix = s:GetLinePrefix(y,numWidth,realWidth,0)
        let fill_screen = fill_screen || s:GetHlVect('NonText')[1] != ''

        if y > line('$') 
            call add(a:lines, prefix.s:SynIdStart(hlID('NonText')).'~'.(fill_screen?repeat(' ', width + numWidth - 1): '').s:SynIdEnd(hlID('NonText')).a:lineEnd)
        else 
            call add(a:lines, s:GetLinePrefix(y,0,realWidth,1).s:SynIdStart(hlID('NonText')).'@'.(fill_screen?repeat(' ', width + numWidth - 1): '').s:SynIdEnd(hlID('NonText')).a:lineEnd)
        endif
        let yReal += 1
    endw
    let style = s:GetDefaultHlVect()
    if len(a:lines) && style[0] != ''
        let a:lines[0] = '<font color='.style[0].'>'.a:lines[0] 
        let a:lines[len(a:lines) - 1] .= '</font>'
    endif
endf
function! s:GetColoredWindowText(window,lines,last)
    exec a:window.num.'wincmd w'
    let fillChars = s:GetFillChars()
    call s:GetColoredText(a:lines, line('w0'),line('w$'),winheight(a:window.num),-1,a:last[0]?'':s:SynIdWrap('VertSplit', fillChars.vert))
    let [fill_stl, synId] = (a:window.active)?[(fillChars.stl), 'StatusLine'] :[fillChars.stlnc, 'StatusLineNC']
    if strlen(&statusline)
        let StatusLine = s:StlPrintf(&statusline,winwidth('.'),fill_stl,'<',synId)
    else
        let name = s:Bufname('%')
        if &modified
            let name .= fillChars.stlnc.'[+]'
        endif
        if &readonly
            let name .= (&modified?'':fillChars.stlnc).'[RO]'
        endif
        if a:window.pos.topline == 1
            if a:window.pos.bottomline == a:window.pos.lastline
                let percents = 'All'
            else
                let percents = 'Top'
            endif
        elseif a:window.pos.bottomline == a:window.pos.lastline
            let percents = 'Bot'
        else
            let percents = (a:window.pos.topline*100/(a:window.pos.lastline + a:window.pos.topline - a:window.pos.bottomline )).'%'
            if strlen(percents) == 2
                let percents = ' '.percents
            endif
        endif
        let posInfo = a:window.pos.line.','.a:window.pos.col.((a:window.pos.col != a:window.pos.virtcol)?('-'.a:window.pos.virtcol): '')
        let width = winwidth('.')
        let magicLen = 18
        let lack =  strlen(name) + magicLen + 1 - width 
        if lack < 0 
            let StatusLine = name.repeat(fillChars.stlnc, width - strlen(name) - magicLen).posInfo.repeat(fillChars.stlnc,magicLen - 3 - strlen(posInfo)).percents
        else
            let free = strlen(name) + magicLen - 1 - strlen(posInfo)
            let widthFree = width - 2 - strlen(posInfo)
            let newNameLen = (strlen(name) - 1)*widthFree/free
            let newInfoLen = (magicLen - strlen(posInfo))*widthFree/free
            let newNameLen += widthFree - newNameLen - newInfoLen
            let StatusLine = s:HtmlEscape('<'.strpart(name, strlen(name) - newNameLen)).' '.posInfo
            let percents = ' '.percents 
            if (newInfoLen>4)
                let StatusLine .= repeat(fillChars.stlnc,newInfoLen - 4).percents
            elseif newInfoLen >= 0 
                let StatusLine .= repeat(fillChars.stlnc,newInfoLen)
            else
                let StatusLine = strpart(StatusLine, 0, strlen(StatusLine) + newInfoLen) 
            endif


        endif
        let StatusLine = s:SynIdWrap(synId,StatusLine)
    endif
    call add(a:lines,StatusLine.s:SynIdWrap(synId, a:last[0]?'':fill_stl))
endf

function! s:InternalToHtml(self,lines,last)
    if has_key(a:self, 'childs')
        let lines = []
        let last = [0,0]
        let b = 0
        for C in range(len(a:self.childs))
            let last[a:self.dir] = a:last[a:self.dir] && C == len(a:self.childs) - 1
            let last[1 - a:self.dir] =  a:last[1 - a:self.dir]
            if b
                let childLines = []
                call s:InternalToHtml(a:self.childs[C],childLines,last)
                if !a:self.dir

                    let i = 0
                    while i < len(childLines)
                        let lines[i] .= childLines[i]
                        let i += 1
                    endw
                else

                    let lines += childLines 
                endif
            else
                call s:InternalToHtml(a:self.childs[C],lines,last)
                let b = 1
            endif

        endfor
        call extend(a:lines, lines)
    elseif has_key(a:self, 'num')
        call s:GetColoredWindowText(a:self, a:lines, a:last)
    endif

endf
function! s:SaveEvents()
    let saved = [&winwidth,&winheight,&winminheight,&winminwidth,&ei]
    let [&winwidth,&winheight,&winminheight,&winminwidth,&ei] = [1, 1, 1, 1, 'all']
    return saved
endf
function! s:RestoreEvents(saved)
    let [&winwidth,&winheight,&winminheight,&winminwidth,&ei] = a:saved 
endf
"}}}
"{{{-----------Top-level functions and commands
if !exists('ScreenShot')
    let ScreenShot = {}
endif
call extend(ScreenShot,{'Title': 1,'Icon': 1,'Credits': 1},'keep')
function! ToHtml()
    let tabline = GetTabLine()
    if g:ScreenShot.Title
        let title = s:GetTitle() 
    endif
    let saved = s:SaveEvents()
    let win = s:EnumWindows()
    let lines = []
    call s:InternalToHtml(win, lines, [1,1])
    call s:RestoreEvents(saved)
    if tabline != ''
        call insert(lines,tabline) 
    endif
    let lines[0] = '<table cellspacing=0 cellpadding=0  '.s:SynIdStyle(s:GetDefaultHlVect()).' '.(exists('title')?' border=2><tr><th align=left style="color:white;background:blue">'.title.'</th></tr>': '>').'<tr><td><pre>'.lines[0]
    let lines[len(lines) - 1] .= '</pre></td></tr>'.(g:ScreenShot.Credits?'<tr><td><table align=right><tr><td width=20%></td><td width=80%><small><i>'.s:GetCredits().'</i></small></td></tr></table></td></tr>': '').'</table>'
    return lines
endf
function! Text2Html(line1,line2)
    let lines = []
    call s:GetColoredText(lines,a:line1,a:line2,0,0,'')
    exec 'new '.bufname('%').'.html'
    let lines[0] = '<table cellspacing=0 cellpadding=0 '.s:SynIdStyle(s:GetDefaultHlVect()).'><tr><td colspan><pre>'.lines[0]
    call append(0,lines + ['</pre></td></tr>'.(g:ScreenShot.Credits?'<tr><td><table align=right><tr><td width=20%></td><td width=80%><small><i>'.s:GetCredits().'</i></small></td></tr></table></td></tr>': '').'</table>'])
endf

function! ScreenShot()
    let a = ToHtml()
    let shots = eval('['.substitute(glob('screenshot-*.html'),'\%(screenshot-\(\d*\).html\|.*\)\%(\n\|$\)','\=((submatch(1)!="")?submatch(1):0).","','g').']')
    exec 'new screenshot-'.(max(shots) + 1).'.html'
    call append(0,a)
endf
function! Diff2Html(line1,line2)
    let buffs = map(filter(tabpagebuflist(tabpagenr()),'getwinvar(bufwinnr(v:val),''&diff'')'),'bufwinnr(v:val)')
    if len(buffs) < 2
        echoerr 'Window in diff mode not found'
        return 0
    endif
    if buffs[0] == winnr() 
        let num = 0
    else
        let num = index(buffs, winnr())
        if num == -1
            echoerr 'Can''t find current buffer!'
            return
        endif
        let buffs[1] = buffs[num]
        let num = 1 
    endif
    let lineTop = eval(join(map(range(1,a:line1),'diff_filler(v:val) - (foldclosed(v:val)>0) + (v:val == foldclosedend(v:val) ) + 1'),'+'))
    let height =  eval(join(map(range(a:line1,a:line2),'diff_filler(v:val) - (foldclosed(v:val)>0) + (v:val == foldclosedend(v:val)) + 1'),'+'))
    exec buffs[1-num].'wincmd w'
    let i = 0 
    let val = 0
    while val < lineTop && i < line('$')
        let i += 1
        let val += diff_filler(i) - (foldclosed(i)>0) + (i == foldclosedend(i) ) + 1
    endw
    let [topfill{num+1}, topfill{2-num}] = [0, val - lineTop]
    let [startY{num+1}, startY{2-num}] = [a:line1, i]
    while val < lineTop + height && i < line('$')
        let i += 1
        let val += diff_filler(i) - (foldclosed(i)>0) + (i == foldclosedend(i) ) + 1
    endw
    let [endY{num+1}, endY{2-num}] = [a:line2, i-1]
    exec buffs[0].'wincmd w'
    let lines1 = []
    call s:GetColoredText(lines1,startY1,endY1,height,topfill1,s:SynIdWrap('VertSplit', s:GetFillChars().vert))
    exec buffs[1].'wincmd w'
    let lines2 = []
    call s:GetColoredText(lines2,startY2,endY2,height,topfill2,'')
    for i in range(len(lines1))
        let lines1[i] .= lines2[i]
    endfor 
    exec 'new '.fnamemodify(bufname(winbufnr(buffs[0])),':t').'\ -\ '.fnamemodify(bufname(winbufnr(buffs[0])),':t').'.diff.html'
    let lines1[0] = '<table cellspacing=0 cellpadding=0 '.s:SynIdStyle(s:GetDefaultHlVect()).'><tr><td colspan><pre>'.lines1[0]
    call append(0,lines1 + ['</pre></td></tr>'.(g:ScreenShot.Credits?'<tr><td><table align=right><tr><td width=20%></td><td width=80%><small><i>'.s:GetCredits().'</i></small></td></tr></table></td></tr>': '').'</table>'])

endf
command! -range=% Text2Html     :call Text2Html(<line1>,<line2>)
command! ScreenShot    :call ScreenShot()
command! -range=% Diff2Html     :call Diff2Html(<line1>,<line2>)
"}}} vim:foldmethod=marker foldlevel=0
