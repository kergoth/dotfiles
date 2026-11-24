import os
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "home/dot_pi/private_agent/bin/executable_pi.tmpl"


def render(tmp_path: pathlib.Path) -> pathlib.Path:
    rendered = subprocess.run(
        ["chezmoi", "execute-template", "--file", str(TEMPLATE)],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    launcher = tmp_path / "launcher"
    launcher.write_text(rendered, encoding="utf-8")
    return launcher


def run(
    launcher: pathlib.Path, home: pathlib.Path, args: list[str], agent_dir: str = ""
):
    return subprocess.run(
        ["/bin/sh", str(launcher), *args],
        check=False,
        capture_output=True,
        text=True,
        env={**os.environ, "HOME": str(home), "PI_CODING_AGENT_DIR": agent_dir},
    )


def install_fake_release(agent_dir: pathlib.Path, version: str, body: str) -> None:
    install = agent_dir / "install"
    install.mkdir(parents=True)
    (install / "current-version").write_text(f"{version}\n", encoding="utf-8")
    binary = install / "releases" / version / "node_modules" / ".bin" / "pi"
    binary.parent.mkdir(parents=True)
    binary.write_text(body, encoding="utf-8")
    binary.chmod(0o755)


def test_launcher_execs_the_active_release_and_forwards_arguments(tmp_path):
    launcher = render(tmp_path)
    home = tmp_path / "home"
    install_fake_release(
        home / ".pi" / "agent", "1.6.0", "#!/bin/sh\nprintf '%s\\n' \"$@\"\n"
    )

    result = run(launcher, home, ["--session", "name with spaces"])

    assert result.returncode == 0, result.stderr
    assert result.stdout.splitlines() == ["--session", "name with spaces"]


def test_launcher_honors_agent_dir_override(tmp_path):
    launcher = render(tmp_path)
    home = tmp_path / "home"
    agent_dir = tmp_path / "custom-agent"
    install_fake_release(agent_dir, "1.6.0", "#!/bin/sh\necho custom\n")

    result = run(launcher, home, [], agent_dir=str(agent_dir))

    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "custom"


def test_launcher_reports_missing_release(tmp_path):
    launcher = render(tmp_path)
    home = tmp_path / "home"
    home.mkdir()

    result = run(launcher, home, [])

    assert result.returncode != 0
    assert "script/update" in result.stderr
