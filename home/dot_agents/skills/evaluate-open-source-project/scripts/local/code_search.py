from __future__ import annotations

from pathlib import Path

UNTRUSTED_NAMES = {"CLAUDE.md", "AGENTS.md"}
UNTRUSTED_PREFIXES = (".claude", ".codex")


def classify_paths(paths):
    visible = []
    quarantined = []
    for path in paths:
        parts = path.parts
        if path.name in UNTRUSTED_NAMES or any(
            part in UNTRUSTED_PREFIXES for part in parts
        ):
            quarantined.append(path)
        else:
            visible.append(path)
    return visible, quarantined


def visible_search_paths(paths):
    visible, _ = classify_paths(paths)
    return visible
