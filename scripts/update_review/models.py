from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class AIReviewRequest:
    prompt: str
    preferred_agent: str | None = None
    model: str | None = None
    timeout: int | None = None


@dataclass(frozen=True)
class RunResult:
    outcome: str
    summaries: dict[str, list[dict[str, Any]]]
