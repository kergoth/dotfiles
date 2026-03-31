#!/usr/bin/env python3
"""Search Claude Code session JSONL history files by keyword."""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


CLAUDE_PROJECTS = Path.home() / ".claude" / "projects"


def cwd_to_slug(cwd: str) -> str:
    """Convert an absolute path to the Claude projects directory slug.

    Claude replaces each '/' with '-', producing a leading '-'.
    Example: '/Users/chris/foo' -> '-Users-chris-foo'
    """
    return cwd.replace("/", "-")


def get_search_dirs(
    scope: str,
    cwd: str,
    projects_root: Path = CLAUDE_PROJECTS,
) -> list[Path]:
    """Return the list of project directories to search.

    For 'project' scope, resolves the slug for cwd and returns that single
    directory. Falls back to global if the slug directory doesn't exist.
    For 'global' scope, returns all subdirectories under projects_root.
    """
    if not projects_root.exists():
        return []

    all_dirs = sorted([d for d in projects_root.iterdir() if d.is_dir()])

    if scope == "project":
        slug = cwd_to_slug(cwd)
        candidate = projects_root / slug
        if candidate.exists():
            return [candidate]
        # Fall back to global with a warning
        print(
            f"Warning: no project dir found for {cwd!r}, searching globally",
            file=sys.stderr,
        )
        return all_dirs

    return all_dirs


def find_matching_files(search_dirs: list[Path], keywords: list[str]) -> list[Path]:
    """Use rg to find .jsonl files containing all of the keywords (AND semantics).

    Runs one rg pass per keyword and intersects the results, so only files
    containing every keyword are returned. rg is case-insensitive.
    """
    if not search_dirs or not keywords:
        return []

    dir_args = [str(d) for d in search_dirs]
    matched: set[str] | None = None

    for kw in keywords:
        cmd = [
            "rg",
            "--files-with-matches",
            "--glob", "*.jsonl",
            "--ignore-case",
            re.escape(kw),
        ] + dir_args

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
        except FileNotFoundError:
            print("Error: rg (ripgrep) not found. Install it with: brew install ripgrep", file=sys.stderr)
            sys.exit(1)

        if result.returncode not in (0, 1):  # 1 = no matches found, not an error
            print(f"rg error: {result.stderr}", file=sys.stderr)
            return []

        hits = {p for p in result.stdout.splitlines() if p.strip()}
        matched = hits if matched is None else matched & hits

    if matched is None:
        return []

    return [Path(p) for p in matched]


def find_files_by_session_ids(
    session_ids: list[str],
    projects_root: Path = CLAUDE_PROJECTS,
) -> list[Path]:
    """Locate JSONL files for specific session IDs by scanning all project dirs."""
    files = []
    for sid in session_ids:
        matches = list(projects_root.glob(f"*/{sid}.jsonl"))
        if matches:
            files.extend(matches)
        else:
            print(f"Warning: session {sid} not found", file=sys.stderr)
    return files


def extract_text(content) -> str:
    """Extract plain text from a message content field.

    Content may be a plain string or a list of typed blocks.
    Only 'text' type blocks are included; tool_use, tool_result, etc. are skipped.
    """
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        # Text blocks already contain their own spacing; join without separator
        return "".join(
            block["text"]
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        )
    return ""


def parse_messages(jsonl_path: Path) -> list[dict]:
    """Parse a JSONL file and return a list of message dicts.

    Each dict has: role (str), text (str), timestamp (str).
    Skips: malformed lines, messages with no text content, non-message event types.
    """
    messages = []
    try:
        f = open(jsonl_path, errors="replace")
    except OSError:
        return messages
    with f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg_type = obj.get("type", "")
            if msg_type not in ("user", "assistant"):
                continue

            data = obj.get("data", obj)
            message = data.get("message", {})
            role = message.get("role", msg_type)
            content = message.get("content", "")
            text = extract_text(content).strip()

            if not text:
                continue

            messages.append({
                "role": role,
                "text": text,
                "timestamp": obj.get("timestamp", ""),
            })
    return messages


