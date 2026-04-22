from __future__ import annotations


def summarize_contributors(contributors):
    total = sum(row["commits"] for row in contributors)
    top = max(row["commits"] for row in contributors)
    return {
        "distinct_authors": len(contributors),
        "top_author_share": top / total if total else 0.0,
    }
