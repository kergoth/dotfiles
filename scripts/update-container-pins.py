#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


DIGEST_RE = r"[0-9a-f]{64}"


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


def resolve_digest(image: str) -> str:
    cmd = [
        "docker",
        "buildx",
        "imagetools",
        "inspect",
        image,
        "--format",
        "{{json .Manifest.Digest}}",
    ]
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    digest_value = json.loads(result.stdout.strip())
    if not isinstance(digest_value, str) or not digest_value.startswith("sha256:"):
        raise ValueError(f"unexpected digest output for {image}: {digest_value!r}")
    if not re.fullmatch(r"sha256:" + DIGEST_RE, digest_value):
        raise ValueError(f"invalid digest for {image}: {digest_value}")
    return digest_value


def dump_lock_yaml(locks: dict[str, str]) -> str:
    lines = ["container_lock:"]
    for key in sorted(locks):
        lines.append(f'  {key}: "{locks[key]}"')
    lines.append("")
    return "\n".join(lines)


def update_target_file(path: Path, kind: str, image: str, digest: str) -> tuple[str, str] | None:
    text = path.read_text(encoding="utf-8")

    if kind == "from":
        pattern = re.compile(r"(FROM\s+" + re.escape(image) + r"@sha256:)(" + DIGEST_RE + r")")
    elif kind == "arg_base_image":
        pattern = re.compile(r"(ARG\s+BASE_IMAGE=" + re.escape(image) + r"@sha256:)(" + DIGEST_RE + r")")
    else:
        raise ValueError(f"unsupported target kind: {kind}")

    match = pattern.search(text)
    if not match:
        raise ValueError(f"missing pinned reference for {image} in {path}")

    old = f"sha256:{match.group(2)}"
    if old == digest:
        return None

    updated = pattern.sub(
        lambda m: f"{m.group(1)}{digest.removeprefix('sha256:')}",
        text,
        count=1,
    )
    path.write_text(updated, encoding="utf-8")
    return old, digest


def update_all(
    repo_root: Path,
    dry_run: bool,
    resolver=resolve_digest,
    data_loader=load_chezmoi_data,
) -> tuple[list[str], list[str]]:
    data = data_loader(repo_root)
    sources = data.get("container_sources", {})
    current_lock = dict(data.get("container_lock", {}))
    targets = data.get("container_targets", [])

    if not sources:
        raise ValueError("container_sources is empty or missing")
    if not isinstance(targets, list) or not targets:
        raise ValueError("container_targets is empty or missing")

    resolved_lock = dict(current_lock)
    changes: list[str] = []
    errors: list[str] = []
    failed_sources: set[str] = set()

    for source_id, source in sources.items():
        if not isinstance(source, dict) or "image" not in source:
            raise ValueError(f"invalid source entry: {source_id}")
        image = source["image"]
        try:
            resolved_lock[source_id] = resolver(image)
        except (ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
            failed_sources.add(source_id)
            errors.append(f"{source_id} ({image}): {exc}")
    for target in targets:
        source_id = target.get("source")
        path = target.get("path")
        kind = target.get("kind")
        if not source_id or not path or not kind:
            raise ValueError(f"invalid target entry: {target}")
        if source_id not in sources:
            raise ValueError(f"target references unknown source: {source_id}")

        image = sources[source_id]["image"]
        if source_id in failed_sources:
            continue
        digest = resolved_lock[source_id]
        target_path = repo_root / path

        if dry_run:
            text = target_path.read_text(encoding="utf-8")
            if kind == "from":
                pattern = re.compile(r"FROM\s+" + re.escape(image) + r"@sha256:(" + DIGEST_RE + r")")
            elif kind == "arg_base_image":
                pattern = re.compile(
                    r"ARG\s+BASE_IMAGE=" + re.escape(image) + r"@sha256:(" + DIGEST_RE + r")"
                )
            else:
                raise ValueError(f"unsupported target kind: {kind}")
            match = pattern.search(text)
            if not match:
                raise ValueError(f"missing pinned reference for {image} in {path}")
            old = f"sha256:{match.group(1)}"
            if old != digest:
                changes.append(f"{path}: {image} {old} -> {digest}")
            continue

        result = update_target_file(target_path, kind, image, digest)
        if result is not None:
            old, new = result
            changes.append(f"{path}: {image} {old} -> {new}")

    lock_path = repo_root / "home" / ".chezmoidata" / "container-lock.yml"
    rendered_lock = dump_lock_yaml(resolved_lock)
    existing_lock_text = lock_path.read_text(encoding="utf-8") if lock_path.exists() else ""
    if not dry_run and rendered_lock != existing_lock_text:
        lock_path.write_text(rendered_lock, encoding="utf-8")

    # If lock changed but pinned files already matched previous digest, surface lock deltas too.
    for source_id in sorted(set(current_lock) | set(resolved_lock)):
        old = current_lock.get(source_id)
        new = resolved_lock.get(source_id)
        if old != new:
            source = sources.get(source_id, {})
            image = source.get("image", source_id)
            line = f"container-lock: {image} {(old or '(new)')} -> {(new or '(removed)')}"
            if line not in changes:
                changes.append(line)

    return changes, errors


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update pinned digests for test container base images"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show digest changes without writing files",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    try:
        changes, errors = update_all(repo_root, dry_run=args.dry_run)
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    for line in changes:
        print(line)
    for err in errors:
        print(f"error: {err}", file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
