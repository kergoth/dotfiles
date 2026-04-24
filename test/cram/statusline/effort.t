Test effort level indicator in model segment:

  $ . "$TESTDIR"/helpers.sh && source_functions

Known effort levels map to their abbreviations:

  $ effort_letter low
  L
  $ effort_letter medium
  M
  $ effort_letter high
  H
  $ effort_letter xhigh
  XH
  $ effort_letter max
  MX

Empty input returns nothing — segment hides (older Claude Code, missing field):

  $ effort_letter ""
  $ effort_letter "" | wc -c | tr -d ' '
  0

Unknown values surface as "?" — visible signal that the mapping needs updating:

  $ effort_letter unknown
  ?
  $ effort_letter HIGH
  ?
  $ effort_letter minimum
  ?

Integration — pipe JSON with effort.level, model renders with abbreviation:

  $ . "$TESTDIR"/helpers.sh
  $ make_json '.effort = {"level": "high"}' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi | grep -o 'Opus·H'
  Opus·H

Integration — effort omitted, model renders as plain "Opus":

  $ make_json | COLUMNS=120 bash "$STATUSLINE" | strip_ansi | grep -oE 'Opus[^ ]*' | head -1
  Opus

Integration — each known level renders correctly:

  $ make_json '.effort = {"level": "low"}'   | COLUMNS=120 bash "$STATUSLINE" | strip_ansi | grep -o 'Opus·L'
  Opus·L
  $ make_json '.effort = {"level": "max"}'   | COLUMNS=120 bash "$STATUSLINE" | strip_ansi | grep -o 'Opus·MX'
  Opus·MX
  $ make_json '.effort = {"level": "xhigh"}' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi | grep -o 'Opus·XH'
  Opus·XH

Integration — unknown level shows "?" rather than hiding:

  $ make_json '.effort = {"level": "ludicrous"}' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi | grep -o 'Opus·?'
  Opus·?
