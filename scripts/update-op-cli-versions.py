#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import re
import sys
import urllib.request
from pathlib import Path


PRODUCT_HISTORY_URL = "https://app-updates.agilebits.com/product_history/CLI2"


def read_old_versions(path: Path) -> dict:
    """Return {platform: version} from an existing versions.yml, or {} if absent."""
    try:
        content = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return {}
    result = {}
    current_platform = None
    for line in content.splitlines():
        m = re.match(r"^\s{4}(\w+):\s*$", line)
        if m:
            current_platform = m.group(1)
            continue
        if current_platform:
            mv = re.match(r'^\s{6}version:\s*"([^"]+)"', line)
            if mv:
                result[current_platform] = mv.group(1)
                # version: always precedes sha256: in each block
                current_platform = None
    return result


def format_version_diff_lines(old_versions: dict, new_versions: dict) -> list:
    """Return one diff line per platform whose version changed."""
    lines = []
    for platform in sorted(set(old_versions) | set(new_versions)):
        old_ver = old_versions.get(platform, "")
        new_ver = new_versions.get(platform, "")
        if old_ver == new_ver:
            continue
        old_display = f"v{old_ver}" if old_ver else "(new)"
        new_display = f"v{new_ver}" if new_ver else "(removed)"
        lines.append(f"op_cli {platform}: {old_display} -> {new_display}")
    return lines


def version_key(version: str) -> tuple[int, ...]:
    """Return a tuple suitable for numeric version comparison."""
    return tuple(int(part) for part in version.split("."))


def parse_links(html: str) -> list[tuple[str, str, str, str]]:
    """Return non-beta op CLI archive links as (platform, arch, version, url)."""
    pattern = re.compile(
        r"https://cache\.agilebits\.com/dist/1P/op2/pkg/v([^/]+)/op_(linux|freebsd)_(amd64|arm64)_v\1\.zip"
    )
    found = []
    for m in pattern.finditer(html):
        ver, platform, arch = m.group(1), m.group(2), m.group(3)
        if "beta" in ver:
            continue
        found.append((platform, arch, ver, m.group(0)))
    return found


def select_latest(found: list[tuple[str, str, str, str]]) -> tuple[dict, list]:
    """Return latest link per platform+arch and stable discovery order."""
    if not found:
        raise RuntimeError("No op CLI links found (non-beta)")

    latest = {}
    order = []
    for platform, arch, ver, link in found:
        key = (platform, arch)
        if key not in latest or version_key(ver) > version_key(latest[key][0]):
            if key not in latest:
                order.append(key)
            latest[key] = (ver, link)
    return latest, order


def platform_versions(latest: dict, order: list) -> dict:
    """Return highest selected version per platform."""
    platform_version = {}
    for platform, arch in order:
        ver, _ = latest[(platform, arch)]
        if platform not in platform_version:
            platform_version[platform] = ver
            continue
        if version_key(ver) > version_key(platform_version[platform]):
            platform_version[platform] = ver
    return platform_version


def render_versions_yml(platform_version: dict, checksums: dict) -> str:
    """Render the op_cli section of versions.yml."""
    lines = []
    lines.append("versions:")
    lines.append("  op_cli:")
    for platform in ("linux", "freebsd"):
        ver = platform_version.get(platform)
        if not ver:
            continue
        lines.append(f"    {platform}:")
        lines.append(f'      version: "{ver}"')
        lines.append("      sha256:")
        for arch in sorted(checksums[platform].keys()):
            lines.append(f'        {arch}: "{checksums[platform][arch]}"')
    return "\n".join(lines) + "\n"


def update_versions(
    path: Path,
    dry_run: bool,
    urlopen=urllib.request.urlopen,
) -> list[str]:
    """Fetch latest op CLI metadata, optionally write versions.yml, return diffs."""
    old_versions = read_old_versions(path)
    html = urlopen(PRODUCT_HISTORY_URL, timeout=20).read().decode("utf-8", "ignore")
    latest, order = select_latest(parse_links(html))
    platform_version = platform_versions(latest, order)

    checksums = {"linux": {}, "freebsd": {}}
    for platform, arch in order:
        _, link = latest[(platform, arch)]
        data = urlopen(link, timeout=60).read()
        h = hashlib.sha256(data).hexdigest()
        checksums[platform][arch] = h

    if not dry_run:
        path.write_text(
            render_versions_yml(platform_version, checksums),
            encoding="utf-8",
        )

    return format_version_diff_lines(old_versions, platform_version)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", "--dry-run", action="store_true")
    args = parser.parse_args(argv)

    repo_root = Path(__file__).resolve().parent.parent
    path = repo_root / "home" / ".chezmoidata" / "versions.yml"

    try:
        diff_lines = update_versions(path, dry_run=args.dry_run)
    except RuntimeError as exc:
        print(exc, file=sys.stderr)
        return 1

    for line in diff_lines:
        print(line)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
