#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from pathlib import Path


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


def resolve_github_head(repo: str, ref: str) -> str:
    cmd = ["git", "ls-remote", f"https://github.com/{repo}.git", f"refs/heads/{ref}"]
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    line = result.stdout.strip()
    if not line:
        raise ValueError(f"unable to resolve ref {ref!r} for {repo}")
    return line.split()[0]


def dump_yaml(locks: dict) -> str:
    lines = ["externals_lock:"]
    for key in sorted(locks):
        lines.append(f'  {key}: "{locks[key]}"')
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Update pinned refs for externals.")
    parser.add_argument("ids", nargs="*", help="Optional external IDs to update")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    data = load_chezmoi_data(repo_root)
    externals = data.get("externals_sources", {})
    if not externals:
        raise SystemExit("no externals data found")

    selected = args.ids or list(externals.keys())
    unknown = [eid for eid in selected if eid not in externals]
    if unknown:
        raise SystemExit(f"unknown external ids: {', '.join(sorted(unknown))}")

    locks = dict(data.get("externals_lock", {}))
    for eid in selected:
        entry = externals[eid]
        locks[eid] = resolve_github_head(entry["repo"], entry.get("ref", "main"))

    output = repo_root / "home" / ".chezmoidata" / "externals-lock.yml"
    output.write_text(dump_yaml(locks), encoding="utf-8")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as exc:
        print(exc.stderr or str(exc), file=sys.stderr, end="")
        raise
