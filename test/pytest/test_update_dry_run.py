import os
import pathlib
import shutil
import subprocess


REPO = pathlib.Path(__file__).resolve().parents[2]


def write_executable(path: pathlib.Path, content: str) -> None:
    path.write_text(content)
    path.chmod(0o755)


def test_update_dry_run_runs_safe_previews(tmp_path):
    test_repo = tmp_path / "repo"
    fake_bin = tmp_path / "bin"
    log = tmp_path / "calls.log"

    (test_repo / "script").mkdir(parents=True)
    (test_repo / "scripts").mkdir()
    fake_bin.mkdir()
    shutil.copy2(REPO / "script" / "update", test_repo / "script" / "update")
    (test_repo / "scripts" / "update-git-lock.py").touch()

    write_executable(
        fake_bin / "chezmoi",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'chezmoi %s\\n' "$*" >>{log}
""",
    )
    write_executable(
        fake_bin / "git",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'git %s\\n' "$*" >>{log}
case "$1" in
symbolic-ref)
    exit 0
    ;;
rev-parse)
    printf 'origin/main\\n'
    ;;
rev-list)
    printf '2\\n'
    ;;
esac
""",
    )
    write_executable(
        fake_bin / "uv",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'uv %s\\n' "$*" >>{log}
case "$*" in
*update-git-lock.py*)
    exit 2
    ;;
esac
""",
    )
    write_executable(
        fake_bin / "python3",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'python3 %s\\n' "$*" >>{log}
""",
    )
    write_executable(
        fake_bin / "jj",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'jj %s\\n' "$*" >>{log}
""",
    )
    write_executable(
        fake_bin / "home-manager-switch",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'path-home-manager-switch %s\\n' "$*" >>{log}
exit 99
""",
    )
    write_executable(
        test_repo / "script" / "home-manager-switch",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'repo-home-manager-switch %s\\n' "$*" >>{log}
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{fake_bin}{os.pathsep}{env['PATH']}"

    result = subprocess.run(
        [str(test_repo / "script" / "update"), "--dry-run", "--no-review"],
        cwd=test_repo,
        env=env,
        capture_output=True,
        text=True,
    )

    calls = log.read_text() if log.exists() else ""

    assert result.returncode == 0, result.stderr
    assert "chezmoi upgrade --dry-run" in calls
    assert "git fetch" in calls
    assert "update-op-cli-versions.py --dry-run" in calls
    assert (
        "repo-home-manager-switch --dry-run --update-inputs nixpkgs nixpkgs-unstable"
        in calls
    )
    assert "path-home-manager-switch" not in calls
    assert "chezmoi apply -R" not in calls
