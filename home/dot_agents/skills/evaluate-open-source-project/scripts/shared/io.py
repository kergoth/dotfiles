from __future__ import annotations

import json
from pathlib import Path


def _ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def write_json(path: Path, data) -> None:
    _ensure_parent(path)
    path.write_text(json.dumps(data, indent=2) + "\n")


def write_markdown(path: Path, text: str) -> None:
    _ensure_parent(path)
    path.write_text(text)
