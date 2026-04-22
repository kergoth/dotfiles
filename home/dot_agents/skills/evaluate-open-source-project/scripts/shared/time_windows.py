from __future__ import annotations

from datetime import date, timedelta

WINDOWS = (30, 90, 180, 365)


def cutoff_date(days: int, *, today: date | None = None) -> date:
    anchor = today or date.today()
    return anchor - timedelta(days=days)


def _calendar_aligned_cutoff(window: int, *, today: date) -> date:
    if window == 90:
        month = today.month - 2
        year = today.year
        while month <= 0:
            month += 12
            year -= 1
        rolling_quarter_start = today.replace(year=year, month=month, day=1)
        return max(cutoff_date(window, today=today), rolling_quarter_start)
    if window == 30:
        return max(cutoff_date(window, today=today), today.replace(day=1))
    if window == 180:
        return max(cutoff_date(window, today=today), today.replace(month=1, day=1))
    return cutoff_date(window, today=today)


def bucket_by_windows(rows, *, key: str, today: date | None = None):
    anchor = today or date.today()
    counts = {window: 0 for window in WINDOWS}
    for row in rows:
        created_at = row[key]
        for window in WINDOWS:
            if created_at >= _calendar_aligned_cutoff(window, today=anchor):
                counts[window] += 1
    return counts
