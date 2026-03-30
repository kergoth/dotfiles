#!/usr/bin/env bash
# Shared test helpers for statusline tests

# TESTDIR is set by cram to the directory containing the .t file
# Navigate from test/cram/statusline/ up to repo root
SCRIPT_DIR="$(cd "$TESTDIR/../../.." && pwd)"
STATUSLINE="$SCRIPT_DIR/home/dot_claude/statusline-command.sh"

# Source just the functions from the statusline script (skip main execution)
source_functions() {
    # The script guards main execution behind a "not sourced" check
    source "$STATUSLINE"
}

# Strip ANSI escape sequences from input
strip_ansi() {
    sed $'s/\033\[[0-9;]*m//g' | sed $'s/\033\[38;2;[0-9;]*m//g' | sed $'s/\033\[48;2;[0-9;]*m//g'
}

# Build minimal JSON fixture (pass overrides as jq args)
# Usage: make_json '.model.display_name = "Opus" | .context_window.used_percentage = 35'
make_json() {
    local overrides="${1:-}"
    cat <<'BASEJSON' | jq "${overrides:-.}"
{
  "model": {"id": "claude-opus-4-6", "display_name": "Opus"},
  "cwd": "/Users/testuser/projects/myapp",
  "workspace": {"project_dir": "/Users/testuser/projects/myapp", "current_dir": "/Users/testuser/projects/myapp"},
  "context_window": {
    "used_percentage": 35,
    "remaining_percentage": 65,
    "context_window_size": 200000,
    "total_input_tokens": 70000,
    "total_output_tokens": 5000,
    "current_usage": {"input_tokens": 1000, "output_tokens": 200, "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0}
  },
  "session_id": "test-session-001",
  "transcript_path": "/tmp/test-transcript.jsonl",
  "cost": {"total_cost_usd": 0.5, "total_duration_ms": 60000, "total_api_duration_ms": 45000, "total_lines_added": 0, "total_lines_removed": 0},
  "version": "2.1.85"
}
BASEJSON
}
