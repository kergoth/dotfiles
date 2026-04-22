from datetime import date
from pathlib import Path

from shared.formatting import markdown_bullets
from shared.io import write_json, write_markdown
from shared.time_windows import bucket_by_windows, cutoff_date


def test_cutoff_date_uses_explicit_today():
    assert cutoff_date(30, today=date(2026, 4, 22)) == date(2026, 3, 23)


def test_bucket_by_windows_counts_items_in_each_window():
    rows = [
        {"created_at": date(2026, 4, 20)},
        {"created_at": date(2026, 3, 25)},
        {"created_at": date(2025, 12, 1)},
    ]

    counts = bucket_by_windows(rows, key="created_at", today=date(2026, 4, 22))

    assert counts[30] == 2
    assert counts[90] == 2
    assert counts[180] == 3
    assert counts[365] == 3


def test_markdown_and_json_writers_create_parent_dirs(tmp_path: Path):
    json_path = tmp_path / "artifacts" / "summary.json"
    md_path = tmp_path / "artifacts" / "summary.md"

    write_json(json_path, {"name": "demo"})
    write_markdown(md_path, markdown_bullets(["one", "two"]))

    assert json_path.read_text() == '{\n  "name": "demo"\n}\n'
    assert md_path.read_text() == "- one\n- two\n"
