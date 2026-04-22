from pathlib import Path

from local.code_search import classify_paths, visible_search_paths
from local.commits import summarize_commits
from local.dependency_manifests import find_dependency_manifests
from local.tags import summarize_tags


def test_summarize_commits_counts_recent_history():
    rows = [
        {"created_at": "2026-04-21"},
        {"created_at": "2026-04-01"},
        {"created_at": "2025-12-01"},
    ]

    summary = summarize_commits(rows)

    assert summary["count"] == 3
    assert set(summary["windows"]) == {30, 90, 180, 365}


def test_summarize_tags_reports_latest_tag():
    summary = summarize_tags(["v1.0.0", "v1.1.0"])
    assert summary["count"] == 2
    assert summary["latest"] == "v1.1.0"


def test_find_dependency_manifests_detects_common_files(tmp_path: Path):
    (tmp_path / "pyproject.toml").write_text("[project]\nname='demo'\n")
    (tmp_path / "docs").mkdir()
    (tmp_path / "docs" / "package.json").write_text('{"name":"demo"}\n')

    manifests = find_dependency_manifests(tmp_path)

    assert tmp_path / "pyproject.toml" in manifests
    assert tmp_path / "docs" / "package.json" in manifests


def test_classify_paths_quarantines_agent_artifacts():
    paths = [
        Path("README.md"),
        Path("CLAUDE.md"),
        Path(".claude/settings.json"),
        Path("src/app.py"),
    ]

    visible, quarantined = classify_paths(paths)

    assert Path("README.md") in visible
    assert Path("src/app.py") in visible
    assert Path("CLAUDE.md") in quarantined
    assert Path(".claude/settings.json") in quarantined
    assert visible_search_paths(paths) == visible
