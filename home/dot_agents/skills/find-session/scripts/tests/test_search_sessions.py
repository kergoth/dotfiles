import json
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

SCRIPT = Path(__file__).parent.parent / "executable_search_sessions.py"

# Import module directly for unit tests
sys.path.insert(0, str(SCRIPT.parent))
from executable_search_sessions import (
    ClaudeProvider,
    CodexProvider,
    CursorProvider,
    build_cursor_workspace_index,
    build_resume_command,
    build_session_name_index,
    cwd_to_slug,
    cursor_parent_jsonl,
    cursor_project_matches_cwd,
    cursor_slug,
    cursor_transcript_parent_id,
    cursor_workspace_storage_dirs,
    extract_text,
    extract_session_data,
    find_files_by_session_ids_across_providers,
    find_matching_files,
    get_match_contexts,
    get_search_dirs,
    get_session_metadata,
    normalize_iso_timestamp,
    parse_messages,
    strip_cursor_user_query,
)


def make_cursor_message(role, text):
    return json.dumps({
        "role": role,
        "message": {"content": [{"type": "text", "text": text}]},
    })


def make_cursor_tool_use(name="Read"):
    return json.dumps({
        "role": "assistant",
        "message": {"content": [{"type": "tool_use", "name": name, "input": {}}]},
    })


def make_cursor_turn_ended():
    return json.dumps({"type": "turn_ended", "status": "completed"})


def make_jsonl_line(type_, role, content, timestamp="2026-01-01T00:00:00", cwd=None, session_id="test-session"):
    """Helper to create a JSONL line for testing."""
    obj = {
        "type": type_,
        "timestamp": timestamp,
        "sessionId": session_id,
        "data": {"message": {"role": role, "content": content}},
    }
    if cwd:
        obj["cwd"] = cwd
    return json.dumps(obj)


def make_codex_session_meta(session_id="019ecodex-test", cwd="/repo", timestamp="2026-06-15T10:00:00.000Z"):
    return json.dumps({
        "timestamp": timestamp,
        "type": "session_meta",
        "payload": {
            "id": session_id,
            "timestamp": timestamp,
            "cwd": cwd,
            "originator": "codex-tui",
            "cli_version": "0.137.0",
        },
    })


def make_codex_message(role, content, timestamp="2026-06-15T10:00:01.000Z"):
    return json.dumps({
        "timestamp": timestamp,
        "type": "response_item",
        "payload": {
            "type": "message",
            "role": role,
            "content": content,
        },
    })


def make_codex_event(text, timestamp="2026-06-15T10:00:02.000Z"):
    return json.dumps({
        "timestamp": timestamp,
        "type": "event_msg",
        "payload": {
            "type": "agent_message",
            "message": text,
        },
    })


def run_script(*args):
    """Run search_sessions.py with given args, return (returncode, stdout, stderr)."""
    result = subprocess.run(
        [sys.executable, str(SCRIPT)] + list(args),
        capture_output=True,
        text=True,
    )
    return result.returncode, result.stdout, result.stderr


def test_help_exits_zero():
    rc, out, _ = run_script("--help")
    assert rc == 0
    assert "scope" in out


def test_requires_keywords():
    rc, _, err = run_script("--scope", "global")
    assert rc != 0


def test_accepts_valid_args():
    # Should not crash on argument parsing alone (may fail on rg/files, that's ok)
    rc, out, err = run_script("--scope", "global", "--depth", "quick", "nonexistent_keyword_xyz")
    assert rc == 0
    result = json.loads(out)
    assert isinstance(result, dict)
    assert "total_matching" in result
    assert "sessions" in result
    assert isinstance(result["sessions"], list)


def test_default_agent_is_all():
    rc, out, err = run_script("--help")
    assert rc == 0
    assert "--agent" in out
    assert "claude" in out
    assert "codex" in out
    assert "cursor" in out
    assert "all" in out


def test_default_agent_help_includes_cursor():
    rc, out, _ = run_script("--help")
    assert rc == 0
    assert "cursor" in out


def test_rollup_session_results_merges_subagent_hits():
    from executable_search_sessions import rollup_session_results

    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    parent_row = {
        "agent": "cursor",
        "session_id": parent,
        "match_count": 1,
        "match_source": "parent",
        "last_timestamp": "2026-06-15T10:00:00.000Z",
        "match_contexts": [{"match": {"text": "parent hit"}}],
    }
    sub_row = {
        "agent": "cursor",
        "session_id": parent,
        "match_count": 2,
        "match_source": "subagent",
        "last_timestamp": "2026-06-16T10:00:00.000Z",
        "match_contexts": [{"match": {"text": "sub hit"}}],
    }
    merged = rollup_session_results([parent_row, sub_row])
    assert len(merged) == 1
    assert merged[0]["match_count"] == 3
    assert merged[0]["match_source"] == "parent"
    assert merged[0]["last_timestamp"] == "2026-06-16T10:00:00.000Z"
    assert len(merged[0]["match_contexts"]) == 2


def test_rollup_session_results_subagent_only():
    from executable_search_sessions import rollup_session_results

    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    sub_row = {
        "agent": "cursor",
        "session_id": parent,
        "match_count": 2,
        "match_source": "subagent",
        "last_timestamp": "2026-06-16T10:00:00.000Z",
        "match_contexts": [{"match": {"text": "sub hit"}}],
    }
    merged = rollup_session_results([sub_row])
    assert merged[0]["match_source"] == "subagent"


