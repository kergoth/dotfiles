#!/usr/bin/env python3
"""Search Claude Code session JSONL history files by keyword."""

import argparse
import json
import os
import re
import shlex
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote


CLAUDE_PROJECTS = Path.home() / ".claude" / "projects"
CODEX_HOME = Path.home() / ".codex"
CODEX_SESSIONS = CODEX_HOME / "sessions"
CODEX_STATE_DB = CODEX_HOME / "state_5.sqlite"
CURSOR_PROJECTS = Path.home() / ".cursor" / "projects"

USER_QUERY_RE = re.compile(r"<user_query>\s*(.*?)\s*</user_query>", re.DOTALL)


def strip_cursor_user_query(text: str) -> str:
    match = USER_QUERY_RE.search(text.strip())
    if match:
        return match.group(1).strip()
    return text.strip()


def cursor_workspace_storage_dirs() -> list[Path]:
    """Return Cursor workspaceStorage paths for this platform (may not exist)."""
    home = Path.home()
    return [
        home / "Library" / "Application Support" / "Cursor" / "User" / "workspaceStorage",
        home / ".config" / "Cursor" / "User" / "workspaceStorage",
    ]


def normalize_iso_timestamp(value: str) -> str:
    if not value:
        return ""
    parseable = value[:-1] + "+00:00" if value.endswith("Z") else value
    try:
        parsed = datetime.fromisoformat(parseable)
    except ValueError:
        return value
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    normalized = parsed.astimezone(timezone.utc)
    return normalized.isoformat(timespec="milliseconds").replace("+00:00", "Z")


