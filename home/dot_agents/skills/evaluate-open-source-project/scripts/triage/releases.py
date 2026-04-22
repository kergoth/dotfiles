from __future__ import annotations

from datetime import date


def summarize_releases(releases, *, today: date):
    latest = max(row["published_at"] for row in releases)
    return {
        "count": len(releases),
        "days_since_latest": (today - latest).days,
    }
