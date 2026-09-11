from __future__ import annotations

import json
import subprocess
import os
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass
class PreparedGitReview:
    provider: "GitProvider"
    candidate: "GitCandidate"
    output: str | None = None

    def show(self, console: Any, *, diff_only: bool = False) -> None:
        if self.output is None:
            change = self.candidate.state
            ref = change["new_sha"] if change.get("kind") == "tag" else change.get("ref") or "main"
            command = [
                "uv", "run", str(self.provider.repo_root / "scripts" / "show-git-changes.py"),
                change["repo"], change["old_sha"], change["new_sha"], "--name", change["id"], "--ref", ref, "--diff", "--no-ai",
            ]
            self.output = subprocess.run(command, check=True, capture_output=True, text=True).stdout
        console.print(self.output)

    def ai_request(self) -> None:
        return None


@dataclass(frozen=True)
class GitCandidate:
    id: str
    label: str
    state: dict[str, Any]
    requires_review: bool = True


class GitProvider:
    name = "git"

    def __init__(self, repo_root: Path) -> None:
        self.repo_root = repo_root
        self.resolution: dict[str, Any] = {"changes": [], "ai_review": {}}

    @property
    def ai_config(self) -> dict[str, Any]:
        return self.resolution.get("ai_review", {})

    def candidate_for(self, change: dict[str, Any]) -> GitCandidate:
        return GitCandidate(
            id=change["id"],
            label=change["id"],
            state=change,
            requires_review=change.get("review", True),
        )

    def resolve(self) -> list[GitCandidate]:
        result = subprocess.run(
            ["uv", "run", str(self.repo_root / "scripts" / "update-git-lock.py"), "--dry-run", "--json"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode == 2:
            self.resolution = {"changes": [], "ai_review": {}}
            return []
        result.check_returncode()
        self.resolution = json.loads(result.stdout)
        return [self.candidate_for(change) for change in self.resolution["changes"]]

    def review(self, candidate: GitCandidate) -> PreparedGitReview:
        return PreparedGitReview(self, candidate)

    def apply(self, approved: list[GitCandidate]) -> list[dict[str, Any]]:
        changes = [candidate.state for candidate in approved]
        payload = {**self.resolution, "changes": changes}
        descriptor, path = tempfile.mkstemp(suffix=".json")
        try:
            with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
                json.dump(payload, handle)
            subprocess.run(
                [
                    "uv",
                    "run",
                    str(self.repo_root / "scripts" / "update-git-lock.py"),
                    "--apply-resolved",
                    path,
                ],
                check=True,
            )
        finally:
            Path(path).unlink(missing_ok=True)
        return [
            {
                "id": change["id"],
                "old_sha": change["old_sha"],
                "new_sha": change["new_sha"],
                "kind": change.get("kind", "branch"),
                "ref": change.get("ref"),
                "tag_pattern": change.get("tag_pattern"),
            }
            for change in changes
        ]
