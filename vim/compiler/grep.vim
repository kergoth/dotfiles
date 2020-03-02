if exists("current_compiler")
  finish
endif
let current_compiler = "grep"
let &l:errorformat = &grepformat
let &l:makeprg = &grepprg
