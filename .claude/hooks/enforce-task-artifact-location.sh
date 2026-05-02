#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
tool_name=$(jq -r '.tool_name // ""' <<<"$input")

if [[ -z "$tool_name" ]]; then
    exit 0
fi

target=""
case "$tool_name" in
    Bash)
        target=$(jq -r '.tool_input.command // ""' <<<"$input")
        ;;
    Write|Edit|MultiEdit)
        target=$(jq -r '.tool_input.file_path // ""' <<<"$input")
        ;;
    *)
        exit 0
        ;;
esac

if [[ -z "$target" ]]; then
    exit 0
fi

case "$target" in
    *"docs/superpowers/specs"*|*"docs/superpowers/plans"*|*"docs/specs"*|*"docs/plans"*)
        ;;
    *)
        exit 0
        ;;
esac

project_dir=${CLAUDE_PROJECT_DIR:-}
if [[ -z "$project_dir" ]]; then
    project_dir=$(jq -r '.cwd // ""' <<<"$input")
fi

if [[ -z "$project_dir" ]]; then
    exit 0
fi

jq -n --arg reason "Project-local policy for this repository: task-specific specs/plans are temporary artifacts. Do not use docs/superpowers/specs, docs/superpowers/plans, docs/specs, or docs/plans. Use .agent/tasks/<date>-<slug>/ unless the user explicitly requests committed project docs for this task." '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
