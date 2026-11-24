#!/usr/bin/env python3
"""Stage a pinned Pi release from the installer artifacts.

Pi's own installer only installs the latest release. The per-version artifacts
it consumes are published, so staging them here gives a pinned install while
keeping upstream's lockfile integrity.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

DEFAULT_API_BASE = "https://pi.dev/api/installer/releases"
MARKER_NAME = "managed-install.json"
PI_BINARY = "pi.cmd" if os.name == "nt" else "pi"
DEFAULT_NPM = "npm.cmd" if os.name == "nt" else "npm"
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$")
NPM_CI_ARGS = [
    "ci",
    "--ignore-scripts",
    "--omit=dev",
    "--include=optional",
    "--no-fund",
    "--no-audit",
    "--loglevel=error",
    "--progress=false",
]
REFUSE_MESSAGE = (
    "pi is installed from dotfiles-pinned releases; "
    "run script/update to move the pin, pi update cannot."
)


@dataclass(frozen=True)
class Config:
    version: str
    api_base: str
    agent_dir: Path
    npm: str
    sha256_package_json: str
    sha256_package_lock: str


def parse_version(value: str) -> str:
    if not VERSION_RE.match(value):
        raise ValueError(f"invalid managed Pi version: {value!r}")
    return value


def fetch(url: str) -> bytes:
    try:
        with urllib.request.urlopen(url, timeout=60) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"could not fetch {url}: HTTP {error.code}") from error
    except urllib.error.URLError as error:
        raise RuntimeError(f"could not fetch {url}: {error.reason}") from error


def verify_blob(data: bytes, expected_sha256: str, label: str) -> None:
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected_sha256:
        raise ValueError(
            f"{label} checksum mismatch: expected {expected_sha256}, got {actual}"
        )


def load_metadata(config: Config) -> dict:
    url = f"{config.api_base.rstrip('/')}/{config.version}"
    metadata = json.loads(fetch(url))
    if metadata.get("schemaVersion") != 1:
        raise ValueError(
            f"unsupported installer metadata schema: {metadata.get('schemaVersion')}"
        )
    reported = metadata.get("version")
    if reported != config.version:
        raise ValueError(
            f"artifact metadata reports version {reported} but the pin is {config.version}"
        )
    return metadata


def release_binary(release_dir: Path) -> Path:
    return release_dir / "node_modules" / ".bin" / PI_BINARY


def run_platform(
    command: list[str], *, check: bool = False, **kwargs: Any
) -> subprocess.CompletedProcess:
    # Windows resolves npm and the release shim through cmd rather than CreateProcess
    if os.name == "nt":
        command = ["cmd", "/c", *command]
    return subprocess.run(command, check=check, **kwargs)


def verify_release(release_dir: Path, version: str) -> None:
    binary = release_binary(release_dir)
    if not binary.exists():
        raise RuntimeError(f"managed Pi executable is missing: {binary}")
    result = run_platform([str(binary), "--version"], capture_output=True, text=True)
    installed = result.stdout.strip()
    if result.returncode != 0 or installed != version:
        detail = result.stderr.strip() or f"exit code {result.returncode}"
        raise RuntimeError(
            f"managed Pi smoke test returned {installed or detail}; expected {version}"
        )


def build_release(config: Config) -> Path:
    root = config.agent_dir / "install"
    release_dir = root / "releases" / config.version
    if release_binary(release_dir).exists():
        verify_release(release_dir, config.version)
        return release_dir

    load_metadata(config)
    staging_root = root / "staging"
    staging_root.mkdir(parents=True, exist_ok=True)
    stage = staging_root / f"update-{os.getpid()}"
    try:
        stage.mkdir()
        artifacts = {
            "package.json": (config.sha256_package_json, "package.json"),
            "package-lock.json": (config.sha256_package_lock, "package-lock.json"),
        }
        for name, (expected, label) in artifacts.items():
            url = f"{config.api_base.rstrip('/')}/{config.version}/{name}"
            digest = fetch(url)
            verify_blob(digest, expected, label)
            (stage / name).write_bytes(digest)
        run_platform([config.npm, *NPM_CI_ARGS], cwd=stage, check=True)
        verify_release(stage, config.version)
        release_dir.parent.mkdir(parents=True, exist_ok=True)
        stage.rename(release_dir)
    finally:
        shutil.rmtree(stage, ignore_errors=True)
    return release_dir


def activate(root: Path, version: str) -> None:
    root.mkdir(parents=True, exist_ok=True)
    temporary = root / f"current-version.tmp.{os.getpid()}"
    temporary.write_text(f"{version}\n", encoding="utf-8")
    os.replace(temporary, root / "current-version")


def write_marker(root: Path, entrypoint: Path) -> None:
    marker_path = root / MARKER_NAME
    if marker_path.exists():
        return
    marker = {
        "kind": "pi-managed-install",
        "schemaVersion": 1,
        "layout": "releases-v1",
        "entrypoint": {
            "type": "file" if os.name == "nt" else "symlink",
            "path": str(entrypoint),
        },
    }
    marker_path.write_text(json.dumps(marker, indent=2) + "\n", encoding="utf-8")


def prune(root: Path, keep: list[str]) -> None:
    releases = root / "releases"
    if not releases.is_dir():
        return
    for entry in releases.iterdir():
        if entry.name in keep or not VERSION_RE.match(entry.name):
            continue
        shutil.rmtree(entry, ignore_errors=True)


def current_version(root: Path) -> str | None:
    try:
        return (root / "current-version").read_text(encoding="utf-8").strip() or None
    except FileNotFoundError:
        return None


def upstream_version(api_base: str) -> str:
    try:
        metadata = json.loads(fetch(f"{api_base.rstrip('/')}/latest"))
    except (RuntimeError, json.JSONDecodeError):
        return "unknown"
    version = metadata.get("version")
    return version if isinstance(version, str) else "unknown"


def default_agent_dir() -> Path:
    configured = os.environ.get("PI_CODING_AGENT_DIR", "").strip()
    return Path(configured) if configured else Path.home() / ".pi" / "agent"


def default_entrypoint(agent_dir: Path) -> Path:
    if os.name == "nt":
        return Path.home() / "AppData" / "Local" / "Programs" / "bin" / "pi.cmd"
    return Path.home() / ".local" / "bin" / "pi"


def check_report(config: Config) -> int:
    root = config.agent_dir / "install"
    print(f"pi pin:\t{config.version}")
    print(f"pi installed:\t{current_version(root) or 'none'}")
    print(f"pi upstream:\t{upstream_version(config.api_base)}")
    return 0


def install(config: Config) -> int:
    root = config.agent_dir / "install"
    previous = current_version(root)
    release = build_release(config)
    activate(root, config.version)
    write_marker(root, default_entrypoint(config.agent_dir))
    keep = [config.version] + ([previous] if previous else [])
    prune(root, keep)
    print(f"Managed Pi {config.version} staged at {release}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--version", help="Pi release version to stage, without the v prefix"
    )
    parser.add_argument("--sha256-package-json", dest="sha256_package_json", default="")
    parser.add_argument("--sha256-package-lock", dest="sha256_package_lock", default="")
    parser.add_argument("--agent-dir", default=str(default_agent_dir()))
    parser.add_argument("--api-base", default=DEFAULT_API_BASE)
    parser.add_argument("--npm", default=DEFAULT_NPM)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Report pinned, installed, and upstream versions without changing anything",
    )
    parser.add_argument(
        "--refuse-self-update",
        action="store_true",
        help="Refuse an update with an explanatory message (selfUpdateCommand guard)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.refuse_self_update:
        print(REFUSE_MESSAGE, file=sys.stderr)
        return 2
    try:
        version = parse_version(args.version or "")
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    config = Config(
        version=version,
        api_base=args.api_base,
        agent_dir=Path(args.agent_dir),
        npm=args.npm,
        sha256_package_json=args.sha256_package_json,
        sha256_package_lock=args.sha256_package_lock,
    )
    if args.check:
        return check_report(config)
    if not config.sha256_package_json or not config.sha256_package_lock:
        print(
            "error: --sha256-package-json and --sha256-package-lock are required",
            file=sys.stderr,
        )
        return 1
    try:
        return install(config)
    except (ValueError, RuntimeError, OSError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
