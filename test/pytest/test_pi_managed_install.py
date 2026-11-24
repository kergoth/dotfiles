import functools
import hashlib
import http.server
import importlib.util
import json
import os
import pathlib
import shutil
import sys
import tempfile
import threading

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/pi-managed-install.py"


def load_module():
    spec = importlib.util.spec_from_file_location("pi_managed_install", SCRIPT)
    if spec is None or spec.loader is None:
        raise ModuleNotFoundError(str(SCRIPT))
    module = importlib.util.module_from_spec(spec)
    sys.modules["pi_managed_install"] = module
    spec.loader.exec_module(module)
    return module


pmi = load_module()


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def serve(files: dict[str, str]):
    root = tempfile.mkdtemp()
    for name, content in files.items():
        path = pathlib.Path(root) / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    handler = functools.partial(QuietHandler, directory=root)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server, f"http://127.0.0.1:{server.server_address[1]}", root


class RoutesHandler(http.server.BaseHTTPRequestHandler):
    routes: dict[str, bytes] = {}

    def do_GET(self):
        body = self.routes.get(self.path)
        if body is None:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


def serve_routes(routes: dict[str, str]):
    handler = type(
        "BoundRoutesHandler",
        (RoutesHandler,),
        {"routes": {path: body.encode("utf-8") for path, body in routes.items()}},
    )
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server, f"http://127.0.0.1:{server.server_address[1]}"


def metadata(version: str, *, schema: int = 1) -> str:
    return json.dumps({"schemaVersion": schema, "version": version, "packages": []})


