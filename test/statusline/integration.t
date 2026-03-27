Full integration — pipe realistic JSON, verify output:

  $ . "$TESTDIR"/helpers.sh

Calm session — model and context only (default cwd has no git repo):

  $ make_json | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  * Opus * ctx 35% * (glob)

Context at warning threshold:

  $ make_json '.context_window.used_percentage = 65' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  * Opus * ctx 65% * (glob)

Context at critical threshold:

  $ make_json '.context_window.used_percentage = 90' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  * Opus * ctx 90% * (glob)

Rate limit at 55%, on-track — should appear:

  $ NOW=$(date +%s)
  $ RESET_5H=$(( NOW + 5400 ))
  $ make_json '.rate_limits.five_hour.used_percentage = 55 | .rate_limits.five_hour.resets_at = '"$RESET_5H" \
  >   | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  *5h*55%*ctx 35%* (glob)

Rate limit below 50% — should NOT appear:

  $ RESET_5H=$(( NOW + 14400 ))
  $ make_json '.rate_limits.five_hour.used_percentage = 30 | .rate_limits.five_hour.resets_at = '"$RESET_5H" \
  >   | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  * Opus * ctx 35% * (glob)

Narrow terminal — segments degrade:

  $ make_json | COLUMNS=20 bash "$STATUSLINE" | strip_ansi
  * Opus * ctx 35% * (glob)

Different model name:

  $ make_json '.model.display_name = "Sonnet"' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  * Sonnet * ctx 35% * (glob)

No API calls yet (null percentage):

  $ make_json 'del(.context_window.used_percentage)' | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  * Opus * ctx 0% * (glob)

Worktree session:

  $ make_json '.worktree.name = "upload-retry" | .worktree.branch = "feature/retry"' \
  >   | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  *upload-retry*retry*ctx 35%* (glob)

Session name not rendered (Claude Code shows it in header bar):

  $ echo '{"type":"custom-title","customTitle":"My Project"}' > "$CRAMTMP/named.jsonl"
  $ make_json '.transcript_path = "'"$CRAMTMP/named.jsonl"'"' \
  >   | COLUMNS=120 bash "$STATUSLINE" | strip_ansi
  * Opus * ctx 35% * (glob)
