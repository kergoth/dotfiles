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


def resolve_ref(repo: str, ref: str) -> str:
    cmd = ["git", "ls-remote", f"{repo}.git", f"refs/heads/{ref}"]
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


def format_diff_lines(
    old_locks: dict, new_locks: dict, externals: dict, selected: list
) -> list:
    """Return one diff line per changed or new entry in `selected`."""
    lines = []
    for eid in selected:
        old_sha = old_locks.get(eid, "")
        new_sha = new_locks.get(eid, "")
        if old_sha == new_sha:
            continue
        ref = externals[eid].get("ref", "main")
        old_display = old_sha[:7] if old_sha else "(new)"
        new_display = new_sha[:7] if new_sha else "(removed)"
        lines.append(f"{eid}: {old_display} \u2192 {new_display} ({ref})")
    return lines


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

    old_locks = dict(data.get("externals_lock", {}))
    new_locks = dict(old_locks)
    for eid in selected:
        entry = externals[eid]
        new_locks[eid] = resolve_ref(entry["repo"], entry.get("ref", "main"))

    diff_lines = format_diff_lines(old_locks, new_locks, externals, selected)
    for line in diff_lines:
        print(line)

    output = repo_root / "home" / ".chezmoidata" / "externals-lock.yml"
    if new_locks != old_locks:
        output.write_text(dump_yaml(new_locks), encoding="utf-8")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as exc:
        print(exc.stderr or str(exc), file=sys.stderr, end="")
        raise
