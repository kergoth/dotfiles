from __future__ import annotations

from datetime import date

from shared.time_windows import bucket_by_windows


def summarize_commits(rows):
    normalized = [{"created_at": date.fromisoformat(row["created_at"])} for row in rows]
    return {
        "count": len(normalized),
        "windows": bucket_by_windows(normalized, key="created_at"),
    }
