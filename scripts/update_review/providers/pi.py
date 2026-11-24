from __future__ import annotations

import json
import re
import urllib.parse
import urllib.request
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from update_review.models import AIReviewRequest

DATA_PATH = Path("home/.chezmoidata/pi-extensions.yml")
SOURCE_LINE_RE = re.compile(
    r'^(?P<prefix>\s*-\s*source:\s*")(?P<source>[^"]+)(?P<suffix>")\s*$'
)
NPM_SOURCE_RE = re.compile(r"^npm:(?P<name>(?:@[^/@]+/)?[^@]+)@(?P<version>[^@]+)$")
REGISTRY_URL = "https://registry.npmjs.org/{}"


def version_key(version: str) -> tuple[int, ...]:
    parts = []
    for component in version.split("-")[0].split("."):
        digits = re.match(r"\d+", component)
        parts.append(int(digits.group()) if digits else 0)
    return tuple(parts)


def npm_latest(name: str) -> str:
    url = REGISTRY_URL.format(urllib.parse.quote(name, safe="@"))
    with urllib.request.urlopen(url, timeout=30) as response:
        payload = json.loads(response.read())
    return str(payload.get("dist-tags", {}).get("latest", ""))


@dataclass
class PiCandidate:
    id: str
    source: str
    name: str
    old_version: str
    new_version: str
    requires_review: bool = False


@dataclass
class PreparedPiReview:
    candidate: PiCandidate

    def show(self, console: Any, *, diff_only: bool = False) -> None:
        console.print(
            f"{self.candidate.name}: {self.candidate.old_version} → {self.candidate.new_version}"
        )

    def ai_request(self) -> AIReviewRequest | None:
        return None


class PiProvider:
    name = "pi"

    def __init__(
        self, repo_root: Path, fetch_latest: Callable[[str], str] | None = None
    ) -> None:
        self.repo_root = repo_root
        self.data_path = repo_root / DATA_PATH
        self.fetch_latest = fetch_latest or npm_latest

    def _sources(self) -> list[str]:
        if not self.data_path.exists():
            return []
        sources = []
        for line in self.data_path.read_text(encoding="utf-8").splitlines():
            match = SOURCE_LINE_RE.match(line)
            if match:
                sources.append(match.group("source"))
        return sources

    def resolve(self) -> list[PiCandidate]:
        candidates = []
        for source in self._sources():
            match = NPM_SOURCE_RE.match(source)
            if not match:
                continue
            name = match.group("name")
            old_version = match.group("version")
            new_version = self.fetch_latest(name)
            if not new_version or version_key(new_version) <= version_key(old_version):
                continue
            candidates.append(
                PiCandidate(
                    id=source,
                    source=source,
                    name=name,
                    old_version=old_version,
                    new_version=new_version,
                )
            )
        return candidates

    def review(self, candidate: PiCandidate) -> PreparedPiReview:
        return PreparedPiReview(candidate)

    def apply(self, approved: list[PiCandidate]) -> list[dict[str, Any]]:
        replacements = {candidate.source: candidate for candidate in approved}
        lines = self.data_path.read_text(encoding="utf-8").splitlines(keepends=True)
        for index, line in enumerate(lines):
            match = SOURCE_LINE_RE.match(line.rstrip("\n"))
            if not match or match.group("source") not in replacements:
                continue
            candidate = replacements[match.group("source")]
            lines[index] = (
                f"{match.group('prefix')}npm:{candidate.name}@{candidate.new_version}"
                f"{match.group('suffix')}\n"
            )
        self.data_path.write_text("".join(lines), encoding="utf-8")
        return [
            {
                "id": candidate.source,
                "name": candidate.name,
                "old_version": candidate.old_version,
                "new_version": candidate.new_version,
            }
            for candidate in approved
        ]
