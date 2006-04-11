if has("win32")
  au BufRead,BufNewFile c:/TEMP/tmp[0-9]*»·if $CLEARCASE_CMDLINE =~ "edcs" | setfiletype cccs | endif
else
  au BufRead,BufNewFile /tmp/tmp[0-9]*»if $CLEARCASE_CMDLINE =~ "edcs" | setfiletype cccs | endif
endif