def test_rollup_session_results_does_not_merge_other_agents():
    from executable_search_sessions import rollup_session_results

    row_a = {"agent": "codex", "session_id": "019eabc", "match_count": 1, "match_contexts": []}
    row_b = {"agent": "codex", "session_id": "019eabc", "match_count": 2, "match_contexts": []}
    merged = rollup_session_results([row_a, row_b])
    assert len(merged) == 2


def test_script_accepts_agent_all_argument():
    rc, out, err = run_script("--agent", "all", "--scope", "global", "xq9z_no_such_keyword_xq9z")
    assert rc == 0
    result = json.loads(out)
    assert "sessions" in result


def test_build_resume_command_quotes_paths_with_spaces():
    data = {
        "project_dir": "/Users/chris/Project With Spaces",
        "session_id": "019ecodex-real-id",
    }

    assert build_resume_command("codex", data) == (
        "cd '/Users/chris/Project With Spaces' && codex resume 019ecodex-real-id"
    )


def test_codex_parse_messages_extracts_user_and_assistant_text(tmp_path):
    f = tmp_path / "rollout-2026-06-15T10-00-00-019ecodex-test.jsonl"
    f.write_text("\n".join([
        make_codex_session_meta(),
        make_codex_message("developer", [{"type": "input_text", "text": "ignore policy text"}]),
        make_codex_message("user", [{"type": "input_text", "text": "Find marketplace session"}]),
        make_codex_message("assistant", [{"type": "output_text", "text": "Found it"}]),
        make_codex_message("assistant", "Plain assistant text"),
        make_codex_event("ignore event text"),
    ]) + "\n")

    provider = CodexProvider(sessions_root=tmp_path)
    messages = provider.parse_messages(f)

    assert messages == [
        {"role": "user", "text": "Find marketplace session", "timestamp": "2026-06-15T10:00:01.000Z"},
        {"role": "assistant", "text": "Found it", "timestamp": "2026-06-15T10:00:01.000Z"},
        {"role": "assistant", "text": "Plain assistant text", "timestamp": "2026-06-15T10:00:01.000Z"},
    ]


def test_codex_metadata_uses_session_meta_id_not_filename(tmp_path):
    f = tmp_path / "rollout-2026-06-15T10-00-00-not-the-id.jsonl"
    f.write_text("\n".join([
        make_codex_session_meta(session_id="019ecodex-real-id", cwd="/repo"),
        make_codex_message("user", [{"type": "input_text", "text": "hello"}]),
    ]) + "\n")

    provider = CodexProvider(sessions_root=tmp_path)
    metadata = provider.get_metadata(f)

    assert metadata["session_id"] == "019ecodex-real-id"
    assert metadata["cwd"] == "/repo"
    assert metadata["first_timestamp"] == "2026-06-15T10:00:00.000Z"


def test_normalize_iso_timestamp_converts_offsets_to_utc():
    assert normalize_iso_timestamp("2026-06-15T03:00:00-07:00") == "2026-06-15T10:00:00.000Z"
    assert normalize_iso_timestamp("2026-06-15T10:00:00.123Z") == "2026-06-15T10:00:00.123Z"


def test_session_name_index_uses_first_non_slash_command():
    history = [
        {"sessionId": "aaa", "display": "/clear", "timestamp": 1000, "project": "/foo"},
        {"sessionId": "aaa", "display": "/clear", "timestamp": 1001, "project": "/foo"},
        {"sessionId": "aaa", "display": "Tell me about X", "timestamp": 1002, "project": "/foo"},
        {"sessionId": "aaa", "display": "Follow up question", "timestamp": 1003, "project": "/foo"},
        {"sessionId": "bbb", "display": "Another session", "timestamp": 2000, "project": "/bar"},
    ]
    with tempfile.NamedTemporaryFile(mode="w", suffix=".jsonl", delete=False) as f:
        for entry in history:
            f.write(json.dumps(entry) + "\n")
        tmp = Path(f.name)

    index = build_session_name_index(tmp)
    assert index["aaa"] == "Tell me about X"
    assert index["bbb"] == "Another session"
    tmp.unlink()


def test_session_name_index_falls_back_to_slash_command():
    history = [
        {"sessionId": "ccc", "display": "/init", "timestamp": 1000, "project": "/foo"},
    ]
    with tempfile.NamedTemporaryFile(mode="w", suffix=".jsonl", delete=False) as f:
        f.write(json.dumps(history[0]) + "\n")
        tmp = Path(f.name)

    index = build_session_name_index(tmp)
    assert index["ccc"] == "/init"
    tmp.unlink()


def test_session_name_index_missing_file():
    index = build_session_name_index(Path("/nonexistent/history.jsonl"))
    assert index == {}


def test_cwd_to_slug():
    assert cwd_to_slug("/Users/chris/Workspace/foo") == "-Users-chris-Workspace-foo"
    assert cwd_to_slug("/Users/chris") == "-Users-chris"


def test_get_search_dirs_project_scope(tmp_path):
    # Create a fake projects dir with a matching slug
    projects = tmp_path / "projects"
    slug = "-Users-chris-myproject"
    (projects / slug).mkdir(parents=True)

    dirs = get_search_dirs("project", "/Users/chris/myproject", projects_root=projects)
    assert len(dirs) == 1
    assert dirs[0].name == slug


def test_get_search_dirs_project_scope_fallback(tmp_path):
    # If slug not found, fall back to global
    projects = tmp_path / "projects"
    (projects / "-Users-chris-other").mkdir(parents=True)

    dirs = get_search_dirs("project", "/Users/chris/notfound", projects_root=projects)
    assert len(dirs) == 1  # falls back to global, returns the one existing dir


