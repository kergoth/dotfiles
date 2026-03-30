Test context percentage display:

  $ . "$TESTDIR"/helpers.sh && source_functions

Format context segment text:

  $ format_context 35
  ctx 35%
  $ format_context 0
  ctx 0%
  $ format_context 100
  ctx 100%

Render context segment with correct colors (strip ANSI, verify text):

  $ render_context_segment 35 | strip_ansi
   ctx 35%  (no-eol)
  $ render_context_segment 72 | strip_ansi
   ctx 72%  (no-eol)
  $ render_context_segment 92 | strip_ansi
   ctx 92%  (no-eol)

Integration — pipe JSON through script, check context appears:

  $ . "$TESTDIR"/helpers.sh
  $ make_json '.context_window.used_percentage = 35' | bash "$STATUSLINE" | strip_ansi
  * ctx 35% * (glob)

Context at warning threshold:

  $ make_json '.context_window.used_percentage = 50' | bash "$STATUSLINE" | strip_ansi
  * ctx 50% * (glob)

Context at critical threshold:

  $ make_json '.context_window.used_percentage = 80' | bash "$STATUSLINE" | strip_ansi
  * ctx 80% * (glob)

No API calls yet (used_percentage is null):

  $ make_json 'del(.context_window.used_percentage)' | bash "$STATUSLINE" | strip_ansi
  * ctx 0% * (glob)
