from __future__ import annotations

from datetime import date, timedelta

WINDOWS = (30, 90, 180, 365)


def cutoff_date(days: int, *, today: date | None = None) -> date:
    anchor = today or date.today()
    return anchor - timedelta(days=days)


def bucket_by_windows(rows, *, key: str, today: date | None = None):
    anchor = today or date.today()
    counts = {window: 0 for window in WINDOWS}
    for row in rows:
        created_at = row[key]
        for window in WINDOWS:
            if created_at >= cutoff_date(window, today=anchor):
                counts[window] += 1
    return counts