def test_get_search_dirs_global(tmp_path):
    projects = tmp_path / "projects"
    for name in ["-Users-a", "-Users-b", "-Users-c"]:
        (projects / name).mkdir(parents=True)

    dirs = get_search_dirs("global", "/Users/a", projects_root=projects)
    assert len(dirs) == 3


def test_extract_text_from_string():
    assert extract_text("hello world") == "hello world"


def test_extract_text_from_blocks():
    blocks = [
        {"type": "text", "text": "Hello"},
        {"type": "tool_use", "id": "x", "name": "bash"},
        {"type": "text", "text": " world"},
    ]
    assert extract_text(blocks) == "Hello world"


def test_extract_text_from_tool_only_blocks():
    blocks = [{"type": "tool_use", "id": "x", "name": "bash"}]
    assert extract_text(blocks) == ""


def test_parse_messages_basic(tmp_path):
    lines = [
        make_jsonl_line("user", "user", "Hello Claude", timestamp="2026-01-01T10:00:00", cwd="/foo"),
        make_jsonl_line("assistant", "assistant", "Hello! How can I help?", timestamp="2026-01-01T10:00:01"),
        make_jsonl_line("user", "user", "Tell me about X", timestamp="2026-01-01T10:01:00"),
    ]
    f = tmp_path / "session.jsonl"
    f.write_text("\n".join(lines) + "\n")

    msgs = parse_messages(f)
    assert len(msgs) == 3
    assert msgs[0] == {"role": "user", "text": "Hello Claude", "timestamp": "2026-01-01T10:00:00"}
    assert msgs[1]["role"] == "assistant"
    assert msgs[2]["text"] == "Tell me about X"


def test_parse_messages_skips_empty_and_malformed(tmp_path):
    lines = [
        make_jsonl_line("user", "user", ""),  # empty text
        "not valid json",  # malformed
        make_jsonl_line("user", "user", [{"type": "tool_use", "id": "x"}]),  # tool-only
        make_jsonl_line("user", "user", "Real message"),
    ]
    f = tmp_path / "session.jsonl"
    f.write_text("\n".join(lines) + "\n")

    msgs = parse_messages(f)
    assert len(msgs) == 1
    assert msgs[0]["text"] == "Real message"


def test_get_session_metadata(tmp_path):
    lines = [
        json.dumps({"type": "system", "timestamp": "2026-01-01T09:00:00", "sessionId": "abc123", "cwd": "/my/project"}),
        make_jsonl_line("user", "user", "Hello", timestamp="2026-01-01T10:00:00"),
    ]
    f = tmp_path / "abc123.jsonl"
    f.write_text("\n".join(lines) + "\n")

    meta = get_session_metadata(f)
    assert meta["session_id"] == "abc123"
    assert meta["cwd"] == "/my/project"
    assert meta["first_timestamp"] == "2026-01-01T09:00:00"
    assert meta["away_summary"] == ""


def test_get_session_metadata_away_summary(tmp_path):
    lines = [
        json.dumps({"type": "system", "timestamp": "2026-01-01T09:00:00", "cwd": "/my/project"}),
        make_jsonl_line("user", "user", "Hello", timestamp="2026-01-01T10:00:00"),
        json.dumps({"type": "system", "subtype": "away_summary", "content": "First recap", "timestamp": "2026-01-01T11:00:00"}),
        make_jsonl_line("user", "user", "More work", timestamp="2026-01-01T12:00:00"),
        json.dumps({"type": "system", "subtype": "away_summary", "content": "Full arc recap here", "timestamp": "2026-01-01T13:00:00"}),
    ]
    f = tmp_path / "recap-session.jsonl"
    f.write_text("\n".join(lines) + "\n")

    meta = get_session_metadata(f)
    # Most recent away_summary should win
    assert meta["away_summary"] == "Full arc recap here"


def test_get_match_contexts_basic():
    messages = [
        {"role": "user", "text": "unrelated one", "timestamp": "t1"},
        {"role": "assistant", "text": "response one", "timestamp": "t2"},
        {"role": "user", "text": "tell me about marketplace", "timestamp": "t3"},
        {"role": "assistant", "text": "response two", "timestamp": "t4"},
        {"role": "user", "text": "another question about marketplace", "timestamp": "t5"},
        {"role": "assistant", "text": "another response", "timestamp": "t6"},
        {"role": "user", "text": "unrelated two", "timestamp": "t7"},
    ]
    contexts = get_match_contexts(messages, ["marketplace"], context_size=1)
    assert len(contexts) == 2  # two non-overlapping matches with context_size=1
    assert contexts[0]["match"]["text"] == "tell me about marketplace"
    assert len(contexts[0]["context_before"]) == 1
    assert contexts[0]["context_before"][0]["text"] == "response one"
    assert contexts[1]["match"]["text"] == "another question about marketplace"


def test_get_match_contexts_no_duplicate_windows():
    # Two matches close together should not produce overlapping context windows
    messages = [
        {"role": "user", "text": "first match", "timestamp": "t1"},
        {"role": "assistant", "text": "second match", "timestamp": "t2"},
        {"role": "user", "text": "unrelated", "timestamp": "t3"},
    ]
    contexts = get_match_contexts(messages, ["match"], context_size=2)
    # Should return contexts but not duplicate messages
    all_match_texts = [c["match"]["text"] for c in contexts]
    assert len(all_match_texts) == len(set(all_match_texts))


