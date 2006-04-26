runtime syntax/doxygen.vim

syn cluster cCommentGroup add=vimModeline

" libcheck
syn keyword checkMacros START_TEST END_TEST
hi def link checkMacros Macro
