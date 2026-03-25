import importlib.util
import io
import json
import pathlib
import subprocess
import sys
import types
from unittest.mock import MagicMock, patch

spec = importlib.util.spec_from_file_location(
    "update_externals_lock",
    pathlib.Path(__file__).parent.parent / "update-externals-lock.py",
)
assert spec is not None and spec.loader is not None
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

format_diff_lines = mod.format_diff_lines
resolve_latest_tag = mod.resolve_latest_tag  # add after format_diff_lines binding
_SHA_RE = mod._SHA_RE  # needed in Task 6 integration test


def test_format_diff_lines_branch_unchanged():
    """Branch entries still show 7-char SHA and ref suffix."""
    externals = {"foo": {"repo": "https://github.com/x/y", "ref": "master"}}
    result = format_diff_lines(
        {"foo": "aaa" + "0" * 37},
        {"foo": "bbb" + "0" * 37},
        externals,
        ["foo"],
    )
    assert result == ["foo: aaa0000 \u2192 bbb0000 (master)"]


def test_format_diff_lines_tagged_new():
    """Tagged new entry shows full tag name, no ref suffix."""
    externals = {"bar": {"repo": "https://github.com/x/y", "tagged": True}}
    result = format_diff_lines({}, {"bar": "v0.35.0"}, externals, ["bar"])
    assert result == ["bar: (new) \u2192 v0.35.0"]


def test_format_diff_lines_tagged_update():
    """Tagged update shows both tag names, no truncation."""
    externals = {"bar": {"repo": "https://github.com/x/y", "tagged": True}}
    result = format_diff_lines(
        {"bar": "v0.34.0"}, {"bar": "v0.35.0"}, externals, ["bar"]
    )
    assert result == ["bar: v0.34.0 \u2192 v0.35.0"]


def test_format_diff_lines_tagged_missing_externals_key():
    """Stale id not in externals defaults to branch display."""
    result = format_diff_lines(
        {"stale": "aaa" + "0" * 37},
        {"stale": "bbb" + "0" * 37},
        {},
        ["stale"],
    )
    assert result == ["stale: aaa0000 \u2192 bbb0000 (main)"]


def _run_main_dry_run_json(externals: dict, ids: list[str]) -> list:
    """Call main() directly with mocked data, return parsed JSON changes list."""
    fake_data = {"externals_sources": externals, "externals_lock": {}}
    fake_sha = "a" * 40

    captured = io.StringIO()
    with (
        patch.object(mod, "load_chezmoi_data", return_value=fake_data),
        patch.object(mod, "resolve_ref", return_value=fake_sha),
        patch.object(mod, "resolve_latest_tag", return_value="v1.0.0"),
        patch("sys.stdout", captured),
        patch("sys.argv", ["update-externals-lock.py", "--dry-run", "--json"] + ids),
    ):
        rc = mod.main()

    assert rc == 0, f"main() returned {rc}"
    return json.loads(captured.getvalue())


def test_dry_run_json_branch_has_kind():
    """Branch entries get kind=branch in JSON output."""
    externals = {
        "_test_kind": {"repo": "https://github.com/x/y", "ref": "master"},
    }
    changes = _run_main_dry_run_json(externals, ["_test_kind"])
    assert len(changes) == 1, f"expected 1 change, got {changes}"
    assert changes[0]["kind"] == "branch"


def test_dry_run_json_tag_has_kind():
    """Tagged entries get kind=tag in JSON output."""
    externals = {
        "_test_kind": {
            "repo": "https://github.com/x/y",
            "tagged": True,
        },
    }
    changes = _run_main_dry_run_json(externals, ["_test_kind"])
    assert len(changes) == 1, f"expected 1 change, got {changes}"
    assert changes[0]["kind"] == "tag"
    assert changes[0]["tag_pattern"] is None
    assert changes[0]["ref"] is None


def _gh_result(data):
    m = MagicMock()
    m.stdout = json.dumps(data)
    m.returncode = 0
    return m


def test_resolve_latest_tag_github_no_pattern():
    """GitHub repo without pattern uses releases/latest."""
    fake = _gh_result({"tag_name": "v1.2.3"})
    with patch("subprocess.run", return_value=fake) as mock_run:
        tag = resolve_latest_tag("https://github.com/owner/repo", "owner/repo", None)
    assert tag == "v1.2.3"
    call_args = mock_run.call_args[0][0]
    assert "releases/latest" in " ".join(call_args)


