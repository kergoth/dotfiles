" Vim color file
" Maintainer:   Pierre-Antoine Lacaze <pa.lacaze@gmail.com>
" Last Change:
" License:      GPLv2

" To install, copy to ~/.vim/colors directory. Then :colorscheme spectro

" spectro is a colorscheme that lets you define the global saturation and
" the global lightness to be used for all the colors. The hue is then
" defined on a per color basis
" hue, saturation and lightness shall be set between 0 and 255
" I shamelessly used inkscape colors algorithm for HSL -> RGB conversion

" The main interest is the ability to adapt to different screens
" by only changing the saturation and lightness in your vimrc :
" let g:spectro_saturation = 120
" let g:spectro_lightness = 160

set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif

let g:colors_name="spectro"

" default saturation value
if ! exists("g:spectro_saturation")
    let g:spectro_saturation = 130
else
    if g:spectro_saturation > 255
	let g:spectro_saturation = 255
    elseif g:spectro_saturation < 0
	let g:spectro_saturation = 0
    endif
endif

" default lightness value
if ! exists("g:spectro_lightness")
    let g:spectro_lightness = 130
else
    if g:spectro_lightness > 255
	let g:spectro_lightness = 255
    elseif g:spectro_lightness < 0
	let g:spectro_lightness = 0
    endif

endif

" function returning the hexadecimal value of an integer between 0 and 16
fun! Dec2hex(s)
    let str = "0123456789ABCDEF"
    return str[a:s]
endfunc

" function converting a (R,G,B) triplet into a "#rrggbb" string
fun! FormatRGB(rgb)
    let r1 = a:rgb[0] / 16
    let g1 = a:rgb[1] / 16
    let b1 = a:rgb[2] / 16
    let r2 = a:rgb[0] % 16
    let g2 = a:rgb[1] % 16
    let b2 = a:rgb[2] % 16
    return "#".Dec2hex(r1).Dec2hex(r2).Dec2hex(g1).Dec2hex(g2).Dec2hex(b1).Dec2hex(b2)
endfun

" function converting hue to RGB
fun! Hue2rgbImpl(v1,v2,H)
    let v1 = a:v1
    let v2 = a:v2
    let H = a:H
    if H < 0
	let H += 6 * 255
    elseif H > 6 * 255
	let H -= 6 * 255
    end

    if H < 255
	return (v1 * 255 + (v2 - v1) * H) / (255 * 255)
    elseif H < 3 * 255
	return v2 / 255
    elseif H < 4 * 255
	return (v1 * 255 + (v2 - v1) * (4 * 255 - H)) / (255 * 255)
    else
	return v1 / 255
    endif
endfun

" function converting a (H,S,L) triplet into a (R,G,B) triplet
fun! s:Hsl2rgb(H, S, L)
    let H = a:H
    let S = a:S
    let L = a:L
    if S == 0
	let RGB = [L,L,L]
    else
	let RGB = [0,0,0]
	if L < 128
	    let v2 = L * (255 + S)
	else
	    let v2 = 255* (L + S) - L * S
	endif
	let v1 = 2 * 255 * L - v2
	let RGB[0] = Hue2rgbImpl(v1,v2,H * 6 + 2 * 255)
	let RGB[1] = Hue2rgbImpl(v1,v2,H * 6)
	let RGB[2] = Hue2rgbImpl(v1,v2,H * 6 - 2 * 255)
    endif
    return FormatRGB(RGB)
endfun

"     g:spectro_saturation
"     let L = g:spectro_lightness
fun! s:Hue2rgb(h)
  return Hsl2rgb(a:h, g:spectro_saturation, g:spectro_lightness)
endfun

" List to ensure Normal is set up first, for now
let g:kcomb_colorlist = ['Normal']

