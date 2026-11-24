import json
import pathlib
import shutil
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "home/.chezmoiscripts/posix/run_onchange_before_26_install-pi.tmpl"
DIGEST_JSON = "a" * 64
DIGEST_LOCK = "b" * 64


def render(tmp_path: pathlib.Path) -> pathlib.Path:
    override_data = {
        "user_setup": True,
        "chezmoi": {"os": "darwin", "homeDir": "/home/tester"},
        "git_lock": {"pi": "v1.6.0"},
        "fetch_lock": {
            "pi_package_json": DIGEST_JSON,
            "pi_package_lock": DIGEST_LOCK,
        },
    }
    rendered = subprocess.run(
        [
            "chezmoi",
            "execute-template",
            "--file",
            "--override-data",
            json.dumps(override_data),
            str(TEMPLATE),
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    hook = tmp_path / "hook.sh"
    hook.write_text(rendered, encoding="utf-8")
    return hook


def run_hook(
    hook: pathlib.Path, tmp_path: pathlib.Path, path_dir: pathlib.Path, env=None
):
    return subprocess.run(
        [shutil.which("bash"), str(hook)],
        check=False,
        capture_output=True,
        text=True,
        env={
            "PATH": str(path_dir),
            "CHEZMOI_WORKING_TREE": str(tmp_path / "worktree"),
            **(env or {}),
        },
    )


def test_hook_passes_version_and_digests_to_the_stager(tmp_path):
    hook = render(tmp_path)
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    stub = bin_dir / "python3"
    stub.write_text('#!/bin/sh\nprintf \'%s\\n\' "$@" > "$RECORD"\n', encoding="utf-8")
    stub.chmod(0o755)
    npm_stub = bin_dir / "npm"
    npm_stub.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
    npm_stub.chmod(0o755)
    worktree_scripts = tmp_path / "worktree" / "scripts"
    worktree_scripts.mkdir(parents=True)
    (worktree_scripts / "pi-managed-install.py").write_text("", encoding="utf-8")

    record = tmp_path / "record"
    result = run_hook(hook, tmp_path, bin_dir, env={"RECORD": str(record)})

    assert result.returncode == 0, result.stderr
    assert record.read_text(encoding="utf-8").splitlines() == [
        str(worktree_scripts / "pi-managed-install.py"),
        "--version",
        "1.6.0",
        "--sha256-package-json",
        DIGEST_JSON,
        "--sha256-package-lock",
        DIGEST_LOCK,
    ]


def test_hook_skips_cleanly_without_python3(tmp_path):
    hook = render(tmp_path)
    empty = tmp_path / "empty"
    empty.mkdir()
    record = tmp_path / "record"

    result = run_hook(hook, tmp_path, empty, env={"RECORD": str(record)})

    assert result.returncode == 0, result.stderr
    assert "skipping pinned Pi install" in result.stderr
    assert not record.exists()


def test_hook_skips_cleanly_without_npm(tmp_path):
    hook = render(tmp_path)
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    stub = bin_dir / "python3"
    stub.write_text("#!/bin/sh\nexit 1\n", encoding="utf-8")
    stub.chmod(0o755)
    record = tmp_path / "record"

    result = run_hook(hook, tmp_path, bin_dir, env={"RECORD": str(record)})

    assert result.returncode == 0, result.stderr
    assert "skipping pinned Pi install, npm is not installed" in result.stderr
    assert not record.exists()
