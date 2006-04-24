setlocal cinkeys-=:
setlocal commentstring=//\ %s
if exists('+omnifunc')
  set omnifunc=cppomnicomplete#Complete
endif