def get_session_metadata(jsonl_path: Path) -> dict:
    """Extract session_id, cwd, first timestamp, and custom title from a JSONL file.

    Reads the full file to ensure custom-title events (which can appear anywhere)
    are not missed.
    """
    session_id = jsonl_path.stem
    cwd = ""
    first_timestamp = ""
    custom_title = ""

    try:
        with open(jsonl_path, errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if not first_timestamp and obj.get("timestamp"):
                    first_timestamp = obj["timestamp"]
                if not cwd and obj.get("cwd"):
                    cwd = obj["cwd"]
                if obj.get("type") == "custom-title":
                    custom_title = obj.get("customTitle", "")
    except OSError:
        pass

    return {
        "session_id": session_id,
        "cwd": cwd,
        "first_timestamp": first_timestamp,
        "custom_title": custom_title,
    }


def get_match_contexts(
    messages: list[dict],
    keywords: list[str],
    context_size: int,
) -> list[dict]:
    """Find messages matching keywords and return each with surrounding context.

    context_size is the number of messages to include before and after each match.
    Overlapping windows are merged so no message appears in two separate context objects.
    """
    if not keywords:
        return []

    pattern = re.compile("|".join(re.escape(kw) for kw in keywords), re.IGNORECASE)
    contexts = []
    last_window_end = -1  # track to avoid duplicate context windows

    for i, msg in enumerate(messages):
        if not pattern.search(msg["text"]):
            continue
        if i <= last_window_end:
            # This match is inside the previous context window — extend it.
            if contexts:
                end = min(len(messages), i + context_size + 1)
                contexts[-1]["context_after"] = messages[i + 1 : end]
                last_window_end = end - 1
            continue

        start = max(0, i - context_size)
        end = min(len(messages), i + context_size + 1)
        contexts.append({
            "match": msg,
            "context_before": messages[start:i],
            "context_after": messages[i + 1 : end],
        })
        last_window_end = end - 1

    return contexts


def extract_session_data(
    jsonl_path: Path,
    keywords: list[str],
    depth: str,
) -> dict | None:
    """Extract structured data from one session file for the given depth.

    Returns None if the session has no user messages (automated session).
    """
    metadata = get_session_metadata(jsonl_path)
    messages = parse_messages(jsonl_path)

    user_messages = [m for m in messages if m["role"] == "user"]
    if not user_messages:
        return None

    num_exchanges = 1 if depth == "quick" else 3
    context_size = 2 if depth == "quick" else 5

    def build_exchanges(msg_list: list[dict], count: int, from_end: bool = False) -> list[dict]:
        """Extract up to `count` consecutive user+assistant exchange pairs."""
        exchanges = []
        indices = range(len(msg_list) - 1, -1, -1) if from_end else range(len(msg_list))
        for i in indices:
            if len(exchanges) >= count:
                break
            if msg_list[i]["role"] == "user":
                j = i + 1
                asst = msg_list[j] if j < len(msg_list) and msg_list[j]["role"] == "assistant" else None
                pair = {"user": msg_list[i], "assistant": asst}
                if from_end:
                    exchanges.insert(0, pair)
                else:
                    exchanges.append(pair)
        return exchanges

    first_exchanges = build_exchanges(messages, num_exchanges, from_end=False)
    last_exchanges = build_exchanges(messages, num_exchanges, from_end=True)
    match_contexts = get_match_contexts(messages, keywords, context_size)

    last_timestamp = messages[-1]["timestamp"] if messages else ""

    return {
        "session_id": metadata["session_id"],
        "session_name": metadata["custom_title"] or None,
        "project_dir": metadata["cwd"],
        "first_timestamp": metadata["first_timestamp"],
        "last_timestamp": last_timestamp,
        "match_count": len(match_contexts),
        "first_exchanges": first_exchanges,
        "last_exchanges": last_exchanges,
        "match_contexts": match_contexts,
    }


def parse_args():
    parser = argparse.ArgumentParser(
        description="Search Claude Code session history by keyword"
    )
    parser.add_argument("keywords", nargs="*", help="Keywords to search for")
    parser.add_argument(
        "--scope",
        choices=["project", "global"],
        default="global",
        help="Search scope: current project dir or all projects",
    )
    parser.add_argument(
        "--depth",
        choices=["quick", "thorough"],
        default="quick",
        help="Extraction depth: quick (first/last + small context) or thorough (more exchanges + larger context)",
    )
    parser.add_argument(
        "--cwd",
        default=os.getcwd(),
        help="Working directory for project scope resolution (default: cwd)",
    )
    parser.add_argument(
        "--max-results",
        type=int,
        default=10,
        help="Maximum number of sessions to return (default: 10)",
    )
    parser.add_argument(
        "--exclude",
        metavar="SESSION_ID",
        action="append",
        default=[],
        help="Exclude a session by ID (repeatable)",
    )
    parser.add_argument(
        "--session-ids",
        metavar="SESSION_ID",
        action="append",
        default=[],
        help="Fetch specific sessions by ID, bypassing keyword search (repeatable)",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if args.session_ids:
        matching_files = find_files_by_session_ids(args.session_ids)
    else:
        if not args.keywords:
            print("Error: keywords are required unless --session-ids is provided", file=sys.stderr)
            sys.exit(1)
        search_dirs = get_search_dirs(args.scope, args.cwd)
        matching_files = find_matching_files(search_dirs, args.keywords)

    results = []
    for jsonl_path in matching_files:
        try:
            data = extract_session_data(jsonl_path, args.keywords, args.depth)
        except Exception as e:
            print(f"Warning: failed to process {jsonl_path}: {type(e).__name__}: {e}", file=sys.stderr)
            continue
        if data is None:
            continue
        if data["session_id"] in args.exclude:
            continue
        results.append(data)

    # Sort by match_count descending (more hits = more likely to be the primary topic),
    # with last_timestamp as tiebreaker so equally-relevant sessions show newest first.
    results.sort(key=lambda x: (x.get("match_count", 0), x.get("last_timestamp", "")), reverse=True)

    total = len(results)
    print(json.dumps({"total_matching": total, "sessions": results[: args.max_results]}, indent=2))


if __name__ == "__main__":
    main()
