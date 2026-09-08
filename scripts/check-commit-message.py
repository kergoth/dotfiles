#!/usr/bin/env python3
"""Check commit-message line lengths without third-party dependencies."""

import argparse
import pathlib
import re
import sys

SUMMARY_WARNING = 50
SUMMARY_ERROR = 72
BODY_WARNING = 72
BODY_ERROR = 80
URL_PATTERN = re.compile(r"https?://\S+")


def report_length(
    *,
    kind: str,
    line_number: int | None,
    length: int,
    warning_limit: int,
    error_limit: int,
) -> bool:
    location = kind if line_number is None else f"{kind} line {line_number}"
    if length > error_limit:
        print(
            f"error: {location} is {length} characters (maximum {error_limit})",
            file=sys.stderr,
        )
        return True
    if length > warning_limit:
        print(
            f"warning: {location} is {length} characters (preferred maximum {warning_limit})",
            file=sys.stderr,
        )
    return False


def check_message(message_path: pathlib.Path) -> bool:
    lines = message_path.read_text(encoding="utf-8").splitlines()
    if not lines:
        return False

    has_errors = report_length(
        kind="summary",
        line_number=None,
        length=len(lines[0]),
        warning_limit=SUMMARY_WARNING,
        error_limit=SUMMARY_ERROR,
    )
    for line_number, line in enumerate(lines[1:], start=2):
        if URL_PATTERN.search(line):
            continue
        has_errors |= report_length(
            kind="body",
            line_number=line_number,
            length=len(line),
            warning_limit=BODY_WARNING,
            error_limit=BODY_ERROR,
        )
    return has_errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("commit_message", type=pathlib.Path)
    args = parser.parse_args()
    try:
        return int(check_message(args.commit_message))
    except OSError as error:
        parser.error(str(error))


if __name__ == "__main__":
    raise SystemExit(main())
