#!/usr/bin/env python3
import hashlib
import re
import sys
import urllib.request
from pathlib import Path


def read_old_versions(path: Path) -> dict:
    """Return {platform: version} from an existing versions.yml, or {} if absent."""
    try:
        content = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return {}
    result = {}
    current_platform = None
    for line in content.splitlines():
        m = re.match(r'^\s{4}(\w+):\s*$', line)
        if m:
            current_platform = m.group(1)
            continue
        if current_platform:
            mv = re.match(r'^\s{6}version:\s*"([^"]+)"', line)
            if mv:
                result[current_platform] = mv.group(1)
                current_platform = None  # version: always precedes sha256: in each block
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
        lines.append(f"op_cli {platform}: {old_display} \u2192 {new_display}")
    return lines


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    path = repo_root / "home" / ".chezmoidata" / "versions.yml"

    old_versions = read_old_versions(path)

    url = "https://app-updates.agilebits.com/product_history/CLI2"
    html = urllib.request.urlopen(url, timeout=20).read().decode("utf-8", "ignore")

    pattern = re.compile(
        r"https://cache\.agilebits\.com/dist/1P/op2/pkg/v([^/]+)/op_(linux|freebsd)_(amd64|arm64)_v\1\.zip"
    )
    found = []
    for m in pattern.finditer(html):
        ver, platform, arch = m.group(1), m.group(2), m.group(3)
        if "beta" in ver:
            continue
        found.append((platform, arch, ver, m.group(0)))

    if not found:
        print("No op CLI links found (non-beta)", file=sys.stderr)
        return 1

    # Pick the highest version per platform+arch by comparing version tuples,
    # not by page order (which is unreliable and caused version flip-flopping).
    def version_key(v: str) -> tuple:
        return tuple(int(x) for x in v.split("."))

    latest = {}
    order = []
    for platform, arch, ver, link in found:
        key = (platform, arch)
        if key not in latest or version_key(ver) > version_key(latest[key][0]):
            if key not in latest:
                order.append(key)
            latest[key] = (ver, link)

    platform_version = {}
    for platform, arch in order:
        ver, _ = latest[(platform, arch)]
        platform_version.setdefault(platform, ver)

    checksums = {"linux": {}, "freebsd": {}}
    for platform, arch in order:
        ver, link = latest[(platform, arch)]
        data = urllib.request.urlopen(link, timeout=60).read()
        h = hashlib.sha256(data).hexdigest()
        checksums[platform][arch] = h

    lines = []
    lines.append("versions:")
    lines.append("  op_cli:")
    for platform in ("linux", "freebsd"):
        ver = platform_version.get(platform)
        if not ver:
            continue
        lines.append(f"    {platform}:")
        lines.append(f"      version: \"{ver}\"")
        lines.append("      sha256:")
        for arch in sorted(checksums[platform].keys()):
            lines.append(f"        {arch}: \"{checksums[platform][arch]}\"")

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    diff_lines = format_version_diff_lines(old_versions, platform_version)
    for line in diff_lines:
        print(line)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
