Test color constant definitions:

  $ . "$TESTDIR"/helpers.sh && source_functions

All color constants must be defined (non-empty) in default dark palette:

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

Theme detection respects CLITHEME env var:

  $ CLITHEME=dark detect_theme
  dark
  $ CLITHEME=light detect_theme
  light

CLITHEME=auto falls through to detection (defaults dark without tty):

  $ CLITHEME=auto detect_theme
  dark

Unset CLITHEME also falls through:

  $ unset CLITHEME; detect_theme
  dark

Light palette switches all color constants:

  $ dark_green_bg="$COLOR_GREEN_BG"
  $ init_palette light
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
  $ [ "$COLOR_GREEN_BG" != "$dark_green_bg" ] && echo "palettes differ"
  palettes differ

Re-init dark palette restores original values:

  $ init_palette dark
  $ [ "$COLOR_GREEN_BG" = "$dark_green_bg" ] && echo "restored"
  restored
