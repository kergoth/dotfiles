#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


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


_SHA_RE = re.compile(r"^[0-9a-f]{40}$")


def _is_github_repo(url: str) -> bool:
    return urlparse(url).hostname == "github.com"


def _github_owner_repo(url: str) -> str:
    parts = urlparse(url).path.strip("/").removesuffix(".git").split("/")
    if len(parts) < 2:
        raise ValueError(f"cannot parse GitHub owner/repo from {url!r}")
    return f"{parts[0]}/{parts[1]}"


def _gh_api(path: str) -> Any:
    result = subprocess.run(
        ["gh", "api", path],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def resolve_latest_tag(
    repo: str, name: str, tag_pattern: str | None, tag_source: str | None = None
) -> str:
    """Return the latest pinned tag according to the requested source."""
    if tag_source is None:
        tag_source = "github_releases" if _is_github_repo(repo) else "git_tags"

    if tag_source == "github_releases":
        if not _is_github_repo(repo):
            raise SystemExit(
                f"error: tag_source 'github_releases' is only valid for GitHub repos ({name!r})"
            )
        return _resolve_github_tag(repo, name, tag_pattern)
    if tag_source == "git_tags":
        return _resolve_generic_tag(repo, name, tag_pattern)
    raise SystemExit(
        f"error: invalid tag_source {tag_source!r} for {name!r} "
        "(expected 'github_releases' or 'git_tags')"
    )


def _resolve_github_tag(repo: str, name: str, tag_pattern: str | None) -> str:
    owner_repo = _github_owner_repo(repo)
    try:
        if tag_pattern is None:
            data = _gh_api(f"repos/{owner_repo}/releases/latest")
            return data["tag_name"]

        pattern = re.compile(tag_pattern)  # already validated at startup
        page = 1
        while True:
            releases = _gh_api(f"repos/{owner_repo}/releases?per_page=100&page={page}")
            if not releases:
                raise SystemExit(
                    f"error: no releases matching {tag_pattern!r} for {name!r}"
                )
            for release in releases:
                if release.get("draft"):
                    continue
                if pattern.fullmatch(release["tag_name"]):
                    return release["tag_name"]
            page += 1
    except subprocess.CalledProcessError as exc:
        stderr = (exc.stderr or "").strip()
        if "404" in stderr or exc.returncode == 1:
            raise SystemExit(
                f"error: no releases found for {name!r} — is 'tagged: true' correct?"
            ) from exc
        if "401" in stderr or "403" in stderr:
            raise SystemExit(
                "error: gh CLI not authenticated — run 'gh auth login'"
            ) from exc
        raise SystemExit(f"error: gh API failed for {name}: {stderr}") from exc
    except FileNotFoundError:
        raise SystemExit(
            "error: gh CLI not found — required for tagged GitHub externals"
        )


def _semver_key(tag: str, name: str) -> tuple[int, int, int]:
    """Parse tag as semver for sorting. Hard-fail if not parseable."""
    s = tag.lstrip("v")
    m = re.search(r"(\d+)\.(\d+)\.(\d+)", s)
    if not m:
        raise SystemExit(
            f"error: tag {tag!r} for {name!r} is not semver-parseable — "
            "non-GitHub repos require semver-orderable tags"
        )
    return int(m.group(1)), int(m.group(2)), int(m.group(3))


def _resolve_generic_tag(repo: str, name: str, tag_pattern: str | None) -> str:
    clone_url = repo if repo.endswith(".git") else f"{repo}.git"
    result = subprocess.run(
        ["git", "ls-remote", "--tags", clone_url],
        check=True,
        capture_output=True,
        text=True,
    )
    pattern = re.compile(tag_pattern or r"v?\d+\.\d+\.\d+")
    tag_names = []
    for line in result.stdout.splitlines():
        if "\t" not in line:
            continue
        _, ref = line.split("\t", 1)
        if ref.endswith("^{}"):
            continue  # annotated-tag peel artifact — skip
        tag_name = ref.removeprefix("refs/tags/")
        if pattern.fullmatch(tag_name):
            tag_names.append(tag_name)

    if not tag_names:
        pattern_desc = repr(tag_pattern) if tag_pattern else "default semver pattern"
        raise SystemExit(f"error: no tags matching {pattern_desc} for {name!r}")

    return max(tag_names, key=lambda t: _semver_key(t, name))


def dump_yaml(locks: dict) -> str:
    lines = ["git_lock:"]
    for key in sorted(locks):
        lines.append(f'  {key}: "{locks[key]}"')
    lines.append("")
    return "\n".join(lines)


def format_diff_lines(
    old_locks: dict, new_locks: dict, sources: dict, selected: list
) -> list:
    """Return one diff line per changed or new entry in `selected`."""
    lines = []
    for eid in selected:
        old_sha = old_locks.get(eid, "")
        new_sha = new_locks.get(eid, "")
        if old_sha == new_sha:
            continue
        entry = sources.get(eid, {})
        if entry.get("tagged"):
            old_display = old_sha if old_sha else "(new)"
            new_display = new_sha if new_sha else "(removed)"
            lines.append(f"{eid}: {old_display} \u2192 {new_display}")
        else:
            ref = entry.get("ref", "main")
            old_display = old_sha[:7] if old_sha else "(new)"
            new_display = new_sha[:7] if new_sha else "(removed)"
            lines.append(f"{eid}: {old_display} \u2192 {new_display} ({ref})")
    return lines


def find_stale_lock_entries(locks: dict, sources: dict) -> list[str]:
    return sorted(set(locks) - set(sources))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update pinned refs for Git sources."
    )
    parser.add_argument("ids", nargs="*", help="Optional Git source IDs to update")
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
    sources = data.get("git_sources", {})
    old_locks = dict(data.get("git_lock", {}))

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
        # Validate kind/value consistency
        for change in changes:
            kind = change.get("kind", "branch")
            value = change.get("new_sha", "")
            is_sha = bool(_SHA_RE.fullmatch(value))
            if kind == "tag" and is_sha:
                print(
                    f"error: entry '{change['id']}' has kind=tag "
                    f"but value looks like a SHA — aborting",
                    file=sys.stderr,
                )
                return 1
            if kind == "branch" and value and not is_sha:
                print(
                    f"error: entry '{change['id']}' has kind=branch "
                    f"but value {value!r} is not a SHA — aborting",
                    file=sys.stderr,
                )
                return 1
        output = repo_root / "home" / ".chezmoidata" / "git-lock.yml"
        output.write_text(dump_yaml(merged), encoding="utf-8")
        diff_lines = format_diff_lines(
            old_locks,
            merged,
            sources,
            [c["id"] for c in changes],
        )
        for line in diff_lines:
            print(line)
        return 0

    if not sources:
        raise SystemExit("no git sources data found")

    selected = args.ids or list(sources.keys())
    unknown = [eid for eid in selected if eid not in sources]
    if unknown:
        raise SystemExit(f"unknown git source ids: {', '.join(sorted(unknown))}")

    stale_locks = find_stale_lock_entries(old_locks, sources)
    for eid in stale_locks:
        print(
            f"warning: lock entry lacks source entry: {eid}",
            file=sys.stderr,
        )

    # Validate tag_pattern regexes upfront before any network calls
    for eid in selected:
        entry = sources[eid]
        if entry.get("tagged") and entry.get("ref"):
            print(
                f"warning: {eid!r} has both 'tagged: true' and 'ref' — "
                "ref is ignored for tagged entries",
                file=sys.stderr,
            )
        pattern = entry.get("tag_pattern")
        if pattern:
            try:
                re.compile(pattern)
            except re.error as exc:
                raise SystemExit(f"error: invalid tag_pattern for {eid!r}: {exc}")
        tag_source = entry.get("tag_source")
        if tag_source and tag_source not in {"github_releases", "git_tags"}:
            raise SystemExit(
                f"error: invalid tag_source for {eid!r}: {tag_source!r}"
            )
        if (
            tag_source == "github_releases"
            and not _is_github_repo(entry["repo"])
        ):
            raise SystemExit(
                f"error: tag_source 'github_releases' is only valid for GitHub repos ({eid!r})"
            )

    new_locks = dict(old_locks)
    for eid in selected:
        entry = sources[eid]
        if entry.get("tagged"):
            new_locks[eid] = resolve_latest_tag(
                entry["repo"], eid, entry.get("tag_pattern"), entry.get("tag_source")
            )
        else:
            new_locks[eid] = resolve_ref(entry["repo"], entry.get("ref", "main"))

    if args.dry_run:
        changes = []
        for eid in selected:
            old_sha = old_locks.get(eid, "")
            new_sha = new_locks.get(eid, "")
            if old_sha != new_sha:
                entry = sources[eid]
                changes.append(
                    {
                        "id": eid,
                        "kind": "tag" if entry.get("tagged") else "branch",
                        "repo": entry["repo"],
                        "ref": entry.get("ref"),
                        "tag_pattern": entry.get("tag_pattern"),
                        "tag_source": entry.get("tag_source"),
                        "old_sha": old_sha,
                        "new_sha": new_sha,
                        "review": entry.get("review", True),
                        "review_note": entry.get("review_note"),
                        "review_paths": entry.get("review_paths"),
                    }
                )
        if not changes:
            return 2
        if args.json:
            print(json.dumps(changes, indent=2))
        else:
            for line in format_diff_lines(old_locks, new_locks, sources, selected):
                print(line)
        return 0

    diff_lines = format_diff_lines(old_locks, new_locks, sources, selected)
    for line in diff_lines:
        print(line)

    output = repo_root / "home" / ".chezmoidata" / "git-lock.yml"
    if new_locks != old_locks:
        output.write_text(dump_yaml(new_locks), encoding="utf-8")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as exc:
        print(exc.stderr or str(exc), file=sys.stderr, end="")
        raise
