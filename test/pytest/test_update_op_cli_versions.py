import hashlib
import importlib.util
import pathlib


spec = importlib.util.spec_from_file_location(
    "update_op_cli_versions",
    pathlib.Path(__file__).parent.parent.parent
    / "scripts"
    / "update-op-cli-versions.py",
)
assert spec is not None and spec.loader is not None
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def test_format_version_diff_lines_reports_changed_platforms():
    result = mod.format_version_diff_lines(
        {"linux": "2.30.0"},
        {"linux": "2.31.0"},
    )

    assert result == ["op_cli linux: v2.30.0 -> v2.31.0"]


def test_render_versions_yml_is_stable():
    result = mod.render_versions_yml(
        {"linux": "2.31.0"},
        {
            "linux": {
                "arm64": "b" * 64,
                "amd64": "a" * 64,
            }
        },
    )

    assert result == (
        "versions:\n"
        "  op_cli:\n"
        "    linux:\n"
        '      version: "2.31.0"\n'
        "      sha256:\n"
        f'        amd64: "{"a" * 64}"\n'
        f'        arm64: "{"b" * 64}"\n'
    )


class FakeResponse:
    def __init__(self, data: bytes):
        self.data = data

    def read(self) -> bytes:
        return self.data


def test_dry_run_does_not_write_versions_file(tmp_path):
    path = tmp_path / "versions.yml"
    original = (
        "versions:\n"
        "  op_cli:\n"
        "    linux:\n"
        '      version: "2.30.0"\n'
        "      sha256:\n"
        f'        amd64: "{"0" * 64}"\n'
    )
    path.write_text(original, encoding="utf-8")

    linux_amd64 = b"linux-amd64"
    linux_arm64 = b"linux-arm64"
    archive_urls = {
        "https://cache.agilebits.com/dist/1P/op2/pkg/v2.31.0/op_linux_amd64_v2.31.0.zip": linux_amd64,
        "https://cache.agilebits.com/dist/1P/op2/pkg/v2.31.0/op_linux_arm64_v2.31.0.zip": linux_arm64,
    }
    html = "\n".join(archive_urls)

    def fake_urlopen(url, timeout):
        del timeout
        if url == "https://app-updates.agilebits.com/product_history/CLI2":
            return FakeResponse(html.encode("utf-8"))
        return FakeResponse(archive_urls[url])

    result = mod.update_versions(path, dry_run=True, urlopen=fake_urlopen)

    assert result == ["op_cli linux: v2.30.0 -> v2.31.0"]
    assert path.read_text(encoding="utf-8") == original


def test_update_versions_writes_rendered_content(tmp_path):
    path = tmp_path / "versions.yml"
    path.write_text("", encoding="utf-8")

    linux_amd64 = b"linux-amd64"
    linux_arm64 = b"linux-arm64"
    archive_urls = {
        "https://cache.agilebits.com/dist/1P/op2/pkg/v2.31.0/op_linux_amd64_v2.31.0.zip": linux_amd64,
        "https://cache.agilebits.com/dist/1P/op2/pkg/v2.31.0/op_linux_arm64_v2.31.0.zip": linux_arm64,
    }
    html = "\n".join(archive_urls)

    def fake_urlopen(url, timeout):
        del timeout
        if url == "https://app-updates.agilebits.com/product_history/CLI2":
            return FakeResponse(html.encode("utf-8"))
        return FakeResponse(archive_urls[url])

    result = mod.update_versions(path, dry_run=False, urlopen=fake_urlopen)

    assert result == ["op_cli linux: (new) -> v2.31.0"]
    assert path.read_text(encoding="utf-8") == mod.render_versions_yml(
        {"linux": "2.31.0"},
        {
            "linux": {
                "amd64": hashlib.sha256(linux_amd64).hexdigest(),
                "arm64": hashlib.sha256(linux_arm64).hexdigest(),
            }
        },
    )
