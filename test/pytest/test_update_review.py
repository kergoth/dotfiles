from __future__ import annotations

import pathlib
import subprocess
import sys
from dataclasses import dataclass

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "scripts"))

from update_review.ai import dispatch_ai_review
from update_review.models import AIReviewRequest
from update_review.runner import run_review_session


class FakeConsole:
    def __init__(self) -> None:
        self.messages: list[str] = []

    def print(self, *args: object, **_kwargs: object) -> None:
        self.messages.append(" ".join(map(str, args)))


@dataclass(frozen=True)
class FakeCandidate:
    id: str
    label: str
    requires_review: bool = True


class FakePreparedReview:
    def __init__(self) -> None:
        self.full_calls = 0
        self.diff_calls = 0

    def show(self, _console: FakeConsole, *, diff_only: bool = False) -> None:
        if diff_only:
            self.diff_calls += 1
        else:
            self.full_calls += 1

    def ai_request(self) -> None:
        return None


class FakeProvider:
    name = "fake"

    def __init__(self) -> None:
        self.candidates = [FakeCandidate("one", "One"), FakeCandidate("two", "Two")]
        self.reviews: dict[str, FakePreparedReview] = {}
        self.applied: list[FakeCandidate] | None = None

    def resolve(self) -> list[FakeCandidate]:
        return self.candidates

    def review(self, candidate: FakeCandidate) -> FakePreparedReview:
        return self.reviews.setdefault(candidate.id, FakePreparedReview())

    def apply(self, approved: list[FakeCandidate]) -> list[dict[str, str]]:
        self.applied = approved
        return [{"id": candidate.id} for candidate in approved]


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


def test_finish_applies_prior_selection_and_stops_review():
    provider = FakeProvider()
    answers = iter(["a", "f"])

    result = run_review_session(
        [provider],
        input_fn=lambda _prompt: next(answers),
        console=FakeConsole(),
        ai_config={},
    )

    assert result.outcome == "finish"
    assert provider.applied == [provider.candidates[0]]
    assert provider.reviews["one"].full_calls == 1
    assert provider.reviews["two"].full_calls == 1


def test_cancel_discards_prior_selection_without_applying():
    provider = FakeProvider()
    answers = iter(["a", "c"])

    result = run_review_session(
        [provider],
        input_fn=lambda _prompt: next(answers),
        console=FakeConsole(),
        ai_config={},
    )

    assert result.outcome == "cancel"
    assert provider.applied is None


def test_session_applies_provider_when_provider_iterable_is_single_pass():
    provider = FakeProvider()
    answers = iter(["a", "s"])

    result = run_review_session(
        iter([provider]),
        input_fn=lambda _prompt: next(answers),
        console=FakeConsole(),
        ai_config={},
    )

    assert result.outcome == "complete"
    assert provider.applied == [provider.candidates[0]]


def test_dry_run_shows_enabled_reviews_without_prompting_or_applying():
    provider = FakeProvider()

    result = run_review_session(
        [provider],
        input_fn=lambda _prompt: (_ for _ in ()).throw(AssertionError("prompted")),
        console=FakeConsole(),
        ai_config={},
        dry_run=True,
    )

    assert result.outcome == "dry-run"
    assert provider.applied is None
    assert provider.reviews["one"].full_calls == 1
    assert provider.reviews["two"].full_calls == 1


def test_no_review_applies_all_without_preparing_evidence():
    provider = FakeProvider()

    result = run_review_session(
        [provider],
        input_fn=lambda _prompt: (_ for _ in ()).throw(AssertionError("prompted")),
        console=FakeConsole(),
        ai_config={},
        no_review=True,
    )

    assert result.outcome == "complete"
    assert provider.applied == provider.candidates
    assert provider.reviews == {}
