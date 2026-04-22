from __future__ import annotations


def markdown_bullets(lines):
    return "".join(f"- {line}\n" for line in lines)