def test_extract_session_data_quick(tmp_path):
    lines = []
    for i in range(10):
        role = "user" if i % 2 == 0 else "assistant"
        type_ = role
        lines.append(make_jsonl_line(type_, role, f"message {i}", timestamp=f"2026-01-01T10:0{i}:00", cwd="/foo"))
    # Add a keyword match in the middle
    lines.insert(5, make_jsonl_line("user", "user", "talking about marketplace here", timestamp="2026-01-01T10:05:30", cwd="/foo"))

    f = tmp_path / "mysession.jsonl"
    f.write_text("\n".join(lines) + "\n")

    data = extract_session_data(f, ["marketplace"], depth="quick")
    assert data is not None
    assert data["session_id"] == "mysession"
    assert data["project_dir"] == "/foo"
    assert len(data["first_exchanges"]) == 1   # quick = 1 exchange
    assert len(data["last_exchanges"]) == 1
    assert len(data["match_contexts"]) >= 1
    assert any("marketplace" in c["match"]["text"] for c in data["match_contexts"])


def test_extract_session_data_returns_none_for_no_user_messages(tmp_path):
    # Automated session with no user messages
    lines = [
        json.dumps({"type": "system", "timestamp": "t1", "sessionId": "auto", "cwd": "/foo"}),
    ]
    f = tmp_path / "auto.jsonl"
    f.write_text("\n".join(lines) + "\n")
    assert extract_session_data(f, ["anything"], depth="quick") is None


def test_codex_extract_session_data_requires_keywords_in_normalized_messages(tmp_path):
    f = tmp_path / "rollout-2026-06-15T10-00-00-019ecodex-filter.jsonl"
    f.write_text("\n".join([
        make_codex_session_meta(session_id="019ecodex-filter", cwd="/repo"),
        make_codex_message("developer", [{"type": "input_text", "text": "marketplace only here"}]),
        make_codex_message("user", [{"type": "input_text", "text": "Find session"}]),
    ]) + "\n")

    provider = CodexProvider(sessions_root=tmp_path)

    assert provider.extract_session_data(f, ["marketplace", "session"], "quick") is None


def test_codex_extract_session_data_builds_normalized_record(tmp_path):
    f = tmp_path / "rollout-2026-06-15T10-00-00-019ecodex-record.jsonl"
    f.write_text("\n".join([
        make_codex_session_meta(session_id="019ecodex-record", cwd="/repo", timestamp="2026-06-15T10:00:00.000Z"),
        make_codex_message("user", [{"type": "input_text", "text": "Find marketplace session"}], timestamp="2026-06-15T10:00:01.000Z"),
        make_codex_message("assistant", [{"type": "output_text", "text": "Found marketplace details"}], timestamp="2026-06-15T10:00:02.000Z"),
    ]) + "\n")

    provider = CodexProvider(sessions_root=tmp_path)
    data = provider.extract_session_data(f, ["marketplace"], "quick")

    assert data is not None
    assert data["agent"] == "codex"
    assert data["session_id"] == "019ecodex-record"
    assert data["project_dir"] == "/repo"
    assert data["first_timestamp"] == "2026-06-15T10:00:00.000Z"
    assert data["last_timestamp"] == "2026-06-15T10:00:02.000Z"
    assert data["match_count"] >= 1
    assert data["resume_command"] == "cd /repo && codex resume 019ecodex-record"


def test_codex_search_files_uses_rg_candidates_and_parsed_filter(tmp_path):
    good = tmp_path / "2026" / "06" / "15" / "rollout-2026-06-15T10-00-00-019egood.jsonl"
    bad = tmp_path / "2026" / "06" / "15" / "rollout-2026-06-15T10-00-00-019ebad.jsonl"
    good.parent.mkdir(parents=True)
    good.write_text("\n".join([
        make_codex_session_meta(session_id="019egood", cwd="/repo"),
        make_codex_message("user", [{"type": "input_text", "text": "marketplace proposal"}]),
    ]) + "\n")
    bad.write_text("\n".join([
        make_codex_session_meta(session_id="019ebad", cwd="/repo"),
        make_codex_message("developer", [{"type": "input_text", "text": "marketplace"}]),
        make_codex_message("user", [{"type": "input_text", "text": "proposal"}]),
    ]) + "\n")

    provider = CodexProvider(sessions_root=tmp_path)
    files = provider.search_files("global", "/repo", ["marketplace", "proposal"])

    assert files == [good]


def test_codex_project_scope_filters_by_cwd_from_jsonl(tmp_path):
    keep = tmp_path / "2026" / "06" / "15" / "rollout-2026-06-15T10-00-00-019ekeep.jsonl"
    drop = tmp_path / "2026" / "06" / "15" / "rollout-2026-06-15T10-00-00-019edrop.jsonl"
    keep.parent.mkdir(parents=True)
    keep.write_text("\n".join([
        make_codex_session_meta(session_id="019ekeep", cwd="/repo"),
        make_codex_message("user", [{"type": "input_text", "text": "marketplace"}]),
    ]) + "\n")
    drop.write_text("\n".join([
        make_codex_session_meta(session_id="019edrop", cwd="/other"),
        make_codex_message("user", [{"type": "input_text", "text": "marketplace"}]),
    ]) + "\n")

    provider = CodexProvider(sessions_root=tmp_path, state_db=tmp_path / "missing.sqlite")
    files = provider.search_files("project", "/repo", ["marketplace"])

    assert files == [keep]


def test_codex_files_by_session_ids_resolves_true_id_prefix(tmp_path):
    f = tmp_path / "2026" / "06" / "15" / "rollout-2026-06-15T10-00-00-not-the-id.jsonl"
    f.parent.mkdir(parents=True)
    f.write_text("\n".join([
        make_codex_session_meta(session_id="019ecodex-real-id", cwd="/repo"),
        make_codex_message("user", [{"type": "input_text", "text": "hello"}]),
    ]) + "\n")

    provider = CodexProvider(sessions_root=tmp_path)

    assert provider.files_by_session_ids(["019ecodex-real"]) == [f]


