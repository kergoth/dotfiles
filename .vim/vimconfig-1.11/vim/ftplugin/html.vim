" HTML filetype plugin
" Language:		HTML (ft=html)
" Maintainer:	Srinath Avadhanula <srinath AT eecs.berkeley.edu>
" License:		GNU GPL
" Version:		$Platon: vimconfig/vim/ftplugin/html.vim,v 1.8 2003/11/03 08:20:21 rajo Exp $

" HTML mappings {{{
if !exists('s:doneMappings')
	let s:doneMappings = 1
	let s:ml = exists('g:mapleader') ? g:mapleader : '\'

	" Create parent tag for tag on current line
	imap <buffer> QQ </><Esc>2F<lywf>f/pF<i
	" Create tag from previous word
	imap <buffer> ,, ></><ESC>3hbi<<ESC>lvt>ugvy/</><CR>lp?></<CR>a<C-O>:nohlsearch<CR>
	" Create tag from previous word but add also newlines
	imap <buffer> ,. ,,<CR><CR><Up><Space><Space>

	" HTML commands {{{2
	call IMAP ('tab' .s:ml, "<table border=2 cellspacing=2 cellpadding=5>\<cr><tr>\<cr>\<tab><td>הה</td>\<cr>\<bs></tr>\<cr></table>", 'html')
	call IMAP ('ref' .s:ml, "<a href=\"הה\"></a>", 'html')
	call IMAP ('ol'  .s:ml, "<ol>\<cr><li>הה</li>\<cr></ol>", 'html')
	call IMAP ('ul'  .s:ml, "<ul>\<cr><li>הה</li>\<cr></ul>", 'html')
	call IMAP ('tr'  .s:ml, "<tr>\<cr>\<tab><td>הה</td>\<cr>\<bs></tr>", 'html')
	call IMAP ('td'  .s:ml, "<td>הה</td>", 'html')
	call IMAP ('bb'  .s:ml, "<b>הה</b>", 'html')
	call IMAP ('it'  .s:ml, "<i>הה</i>", 'html')
	" HTML greek characters {{{2
	call IMAP ('a' .s:ml, "\&alpha;", 'html')
	call IMAP ('b' .s:ml, "\&beta;", 'html')
	call IMAP ('c' .s:ml, "\&chi;", 'html')
	call IMAP ('d' .s:ml, "\&delta;", 'html')
	call IMAP ('e' .s:ml, "\&epsilon;", 'html')
	call IMAP ('f' .s:ml, "\&phi;", 'html')
	call IMAP ('g' .s:ml, "\&gamma;", 'html')
	call IMAP ('h' .s:ml, "\&eta;", 'html')
	call IMAP ('k' .s:ml, "\&kappa;", 'html')
	call IMAP ('l' .s:ml, "\&lambda;", 'html')
	call IMAP ('m' .s:ml, "\&mu;", 'html')
	call IMAP ('n' .s:ml, "\&nu;", 'html')
	call IMAP ('p' .s:ml, "\&pi;", 'html')
	call IMAP ('q' .s:ml, "\&theta;", 'html')
	call IMAP ('r' .s:ml, "\&rho;", 'html')
	call IMAP ('s' .s:ml, "\&sigma;", 'html')
	call IMAP ('t' .s:ml, "\&tau;", 'html')
	call IMAP ('u' .s:ml, "\&upsilon;", 'html')
	call IMAP ('v' .s:ml, "\&varsigma;", 'html')
	call IMAP ('w' .s:ml, "\&omega;", 'html')
	call IMAP ('x' .s:ml, "\&xi;", 'html')
	call IMAP ('y' .s:ml, "\&psi;", 'html')
	call IMAP ('z' .s:ml, "\&zeta;", 'html')
	call IMAP ('A' .s:ml, "\&Alpha;", 'html')
	call IMAP ('B' .s:ml, "\&Beta;", 'html')
	call IMAP ('C' .s:ml, "\&Chi;", 'html')
	call IMAP ('D' .s:ml, "\&Delta;", 'html')
	call IMAP ('E' .s:ml, "\&Epsilon;", 'html')
	call IMAP ('F' .s:ml, "\&Phi;", 'html')
	call IMAP ('G' .s:ml, "\&Gamma;", 'html')
	call IMAP ('H' .s:ml, "\&Eta;", 'html')
	call IMAP ('K' .s:ml, "\&Kappa;", 'html')
	call IMAP ('L' .s:ml, "\&Lambda;", 'html')
	call IMAP ('M' .s:ml, "\&Mu;", 'html')
	call IMAP ('N' .s:ml, "\&Nu;", 'html')
	call IMAP ('P' .s:ml, "\&Pi;", 'html')
	call IMAP ('Q' .s:ml, "\&Theta;", 'html')
	call IMAP ('R' .s:ml, "\&Rho;", 'html')
	call IMAP ('S' .s:ml, "\&Sigma;", 'html')
	call IMAP ('T' .s:ml, "\&Tau;", 'html')
	call IMAP ('U' .s:ml, "\&Upsilon;", 'html')
	call IMAP ('V' .s:ml, "\&Varsigma;", 'html')
	call IMAP ('W' .s:ml, "\&Omega;", 'html')
	call IMAP ('X' .s:ml, "\&Xi;", 'html')
	call IMAP ('Y' .s:ml, "\&Psi;", 'html')
	call IMAP ('Z' .s:ml, "\&Zeta;", 'html')
	" }}}
endif 
" end HTML mappings }}}

" SmartBS: smart backspacing {{{
let g:smartBS_html = '\(' .
			\ '&[^;]\+;'  .
			\ '\)' . "$"

inoremap <buffer> <BS> <C-R>=SmartBS()<CR>
" }}} 

let b:input_method = "iso8859-2"
call UseDiacritics()

" Modeline {{{
" vim:set ts=4:
" vim600:fdm=marker fdl=0 fdc=3 nowrap:
" }}}

