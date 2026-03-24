#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

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


def find_stale_lock_entries(locks: dict, externals: dict) -> list[str]:
    return sorted(set(locks) - set(externals))


def main() -> int:
    parser = argparse.ArgumentParser(description="Update pinned refs for externals.")
    parser.add_argument("ids", nargs="*", help="Optional external IDs to update")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Resolve refs without writing the lock file",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output changes as JSON (requires --dry-run)",
    )
    parser.add_argument(
        "--apply-resolved",
        metavar="FILE",
        help="Write lock from pre-resolved JSON file instead of resolving",
    )
    args = parser.parse_args()

    if args.json and not args.dry_run:
        parser.error("--json requires --dry-run")

    repo_root = Path(__file__).resolve().parent.parent
    data = load_chezmoi_data(repo_root)
    externals = data.get("externals_sources", {})
    old_locks = dict(data.get("externals_lock", {}))

    if args.apply_resolved:
        try:
            with open(args.apply_resolved) as f:
                changes = json.load(f)
        except FileNotFoundError:
            print(f"error: file not found: {args.apply_resolved}", file=sys.stderr)
            return 1
        except json.JSONDecodeError as e:
            print(f"error: invalid JSON in {args.apply_resolved}: {e}", file=sys.stderr)
            return 1
        if not isinstance(changes, list):
            print(
                f"error: expected JSON array in {args.apply_resolved}", file=sys.stderr
            )
            return 1
        merged = dict(old_locks)
        try:
            for change in changes:
                merged[change["id"]] = change["new_sha"]
        except (KeyError, TypeError) as e:
            field = e.args[0] if isinstance(e, KeyError) else "id/new_sha"
            print(f"error: missing field '{field}' in JSON entry", file=sys.stderr)
            return 1
        output = repo_root / "home" / ".chezmoidata" / "externals-lock.yml"
        output.write_text(dump_yaml(merged), encoding="utf-8")
        diff_lines = format_diff_lines(
            old_locks,
            merged,
            externals,
            [c["id"] for c in changes],
        )
        for line in diff_lines:
            print(line)
        return 0

    if not externals:
        raise SystemExit("no externals data found")

    selected = args.ids or list(externals.keys())
    unknown = [eid for eid in selected if eid not in externals]
    if unknown:
        raise SystemExit(f"unknown external ids: {', '.join(sorted(unknown))}")

    stale_locks = find_stale_lock_entries(old_locks, externals)
    for eid in stale_locks:
        print(
            f"warning: lock entry lacks source entry: {eid}",
            file=sys.stderr,
        )

    new_locks = dict(old_locks)
    for eid in selected:
        entry = externals[eid]
        new_locks[eid] = resolve_ref(entry["repo"], entry.get("ref", "main"))

    if args.dry_run:
        changes = []
        for eid in selected:
            old_sha = old_locks.get(eid, "")
            new_sha = new_locks.get(eid, "")
            if old_sha != new_sha:
                entry = externals[eid]
                changes.append(
                    {
                        "id": eid,
                        "repo": entry["repo"],
                        "ref": entry.get("ref", "main"),
                        "old_sha": old_sha,
                        "new_sha": new_sha,
                        "review": entry.get("review", True),
                        "review_note": entry.get("review_note"),
                    }
                )
        if not changes:
            return 2
        if args.json:
            print(json.dumps(changes, indent=2))
        else:
            for line in format_diff_lines(old_locks, new_locks, externals, selected):
                print(line)
        return 0

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
