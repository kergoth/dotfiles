#!/usr/bin/env python3
import hashlib
import re
import sys
import urllib.request


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: update-op-cli-versions.py <versions.yml>", file=sys.stderr)
        return 1

    path = sys.argv[1]
    url = "https://app-updates.agilebits.com/product_history/CLI2"
    html = urllib.request.urlopen(url, timeout=20).read().decode("utf-8", "ignore")

    pattern = re.compile(
        r"https://cache\.agilebits\.com/dist/1P/op2/pkg/v([^/]+)/op_(linux|freebsd)_([a-z0-9]+)_v\\1\\.zip"
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

    # Newest first in HTML; take first per platform+arch.
    latest = {}
    order = []
    for platform, arch, ver, link in found:
        key = (platform, arch)
        if key not in latest:
            latest[key] = (ver, link)
            order.append(key)

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

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
