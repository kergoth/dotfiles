setlocal cinkeys-=:
setlocal commentstring=//\ %s

if exists('+omnifunc')
    " OmniCppComplete initialization
    call omni#cpp#complete#Init()
endif
