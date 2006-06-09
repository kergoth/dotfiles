"   Copyright (c) 2006, Michael Shvarts <shvarts@akmosoft.com>
"
"{{{-----------License:
"   ScreenShoot.vim is free software; you can redistribute it and/or modify it under
"   the terms of the GNU General Public License as published by the Free
"   Software Foundation; either version 2, or (at your option) any later
"   version.
"
"   ScreenShoot.vim is distributed in the hope that it will be useful, but WITHOUT ANY
"   WARRANTY; without even the implied warranty of MERCHANTABILITY or
"   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
"   for more details.
"
"   You should have received a copy of the GNU General Public License along
"   with ScreenShoot.vim; see the file COPYING.  If not, write to the Free Software
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
"    0.8: Added:
"       a) Full 'nowrap' option support
"       b) Non-printable characters support
"       c) 'showbreak' option support
"       d) 'display' option support (lastline and uhex both)
"       e) 'list' option support
"    0.81: Bug in HTML code generation fixed (an unmatched closing tag </span> in some cases)
"
" TODO:
"   1.Very small windows proper rendering
"   2.Linebreak option support
"   }}}
"{{{-----------Utils
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
	call s:Window_DelParent(cur)
	let &ei = ei_save
	exec winnr_save.'wincmd w'
	return string(cur)

endf
"}}}
"{{{-----------Html generation functions
if has('gui')
        function! s:GetColor(id,type)
                return synIDattr(a:id,a:type)
        endf
else
	let s:Colors = ['#000000', '#c00000', '#008000', '#808000', '#0000c0', '#c000c0', '#008080', '#c0c0c0', '#808080', '#ff6060', '#00ff00', '#ffff00', '#8080ff', '#ff40ff', '#00ffff', '#ffffff']
	function! s:GetColor(id,type)
                let c = synIDattr(a:id,a:type)
                if c == '-1' || c == ''
                        return ''
                endif
                return s:Colors[eval(c)]
        endf
endif
function! s:SynIdStyle(id)
	let color = s:GetColor(a:id,'fg#') 
	let background = s:GetColor(a:id,'bg#') 
	if synIDattr(a:id,'reverse') == '1'
                if color == '' && background == ''
                        let color = s:GetColor(hlID('Normal'),'fg#')
                        if color == ''
                                let color = '#000000'
                        endif
                        let background = s:GetColor(hlID('Normal'),'bg#')
                       if background == ''
                              let background = '#ffffff' 
                      endif
                endif
		return '"'.(strlen(background)?('color:'.background): '').';background:'.color.'"'
	endif
	if color == '' && background == ''
		return '' 
	endif
	return '"color:'.color.';background:'.background.'"'

endf
function! s:SynIdStart(id)
	let res = ''
	let style = s:SynIdStyle(a:id) 
	if strlen(style)
		let res .=  '<span style='.style.'>'
	endif
	if synIDattr(synIDtrans(a:id),'italic') == '1'
		let res .= '<i>'	
	endif
	if synIDattr(synIDtrans(a:id),'bold') == '1'
		let res .= '<b>'	
	endif
	if synIDattr(synIDtrans(a:id),'underline') == '1'
		let res .= '<u>'	
	endif
	return res
endf
function! s:SynIdEnd(id)
	let res = ''
	if synIDattr(synIDtrans(a:id),'underline') == '1'
		let res .= '</u>'	
	endif
	if synIDattr(synIDtrans(a:id),'bold') == '1'
		let res .= '</b>'	
	endif
	if synIDattr(synIDtrans(a:id),'italic') == '1'
		let res .= '</i>'	
	endif
	if strlen(s:SynIdStyle(a:id))
		let res .= '</span>'
	endif
	return res
endf
function! s:SynIdWrap(id,text)
	let id = (type(a:id) == type(1))?(a:id):hlID(a:id)
	return s:SynIdStart(id).a:text.s:SynIdEnd(id)
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
                                                let prefix .= i
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
                                        let prefix = level
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
	return extend({"fold": "-",'vert': '|','stl': ' ','stlnc': ' '},s:Opt2Dict(&fillchars))
