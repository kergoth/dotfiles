#!/bin/sh

set -eu

REPO_ROOT=$(cd "$TESTDIR/../../.." && pwd)
export REPO_ROOT

setup_review_env() {
    WORKDIR="$CRAMTMP/work"
    BINDIR="$CRAMTMP/bin"
    HOME="$CRAMTMP/home"
    PYTHON_BIN=
    for candidate in \
        /Users/kergoth/.local/bin/python3.10 \
        /Users/kergoth/.local/bin/python3.11 \
        /Users/kergoth/.local/bin/python3.12 \
        /Users/kergoth/.nix-profile/bin/python3.13 \
        "$(command -v python3.10 || true)" \
        "$(command -v python3.11 || true)" \
        "$(command -v python3.12 || true)" \
        "$(command -v python3.13 || true)" \
        "$(command -v python3 || true)"
    do
        if [ -n "$candidate" ] && [ -x "$candidate" ]; then
            PYTHON_BIN=$candidate
            break
        fi
    done
    mkdir -p "$WORKDIR" "$BINDIR" "$HOME"
    export WORKDIR BINDIR HOME PYTHON_BIN
    export UV_CACHE_DIR="$CRAMTMP/uv-cache"
    export PATH="$BINDIR:/usr/bin:/bin"
    write_fake_uv
}

write_fake_uv() {
    stub_dir="$CRAMTMP/rich-stub"
    mkdir -p "$stub_dir/rich"
    cat >"$stub_dir/rich/__init__.py" <<'PYEOF'
PYEOF
    cat >"$stub_dir/rich/console.py" <<'PYEOF'
import sys


class Console:
    def __init__(self, stderr=False):
        self._file = sys.stderr if stderr else sys.stdout

    def print(self, *args, **kwargs):
        kwargs.pop("style", None)
        kwargs.pop("highlight", None)
        print(*args, file=self._file, **kwargs)
PYEOF
    cat >"$stub_dir/rich/panel.py" <<'PYEOF'
class Panel:
    def __init__(self, renderable, title=None, subtitle=None):
        self.renderable = renderable
        self.title = title
        self.subtitle = subtitle

    def __str__(self):
        return str(self.renderable)
PYEOF
    cat >"$stub_dir/rich/syntax.py" <<'PYEOF'
class Syntax:
    def __init__(self, code, lexer, theme=None, line_numbers=False):
        self.code = code

    def __str__(self):
        return self.code
PYEOF
    cat >"$BINDIR/uv" <<'PYEOF'
#!/usr/bin/env python3
import os
import sys


def main() -> int:
    if len(sys.argv) < 3 or sys.argv[1] != "run":
        return 2

    stub_dir = os.environ["FAKE_UV_RICH_STUB"]
    python_bin = os.environ["FAKE_UV_PYTHON_BIN"]
    env = os.environ.copy()
    env["PYTHONPATH"] = (
        stub_dir
        if not env.get("PYTHONPATH")
        else stub_dir + os.pathsep + env["PYTHONPATH"]
    )
    os.execvpe(python_bin, [python_bin, *sys.argv[2:]], env)


if __name__ == "__main__":
    raise SystemExit(main())
PYEOF
    chmod +x "$BINDIR/uv"
    export FAKE_UV_RICH_STUB="$stub_dir"
    export FAKE_UV_PYTHON_BIN="$PYTHON_BIN"
}

write_fake_gh() {
    fixtures_json=$1
    cat >"$BINDIR/gh" <<'PYEOF'
#!/usr/bin/env python3
import json
import os
import sys


def main() -> int:
    if len(sys.argv) < 3 or sys.argv[1] != "api":
        return 2

    route = sys.argv[2]

    with open(os.environ["FAKE_GH_FIXTURES"], "r", encoding="utf-8") as handle:
        fixtures = json.load(handle)

    if route.startswith("repos/") and "/compare/" in route:
        print(json.dumps(fixtures.get("compare", {})))
        return 0

    if route.startswith("repos/") and "/releases?per_page=100&page=" in route:
        page = route.rsplit("page=", 1)[1]
        pages = fixtures.get("releases_pages", {})
        print(json.dumps(pages.get(page, [])))
        return 0

    if route.startswith("repos/") and "/releases/tags/" in route:
        tag = route.rsplit("/releases/tags/", 1)[1]
        by_tag = fixtures.get("releases_by_tag", {})
        if tag not in by_tag:
            return 1
        print(json.dumps(by_tag[tag]))
        return 0

    return 2


if __name__ == "__main__":
    raise SystemExit(main())
PYEOF
    chmod +x "$BINDIR/gh"
    export FAKE_GH_FIXTURES="$fixtures_json"
}

write_fake_agent() {
    capture_file=$1
    cat >"$BINDIR/agent" <<'PYEOF'
#!/usr/bin/env python3
import os
import sys

capture = os.environ["FAKE_AGENT_CAPTURE_FILE"]
prompt = sys.argv[2] if len(sys.argv) > 2 else ""
with open(capture, "w", encoding="utf-8") as handle:
    handle.write(prompt)
    handle.write("\n")
print("fake review result")
PYEOF
    chmod +x "$BINDIR/agent"
    export FAKE_AGENT_CAPTURE_FILE="$capture_file"
}

run_show_git_changes() {
    PYTHONPATH="$FAKE_UV_RICH_STUB${PYTHONPATH:+:$PYTHONPATH}" \
        "$PYTHON_BIN" "$REPO_ROOT/scripts/show-git-changes.py" \
        --ai-cmd agent "$@"
}