def test_cross_provider_session_id_prefix_rejects_ambiguity(tmp_path):
    claude_file = tmp_path / "claude" / "project" / "019eshared-claude.jsonl"
    codex_file = tmp_path / "codex" / "2026" / "06" / "15" / "rollout-2026-06-15T10-00-00-019eshared-codex.jsonl"
    claude_file.parent.mkdir(parents=True)
    codex_file.parent.mkdir(parents=True)
    claude_file.write_text(make_jsonl_line("user", "user", "hello", session_id="019eshared-claude") + "\n")
    codex_file.write_text("\n".join([
        make_codex_session_meta(session_id="019eshared-codex", cwd="/repo"),
        make_codex_message("user", [{"type": "input_text", "text": "hello"}]),
    ]) + "\n")

    claude = ClaudeProvider(projects_root=tmp_path / "claude")
    codex = CodexProvider(sessions_root=tmp_path / "codex")

    with pytest.raises(SystemExit):
        find_files_by_session_ids_across_providers([claude, codex], ["019eshared"])


def test_codex_enrich_results_uses_sqlite_title_and_updated_time(tmp_path):
    db = tmp_path / "state_5.sqlite"
    session_file = tmp_path / "2026" / "06" / "15" / "rollout-2026-06-15T10-00-00-019esql.jsonl"
    session_file.parent.mkdir(parents=True)
    session_file.write_text("\n".join([
        make_codex_session_meta(
            session_id="019esql",
            cwd="/jsonl-repo",
            timestamp="2026-06-15T10:00:00.000Z",
        ),
        make_codex_message(
            "user",
            [{"type": "input_text", "text": "marketplace"}],
            timestamp="2026-06-15T10:00:01.000Z",
        ),
    ]) + "\n")
    conn = sqlite3.connect(db)
    conn.execute("create table threads (id text, rollout_path text, cwd text, title text, created_at integer, updated_at integer, created_at_ms integer, updated_at_ms integer)")
    conn.execute(
        "insert into threads values (?, ?, ?, ?, ?, ?, ?, ?)",
        ("019esql", str(session_file), "/sqlite-repo", "marketplace-notes", 1781488800, 1781488860, 1781488800000, 1781488860000),
    )
    conn.commit()
    conn.close()

    provider = CodexProvider(sessions_root=tmp_path, state_db=db)
    data = provider.extract_session_data(session_file, ["marketplace"], "quick")
    assert data is not None
    provider.enrich_results([data])

    assert data["session_name"] == "marketplace-notes"
    assert data["project_dir"] == "/sqlite-repo"
    assert data["first_timestamp"] == "2026-06-15T02:00:00.000Z"
    assert data["last_timestamp"] == "2026-06-15T02:01:00.000Z"


def test_codex_enrich_results_uses_sqlite_second_timestamps_over_jsonl(tmp_path):
    db = tmp_path / "state_5.sqlite"
    session_file = tmp_path / "2026" / "06" / "15" / "rollout-2026-06-15T10-00-00-019eseconds.jsonl"
    session_file.parent.mkdir(parents=True)
    session_file.write_text("\n".join([
        make_codex_session_meta(
            session_id="019eseconds",
            cwd="/jsonl-repo",
            timestamp="2026-06-15T10:00:00.000Z",
        ),
        make_codex_message(
            "user",
            [{"type": "input_text", "text": "marketplace"}],
            timestamp="2026-06-15T10:00:01.000Z",
        ),
    ]) + "\n")
    conn = sqlite3.connect(db)
    conn.execute("create table threads (id text, rollout_path text, cwd text, title text, created_at integer, updated_at integer, created_at_ms integer, updated_at_ms integer)")
    conn.execute(
        "insert into threads values (?, ?, ?, ?, ?, ?, ?, ?)",
        ("019eseconds", str(session_file), "/sqlite-repo", "marketplace-notes", 1781488800, 1781488860, None, None),
    )
    conn.commit()
    conn.close()

    provider = CodexProvider(sessions_root=tmp_path, state_db=db)
    data = provider.extract_session_data(session_file, ["marketplace"], "quick")
    assert data is not None
    provider.enrich_results([data])

    assert data["project_dir"] == "/sqlite-repo"
    assert data["first_timestamp"] == "2026-06-15T02:00:00.000Z"
    assert data["last_timestamp"] == "2026-06-15T02:01:00.000Z"


def test_codex_enrich_results_falls_back_to_session_index_then_history(tmp_path):
    session_file = tmp_path / "2026" / "06" / "15" / "rollout-2026-06-15T10-00-00-019eindex.jsonl"
    session_file.parent.mkdir(parents=True)
    session_file.write_text("\n".join([
        make_codex_session_meta(session_id="019eindex", cwd="/repo"),
        make_codex_message("user", [{"type": "input_text", "text": "marketplace"}]),
    ]) + "\n")
    session_index = tmp_path / "session_index.jsonl"
    history = tmp_path / "history.jsonl"
    session_index.write_text(json.dumps({
        "id": "019eindex",
        "thread_name": "index-title",
        "updated_at": "2026-06-15T10:03:00Z",
    }) + "\n")
    history.write_text(json.dumps({
        "session_id": "019eindex",
        "text": "history-title",
        "ts": 1781517600,
    }) + "\n")

    provider = CodexProvider(
        sessions_root=tmp_path,
        state_db=tmp_path / "missing.sqlite",
        session_index_path=session_index,
        history_path=history,
    )
    data = provider.extract_session_data(session_file, ["marketplace"], "quick")
    assert data is not None
    provider.enrich_results([data])

    assert data["session_name"] == "index-title"

    session_index.write_text("")
    data = provider.extract_session_data(session_file, ["marketplace"], "quick")
    assert data is not None
    provider.enrich_results([data])

    assert data["session_name"] == "history-title"


