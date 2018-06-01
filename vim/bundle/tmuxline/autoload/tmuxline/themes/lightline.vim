
function! tmuxline#themes#lightline#get() abort
  if !exists('*lightline#palette')
    throw "tmuxline: Can't load theme from lightline, function lightline#palette() doesn't exist. Is latest lightline loaded?"
  endif

  let palette = lightline#palette()
  let mode = 'normal'
  return tmuxline#util#create_theme_from_lightline(palette[mode])
endfunc
