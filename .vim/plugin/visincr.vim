" visincrPlugin.vim: Visual-block incremented lists
"  Author:      Charles E. Campbell, Jr.  Ph.D.
"  Date:        Mar 21, 2006
"  Public Interface Only

" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_visincr")
  finish
endif
let s:keepcpo        = &cpo
set cpo&vim

" ---------------------------------------------------------------------
"  Methods: {{{1
let s:I     =  0
let s:II    =  1
let s:IMDY  =  2
let s:IYMD  =  3
let s:IDMY  =  4
let s:ID    =  5
let s:IM    =  6
let s:IA    =  7
let s:IX    =  8
let s:IIX   =  9
let s:IO    = 10
let s:IIO   = 11
let s:RI    = 12
let s:RII   = 13
let s:RIMDY = 14
let s:RIYMD = 15
let s:RIDMY = 16
let s:RID   = 17
let s:RIM   = 18

" ------------------------------------------------------------------------------
" Public Interface: {{{1
com! -ra -na=? I    call visincr#VisBlockIncr(s:I     , <f-args>)
com! -ra -na=* II   call visincr#VisBlockIncr(s:II    , <f-args>)
com! -ra -na=* IMDY call visincr#VisBlockIncr(s:IMDY  , <f-args>)
com! -ra -na=* IYMD call visincr#VisBlockIncr(s:IYMD  , <f-args>)
com! -ra -na=* IDMY call visincr#VisBlockIncr(s:IDMY  , <f-args>)
com! -ra -na=? ID   call visincr#VisBlockIncr(s:ID    , <f-args>)
com! -ra -na=? IM   call visincr#VisBlockIncr(s:IM    , <f-args>)
com! -ra -na=? IA	call visincr#VisBlockIncr(s:IA    , <f-args>)
com! -ra -na=? IX   call visincr#VisBlockIncr(s:IX    , <f-args>)
com! -ra -na=? IIX  call visincr#VisBlockIncr(s:IIX   , <f-args>)
com! -ra -na=? IO   call visincr#VisBlockIncr(s:IO    , <f-args>)
com! -ra -na=? IIO  call visincr#VisBlockIncr(s:IIO   , <f-args>)

com! -ra -na=? RI    call visincr#VisBlockIncr(s:RI   , <f-args>)
com! -ra -na=* RII   call visincr#VisBlockIncr(s:RII  , <f-args>)
com! -ra -na=* RIMDY call visincr#VisBlockIncr(s:RIMDY, <f-args>)
com! -ra -na=* RIYMD call visincr#VisBlockIncr(s:RIYMD, <f-args>)
com! -ra -na=* RIDMY call visincr#VisBlockIncr(s:RIDMY, <f-args>)
com! -ra -na=? RID   call visincr#VisBlockIncr(s:RID  , <f-args>)
com! -ra -na=? RIM   call visincr#VisBlockIncr(s:RIM  , <f-args>)

" ------------------------------------------------------------------------------
"  Restoration: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" ------------------------------------------------------------------------------
"  Modelines: {{{1
"  vim: ts=4 fdm=marker