def test_find_matching_files_returns_empty_for_empty_dirs():
    assert find_matching_files([], ["keyword"]) == []


def test_find_matching_files_finds_files(tmp_path):
    # Create a JSONL file containing the keyword
    f = tmp_path / "session.jsonl"
    f.write_text('{"type":"user","text":"hello marketplace world"}\n')
    results = find_matching_files([tmp_path], ["marketplace"])
    assert len(results) == 1
    assert results[0] == f


def test_integration_finds_real_session():
    """Smoke test against actual session history — requires rg and real ~/.claude data."""
    rc, out, err = run_script("--scope", "global", "--depth", "quick", "marketplace")
    assert rc == 0, f"Script failed: {err}"
    result = json.loads(out)
    assert isinstance(result, dict)
    assert "total_matching" in result
    sessions = result["sessions"]
    assert isinstance(sessions, list)
    # We know from manual inspection there are sessions about marketplace
    assert len(sessions) >= 1
    first = sessions[0]
    assert "session_id" in first
    assert "first_exchanges" in first
    assert "match_contexts" in first
    assert "away_summary" in first


def test_script_exits_zero_on_unmatched_keyword():
    # Use --scope project with /tmp as cwd — ~/.claude/projects/-tmp/ does not exist,
    # so get_search_dirs falls back to global but prints a warning. We just verify
    # the script exits 0 and returns a list. The unit-level "no match" case is
    # covered by test_find_matching_files_returns_empty_for_empty_dirs.
    rc, out, err = run_script(
        "--scope", "project",
        "--cwd", "/tmp",
        "--depth", "quick",
        "xq9z_no_such_keyword_xq9z",
    )
    assert rc == 0
    result = json.loads(out)
    assert isinstance(result, dict)
    assert "sessions" in result


def test_cursor_slug_dotfiles():
    assert cursor_slug("/Users/chris/.dotfiles") == "Users-chris-dotfiles"


def test_cursor_slug_github_repo():
    assert cursor_slug("/Users/chris/Repos/github.com/panoai/pano-ec") == (
        "Users-chris-Repos-github-com-panoai-pano-ec"
    )


def test_cursor_slug_worktree():
    path = "/Users/chris/Repos/github.com/panoai/pano-ec/.worktrees/RD-17319-fix"
    assert cursor_slug(path) == (
        "Users-chris-Repos-github-com-panoai-pano-ec-worktrees-RD-17319-fix"
    )


def test_cursor_transcript_parent_id_parent_file(tmp_path):
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    path = tmp_path / "agent-transcripts" / parent / f"{parent}.jsonl"
    path.parent.mkdir(parents=True)
    path.touch()
    assert cursor_transcript_parent_id(path) == parent


def test_cursor_transcript_parent_id_subagent_file(tmp_path):
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    sub = "75d8aebb-f4bc-4220-97ca-9452166d1f16"
    path = tmp_path / "agent-transcripts" / parent / "subagents" / f"{sub}.jsonl"
    path.parent.mkdir(parents=True)
    path.touch()
    assert cursor_transcript_parent_id(path) == parent


def test_cursor_parent_jsonl_parent_file(tmp_path):
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    path = tmp_path / "agent-transcripts" / parent / f"{parent}.jsonl"
    path.parent.mkdir(parents=True)
    path.touch()
    assert cursor_parent_jsonl(path) == path


def test_cursor_parent_jsonl_subagent_file(tmp_path):
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    sub = "75d8aebb-f4bc-4220-97ca-9452166d1f16"
    sub_path = tmp_path / "agent-transcripts" / parent / "subagents" / f"{sub}.jsonl"
    parent_path = tmp_path / "agent-transcripts" / parent / f"{parent}.jsonl"
    sub_path.parent.mkdir(parents=True)
    sub_path.touch()
    parent_path.touch()
    assert cursor_parent_jsonl(sub_path) == parent_path


def test_build_cursor_workspace_index_reads_folder(tmp_path):
    index_root = tmp_path / "workspaceStorage"
    ws = index_root / "abc123"
    ws.mkdir(parents=True)
    (ws / "workspace.json").write_text(
        json.dumps({"folder": "file:///Users/chris/.dotfiles"})
    )

    index = build_cursor_workspace_index(index_root)
    assert index["Users-chris-dotfiles"] == "/Users/chris/.dotfiles"


def test_cursor_workspace_storage_dirs_includes_linux(tmp_path, monkeypatch):
    monkeypatch.setenv("HOME", str(tmp_path))
    dirs = cursor_workspace_storage_dirs()
    assert tmp_path / ".config" / "Cursor" / "User" / "workspaceStorage" in dirs
    assert (
        tmp_path / "Library" / "Application Support" / "Cursor" / "User" / "workspaceStorage"
        in dirs
    )


def test_cursor_strip_user_query_tags():
    raw = "<user_query>\nFind marketplace session\n</user_query>"
    assert strip_cursor_user_query(raw) == "Find marketplace session"