endf
function! s:GetColoredText(lines,start,finish,height,lineEnd)
	let y = a:start 
	let yReal = 0

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
        let skip = view.leftcol + (view.skipcol?(view.skipcol + strlen(&showbreak)):0)
        let maxRealX = width + view.leftcol + view.skipcol
        if width <= 0
                let [width , maxRealX] = [0, 0]
        endif
        let cond = ((!a:height || !lastline))?((a:start == a:finish)?'yReal < a:height && y == a:start || y < a:finish': 'y <= a:finish'): 'yReal < a:height'
        while eval(cond) && y <= line('$')
                let x = 1
		let xx = 0
                let str = getline(y)
                let chunk = '' 
		let xmax = strlen(str) + &list
		let prefix = s:GetLinePrefix(y,numWidth,realWidth,0)
                let realX = 0 
                let [oldId, oldId1] = [0, 0]
		let folded = foldclosed(y)
		if x > xmax
                        call add(a:lines, prefix.repeat(' ', width).a:lineEnd)
                elseif folded != -1
			let text = strpart(foldtextresult(y), 0, width)
			call add(a:lines,prefix.s:SynIdWrap('Folded',s:HtmlEscape(text).repeat(fillChars.fold,width - strlen(text))).a:lineEnd)
                        let y = foldclosedend(y) 
                else
			let tab = ''
			let realX = 0 
                        let eol = 0
                        if view.skipcol
                                let [oldId, oldId1, tab] = [hlID('NonText'), 0, s:SynIdStart(hlID('NonText')).s:HtmlEscape(&showbreak)]
                        endif
                        while x <= xmax && eval(cond)
                                let newLine = ((xx<maxRealX)?(prefix):s:GetLinePrefix(y,numWidth,realWidth,1)).tab
                                while realX < maxRealX
                                        let char = strpart(str, x - 1, 1)
                                        if char == ''
                                                if eol || !&list || !has_key(listChars,'eol')
                                                        let diff = maxRealX - realX 
                                                        let char = repeat(' ',diff)
                                                        let id = 0
                                                else
                                                        let id = hlID('NonText') 
                                                        let diff = 1
                                                        let char = listChars.eol
                                                        let eol = 1
                                                endif
                                        elseif (char < ' ' || char > '~') && char !~ '\p'
                                                if char == "\t" && expandTab
                                                        let id = &list?hlID('SpecialKey'):synIDtrans(synID(y, x, 0))
                                                        let diff = &tabstop - xx%&tabstop
                                                        let char = strpart(listChars.tab,0,1).repeat(strpart(listChars.tab,1),diff-1)
                                                else 
                                                        let id = hlID('SpecialKey')
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
                                                endif
                                        else
                                                let id = synIDtrans(synID(y, x, 0))
                                                let diff = 1
                                        endif
                                        if id != oldId
                                                if chunk != ''
                                                        let newLine .= s:SynIdEnd(oldId1).s:SynIdStart(oldId).s:HtmlEscape(chunk) 
                                                endif
						let [chunk, oldId, oldId1] = ['', id, oldId]
                                        endif
                                        if realX >= skip 
                                                let chunk .= char
                                        elseif realX + strlen(char) >= skip 
                                                let chunk .= strpart(char,skip - realX) 
                                        endif
                                        let realX += diff 
                                        let xx += diff
                                        let x += 1
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
                                let oldId1 = 0
                                if &showbreak != ''
                                        let xx += strlen(&showbreak)
                                        let tab = s:SynIdWrap('NonText',s:HtmlEscape(&showbreak))
                                        let realX += strlen(&showbreak)
                                else
                                        let tab = ''
                                endif
				call add(a:lines, newLine.s:SynIdEnd(save_id).a:lineEnd)
                                if chunk == ''
                                        let oldId = 0
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


	endw
        while yReal < a:height
                let prefix = s:GetLinePrefix(y,numWidth,realWidth,0)


                if y > line('$') 
                        call add(a:lines, prefix.s:SynIdStart(hlID('NonText')).'~'.repeat(' ', width + numWidth - 1).s:SynIdEnd(hlID('NonText')).a:lineEnd)
                else 
                        call add(a:lines, s:GetLinePrefix(y,0,realWidth,1).s:SynIdStart(hlID('NonText')).'@'.repeat(' ', width + numWidth - 1).s:SynIdEnd(hlID('NonText')).a:lineEnd)
                endif
                let yReal += 1
        endw
endf
function! s:GetColoredWindowText(window,lines)
        exec a:window.num.'wincmd w'
        let fillChars = s:GetFillChars()
        call s:GetColoredText(a:lines, line('w0'),line('w$'),winheight(a:window.num),s:SynIdWrap('VertSplit', fillChars.vert))
        let [fill_stl, synId] = (a:window.active)?[(fillChars.stl), 'StatusLine'] :[fillChars.stlnc, 'StatusLineNC']
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
        let StatusLine = s:SynIdWrap(synId,StatusLine.fill_stl)
        call add(a:lines,StatusLine)
endf

function! s:InternalToHtml(self,lines)
	if has_key(a:self, 'childs')
		let lines = []
		let b = 0
		for C in a:self.childs

			if b
				let childLines = []
				call s:InternalToHtml(C,childLines)
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
				call s:InternalToHtml(C,lines)
				let b = 1
			endif

		endfor
		call extend(a:lines, lines)
	elseif has_key(a:self, 'num')
		call s:GetColoredWindowText(a:self, a:lines)
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
function! ToHtml()
        let saved = s:SaveEvents()
	let win = eval(s:EnumWindows())
        let lines = []
        call s:InternalToHtml(win, lines)
        call s:RestoreEvents(saved)
        let lines[0] = '<table><tr><td><pre style='.s:SynIdStyle(hlID('Normal')).'>'.lines[0]
	return lines + ['</pre></td></tr></table>']
endf
function! Text2Html(line1,line2)
        let lines = []
        call s:GetColoredText(lines,a:line1,a:line2,0,'')
        exec 'new '.bufname('%').'.html'
        call append(0,['<table><tr><td><pre style='.s:SynIdStyle(hlID('Normal')).'>'] + lines + ['</pre></td></tr></table>'])
endf
function! ScreenShot()
        let a = ToHtml()
        let shots = eval('['.substitute(glob('screenshot-*.html'),'\%(screenshot-\(\d*\).html\|.*\)\%(\n\|$\)','\=((submatch(1)!="")?submatch(1):0).","','g').']')
        exec 'new screenshot-'.(max(shots) + 1).'.html'
        call append(0,a)
endf
command! -range=% Text2Html     :call Text2Html(<line1>,<line2>)
command! ScreenShot    :call ScreenShot()
"}}} vim:foldmethod=marker foldlevel=0
