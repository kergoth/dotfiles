from __future__ import annotations

from statistics import median


def summarize_issues(issues):
    first_response_days = [row["days_to_first_response"] for row in issues]
    return {
        "count": len(issues),
        "stale_open": sum(
            1 for row in issues if row["state"] == "open" and row["days_open"] >= 30
        ),
        "median_first_response_days": median(first_response_days),
    }