def unix_to_iso(value: int | None, *, milliseconds: bool = False) -> str:
    if value is None:
        return ""
    seconds = value / 1000 if milliseconds else value
    return datetime.fromtimestamp(seconds, tz=timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def cwd_to_slug(cwd: str) -> str:
    """Convert an absolute path to the Claude projects directory slug.

    Claude replaces each '/' with '-', producing a leading '-'.
    Example: '/Users/chris/foo' -> '-Users-chris-foo'
    """
    return cwd.replace("/", "-")


def normalize_path(path: str) -> str:
    if not path:
        return ""
    return os.path.realpath(path)


def cursor_project_matches_cwd(
    project_dir: str,
    cwd: str,
    workspace_index: dict[str, str],
) -> bool:
    """Return whether a transcript's project_dir matches project-scoped cwd.

    Prefer workspaceStorage mapping for cwd when present; otherwise compare
    realpaths so symlinked cwd paths can still match.
    """
    if not project_dir:
        return False
    resolved_project = normalize_path(project_dir)
    indexed_cwd_folder = workspace_index.get(cursor_slug(cwd))
    if indexed_cwd_folder:
        return resolved_project == normalize_path(indexed_cwd_folder)
    return resolved_project == normalize_path(cwd)


def cursor_slug(cwd: str) -> str:
    """Convert an absolute path to the Cursor projects directory slug."""
    path = cwd[1:] if cwd.startswith("/") else cwd
    path = path.replace("/", "-").replace(".", "-")
    return re.sub(r"-+", "-", path)


def cursor_transcript_parent_id(jsonl_path: Path) -> str:
    """Return the parent agent session UUID for a transcript file."""
    parts = jsonl_path.parts
    if "subagents" in parts:
        idx = parts.index("subagents")
        return parts[idx - 1]
    return jsonl_path.parent.name


def cursor_parent_jsonl(jsonl_path: Path) -> Path:
    """Return the parent session JSONL path for parent or subagent transcripts."""
    parent_id = cursor_transcript_parent_id(jsonl_path)
    if "subagents" in jsonl_path.parts:
        # .../<parent>/subagents/<sub>.jsonl -> .../<parent>/<parent>.jsonl
        return jsonl_path.parent.parent / f"{parent_id}.jsonl"
    # .../<parent>/<parent>.jsonl -> same file
    return jsonl_path.parent / f"{parent_id}.jsonl"


def build_cursor_workspace_index(
    workspace_storage: Path | list[Path] | None = None,
) -> dict[str, str]:
    """Build project-slug -> folder path from Cursor workspaceStorage."""
    roots = (
        [workspace_storage]
        if isinstance(workspace_storage, Path)
        else list(workspace_storage or cursor_workspace_storage_dirs())
    )
    index: dict[str, str] = {}
    for root in roots:
        if not root.exists():
            continue
        for entry in root.iterdir():
            if not entry.is_dir():
                continue
            workspace_json = entry / "workspace.json"
            if not workspace_json.exists():
                continue
            try:
                data = json.loads(workspace_json.read_text())
            except (OSError, json.JSONDecodeError):
                continue

            folder = data.get("folder")
            if not folder and isinstance(data.get("configuration"), dict):
                folders = data["configuration"].get("folders") or []
                if folders and isinstance(folders[0], dict):
                    folder = folders[0].get("path")
            if not folder:
                continue
            if folder.startswith("file://"):
                folder = unquote(folder[len("file://"):])
            index[cursor_slug(folder)] = folder
    return index


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


def find_matching_jsonl_files(search_dirs: list[Path], keywords: list[str]) -> list[Path]:
    return find_matching_files(search_dirs, keywords)


def find_files_by_session_ids(
    session_ids: list[str],
    projects_root: Path = CLAUDE_PROJECTS,
) -> list[Path]:
    """Locate JSONL files for specific session IDs or unambiguous prefixes."""
    files = []
    errors = []
    for sid in session_ids:
        # Try exact match first
        matches = list(projects_root.glob(f"*/{sid}.jsonl"))
        if matches:
            files.extend(matches)
            continue
        # Fall back to prefix match
        matches = list(projects_root.glob(f"*/{sid}*.jsonl"))
        if len(matches) == 1:
            resolved = matches[0].stem
            print(f"Resolved prefix {sid} -> {resolved}", file=sys.stderr)
            files.append(matches[0])
        elif len(matches) > 1:
            resolved_ids = [m.stem for m in matches]
            errors.append(
                f"Ambiguous prefix {sid!r} matches {len(matches)} sessions: "
                + ", ".join(resolved_ids)
            )
        else:
            errors.append(f"Session {sid} not found")
    if errors:
        for err in errors:
            print(f"Error: {err}", file=sys.stderr)
        sys.exit(1)
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


def build_session_name_index(history_path: Path = Path.home() / ".claude" / "history.jsonl") -> dict[str, str]:
    """Build a session_id -> display_name mapping from history.jsonl.

    Uses the first non-slash-command entry per session as the display name.
    Falls back to the first entry of any kind if all entries are slash commands.
    """
    if not history_path.exists():
        return {}

    first_any: dict[str, str] = {}
    first_real: dict[str, str] = {}

    try:
        with open(history_path, errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                sid = entry.get("sessionId")
                display = entry.get("display", "").strip()
                if not sid or not display:
                    continue
                if sid not in first_any:
                    first_any[sid] = display
                if sid not in first_real and not display.startswith("/"):
                    first_real[sid] = display
    except OSError:
        return {}

    return {sid: first_real.get(sid, first_any[sid]) for sid in first_any}


def get_session_metadata(jsonl_path: Path) -> dict:
    """Extract session_id, cwd, first timestamp, custom title, and away_summary from a JSONL file.

    Reads the full file to ensure custom-title and away_summary events (which can appear
    anywhere) are not missed. The most recent away_summary is kept as it summarizes the
    full session arc up to that point.
    """
    session_id = jsonl_path.stem
    cwd = ""
    first_timestamp = ""
    custom_title = ""
    away_summary = ""

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
                if obj.get("type") == "system" and obj.get("subtype") == "away_summary":
                    content = obj.get("content", "")
                    if content:
                        away_summary = content  # keep the most recent one
    except OSError:
        pass

    return {
        "session_id": session_id,
        "cwd": cwd,
        "first_timestamp": first_timestamp,
        "custom_title": custom_title,
        "away_summary": away_summary,
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


def all_keywords_match(messages: list[dict], keywords: list[str]) -> bool:
    combined = "\n".join(m["text"] for m in messages)
    return all(re.search(re.escape(kw), combined, re.IGNORECASE) for kw in keywords)


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

    first_exchanges = build_exchanges(messages, num_exchanges, from_end=False)
    last_exchanges = build_exchanges(messages, num_exchanges, from_end=True)
    match_contexts = get_match_contexts(messages, keywords, context_size)

    last_timestamp = messages[-1]["timestamp"] if messages else ""

    custom_title = (metadata["custom_title"] or "").strip()
    return {
        "session_id": metadata["session_id"],
        "session_name": custom_title or None,
        "has_custom_name": bool(custom_title),
        "away_summary": metadata["away_summary"] or None,
        "project_dir": metadata["cwd"],
        "first_timestamp": metadata["first_timestamp"],
        "last_timestamp": last_timestamp,
        "match_count": len(match_contexts),
        "first_exchanges": first_exchanges,
        "last_exchanges": last_exchanges,
        "match_contexts": match_contexts,
    }


class ClaudeProvider:
    name = "claude"

    def __init__(self, projects_root: Path = CLAUDE_PROJECTS):
        self.projects_root = projects_root

    def search_files(self, scope: str, cwd: str, keywords: list[str]) -> list[Path]:
        return find_matching_files(get_search_dirs(scope, cwd, self.projects_root), keywords)

    def files_by_session_ids(self, session_ids: list[str]) -> list[Path]:
        return find_files_by_session_ids(session_ids, self.projects_root)

    def session_id_matches(self, session_id: str) -> list[tuple[Path, str]]:
        matches = list(self.projects_root.glob(f"*/{session_id}.jsonl"))
        if not matches:
            matches = list(self.projects_root.glob(f"*/{session_id}*.jsonl"))
        return [(path, path.stem) for path in matches]

    def extract_session_data(self, jsonl_path: Path, keywords: list[str], depth: str) -> dict | None:
        data = extract_session_data(jsonl_path, keywords, depth)
        if data is None:
            return None
        data["agent"] = self.name
        data["resume_command"] = build_resume_command(self.name, data)
        return data

    def enrich_results(self, results: list[dict]) -> None:
        history_index = build_session_name_index()
        for data in results:
            if data["session_name"] is None:
                data["session_name"] = history_index.get(data["session_id"])


class CodexProvider:
    name = "codex"

    def __init__(
        self,
        sessions_root: Path = CODEX_SESSIONS,
        state_db: Path = CODEX_STATE_DB,
        history_path: Path = CODEX_HOME / "history.jsonl",
        session_index_path: Path = CODEX_HOME / "session_index.jsonl",
    ):
        self.sessions_root = sessions_root
        self.state_db = state_db
        self.history_path = history_path
        self.session_index_path = session_index_path

    def extract_text(self, content) -> str:
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            return "".join(
                block["text"]
                for block in content
                if isinstance(block, dict)
                and block.get("type") in ("input_text", "output_text")
                and isinstance(block.get("text"), str)
            )
        return ""

    def iter_json_objects(self, jsonl_path: Path):
        try:
            f = open(jsonl_path, errors="replace")
        except OSError:
            return
        with f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    yield json.loads(line)
                except json.JSONDecodeError:
                    continue

    def parse_messages(self, jsonl_path: Path) -> list[dict]:
        messages = []
        for obj in self.iter_json_objects(jsonl_path):
            if obj.get("type") != "response_item":
                continue
            payload = obj.get("payload", {})
            if payload.get("type") != "message":
                continue
            role = payload.get("role")
            if role not in ("user", "assistant"):
                continue
            text = self.extract_text(payload.get("content", "")).strip()
            if not text:
                continue
            messages.append({
                "role": role,
                "text": text,
                "timestamp": normalize_iso_timestamp(obj.get("timestamp", "")),
            })
        return messages

    def get_metadata(self, jsonl_path: Path) -> dict:
        session_id = ""
        cwd = ""
        first_timestamp = ""
        for obj in self.iter_json_objects(jsonl_path):
            if obj.get("type") != "session_meta":
                continue
            payload = obj.get("payload", {})
            session_id = payload.get("id", "") or session_id
            cwd = payload.get("cwd", "") or cwd
            first_timestamp = normalize_iso_timestamp(payload.get("timestamp", "") or obj.get("timestamp", ""))
            break
        return {
            "session_id": session_id,
            "cwd": cwd,
            "first_timestamp": first_timestamp,
            "custom_title": "",
            "away_summary": "",
        }

    def all_session_files(self) -> list[Path]:
        if not self.sessions_root.exists():
            return []
        return sorted(self.sessions_root.glob("**/*.jsonl"))

    def project_files_from_sqlite(self, cwd: str) -> list[Path]:
        if not self.state_db.exists():
            return []
        try:
            with sqlite3.connect(self.state_db) as conn:
                rows = conn.execute(
                    "select rollout_path from threads where cwd = ? and rollout_path != ''",
                    (cwd,),
                ).fetchall()
        except sqlite3.Error as e:
            print(f"Warning: failed to read Codex state DB {self.state_db}: {e}", file=sys.stderr)
            return []
        return [Path(row[0]) for row in rows if row[0] and Path(row[0]).exists()]

    def file_matches_project(self, jsonl_path: Path, cwd: str) -> bool:
        return self.get_metadata(jsonl_path).get("cwd") == cwd

    def search_files(self, scope: str, cwd: str, keywords: list[str]) -> list[Path]:
        sqlite_files = []
        if scope == "project":
            sqlite_files = self.project_files_from_sqlite(cwd)
            if sqlite_files:
                candidates = sqlite_files
            else:
                dirs = [self.sessions_root] if self.sessions_root.exists() else []
                candidates = find_matching_jsonl_files(dirs, keywords)
        else:
            dirs = [self.sessions_root] if self.sessions_root.exists() else []
            candidates = find_matching_jsonl_files(dirs, keywords)

        results = []
        for path in candidates:
            if scope == "project" and not sqlite_files and not self.file_matches_project(path, cwd):
                continue
            messages = self.parse_messages(path)
            if not all_keywords_match(messages, keywords):
                continue
            results.append(path)
        return sorted(results)

    def files_by_session_ids(self, session_ids: list[str]) -> list[Path]:
        return [
            path
            for _provider, path in find_files_by_session_ids_across_providers([self], session_ids)
        ]

    def session_id_matches(self, session_id: str) -> list[tuple[Path, str]]:
        metadata_by_path = [(path, self.get_metadata(path)) for path in self.all_session_files()]
        return [
            (path, metadata.get("session_id", ""))
            for path, metadata in metadata_by_path
            if metadata.get("session_id") == session_id
            or metadata.get("session_id", "").startswith(session_id)
        ]

    def extract_session_data(self, jsonl_path: Path, keywords: list[str], depth: str) -> dict | None:
        metadata = self.get_metadata(jsonl_path)
        messages = self.parse_messages(jsonl_path)

        user_messages = [m for m in messages if m["role"] == "user"]
        if not user_messages:
            return None
        if keywords and not all_keywords_match(messages, keywords):
            return None

        num_exchanges = 1 if depth == "quick" else 3
        context_size = 2 if depth == "quick" else 5

        first_exchanges = build_exchanges(messages, num_exchanges, from_end=False)
        last_exchanges = build_exchanges(messages, num_exchanges, from_end=True)
        match_contexts = get_match_contexts(messages, keywords, context_size)

        last_timestamp = messages[-1]["timestamp"] if messages else ""
        data = {
            "agent": self.name,
            "session_id": metadata["session_id"],
            "session_name": None,
            "has_custom_name": False,
            "away_summary": None,
            "project_dir": metadata["cwd"],
            "first_timestamp": metadata["first_timestamp"],
            "last_timestamp": last_timestamp,
            "match_count": len(match_contexts),
            "resume_command": "",
            "first_exchanges": first_exchanges,
            "last_exchanges": last_exchanges,
            "match_contexts": match_contexts,
        }
        data["resume_command"] = build_resume_command(self.name, data)
        return data

    def thread_index(self) -> dict[str, dict]:
        if not self.state_db.exists():
            return {}
        try:
            with sqlite3.connect(self.state_db) as conn:
                conn.row_factory = sqlite3.Row
                rows = conn.execute(
                    "select id, title, cwd, rollout_path, created_at, updated_at, created_at_ms, updated_at_ms from threads"
                ).fetchall()
        except sqlite3.Error as e:
            print(f"Warning: failed to read Codex state DB {self.state_db}: {e}", file=sys.stderr)
            return {}
        return {row["id"]: dict(row) for row in rows}

    def session_name_index(self) -> dict[str, str]:
        if not self.session_index_path.exists():
            return {}
        names = {}
        try:
            with open(self.session_index_path, errors="replace") as f:
                for line in f:
                    try:
                        entry = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    sid = entry.get("id")
                    name = entry.get("thread_name")
                    if sid and name:
                        names[sid] = name
        except OSError:
            return {}
        return names

    def history_name_index(self) -> dict[str, str]:
        if not self.history_path.exists():
            return {}
        names = {}
        try:
            with open(self.history_path, errors="replace") as f:
                for line in f:
                    try:
                        entry = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    sid = entry.get("session_id")
                    text = entry.get("text")
                    if sid and text and sid not in names:
                        names[sid] = text
        except OSError:
            return {}
        return names

    def enrich_results(self, results: list[dict]) -> None:
        threads = self.thread_index()
        session_index = self.session_name_index()
        history_index = self.history_name_index()
        for data in results:
            thread = threads.get(data["session_id"])
            if thread and not data.get("session_name") and thread.get("title"):
                data["session_name"] = thread["title"]
            if not data.get("session_name"):
                data["session_name"] = session_index.get(data["session_id"]) or history_index.get(data["session_id"])
            if thread:
                if thread.get("cwd"):
                    data["project_dir"] = thread["cwd"]
                updated = thread.get("updated_at_ms")
                if updated is not None:
                    data["last_timestamp"] = unix_to_iso(updated, milliseconds=True)
                elif thread.get("updated_at") is not None:
                    data["last_timestamp"] = unix_to_iso(thread["updated_at"])
                created = thread.get("created_at_ms")
                if created is not None:
                    data["first_timestamp"] = unix_to_iso(created, milliseconds=True)
                elif thread.get("created_at") is not None:
                    data["first_timestamp"] = unix_to_iso(thread["created_at"])
            data["resume_command"] = build_resume_command(self.name, data)


class CursorProvider:
    name = "cursor"

    def __init__(
        self,
        projects_root: Path = CURSOR_PROJECTS,
        workspace_storage: Path | list[Path] | None = None,
    ):
        self.projects_root = projects_root
        self.workspace_storage = workspace_storage
        self._workspace_index: dict[str, str] | None = None

    def workspace_index(self) -> dict[str, str]:
        if self._workspace_index is None:
            self._workspace_index = build_cursor_workspace_index(self.workspace_storage)
        return self._workspace_index

    def extract_text(self, content) -> str:
        if isinstance(content, str):
            return strip_cursor_user_query(content)
        if isinstance(content, list):
            return "".join(
                block.get("text", "")
                for block in content
                if isinstance(block, dict) and block.get("type") == "text"
            ).strip()
        return ""

    def parse_messages(self, jsonl_path: Path) -> list[dict]:
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
                if obj.get("type") == "turn_ended":
                    continue
                role = obj.get("role")
                if role not in ("user", "assistant"):
                    continue
                text = self.extract_text(obj.get("message", {}).get("content", "")).strip()
                if role == "user":
                    text = strip_cursor_user_query(text)
                if not text:
                    continue
                messages.append({"role": role, "text": text, "timestamp": ""})
        return messages

    def project_slug_from_path(self, jsonl_path: Path) -> str:
        parts = jsonl_path.parts
        if "agent-transcripts" not in parts:
            return ""
        idx = parts.index("agent-transcripts")
        if idx == 0:
            return ""
        return parts[idx - 1]

    def project_dir_for_path(self, jsonl_path: Path) -> str:
        slug = self.project_slug_from_path(jsonl_path)
        if not slug:
            return ""
        folder = self.workspace_index().get(slug, "")
        if not folder:
            print(
                f"Warning: no workspace mapping for Cursor project slug {slug!r}",
                file=sys.stderr,
            )
        return folder

    def mtime_iso(self, path: Path) -> str:
        try:
            ts = path.stat().st_mtime
        except OSError:
            return ""
        return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat(
            timespec="milliseconds"
        ).replace("+00:00", "Z")

    def is_subagent_transcript(self, jsonl_path: Path) -> bool:
        return "subagents" in jsonl_path.parts

    def parent_session_name(self, jsonl_path: Path, fallback_messages: list[dict]) -> str | None:
        parent_jsonl = cursor_parent_jsonl(jsonl_path)
        if parent_jsonl.exists():
            parent_users = [m for m in self.parse_messages(parent_jsonl) if m["role"] == "user"]
            if parent_users:
                return parent_users[0]["text"][:80] or None
        fallback_users = [m for m in fallback_messages if m["role"] == "user"]
        if fallback_users:
            return fallback_users[0]["text"][:80] or None
        return None

    def extract_session_data(self, jsonl_path: Path, keywords: list[str], depth: str) -> dict | None:
        messages = self.parse_messages(jsonl_path)
        user_messages = [m for m in messages if m["role"] == "user"]
        if not user_messages:
            return None
        if keywords and not all_keywords_match(messages, keywords):
            return None

        parent_id = cursor_transcript_parent_id(jsonl_path)
        parent_jsonl = cursor_parent_jsonl(jsonl_path)
        timestamp_path = parent_jsonl if parent_jsonl.exists() else jsonl_path
        mtime = self.mtime_iso(timestamp_path)

        num_exchanges = 1 if depth == "quick" else 3
        context_size = 2 if depth == "quick" else 5
        first_exchanges = build_exchanges(messages, num_exchanges, from_end=False)
        last_exchanges = build_exchanges(messages, num_exchanges, from_end=True)
        match_contexts = get_match_contexts(messages, keywords, context_size)

        data = {
            "agent": self.name,
            "session_id": parent_id,
            "session_name": self.parent_session_name(jsonl_path, messages),
            "has_custom_name": False,
            "away_summary": None,
            "project_dir": self.project_dir_for_path(jsonl_path),
            "first_timestamp": mtime,
            "last_timestamp": mtime,
            "match_count": len(match_contexts),
            "match_source": "subagent" if self.is_subagent_transcript(jsonl_path) else "parent",
            "resume_command": "",
            "first_exchanges": first_exchanges,
            "last_exchanges": last_exchanges,
            "match_contexts": match_contexts,
        }
        data["resume_command"] = build_resume_command(self.name, data)
        return data

    def enrich_results(self, results: list[dict]) -> None:
        # resume_command is set in extract_session_data; no SQLite-style enrichment.
        return

    def all_transcript_files(self) -> list[Path]:
        if not self.projects_root.exists():
            return []
        return sorted(self.projects_root.glob("**/agent-transcripts/**/*.jsonl"))

    def search_files(self, scope: str, cwd: str, keywords: list[str]) -> list[Path]:
        if not keywords:
            return []

        fallback_filter_cwd = None
        if scope == "project":
            slug = cursor_slug(cwd)
            transcript_root = self.projects_root / slug / "agent-transcripts"
            if transcript_root.exists():
                search_roots = [transcript_root]
            else:
                print(
                    f"Warning: no Cursor project dir found for {cwd!r}, searching globally",
                    file=sys.stderr,
                )
                search_roots = [self.projects_root] if self.projects_root.exists() else []
                fallback_filter_cwd = cwd
        else:
            search_roots = [self.projects_root] if self.projects_root.exists() else []

        candidates = find_matching_jsonl_files(search_roots, keywords)

        results = []
        workspace_index = self.workspace_index() if fallback_filter_cwd else None
        for path in candidates:
            if fallback_filter_cwd:
                project_dir = self.project_dir_for_path(path)
                if not cursor_project_matches_cwd(
                    project_dir, fallback_filter_cwd, workspace_index
                ):
                    continue
            messages = self.parse_messages(path)
            if not all_keywords_match(messages, keywords):
                continue
            results.append(path)
        return sorted(results)

    def session_id_matches(self, session_id: str) -> list[tuple[Path, str]]:
        seen: dict[str, Path] = {}
        for path in self.all_transcript_files():
            parent_id = cursor_transcript_parent_id(path)
            if parent_id == session_id or parent_id.startswith(session_id):
                seen.setdefault(parent_id, cursor_parent_jsonl(path))
        return [(path, pid) for pid, path in seen.items()]

    def files_by_session_ids(self, session_ids: list[str]) -> list[Path]:
        return [
            path
            for _provider, path in find_files_by_session_ids_across_providers([self], session_ids)
        ]


PROVIDERS = {
    "claude": ClaudeProvider(),
    "codex": CodexProvider(),
    "cursor": CursorProvider(),
}


def rollup_session_results(results: list[dict]) -> list[dict]:
    """Merge duplicate Cursor session rows (parent + subagent file hits)."""
    merged: dict[tuple[str, str], dict] = {}
    passthrough: list[dict] = []
    for data in results:
        if data.get("agent") != "cursor":
            passthrough.append(data)
            continue
        key = (data.get("agent", ""), data.get("session_id", ""))
        if key not in merged:
            merged[key] = data
            continue
        existing = merged[key]
        existing["match_count"] = existing.get("match_count", 0) + data.get("match_count", 0)
        existing["match_contexts"] = existing.get("match_contexts", []) + data.get("match_contexts", [])
        if data.get("last_timestamp", "") > existing.get("last_timestamp", ""):
            existing["last_timestamp"] = data["last_timestamp"]
        if existing.get("match_source") == "subagent" and data.get("match_source") == "parent":
            existing["match_source"] = "parent"
        elif existing.get("match_source") != "parent":
            existing["match_source"] = data.get("match_source", existing.get("match_source"))
        if not existing.get("session_name") and data.get("session_name"):
            existing["session_name"] = data["session_name"]
    return passthrough + list(merged.values())


def selected_providers(agent: str) -> list[object]:
    if agent == "all":
        return [PROVIDERS["claude"], PROVIDERS["codex"], PROVIDERS["cursor"]]
    return [PROVIDERS[agent]]


def build_resume_command(agent: str, data: dict) -> str:
    project_dir = shlex.quote(data.get("project_dir") or ".")
    session_id = shlex.quote(data["session_id"])
    if agent == "codex":
        return f"cd {project_dir} && codex resume {session_id}"
    if agent == "cursor":
        return f"cd {project_dir} && agent --resume {session_id}"
    return f"cd {project_dir} && claude --resume {session_id}"


def find_files_by_session_ids_across_providers(providers: list[object], session_ids: list[str]) -> list[tuple[object, Path]]:
    matches_by_sid: dict[str, list[tuple[object, Path, str]]] = {sid: [] for sid in session_ids}
    errors = []

    for sid in session_ids:
        for provider in providers:
            for path, resolved_id in provider.session_id_matches(sid):
                matches_by_sid[sid].append((provider, path, resolved_id))

        matches = matches_by_sid[sid]
        if len(matches) == 1:
            continue
        if len(matches) > 1:
            labels = [f"{provider.name}:{resolved_id}" for provider, _path, resolved_id in matches]
            errors.append(
                f"Ambiguous session prefix {sid!r} matches {len(matches)} sessions: "
                + ", ".join(labels)
            )
        else:
            provider_names = ", ".join(provider.name for provider in providers)
            errors.append(f"Session {sid!r} not found in selected providers: {provider_names}")

    if errors:
        for err in errors:
            print(f"Error: {err}", file=sys.stderr)
        sys.exit(1)

    return [
        (provider, path)
        for matches in matches_by_sid.values()
        for provider, path, _resolved_id in matches
    ]


def parse_args():
    parser = argparse.ArgumentParser(
        description="Search agent session history by keyword"
    )
    parser.add_argument("keywords", nargs="*", help="Keywords to search for")
    parser.add_argument(
        "--agent",
        choices=["claude", "codex", "cursor", "all"],
        default="all",
        help="Session provider to search: claude, codex, cursor, or all (default: all)",
    )
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

    providers = selected_providers(args.agent)

    matching_by_provider: list[tuple[object, Path]] = []
    if args.session_ids:
        matching_by_provider = find_files_by_session_ids_across_providers(providers, args.session_ids)
    else:
        if not args.keywords:
            print("Error: keywords are required unless --session-ids is provided", file=sys.stderr)
            sys.exit(1)
        for provider in providers:
            for path in provider.search_files(args.scope, args.cwd, args.keywords):
                matching_by_provider.append((provider, path))

    results = []
    for provider, jsonl_path in matching_by_provider:
        try:
            data = provider.extract_session_data(jsonl_path, args.keywords, args.depth)
        except Exception as e:
            print(f"Warning: failed to process {jsonl_path}: {type(e).__name__}: {e}", file=sys.stderr)
            continue
        if data is None:
            continue
        if data["session_id"] in args.exclude:
            continue
        results.append(data)

    results = rollup_session_results(results)

    for provider in providers:
        provider.enrich_results([r for r in results if r.get("agent") == provider.name])

    # Sort by match_count descending (more hits = more likely to be the primary topic),
    # with last_timestamp as tiebreaker so equally-relevant sessions show newest first.
    results.sort(key=lambda x: (x.get("match_count", 0), x.get("last_timestamp", "")), reverse=True)

    total = len(results)
    print(json.dumps({"total_matching": total, "sessions": results[: args.max_results]}, indent=2))


if __name__ == "__main__":
    main()
