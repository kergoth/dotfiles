from __future__ import annotations

import pathlib
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "scripts"))

from update_review.ai import dispatch_ai_review
from update_review.models import AIReviewRequest


class FakeConsole:
    def __init__(self) -> None:
        self.messages: list[str] = []

    def print(self, *args: object, **_kwargs: object) -> None:
        self.messages.append(" ".join(map(str, args)))


def test_ai_dispatch_uses_configured_fallback_after_empty_preferred(monkeypatch):
    calls: list[str] = []

    def fake_run(command: list[str], **_kwargs: object) -> subprocess.CompletedProcess[str]:
        calls.append(command[0])
        output = "summary" if command[0] == "codex" else ""
        return subprocess.CompletedProcess(command, 0, output)

    monkeypatch.setattr("update_review.ai.subprocess.run", fake_run)
    monkeypatch.setattr("update_review.ai.shutil.which", lambda _agent: "/fake/bin")

    result = dispatch_ai_review(
        AIReviewRequest(prompt="review evidence", preferred_agent="claude"),
        {"fallback_chain": ["claude", "codex"]},
        FakeConsole(),
    )

    assert result == "summary"
    assert calls == ["claude", "codex"]


def test_ai_dispatch_returns_none_when_no_agent_is_available():
    result = dispatch_ai_review(
        AIReviewRequest(prompt="review evidence"),
        {"fallback_chain": []},
        FakeConsole(),
    )

    assert result is None
