from __future__ import annotations

import json
import os
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from update_review.models import AIReviewRequest


@dataclass
class PreparedGitReview:
    provider: GitProvider
    candidate: GitCandidate
    _summary: str | None = None
    _diff: str | None = None
    _data: dict[str, Any] | None = None

    def _base_command(self) -> list[str]:
        change = self.candidate.state
        ref = (
            change["new_sha"]
            if change.get("kind") == "tag"
            else change.get("ref") or "main"
        )
        cmd = [
            "uv", "run",
            str(self.provider.repo_root / "scripts" / "show-git-changes.py"),
            change["repo"], change["old_sha"], change["new_sha"],
            "--name", change["id"], "--ref", ref,
        ]
        if change.get("kind"):
            cmd += ["--kind", change["kind"]]
        if change.get("tag_pattern"):
            cmd += ["--tag-pattern", change["tag_pattern"]]
        if change.get("review_note"):
            cmd += ["--review-note", change["review_note"]]
        for path in change.get("review_paths") or []:
            cmd += ["--review-paths", path]
        for entry in change.get("usage") or []:
            cmd += ["--usage", json.dumps(entry)]
        return cmd

    def _run_show(self, *extra: str) -> str:
        command = self._base_command() + ["--no-ai", *extra]
        return subprocess.run(
            command, check=True, capture_output=True, text=True
        ).stdout

    def _fetch_data(self) -> dict[str, Any]:
        if self._data is None:
            descriptor, path = tempfile.mkstemp(suffix=".json")
            os.close(descriptor)
            try:
                command = self._base_command() + ["--output-json", path]
                subprocess.run(command, check=True, capture_output=True, text=True)
                self._data = json.loads(Path(path).read_text(encoding="utf-8"))
            finally:
                Path(path).unlink(missing_ok=True)
        return self._data

    def show(self, console: Any, *, diff_only: bool = False) -> None:
        if diff_only:
            if self._diff is None:
                self._diff = self._run_show("--diff-only")
            console.print(self._diff)
        else:
            if self._summary is None:
                self._summary = self._run_show()
            console.print(self._summary)

    def ai_request(self) -> AIReviewRequest | None:
        try:
            data = self._fetch_data()
        except (subprocess.CalledProcessError, OSError):
            return None
        prompt = data.get("prompt", "")
        if not prompt:
            return None
        change = self.candidate.state
        return AIReviewRequest(
            prompt=prompt,
            preferred_agent=change.get("ai_agent"),
            model=change.get("ai_model"),
            timeout=change.get("ai_timeout"),
        )


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
            [
                "uv",
                "run",
                str(self.repo_root / "scripts" / "update-git-lock.py"),
                "--dry-run",
                "--json",
            ],
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
