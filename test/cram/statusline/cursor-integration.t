Cursor statusline integration:

  $ . "$TESTDIR"/helpers.sh
  $ CURSOR_STATUSLINE="$SCRIPT_DIR/home/dot_cursor/executable_statusline.sh"

Calm session — agent label, model, burn, and context:

  $ make_json | COLUMNS=120 bash "$CURSOR_STATUSLINE" | strip_ansi
  *CU*Opus*70k*5.0k*$0.500*ctx 35%* (glob)

Session name line when payload includes session_name:

  $ make_json '.session_name = "dotfiles refactor"' | LINES=24 COLUMNS=120 bash "$CURSOR_STATUSLINE" | strip_ansi
  *dotfiles refactor* (glob)
  *CU*Opus*70k*ctx 35%* (glob)

Narrow terminal — drops burn before context:

  $ make_json | COLUMNS=20 bash "$CURSOR_STATUSLINE" | strip_ansi
  *CU*Opus*ctx 35%* (glob)
