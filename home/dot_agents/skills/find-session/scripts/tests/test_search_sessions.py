import json
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).parent.parent / "search_sessions.py"

# Import module directly for unit tests
sys.path.insert(0, str(SCRIPT.parent))
from search_sessions import (
    build_session_name_index,
    cwd_to_slug,
    extract_text,
    extract_session_data,
    find_matching_files,
    get_match_contexts,
    get_search_dirs,
    get_session_metadata,
    parse_messages,
)


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