def test_resolve_latest_tag_github_no_releases():
    """404 from GitHub hard-fails with SystemExit."""
    import subprocess as _sp

    err = _sp.CalledProcessError(1, "gh")
    err.stderr = "404"
    with patch("subprocess.run", side_effect=err):
        try:
            resolve_latest_tag("https://github.com/owner/repo", "owner/repo", None)
            assert False, "should have raised"
        except SystemExit:
            pass


def test_resolve_latest_tag_github_with_pattern_matches():
    """With pattern, iterates releases and returns first tag name match."""
    releases = [
        {"tag_name": "v2.0.0-rc1", "draft": False, "prerelease": True},
        {"tag_name": "v1.9.0", "draft": False, "prerelease": False},
    ]
    with patch("subprocess.run", return_value=_gh_result(releases)):
        tag = resolve_latest_tag(
            "https://github.com/owner/repo", "owner/repo", r"v\d+\.\d+\.\d+-rc\d+"
        )
    assert tag == "v2.0.0-rc1"


def test_resolve_latest_tag_github_with_pattern_skips_drafts():
    """Draft releases are always skipped regardless of pattern."""
    releases = [
        {"tag_name": "v2.0.0", "draft": True, "prerelease": False},
        {"tag_name": "v1.9.0", "draft": False, "prerelease": False},
    ]
    with patch("subprocess.run", return_value=_gh_result(releases)):
        tag = resolve_latest_tag(
            "https://github.com/owner/repo", "owner/repo", r"v\d+.*"
        )
    assert tag == "v1.9.0"


def test_resolve_latest_tag_github_pattern_no_match():
    """Hard-fail when no releases match the pattern."""
    releases = [{"tag_name": "v1.0.0", "draft": False, "prerelease": False}]
    # side_effect list: first page returns releases, second page returns [] to end pagination
    with patch("subprocess.run", side_effect=[_gh_result(releases), _gh_result([])]):
        try:
            resolve_latest_tag(
                "https://github.com/owner/repo", "owner/repo", r"v2\.\d+\.\d+"
            )
            assert False, "should have raised"
        except SystemExit:
            pass


def _ls_remote_result(tags: list[str]) -> MagicMock:
    """Build a fake git ls-remote --tags result."""
    lines = []
    for tag in tags:
        lines.append(f"abc123{'0' * 34}\trefs/tags/{tag}")
        lines.append(f"def456{'0' * 34}\trefs/tags/{tag}^{{}}")  # peeled
    m = MagicMock()
    m.stdout = "\n".join(lines) + "\n"
    m.returncode = 0
    return m


def test_resolve_latest_tag_non_github_default_pattern():
    """Non-GitHub uses default vX.Y.Z pattern and returns highest semver."""
    fake = _ls_remote_result(["v1.0.0", "v1.2.0", "v1.10.0", "v0.9.9"])
    with patch("subprocess.run", return_value=fake):
        tag = resolve_latest_tag("https://gitlab.com/owner/repo", "repo", None)
    assert tag == "v1.10.0"


def test_resolve_latest_tag_non_github_custom_pattern():
    """Non-GitHub with custom pattern filters and returns highest semver match."""
    fake = _ls_remote_result(["release-1.0.0", "release-2.0.0", "nightly-2024"])
    with patch("subprocess.run", return_value=fake):
        tag = resolve_latest_tag(
            "https://gitlab.com/owner/repo", "repo", r"release-\d+\.\d+\.\d+"
        )
    assert tag == "release-2.0.0"


def test_resolve_latest_tag_non_github_non_semver_hard_fails():
    """Non-semver tags matched by custom pattern cause hard-fail."""
    fake = _ls_remote_result(["nightly-20240101", "nightly-20240201"])
    with patch("subprocess.run", return_value=fake):
        try:
            resolve_latest_tag("https://gitlab.com/owner/repo", "repo", r"nightly-\d+")
            assert False, "should have raised"
        except SystemExit:
            pass


def test_resolve_latest_tag_non_github_no_match_hard_fails():
    """No matching tags causes hard-fail."""
    fake = _ls_remote_result(["alpha-1", "alpha-2"])
    with patch("subprocess.run", return_value=fake):
        try:
            resolve_latest_tag("https://gitlab.com/owner/repo", "repo", None)
            assert False, "should have raised"
        except SystemExit:
            pass