def test_cursor_strip_user_query_with_surrounding_content():
    raw = (
        "<user_info>OS: darwin</user_info>\n"
        "<user_query>\nFind marketplace session\n</user_query>\n"
        "<rules>follow AGENTS.md</rules>"
    )
    assert strip_cursor_user_query(raw) == "Find marketplace session"


def test_cursor_provider_parse_messages(tmp_path):
    f = tmp_path / "session.jsonl"
    f.write_text("\n".join([
        make_cursor_message("user", "<user_query>\nFind marketplace\n</user_query>"),
        make_cursor_message("assistant", "Found marketplace details"),
        make_cursor_turn_ended(),
        make_cursor_tool_use("Read"),
    ]) + "\n")

    provider = CursorProvider(projects_root=tmp_path)
    messages = provider.parse_messages(f)

    assert len(messages) == 2
    assert messages[0]["role"] == "user"
    assert messages[0]["text"] == "Find marketplace"
    assert messages[1]["text"] == "Found marketplace details"


def test_build_resume_command_cursor():
    data = {
        "project_dir": "/Users/chris/.dotfiles",
        "session_id": "efc4a65e-6720-4793-8d9c-0d923d3a771a",
    }
    assert build_resume_command("cursor", data) == (
        "cd /Users/chris/.dotfiles && agent --resume efc4a65e-6720-4793-8d9c-0d923d3a771a"
    )


def test_cursor_extract_session_data_builds_record(tmp_path):
    slug = "Users-chris-dotfiles"
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    projects = tmp_path / "projects" / slug / "agent-transcripts" / parent
    projects.mkdir(parents=True)
    parent_file = projects / f"{parent}.jsonl"
    parent_file.write_text("\n".join([
        make_cursor_message("user", "<user_query>\nFind marketplace\n</user_query>"),
        make_cursor_message("assistant", "marketplace details here"),
    ]) + "\n")

    ws_root = tmp_path / "workspaceStorage" / "ws1"
    ws_root.mkdir(parents=True)
    (ws_root / "workspace.json").write_text(
        json.dumps({"folder": "file:///Users/chris/.dotfiles"})
    )

    provider = CursorProvider(
        projects_root=tmp_path / "projects",
        workspace_storage=ws_root.parent,
    )
    data = provider.extract_session_data(parent_file, ["marketplace"], "quick")

    assert data is not None
    assert data["agent"] == "cursor"
    assert data["session_id"] == parent
    assert data["project_dir"] == "/Users/chris/.dotfiles"
    assert data["session_name"] == "Find marketplace"
    assert data["match_source"] == "parent"
    assert data["has_custom_name"] is False
    assert data["away_summary"] is None
    assert data["match_count"] >= 1
    assert "agent --resume" in data["resume_command"]


def test_cursor_extract_session_data_subagent_only_uses_parent_name(tmp_path):
    slug = "Users-chris-dotfiles"
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    sub = "75d8aebb-f4bc-4220-97ca-9452166d1f16"
    parent_dir = tmp_path / "projects" / slug / "agent-transcripts" / parent
    parent_dir.mkdir(parents=True)
    parent_file = parent_dir / f"{parent}.jsonl"
    sub_file = parent_dir / "subagents" / f"{sub}.jsonl"
    parent_file.write_text("\n".join([
        make_cursor_message("user", "<user_query>\nParent topic about zoxide\n</user_query>"),
    ]) + "\n")
    sub_file.parent.mkdir(parents=True, exist_ok=True)
    sub_file.write_text("\n".join([
        make_cursor_message("user", "Search for marketplace in subagent task"),
    ]) + "\n")

    ws_root = tmp_path / "workspaceStorage" / "ws1"
    ws_root.mkdir(parents=True)
    (ws_root / "workspace.json").write_text(
        json.dumps({"folder": "file:///Users/chris/.dotfiles"})
    )

    provider = CursorProvider(
        projects_root=tmp_path / "projects",
        workspace_storage=ws_root.parent,
    )
    data = provider.extract_session_data(sub_file, ["marketplace"], "quick")

    assert data is not None
    assert data["match_source"] == "subagent"
    assert data["session_name"] == "Parent topic about zoxide"


def test_cursor_search_files_global_and_filter(tmp_path):
    slug = "Users-chris-dotfiles"
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    good = tmp_path / slug / "agent-transcripts" / parent / f"{parent}.jsonl"
    bad = tmp_path / slug / "agent-transcripts" / "other" / "other.jsonl"
    good.parent.mkdir(parents=True)
    bad.parent.mkdir(parents=True)
    good.write_text("\n".join([
        make_cursor_message("user", "Find marketplace proposal"),
    ]) + "\n")
    # rg finds "marketplace" in raw JSON inside tool_use; parse_messages drops it
    bad.write_text("\n".join([
        make_cursor_message("user", "Find proposal"),
        json.dumps({
            "role": "assistant",
            "message": {"content": [{"type": "tool_use", "name": "Grep", "input": {"pattern": "marketplace"}}]},
        }),
    ]) + "\n")

    provider = CursorProvider(projects_root=tmp_path)
    files = provider.search_files("global", "/Users/chris/.dotfiles", ["marketplace", "proposal"])
    assert files == [good]


