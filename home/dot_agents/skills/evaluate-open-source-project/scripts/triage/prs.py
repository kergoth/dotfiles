from __future__ import annotations


def summarize_prs(prs):
    external = [
        row for row in prs if row["author_association"] not in {"OWNER", "MEMBER"}
    ]
    return {
        "count": len(prs),
        "external_prs": len(external),
        "external_merged": sum(1 for row in external if row["merged"]),
        "stale_external_prs": sum(
            1 for row in external if not row["merged"] and row["days_to_review"] >= 30
        ),
    }