def test_tagged_entry_routes_to_resolve_latest_tag():
    """tagged: true entries call resolve_latest_tag, not resolve_ref."""
    externals = {
        "_test_tagged": {
            "repo": "https://github.com/x/y",
            "tagged": True,
        },
    }
    fake_data = {"externals_sources": externals, "externals_lock": {}}

    captured = io.StringIO()
    with (
        patch.object(mod, "load_chezmoi_data", return_value=fake_data),
        patch.object(mod, "resolve_latest_tag", return_value="v1.0.0") as mock_tag,
        patch.object(mod, "resolve_ref") as mock_ref,
        patch("sys.stdout", captured),
        patch("sys.argv", ["update-externals-lock.py", "--dry-run", "_test_tagged"]),
    ):
        rc = mod.main()

    assert rc == 0
    mock_tag.assert_called_once_with("https://github.com/x/y", "_test_tagged", None)
    mock_ref.assert_not_called()


def test_apply_resolved_rejects_sha_for_tag_kind(tmp_path):
    """kind=tag with a SHA value causes hard-fail."""
    repo_root = pathlib.Path(__file__).parent.parent.parent
    bad_json = json.dumps(
        [
            {
                "id": "zsh_autosuggestions",
                "kind": "tag",
                "new_sha": "a" * 40,
            }
        ]
    )
    json_file = tmp_path / "changes.json"
    json_file.write_text(bad_json)
    result = subprocess.run(
        [
            "uv",
            "run",
            str(repo_root / "scripts/update-externals-lock.py"),
            "--apply-resolved",
            str(json_file),
        ],
        capture_output=True,
        text=True,
        cwd=repo_root,
    )
    assert result.returncode != 0
    assert "kind" in result.stderr or "tag" in result.stderr


def test_apply_resolved_rejects_tag_for_branch_kind(tmp_path):
    """kind=branch with a tag name value causes hard-fail."""
    repo_root = pathlib.Path(__file__).parent.parent.parent
    bad_json = json.dumps(
        [
            {
                "id": "zsh_autosuggestions",
                "kind": "branch",
                "new_sha": "v1.2.3",
            }
        ]
    )
    json_file = tmp_path / "changes.json"
    json_file.write_text(bad_json)
    result = subprocess.run(
        [
            "uv",
            "run",
            str(repo_root / "scripts/update-externals-lock.py"),
            "--apply-resolved",
            str(json_file),
        ],
        capture_output=True,
        text=True,
        cwd=repo_root,
    )
    assert result.returncode != 0
    assert "kind" in result.stderr or "branch" in result.stderr


# --- show-git-changes.py helpers ---
# show-git-changes.py depends on `rich` which is not installed in the test env.
# Inject minimal stubs so exec_module can complete without the package.
def _make_rich_stubs():
    rich = types.ModuleType("rich")
    console_mod = types.ModuleType("rich.console")
    panel_mod = types.ModuleType("rich.panel")
    syntax_mod = types.ModuleType("rich.syntax")

    class _FakeConsole:
        def __init__(self, *a, **kw):
            pass

        def print(self, *a, **kw):
            pass

    console_mod.Console = _FakeConsole
    panel_mod.Panel = object
    syntax_mod.Syntax = object
    return rich, console_mod, panel_mod, syntax_mod


_rich, _rich_console, _rich_panel, _rich_syntax = _make_rich_stubs()
_rich_stubs = {
    "rich": _rich,
    "rich.console": _rich_console,
    "rich.panel": _rich_panel,
    "rich.syntax": _rich_syntax,
}

_sgc_spec = importlib.util.spec_from_file_location(
    "show_git_changes",
    pathlib.Path(__file__).parent.parent / "show-git-changes.py",
)
assert _sgc_spec is not None and _sgc_spec.loader is not None
_sgc_mod = importlib.util.module_from_spec(_sgc_spec)
_prev_rich = {k: sys.modules.get(k) for k in _rich_stubs}
sys.modules.update(_rich_stubs)
try:
    _sgc_spec.loader.exec_module(_sgc_mod)
finally:
    for k, v in _prev_rich.items():
        if v is None:
            sys.modules.pop(k, None)
        else:
            sys.modules[k] = v


def test_display_ref_truncates_sha():
    """40-char SHAs are truncated to 7 chars."""
    assert _sgc_mod._display_ref("a" * 40) == "a" * 7


def test_display_ref_preserves_tag():
    """Tag names are returned unchanged."""
    assert _sgc_mod._display_ref("v2024.08.24") == "v2024.08.24"
