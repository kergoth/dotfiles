#!/usr/bin/env bash
# Stop hook: archive session transcript to CLAUDE_SESSION_ARCHIVE on session end.
# Always exits 0 unless CLAUDE_ARCHIVE_VERBOSE=1, in which case exits 1 on failure.
# Errors logged to $ARCHIVE_ROOT/archive.log.
#
# set -euo pipefail intentionally omitted: error routing is via _fail(), which gives
# fine-grained control over logged-and-continue vs. fatal failures, and ensures the
# hook never accidentally blocks session end.

ARCHIVE_ROOT="${CLAUDE_SESSION_ARCHIVE:-$HOME/.claude/projects-archive}"
VERBOSE="${CLAUDE_ARCHIVE_VERBOSE:-0}"

_fail() {
    local msg="$1"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || printf 'unknown-time')
    printf '%s ERROR archive-session: %s\n' "$ts" "$msg" >> "$ARCHIVE_ROOT/archive.log" 2>/dev/null || true
    printf 'archive-session: %s\n' "$msg" >&2
    if [[ "${VERBOSE}" == "1" ]]; then exit 1; else exit 0; fi
}

# Step 1: ensure archive root exists (required before any log writes)
mkdir -p "$ARCHIVE_ROOT" 2>/dev/null || {
    printf 'archive-session: cannot create %s\n' "$ARCHIVE_ROOT" >&2
    if [[ "${VERBOSE}" == "1" ]]; then exit 1; else exit 0; fi
}

# Step 2: parse stdin
INPUT=$(cat)
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

[[ -z "$TRANSCRIPT_PATH" ]] && _fail "transcript_path missing from hook input"
[[ ! -r "$TRANSCRIPT_PATH" ]] && _fail "transcript not readable: $TRANSCRIPT_PATH"

# Step 3: derive session_id and slug from transcript path
SESSION_ID=$(basename "$TRANSCRIPT_PATH" .jsonl)
SLUG=$(basename "$(dirname "$TRANSCRIPT_PATH")")

# Step 4: look up display name from history.jsonl
# history.jsonl uses sessionId (camelCase); .sessionId? handles lines where field is absent
SESSION_NAME=""
HISTORY="$HOME/.claude/history.jsonl"
if [[ -r "$HISTORY" ]]; then
    SESSION_NAME=$(jq -r --arg sid "$SESSION_ID" \
        'select((.sessionId? // "") == $sid) | select((.display // "") != "") | .display' \
        "$HISTORY" 2>/dev/null | grep -v '^/' | head -1) || SESSION_NAME=""
    if [[ -z "$SESSION_NAME" ]]; then
        SESSION_NAME=$(jq -r --arg sid "$SESSION_ID" \
            'select((.sessionId? // "") == $sid) | select((.display // "") != "") | .display' \
            "$HISTORY" 2>/dev/null | head -1) || SESSION_NAME=""
    fi
fi

# Step 5: create per-slug archive directory
SLUG_DIR="$ARCHIVE_ROOT/$SLUG"
mkdir -p "$SLUG_DIR" || _fail "cannot create $SLUG_DIR"

# Step 6: atomic copy via temp file + rename (prevents partial writes on kill)
TMP_JSONL=$(mktemp "$SLUG_DIR/.tmp.XXXXXX") || _fail "cannot create temp file in $SLUG_DIR"
if ! cp "$TRANSCRIPT_PATH" "$TMP_JSONL"; then
    rm -f "$TMP_JSONL"
    _fail "copy failed: $TRANSCRIPT_PATH"
fi
mv "$TMP_JSONL" "$SLUG_DIR/$SESSION_ID.jsonl" || {
    rm -f "$TMP_JSONL"
    _fail "rename failed for $SESSION_ID.jsonl"
}

# Step 7: write sidecar with history-derived name and archive timestamp
ARCHIVED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || printf 'unknown')
printf '{"session_name":%s,"archived_at":%s}\n' \
    "$(jq -Rn --arg s "$SESSION_NAME" '$s')" \
    "$(jq -Rn --arg s "$ARCHIVED_AT" '$s')" \
    > "$SLUG_DIR/$SESSION_ID.meta.json" || _fail "cannot write sidecar for $SESSION_ID"

exit 0
