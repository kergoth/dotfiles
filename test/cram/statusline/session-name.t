Test session name extraction from transcript JSONL:

  $ . "$TESTDIR"/helpers.sh && source_functions

Create transcript with custom-title and extract name:

  $ echo '{"type":"custom-title","customTitle":"my cool project","sessionId":"abc"}' > "$CRAMTMP/renamed.jsonl"
  $ get_session_name "$CRAMTMP/renamed.jsonl"
  my cool project

Transcript without custom-title returns empty:

  $ echo '{"type":"user","sessionId":"def"}' > "$CRAMTMP/unnamed.jsonl"
  $ get_session_name "$CRAMTMP/unnamed.jsonl"

Multiple renames — use last one:

  $ echo '{"type":"custom-title","customTitle":"first name"}' > "$CRAMTMP/multi.jsonl"
  $ echo '{"type":"custom-title","customTitle":"better name"}' >> "$CRAMTMP/multi.jsonl"
  $ get_session_name "$CRAMTMP/multi.jsonl"
  better name

Non-existent transcript returns empty:

  $ get_session_name "$CRAMTMP/no-such-file.jsonl"

Name line rendering with sufficient terminal height:

  $ LINES=20 render_name_line "my cool project" | strip_ansi
  * my cool project* (glob)

Name line suppressed when terminal too short:

  $ LINES=10 render_name_line "my cool project"

Name line suppressed when name is empty:

  $ render_name_line ""
