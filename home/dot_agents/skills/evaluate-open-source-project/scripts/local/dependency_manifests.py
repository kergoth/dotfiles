from __future__ import annotations

from pathlib import Path

MANIFEST_NAMES = {
    "pyproject.toml",
    "requirements.txt",
    "package.json",
    "Cargo.toml",
    "go.mod",
}


def find_dependency_manifests(root: Path):
    return sorted(
        path
        for path in root.rglob("*")
        if path.is_file() and path.name in MANIFEST_NAMES
    )
