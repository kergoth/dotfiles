import os
import pathlib
import subprocess


ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "script/home-manager-switch"


def write_executable(path: pathlib.Path, content: str) -> None:
    path.write_text(content)
    path.chmod(0o755)


def test_home_manager_switch_dry_run_previews_without_mutating(tmp_path):
    home = tmp_path / "home"
    home_manager = home / ".config/home-manager"
    fake_bin = tmp_path / "bin"
    log = tmp_path / "calls.log"

    home_manager.mkdir(parents=True)
    fake_bin.mkdir()
    (home_manager / "flake.nix").write_text("{ outputs = _: {}; }\n")

    write_executable(
        fake_bin / "nix",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'nix %s\\n' "$*" >>{log}
cmd=""
for arg in "$@"; do
    case "$arg" in
    build|path-info|flake)
        cmd="$arg"
        break
        ;;
    esac
done
case "$cmd" in
build)
    exit 0
    ;;
path-info)
    if [[ "$*" == *path:* ]]; then
        printf '/nix/store/after\\n'
    else
        printf '/nix/store/before\\n'
    fi
    ;;
flake)
    exit 0
    ;;
*)
    exit 0
    ;;
esac
""",
    )
    write_executable(
        fake_bin / "chezmoi",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'chezmoi %s\\n' "$*" >>{log}
""",
    )
    write_executable(
        fake_bin / "home-manager",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'home-manager %s\\n' "$*" >>{log}
""",
    )
    write_executable(
        fake_bin / "nvd",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'nvd %s\\n' "$*" >>{log}
printf 'package diff\\n'
""",
    )
    write_executable(
        fake_bin / "nix-env",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'nix-env %s\\n' "$*" >>{log}
""",
    )
    write_executable(
        fake_bin / "git",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'git %s\\n' "$*" >>{log}
""",
    )
    write_executable(
        fake_bin / "jj",
        f"""#!/usr/bin/env bash
set -euo pipefail
printf 'jj %s\\n' "$*" >>{log}
""",
    )

    env = os.environ.copy()
    env.update(
        {
            "HOME": str(home),
            "PATH": f"{fake_bin}{os.pathsep}{env['PATH']}",
            "USER": "tester",
        }
    )

    result = subprocess.run(
        [
            str(SCRIPT),
            "--dry-run",
            "--update-inputs",
            "nixpkgs nixpkgs-unstable",
            "Update Home Manager packages",
        ],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
    )

    calls = log.read_text() if log.exists() else ""

    assert result.returncode == 0, result.stderr
    assert "nvd diff /nix/store/before /nix/store/after" in calls
    assert "home-manager switch" not in calls
    assert "home-manager expire-generations" not in calls
    assert "git commit" not in calls
    assert "jj commit" not in calls
    assert "chezmoi re-add" not in calls
    assert "chezmoi apply" not in calls
    assert "nix-env --delete-generations old" not in calls
