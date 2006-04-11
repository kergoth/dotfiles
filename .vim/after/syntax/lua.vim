syn match   luaComment		"--.*$" contains=luaTodo,@Spell,vimModeline
if lua_version > 4
  syn region  luaComment	matchgroup=luaComment start="--\[\[" end="\]\]" contains=luaTodo,luaInnerComment,@Spell,vimModeline
  syn region  luaInnerComment	contained transparent start="\[\[" end="\]\]"
endif