def digest(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def make_config(base_url: str, tmp_path: pathlib.Path, version: str = "1.6.0"):
    package_json = '{"name":"@earendil-works/pi-coding-agent-install"}'
    package_lock = '{"lockfileVersion":3}'
    return (
        pmi.Config(
            version=version,
            api_base=base_url,
            agent_dir=tmp_path,
            npm="npm",
            sha256_package_json=digest(package_json),
            sha256_package_lock=digest(package_lock),
        ),
        package_json,
        package_lock,
    )


def fake_release(tmp_path: pathlib.Path, version: str = "1.6.0") -> pathlib.Path:
    release = tmp_path / "install" / "releases" / version
    bin_dir = release / "node_modules" / ".bin"
    bin_dir.mkdir(parents=True)
    stub = bin_dir / "pi"
    stub.write_text(f'#!/bin/sh\necho "{version}"\n', encoding="utf-8")
    stub.chmod(0o755)
    return release


def test_parse_version_accepts_plain_semver():
    assert pmi.parse_version("1.6.0") == "1.6.0"
    assert pmi.parse_version("1.6.0-beta.1") == "1.6.0-beta.1"


@pytest.mark.parametrize("value", ["v1.6.0", "1.6", "../../etc", "1.6.0/../../x", ""])
def test_parse_version_rejects_prefixed_and_traversal_values(value):
    with pytest.raises(ValueError):
        pmi.parse_version(value)


def test_verify_blob_rejects_mismatch():
    with pytest.raises(ValueError, match="package.json"):
        pmi.verify_blob(b"payload", "0" * 64, "package.json")


def test_build_release_rejects_metadata_version_mismatch(tmp_path):
    server, base, root = serve({"1.6.0": metadata("9.9.9")})
    try:
        config, _, _ = make_config(base, tmp_path)
        with pytest.raises(ValueError, match="9.9.9"):
            pmi.build_release(config)
    finally:
        server.shutdown()
        server.server_close()
        shutil.rmtree(root)


def test_activate_is_atomic_and_marks_managed(tmp_path):
    root = tmp_path / "install"
    root.mkdir()
    pmi.activate(root, "1.6.0")
    assert (root / "current-version").read_text(encoding="utf-8") == "1.6.0\n"
    assert not list(root.glob("current-version.tmp.*"))
    entrypoint = tmp_path / ".local" / "bin" / "pi"
    pmi.write_marker(root, entrypoint)
    marker = json.loads((root / "managed-install.json").read_text(encoding="utf-8"))
    assert marker["kind"] == "pi-managed-install"
    assert marker["schemaVersion"] == 1
    assert marker["layout"] == "releases-v1"
    assert marker["entrypoint"]["path"] == str(entrypoint)


def test_prune_keeps_requested_versions(tmp_path):
    root = tmp_path / "install"
    for version in ("1.4.0", "1.5.0", "1.6.0"):
        (root / "releases" / version).mkdir(parents=True)
    pmi.prune(root, ["1.6.0", "1.5.0"])
    remaining = sorted(path.name for path in (root / "releases").iterdir())
    assert remaining == ["1.5.0", "1.6.0"]


def test_existing_release_skips_download(tmp_path):
    fake_release(tmp_path)
    config, _, _ = make_config("http://127.0.0.1:1", tmp_path)
    release = pmi.build_release(config)
    assert release == tmp_path / "install" / "releases" / "1.6.0"


def test_refuse_self_update_exits_two(capsys):
    assert pmi.main(["--refuse-self-update"]) == 2
    assert "script/update" in capsys.readouterr().err


def test_check_reports_pin_installed_and_upstream(tmp_path, capsys):
    server, base, root = serve({"latest": metadata("1.7.0")})
    try:
        install = tmp_path / "install"
        install.mkdir()
        (install / "current-version").write_text("1.5.0\n", encoding="utf-8")
        code = pmi.main(
            [
                "--check",
                "--version",
                "1.6.0",
                "--agent-dir",
                str(tmp_path),
                "--api-base",
                base,
            ]
        )
        assert code == 0
        out = capsys.readouterr().out
        assert "pin:" in out and "1.6.0" in out
        assert "installed:" in out and "1.5.0" in out
        assert "upstream:" in out and "1.7.0" in out
        assert (install / "current-version").read_text(encoding="utf-8") == "1.5.0\n"
    finally:
        server.shutdown()
        server.server_close()
        shutil.rmtree(root)


def test_artifact_http_error_is_raised(tmp_path):
    server, base, root = serve({"1.6.0": metadata("1.6.0")})
    try:
        config, _, _ = make_config(base, tmp_path)
        with pytest.raises(RuntimeError, match="404"):
            pmi.build_release(config)
        staging = tmp_path / "install" / "staging"
        assert not list(staging.glob("update-*"))
    finally:
        server.shutdown()
        server.server_close()
        shutil.rmtree(root)


def test_main_stages_a_release_through_npm(tmp_path):
    package_json = '{"name":"@earendil-works/pi-coding-agent-install"}'
    package_lock = '{"lockfileVersion":3}'
    server, base = serve_routes(
        {
            "/1.6.0": metadata("1.6.0"),
            "/1.6.0/package.json": package_json,
            "/1.6.0/package-lock.json": package_lock,
        }
    )
    try:
        bin_dir = tmp_path / "bin"
        bin_dir.mkdir()
        npm_stub = bin_dir / "npm"
        npm_stub.write_text(
            "#!/bin/sh\n"
            "mkdir -p node_modules/.bin\n"
            "printf '#!/bin/sh\\necho 1.6.0\\n' > node_modules/.bin/pi\n"
            "chmod +x node_modules/.bin/pi\n"
            'printf "%s\\n" "$@" > "$NPM_RECORD"\n',
            encoding="utf-8",
        )
        npm_stub.chmod(0o755)
        record = tmp_path / "npm-record"
        os.environ["NPM_RECORD"] = str(record)

        code = pmi.main(
            [
                "--version",
                "1.6.0",
                "--sha256-package-json",
                digest(package_json),
                "--sha256-package-lock",
                digest(package_lock),
                "--agent-dir",
                str(tmp_path),
                "--api-base",
                base,
                "--npm",
                str(npm_stub),
            ]
        )

        install = tmp_path / "install"
        assert code == 0
        assert (install / "current-version").read_text(encoding="utf-8") == "1.6.0\n"
        assert (install / "managed-install.json").exists()
        assert (
            install / "releases" / "1.6.0" / "node_modules" / ".bin" / "pi"
        ).exists()
        assert record.read_text(encoding="utf-8").splitlines() == pmi.NPM_CI_ARGS
        assert not list((install / "staging").glob("update-*"))
    finally:
        server.shutdown()
        server.server_close()
