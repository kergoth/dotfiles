import json
import pathlib
import shutil
import subprocess

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]
HOOK = ROOT / "home/.chezmoiscripts/windows/run_onchange_before_26_install-pi.ps1.tmpl"
IGNORE = ROOT / "home/.chezmoiignore.tmpl"
DIGEST_JSON = "a" * 64
DIGEST_LOCK = "b" * 64


def render(template: pathlib.Path, override: dict) -> str:
    data = {
        "user_setup": True,
        "chezmoi": {"homeDir": "/home/tester"},
        "git_lock": {"pi": "v1.6.0"},
        "fetch_lock": {
            "pi_package_json": DIGEST_JSON,
            "pi_package_lock": DIGEST_LOCK,
        },
        **override,
    }
    return subprocess.run(
        [
            "chezmoi",
            "execute-template",
            "--file",
            "--override-data",
            json.dumps(data),
            str(template),
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def test_hook_parses_as_powershell(tmp_path):
    pwsh = shutil.which("pwsh")
    if not pwsh:
        pytest.skip("pwsh is not installed")
    script = tmp_path / "hook.ps1"
    script.write_text(render(HOOK, {"chezmoi": {"os": "windows"}}), encoding="utf-8")

    result = subprocess.run(
        [
            pwsh,
            "-NoProfile",
            "-Command",
            f"$errors = $null; $null = [System.Management.Automation.Language.Parser]::ParseFile('{script}', [ref]$null, [ref]$errors); if ($errors) {{ $errors | ForEach-Object {{ $_.Message }}; exit 1 }}",
        ],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, result.stdout + result.stderr


def ignore_lines(os_name: str) -> list[str]:
    return render(IGNORE, {"chezmoi": {"os": os_name}}).splitlines()


def test_windows_ignores_the_posix_launchers():
    lines = ignore_lines("windows")

    assert ".pi/agent/bin/pi" in lines
    assert ".local/bin/pi" in lines


def test_posix_keeps_the_launchers_and_ignores_appdata():
    lines = ignore_lines("darwin")

    assert ".pi/agent/bin/pi" not in lines
    assert ".local/bin/pi" not in lines
    assert "AppData" in lines


def test_update_ps1_parses_as_powershell():
    pwsh = shutil.which("pwsh")
    if not pwsh:
        pytest.skip("pwsh is not installed")

    result = subprocess.run(
        [
            pwsh,
            "-NoProfile",
            "-Command",
            f"$errors = $null; $null = [System.Management.Automation.Language.Parser]::ParseFile('{ROOT / 'script/update.ps1'}', [ref]$null, [ref]$errors); if ($errors) {{ $errors | ForEach-Object {{ $_.Message }}; exit 1 }}",
        ],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, result.stdout + result.stderr
