from __future__ import annotations


def summarize_tags(tags):
    ordered = sorted(tags)
    return {
        "count": len(ordered),
        "latest": ordered[-1] if ordered else None,
    }