def test_cursor_search_files_project_scope(tmp_path):
    slug = "Users-chris-dotfiles"
    other_slug = "Users-chris-other"
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    keep = tmp_path / slug / "agent-transcripts" / parent / f"{parent}.jsonl"
    drop = tmp_path / other_slug / "agent-transcripts" / "x" / "x.jsonl"
    keep.parent.mkdir(parents=True)
    drop.parent.mkdir(parents=True)
    keep.write_text(make_cursor_message("user", "marketplace here") + "\n")
    drop.write_text(make_cursor_message("user", "marketplace here") + "\n")

    ws_root = tmp_path / "workspaceStorage" / "ws1"
    ws_root.mkdir(parents=True)
    (ws_root / "workspace.json").write_text(
        json.dumps({"folder": "file:///Users/chris/.dotfiles"})
    )

    provider = CursorProvider(
        projects_root=tmp_path,
        workspace_storage=ws_root.parent,
    )
    files = provider.search_files("project", "/Users/chris/.dotfiles", ["marketplace"])
    assert files == [keep]


def test_cursor_search_files_project_scope_fallback(tmp_path):
    """Slug dir missing: strict cwd filter rejects unrelated --cwd paths."""
    mapped_slug = "Users-chris-dotfiles"
    other_slug = "Users-chris-other"
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    keep = tmp_path / mapped_slug / "agent-transcripts" / parent / f"{parent}.jsonl"
    drop = tmp_path / other_slug / "agent-transcripts" / "x" / "x.jsonl"
    keep.parent.mkdir(parents=True)
    drop.parent.mkdir(parents=True)
    keep.write_text(make_cursor_message("user", "marketplace here") + "\n")
    drop.write_text(make_cursor_message("user", "marketplace here") + "\n")

    ws_root = tmp_path / "workspaceStorage" / "ws1"
    ws_root.mkdir(parents=True)
    (ws_root / "workspace.json").write_text(
        json.dumps({"folder": "file:///Users/chris/.dotfiles"})
    )

    provider = CursorProvider(
        projects_root=tmp_path,
        workspace_storage=ws_root.parent,
    )
    files = provider.search_files("project", "/Users/chris/missing", ["marketplace"])
    assert files == []


def test_cursor_search_files_project_scope_fallback_two_indexed(tmp_path):
    """Unrelated cwd returns no hits even when multiple projects are indexed."""
    slug_a = "Users-chris-dotfiles"
    slug_b = "Users-chris-other"
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    a = tmp_path / slug_a / "agent-transcripts" / parent / f"{parent}.jsonl"
    b = tmp_path / slug_b / "agent-transcripts" / "x" / "x.jsonl"
    a.parent.mkdir(parents=True)
    b.parent.mkdir(parents=True)
    a.write_text(make_cursor_message("user", "marketplace here") + "\n")
    b.write_text(make_cursor_message("user", "marketplace here") + "\n")

    ws_a = tmp_path / "workspaceStorage" / "ws1"
    ws_a.mkdir(parents=True)
    (ws_a / "workspace.json").write_text(
        json.dumps({"folder": "file:///Users/chris/.dotfiles"})
    )
    ws_b = tmp_path / "workspaceStorage" / "ws2"
    ws_b.mkdir(parents=True)
    (ws_b / "workspace.json").write_text(
        json.dumps({"folder": "file:///Users/chris/other"})
    )

    provider = CursorProvider(
        projects_root=tmp_path,
        workspace_storage=ws_a.parent,
    )
    files = provider.search_files("project", "/Users/chris/unrelated", ["marketplace"])
    assert files == []


def test_cursor_search_files_project_scope_fallback_direct_path(tmp_path):
    """When cwd is absent from workspace index, match project_dir by realpath."""
    repo = tmp_path / "repo"
    repo.mkdir()
    link = tmp_path / "repo-link"
    link.symlink_to(repo)

    transcript_slug = cursor_slug(str(repo))
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    keep = tmp_path / transcript_slug / "agent-transcripts" / parent / f"{parent}.jsonl"
    keep.parent.mkdir(parents=True)
    keep.write_text(make_cursor_message("user", "marketplace here") + "\n")

    ws_root = tmp_path / "workspaceStorage" / "ws1"
    ws_root.mkdir(parents=True)
    (ws_root / "workspace.json").write_text(
        json.dumps({"folder": f"file://{repo}"})
    )

    provider = CursorProvider(
        projects_root=tmp_path,
        workspace_storage=ws_root.parent,
    )
    assert cursor_slug(str(link)) != transcript_slug
    files = provider.search_files("project", str(link), ["marketplace"])
    assert files == [keep]


def test_cursor_project_matches_cwd_uses_index_then_realpath():
    index = {"Users-chris-dotfiles": "/Users/chris/.dotfiles"}
    assert cursor_project_matches_cwd("/Users/chris/.dotfiles", "/Users/chris/.dotfiles", index)
    assert not cursor_project_matches_cwd("/Users/chris/other", "/Users/chris/.dotfiles", index)
    assert not cursor_project_matches_cwd("/Users/chris/.dotfiles", "/Users/chris/missing", {})
    assert cursor_project_matches_cwd("/Users/chris/.dotfiles", "/Users/chris/.dotfiles", {})


def test_cursor_files_by_session_ids(tmp_path):
    parent = "efc4a65e-6720-4793-8d9c-0d923d3a771a"
    sub = "75d8aebb-f4bc-4220-97ca-9452166d1f16"
    parent_path = tmp_path / "Users-chris-dotfiles" / "agent-transcripts" / parent / f"{parent}.jsonl"
    sub_path = parent_path.parent / "subagents" / f"{sub}.jsonl"
    parent_path.parent.mkdir(parents=True)
    parent_path.write_text(make_cursor_message("user", "hello") + "\n")
    sub_path.parent.mkdir(parents=True, exist_ok=True)
    sub_path.write_text(make_cursor_message("user", "subagent hello") + "\n")

    provider = CursorProvider(projects_root=tmp_path)
    assert provider.files_by_session_ids(["efc4a65e"]) == [parent_path]
