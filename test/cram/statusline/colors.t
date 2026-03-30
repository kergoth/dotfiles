Test color constant definitions:

  $ . "$TESTDIR"/helpers.sh && source_functions

All color constants must be defined (non-empty):

  $ [ -n "$COLOR_GREEN_BG" ] && echo ok
  ok
  $ [ -n "$COLOR_YELLOW_BG" ] && echo ok
  ok
  $ [ -n "$COLOR_RED_BG" ] && echo ok
  ok
  $ [ -n "$COLOR_DARK_TEXT" ] && echo ok
  ok
  $ [ -n "$COLOR_SUBTLE_GREEN_BG" ] && echo ok
  ok
  $ [ -n "$COLOR_RESET" ] && echo ok
  ok

Severity-to-color mapping for context:

  $ context_color 30
  subtle_green
  $ context_color 49
  subtle_green
  $ context_color 50
  yellow
  $ context_color 79
  yellow
  $ context_color 80
  red
  $ context_color 100
  red
