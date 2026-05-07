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


def test_powershell_update_dry_run_previews_non_external_steps(tmp_path):
    if shutil.which("pwsh") is None:
        return

    test_repo = tmp_path / "repo"
    fake_bin = tmp_path / "bin"
    log = tmp_path / "calls.log"
    home = tmp_path / "home"

    (test_repo / "script").mkdir(parents=True)
    (test_repo / "scripts").mkdir()
    (test_repo / "home" / "dot_config" / "home-manager").mkdir(parents=True)
    (test_repo / ".git").mkdir()
    (home / ".config" / "home-manager").mkdir(parents=True)
    fake_bin.mkdir()
    shutil.copy2(REPO / "script" / "update.ps1", test_repo / "script" / "update.ps1")
    (test_repo / "scripts" / "update-git-lock.py").touch()
    (home / ".config" / "home-manager" / "flake.nix").write_text("{}")

    def write_pwsh_command(name: str, body: str) -> None:
        write_executable(
            fake_bin / name,
            f"""#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
$argsText = $args -join " "
Add-Content -Path '{log}' -Value "{name} $argsText"
{body}
""",
        )

    write_pwsh_command("chezmoi", "")
    write_pwsh_command(
        "git",
        """
if ($args[0] -eq "rev-parse") {
    "origin/main"
} elseif ($args[0] -eq "rev-list") {
    "2"
}
""",
    )
    write_pwsh_command(
        "uv",
        """
if ($argsText -like "*update-git-lock.py*") {
    exit 2
}
""",
    )
    write_pwsh_command("python3", "")
    write_pwsh_command("jj", "")
    write_pwsh_command(
        "nix",
        """
if ($argsText -like "*path-info*$HOME/.config/home-manager#homeConfigurations.*") {
    "/nix/store/before"
} elseif ($argsText -like "*path:*#homeConfigurations.*") {
    "/nix/store/after"
}
""",
    )
    write_pwsh_command(
        "home-manager",
        """
if ($args[0] -eq "generations") {
    "2026-01-01 00:00 : id 1 -> /nix/store/before"
}
""",
    )
    write_pwsh_command("nvd", "")

    env = os.environ.copy()
    env["PATH"] = f"{fake_bin}{os.pathsep}{env['PATH']}"
    env["HOME"] = str(home)
    env["USER"] = "tester"

    result = subprocess.run(
        [
            "pwsh",
            "-NoProfile",
            "-File",
            str(test_repo / "script" / "update.ps1"),
            "-DryRun",
            "-NoReview",
        ],
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
    assert "nvd diff /nix/store/before /nix/store/after" in calls
    assert "chezmoi apply -R" not in calls
    assert "chezmoi apply" not in calls
    assert "chezmoi re-add" not in calls
    assert "git commit" not in calls
    assert "jj commit" not in calls
    assert "home-manager switch" not in calls
    assert "nix-env --delete-generations old" not in calls


def test_powershell_home_manager_update_inputs_match_dry_run():
    script = (REPO / "script" / "update.ps1").read_text()

    update_call = 'Invoke-Nix @("flake", "update", "nixpkgs", "nixpkgs-unstable")'

    assert script.count(update_call) == 2
    assert "--override-input" not in script


def test_powershell_update_dry_run_fails_on_nix_update_failure(tmp_path):
    if shutil.which("pwsh") is None:
        return

    test_repo = tmp_path / "repo"
    fake_bin = tmp_path / "bin"
    log = tmp_path / "calls.log"
    home = tmp_path / "home"

    (test_repo / "script").mkdir(parents=True)
    (test_repo / "scripts").mkdir()
    (test_repo / ".git").mkdir()
    (home / ".config" / "home-manager").mkdir(parents=True)
    fake_bin.mkdir()
    shutil.copy2(REPO / "script" / "update.ps1", test_repo / "script" / "update.ps1")
    (test_repo / "scripts" / "update-git-lock.py").touch()
    (home / ".config" / "home-manager" / "flake.nix").write_text("{}")

    def write_pwsh_command(name: str, body: str) -> None:
        write_executable(
            fake_bin / name,
            f"""#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
$argsText = $args -join " "
Add-Content -Path '{log}' -Value "{name} $argsText"
{body}
""",
        )

    write_pwsh_command("chezmoi", "")
    write_pwsh_command(
        "git",
        """
if ($args[0] -eq "rev-parse") {
    "origin/main"
} elseif ($args[0] -eq "rev-list") {
    "0"
}
""",
    )
    write_pwsh_command(
        "uv",
        """
if ($argsText -like "*update-git-lock.py*") {
    exit 2
}
""",
    )
    write_pwsh_command("python3", "")
    write_pwsh_command("jj", "")
    write_pwsh_command(
        "nix",
        """
if ($argsText -like "*path-info*$HOME/.config/home-manager#homeConfigurations.*") {
    "/nix/store/before"
} elseif ($argsText -like "*flake update nixpkgs nixpkgs-unstable*") {
    exit 7
} elseif ($argsText -like "*path:*#homeConfigurations.*") {
    "/nix/store/after"
}
""",
    )
    write_pwsh_command("home-manager", "")
    write_pwsh_command("nvd", "")

    env = os.environ.copy()
    env["PATH"] = f"{fake_bin}{os.pathsep}{env['PATH']}"
    env["HOME"] = str(home)
    env["USER"] = "tester"

    result = subprocess.run(
        [
            "pwsh",
            "-NoProfile",
            "-File",
            str(test_repo / "script" / "update.ps1"),
            "-DryRun",
            "-NoReview",
        ],
        cwd=test_repo,
        env=env,
        capture_output=True,
        text=True,
    )

    calls = log.read_text() if log.exists() else ""

    assert result.returncode != 0
    assert "nix --experimental-features nix-command flakes flake update nixpkgs nixpkgs-unstable" in calls
    assert "nvd diff" not in calls
