"   Copyright (c) 2006, Michael Shvarts <shvarts@akmosoft.com>
"
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

function! s:Window_New(window,num)
	call extend(a:window,{'num':a:num,'size': [winwidth(a:num),winheight(a:num)]})
endf
function! s:Window_TryMerge(self,new)
	if has_key(a:self,'prev')
		if a:self.size[!a:self.prevdir] == a:self.prev.size[!a:self.prevdir]
			if !has_key(a:self.prev, 'dir')
				let a:self.prev.dir = a:self.prevdir
			endif
			if a:self.prev.dir == a:self.prevdir && has_key(a:self.prev, 'Add')
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
function! GetWindowText(num)
	exec a:num.'wincmd w'
	return '<pre>'.join(map(map(getline('w0', 'w$'),"substitute(v:val,'\t',repeat(' ',&tabstop),'g')"), "substitute(v:val,'.\\{,".winwidth(a:num)."\\}','\\=submatch(0).repeat(\"#\", ".winwidth(a:num)." - strlen(submatch(0))).\"<br>\"','g')"), "<br>").'</pre>'------------------------------------------------------------------------------------------------------------------------------

endf
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

function! s:GetLinePrefix(y,numWidth,wrapped)
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
                let prefix = s:SynIdWrap('FoldColumn',prefix)
	endif
	if &number && a:y <= line('$')
		if a:wrapped 
			let prefix .= s:SynIdWrap(a:wrapped?'LineNr': 'NonText',repeat(' ',a:numWidth))
		else
			let prefix .= s:SynIdWrap(closed?'Folded': 'LineNr',repeat(' ',a:numWidth - 1 - strlen(a:y)).a:y.' ')
		endif
	endif
	return prefix
endf
function! s:HtmlEscape(text)
	return substitute(a:text,'[<>&]','\={"<": "&lt;",">": "&gt;","&": "&amp;"}[submatch(0)]','g')
endf
function! s:GetFillChars()
	return string(extend({"fold": "-",'vert': '|','stl': ' ','stlnc': ' '},eval('{'.substitute(&fillchars,'\(\w\+\):\([^,]*\)\(,\|$\)',"'\\1':'\\2'\\3", 'g').'}')))
endf
function! s:GetColoredText(lines,start,finish,height,lineEnd)
	let y = a:start 
	let ymax = line('$')
	let yReal = 0

	let realWidth = winwidth(winnr())
	let foldWidth = &foldcolumn 
	let numWidth = &number?max([&numberwidth,strlen(line('$'))+1]):0
	let width = realWidth - numWidth - foldWidth 
	let fillChars = eval(s:GetFillChars())
	let realX = 0 


	while y <= a:finish 
		let x = 1 
		let xx = 0
		let str = getline(y)
		let xmax = strlen(str)
		let prefix = s:GetLinePrefix(y,numWidth,0)
		let realX = 0 
		let folded = foldclosed(y)
		if !xmax
                        call add(a:lines, prefix.repeat(' ', width).a:lineEnd)
                elseif folded != -1
			let text = strpart(foldtextresult(y), 0, width)
			call add(a:lines,prefix.s:SynIdWrap('Folded',s:HtmlEscape(text).repeat(fillChars.fold,width - strlen(text))).a:lineEnd)
                        let y = foldclosedend(y) 
                else
			let tab = ''
			let realX = 0 

			while x <= xmax && y <= a:finish
				let oldId = 0
				let newLine = ((xx<width)?(prefix):s:GetLinePrefix(y,numWidth,1)).tab 
				while realX < width
					let id = synIDtrans(synID(y, x, 0))
					if id != oldId
						let newLine .= s:SynIdEnd(oldId).s:SynIdStart(id)
						let oldId = id
					endif
					let char = strpart(str, x - 1, 1)
					let diff = (char == "\t")?&tabstop - xx%&tabstop:1
					let xx += diff
					let newLine .= (char == '&')?'&amp;':(char == '<')?'&lt;':(char == '>')?'&gt;':(char == "\t")?repeat(' ',diff):(char == '')?' ':char

					let x += 1
					let realX += diff 
				endwhile
				if &wrap && realX > width
					let realX = realX%width
					let tab =  strpart(newLine,strlen(newLine) - realX)
					let newLine = strpart(newLine,0,strlen(newLine) - realX)
				else
					let realX = 0 
					let tab = ''
				endif
				call add(a:lines, newLine.s:SynIdEnd(oldId).a:lineEnd)
				let yReal += 1
				if !&wrap
					break
				endif
			endw
			let yReal -= 1
		endif
		let yReal += 1
		let y += 1


	endw
        while yReal < a:height
                let prefix = s:GetLinePrefix(y,numWidth,0)


                if y > ymax
                        call add(a:lines, prefix.s:SynIdStart(hlID('NonText')).'~'.repeat(' ', width + numWidth - 1).s:SynIdEnd(hlID('NonText')).a:lineEnd)
                else 
                        call add(a:lines, s:GetLinePrefix(y,0,1).s:SynIdStart(hlID('NonText')).'@'.repeat(' ', width + numWidth - 1).s:SynIdEnd(hlID('NonText')).a:lineEnd)
                endif
                let yReal += 1
        endw
endf
function! s:GetColoredWindowText(window,lines)
	exec a:window.num.'wincmd w'
	let fillChars = eval(s:GetFillChars())
	call s:GetColoredText(a:lines, line('w0'),line('w$'),winheight(a:window.num),s:SynIdWrap('VertSplit', fillChars.vert))

	let name = bufname('%')
	if name == ''
		let name = '[No name]'
	endif
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
	call add(a:lines,s:SynIdWrap(((a:window.active)?'StatusLine': 'StatusLineNC'),StatusLine.fillChars.stlnc))
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
function! ToHtml()
        let [winheight,winminheight,winminwidth,ei] = [&winheight,&winminheight,&winminwidth,&ei]
        set ei=all
	set winminwidth=1
	set winminheight=1
        set winwidth=1
	let win = eval(s:EnumWindows())
        let lines = []
        call s:InternalToHtml(win, lines)
	let [&winheight,&winminheight,&winminwidth,&ei] = [winheight,winminheight,winminwidth,ei]
	return '<table><tr><td><pre style='.s:SynIdStyle(hlID('Normal')).'>'.join(lines,'<br>').'</pre></td></tr></table>'
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
function! Text2Html(line1,line2)
        let lines = []
        call s:GetColoredText(lines,a:line1,a:line2,0,'')
        exec 'new '.bufname('%').'.html'
        call append('.','<table><tr><td><pre style='.s:SynIdStyle(hlID('Normal')).'>'.join(lines,'<br>').'</pre></td></tr></table>')
endf
function! ScreenShot()
        let a = ToHtml()
        let shots = eval('['.substitute(glob('screenshot-*.html'),'\%(screenshot-\(\d*\).html\|.*\)\%(\n\|$\)','\=((submatch(1)!="")?submatch(1):0).","','g').']')
        exec 'new screenshot-'.(max(shots) + 1).'.html'
        call append('.',a)
endf
command! -range=% Text2Html     :call Text2Html(<line1>,<line2>)
command! ScreenShoot    :call ScreenShot()