" Color hues
let g:kcomb_colors = {
      \ 'Normal': {
      \     'fg': ['bright', 157],
      \     'bg': ['backgrounds', 165],
      \ },
      \ 'Comment': {
      \     'fg': ['dark', 128],
      \ },
      \ 'Conditional': {
      \     'fg': ['default', 240],
      \ },
      \ 'Constant': {
      \     'fg': ['default', 162],
      \ },
      \ 'Cursor': {
      \     'fg': ['default', 170],
      \     'bg': ['backgrounds', 65],
      \ },
      \ 'CursorColumn': {
      \     'fg': ['default', 162],
      \ },
      \ 'CursorLine': {
      \     'fg': ['default', 162],
      \ },
      \ 'Directory': {
      \     'fg': ['default', 145],
      \ },
      \ 'Error': {
      \     'fg': ['default', 245],
      \ },
      \ 'ErrorMsg': {
      \     'fg': ['default', 255],
      \ },
      \ 'Exception': {
      \     'fg': ['default', 250],
      \ },
      \ 'FoldColumn': {
      \     'fg': ['default', 29],
      \     'bg': ['backgrounds', 170],
      \ },
      \ 'Folded': {
      \     'fg': ['default', 213],
      \     'bg': ['backgrounds', 172],
      \ },
      \ 'Function': {
      \     'fg': ['default', 38],
      \ },
      \ 'Identifier': {
      \     'fg': ['default', 145],
      \ },
      \ 'IncSearch': {
      \     'fg': ['default', 51],
      \     'bg': ['backgrounds', 55],
      \ },
      \ 'LineNr': {
      \     'fg': ['default', 147],
      \     'bg': ['backgrounds', 168],
      \ },
      \ 'MatchParen': {
      \     'fg': ['default', 149],
      \     'bg': ['backgrounds', 6],
      \ },
      \ 'ModeMsg': {
      \     'fg': ['default', 135],
      \ },
      \ 'MoreMsg': {
      \     'fg': ['default', 104],
      \ },
      \ 'NonText': {
      \     'fg': ['default', 16],
      \ },
      \ 'Number': {
      \     'fg': ['default', 147],
      \ },
      \ 'Operator': {
      \     'fg': ['default', 14],
      \ },
      \ 'Pmenu': {
      \     'fg': ['default', 156],
      \     'bg': ['backgrounds', 150],
      \ },
      \ 'PmenuSel': {
      \     'fg': ['default', 149],
      \     'bg': ['backgrounds', 148],
      \ },
      \ 'PreProc': {
      \     'fg': ['default', 203],
      \ },
      \ 'Question': {
      \     'fg': ['default', 149],
      \ },
      \ 'Repeat': {
      \     'fg': ['default', 250],
      \ },
      \ 'Special': {
      \     'fg': ['default', 170],
      \ },
      \ 'SpecialKey': {
      \     'fg': ['verydark', 0],
      \ },
      \ 'Statement': {
      \     'fg': ['default', 251],
      \ },
      \ 'StatusLine': {
      \     'fg': ['default', 162],
      \     'bg': ['backgrounds', 162],
      \ },
      \ 'StatusLineNC': {
      \     'fg': ['default', 163],
      \     'bg': ['backgrounds', 166],
      \ },
      \ 'tabline': {
      \     'fg': ['default', 155],
      \     'bg': ['backgrounds', 170],
      \ },
      \ 'tablinefill': {
      \     'fg': ['default', 0],
      \     'bg': ['backgrounds', 170],
      \ },
      \ 'tablinesel': {
      \     'fg': ['default', 144],
      \     'bg': ['backgrounds', 158],
      \ },
      \ 'Title': {
      \     'fg': ['default', 43],
      \ },
      \ 'Todo': {
      \     'fg': ['default', 128],
      \     'bg': ['backgrounds', 125],
      \ },
      \ 'Type': {
      \     'fg': ['default', 144],
      \ },
      \ 'Underlined': {
      \     'fg': ['default', 85],
      \ },
      \ 'VertSplit': {
      \     'fg': ['default', 156],
      \     'bg': ['backgrounds', 165],
      \ },
      \ 'Visual': {
      \     'fg': ['default', 149],
      \     'bg': ['dark', 158],
      \ },
      \ 'VisualNOS': {
      \     'fg': ['default', 182],
      \     'bg': ['backgrounds', 169],
      \ },
      \ 'WarningMsg': {
      \     'fg': ['default', 4],
      \ },
\ }

" Colors grouped by their saturation & lightness values
let g:kcomb_colorgroups = {
      \ 'verybright': [120, 240],
      \ 'bright': [120, 200],
      \ 'default': [80, 170],
      \ 'dark': [120, 100],
      \ 'verydark': [120, 60],
      \ 'backgrounds': [220, 25],
\ }

fun! s:GetHighlight(higrp)
  let higrp = a:higrp

  let fgdata = g:kcomb_colors[higrp].fg
  let fgsl = g:kcomb_colorgroups[fgdata[0]]
  let guifg = s:Hsl2rgb(fgdata[1], fgsl[0], fgsl[1])
  let msg = "hi ".higrp." guifg=".guifg

  let bgdata = get(g:kcomb_colors[higrp], 'bg')
  if type(bgdata) == type([])
    let bgsl = g:kcomb_colorgroups[bgdata[0]]
    let guibg = s:Hsl2rgb(bgdata[1], bgsl[0], bgsl[1])
    let msg = msg." guibg=".guibg
  endif

  return msg
endfun

for higrp in g:kcomb_colorlist
  exe s:GetHighlight(higrp)
endfor

for higrp in keys(g:kcomb_colors)
  exe s:GetHighlight(higrp)
endfor
