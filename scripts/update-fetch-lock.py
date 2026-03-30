#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import urlopen


def load_chezmoi_data(repo_root: Path) -> dict:
    cmd = [
        "chezmoi",
        "data",
        "--format",
        "json",
        "-S",
        str(repo_root / "home"),
        "-W",
        str(repo_root),
    ]
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def get_nested_value(data: dict, dotted_key: str) -> str:
    value: object = data
    for part in dotted_key.split("."):
        if not isinstance(value, dict) or part not in value:
            raise KeyError(dotted_key)
        value = value[part]
    if not isinstance(value, str):
        raise TypeError(dotted_key)
    return value


def resolve_url(data: dict, source: dict) -> str:
    url_template = source["url_template"]
    version_source = source.get("version_source")
    if not version_source:
        return url_template
    if "{version}" not in url_template and "{version_no_v}" not in url_template:
        raise ValueError("version_source requires {version} or {version_no_v} in url_template")

    version = get_nested_value(data, version_source)
    return url_template.format(
        version=version,
        version_no_v=version.removeprefix("v"),
    )


def sha256_url(url: str) -> str:
    with urlopen(url) as response:
        return hashlib.sha256(response.read()).hexdigest()


def dump_yaml(locks: dict[str, str]) -> str:
    lines = ["fetch_lock:"]
    for key in sorted(locks):
        lines.append(f'  {key}: "{locks[key]}"')
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update pinned SHA-256 values for fetched file sources."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Resolve fetch locks without writing the lock file",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    data = load_chezmoi_data(repo_root)
    sources = data.get("fetch_sources", {})
    current_lock = dict(data.get("fetch_lock", {}))
    updated_lock = dict(current_lock)

    try:
        for source_id, source in sources.items():
            url = resolve_url(data, source)
            updated_lock[source_id] = sha256_url(url)
    except (KeyError, TypeError, ValueError) as exc:
        print(f"error: invalid fetch source metadata for {exc}", file=sys.stderr)
        return 1
    except HTTPError as exc:
        print(f"error: failed to fetch {exc.url}: HTTP {exc.code}", file=sys.stderr)
        return 1
    except URLError as exc:
        print(f"error: failed to fetch source URL: {exc.reason}", file=sys.stderr)
        return 1

    rendered = dump_yaml(updated_lock)
    if args.dry_run:
        sys.stdout.write(rendered)
        return 0

    lock_path = repo_root / "home" / ".chezmoidata" / "fetch-lock.yml"
    lock_path.write_text(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
