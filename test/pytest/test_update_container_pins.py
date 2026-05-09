import importlib.util
from pathlib import Path


spec = importlib.util.spec_from_file_location(
    "update_container_pins",
    Path(__file__).parent.parent.parent / "scripts" / "update-container-pins.py",
)
assert spec is not None and spec.loader is not None
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _write_fixture_tree(root: Path) -> None:
    (root / "test/containers/arch").mkdir(parents=True, exist_ok=True)
    (root / "test/containers/chimera").mkdir(parents=True, exist_ok=True)
    (root / "test/containers/debian").mkdir(parents=True, exist_ok=True)
    (root / "test/containers/fedora").mkdir(parents=True, exist_ok=True)
    (root / "test/containers/ubuntu").mkdir(parents=True, exist_ok=True)
    (root / "home/.chezmoidata").mkdir(parents=True, exist_ok=True)

    (root / "test/containers/debian/Dockerfile").write_text(
        "FROM debian:latest@sha256:" + "a" * 64 + "\n", encoding="utf-8"
    )
    (root / "test/containers/ubuntu/Dockerfile").write_text(
        "FROM ubuntu:latest@sha256:" + "b" * 64 + "\n", encoding="utf-8"
    )
    (root / "test/containers/fedora/Dockerfile").write_text(
        "FROM fedora:latest@sha256:" + "c" * 64 + "\n", encoding="utf-8"
    )
    (root / "test/containers/chimera/Dockerfile").write_text(
        "FROM chimeralinux/chimera:latest@sha256:" + "d" * 64 + "\n", encoding="utf-8"
    )
    (root / "test/containers/arch/Dockerfile.amd64").write_text(
        "FROM archlinux/archlinux:latest@sha256:" + "e" * 64 + "\n", encoding="utf-8"
    )
    (root / "test/containers/arch/Dockerfile.arm64").write_text(
        "FROM ghcr.io/baerenbude-org/archlinuxarm-arm64v8:latest@sha256:" + "1" * 64 + "\n",
        encoding="utf-8",
    )

    (root / "home/.chezmoidata/container-lock.yml").write_text(
        mod.dump_lock_yaml(
            {
                "debian_latest": "sha256:" + "a" * 64,
                "ubuntu_latest": "sha256:" + "b" * 64,
                "fedora_latest": "sha256:" + "c" * 64,
                "chimera_latest": "sha256:" + "d" * 64,
                "arch_amd64_latest": "sha256:" + "e" * 64,
                "arch_arm64_latest": "sha256:" + "1" * 64,
            }
        ),
        encoding="utf-8",
    )


def _data_with_current_lock() -> dict:
    return {
        "container_sources": {
            "debian_latest": {"image": "debian:latest"},
            "ubuntu_latest": {"image": "ubuntu:latest"},
            "fedora_latest": {"image": "fedora:latest"},
            "chimera_latest": {"image": "chimeralinux/chimera:latest"},
            "arch_amd64_latest": {"image": "archlinux/archlinux:latest"},
            "arch_arm64_latest": {
                "image": "ghcr.io/baerenbude-org/archlinuxarm-arm64v8:latest"
            },
        },
        "container_lock": {
            "debian_latest": "sha256:" + "a" * 64,
            "ubuntu_latest": "sha256:" + "b" * 64,
            "fedora_latest": "sha256:" + "c" * 64,
            "chimera_latest": "sha256:" + "d" * 64,
            "arch_amd64_latest": "sha256:" + "e" * 64,
            "arch_arm64_latest": "sha256:" + "1" * 64,
        },
        "container_targets": [
            {"source": "debian_latest", "path": "test/containers/debian/Dockerfile", "kind": "from"},
            {"source": "ubuntu_latest", "path": "test/containers/ubuntu/Dockerfile", "kind": "from"},
            {"source": "fedora_latest", "path": "test/containers/fedora/Dockerfile", "kind": "from"},
            {"source": "chimera_latest", "path": "test/containers/chimera/Dockerfile", "kind": "from"},
            {"source": "arch_amd64_latest", "path": "test/containers/arch/Dockerfile.amd64", "kind": "from"},
            {"source": "arch_arm64_latest", "path": "test/containers/arch/Dockerfile.arm64", "kind": "from"},
        ],
    }


def test_update_all_dry_run_reports_changes_without_writing(tmp_path):
    _write_fixture_tree(tmp_path)
    data = _data_with_current_lock()

    digests = {
        "debian:latest": "sha256:" + "0" * 64,
        "ubuntu:latest": "sha256:" + "2" * 64,
        "fedora:latest": "sha256:" + "3" * 64,
        "chimeralinux/chimera:latest": "sha256:" + "4" * 64,
        "archlinux/archlinux:latest": "sha256:" + "5" * 64,
        "ghcr.io/baerenbude-org/archlinuxarm-arm64v8:latest": "sha256:" + "6" * 64,
    }

    before = (tmp_path / "test/containers/debian/Dockerfile").read_text(encoding="utf-8")
    lines, errors = mod.update_all(
        tmp_path,
        dry_run=True,
        resolver=lambda image: digests[image],
        data_loader=lambda _: data,
    )
    after = (tmp_path / "test/containers/debian/Dockerfile").read_text(encoding="utf-8")

    assert before == after
    assert errors == []
    assert any(
        line.startswith("test/containers/debian/Dockerfile: debian:latest sha256:")
        for line in lines
    )


def test_update_all_continues_when_one_source_fails(tmp_path):
    _write_fixture_tree(tmp_path)
    data = _data_with_current_lock()

    def resolver(image: str) -> str:
        if image == "chimeralinux/chimera:latest":
            raise ValueError("429 Too Many Requests")
        return "sha256:" + "f" * 64

    lines, errors = mod.update_all(
        tmp_path,
        dry_run=False,
        resolver=resolver,
        data_loader=lambda _: data,
    )

    assert any("debian:latest" in line for line in lines)
    assert any("chimera_latest (chimeralinux/chimera:latest):" in err for err in errors)


def test_update_all_writes_new_digests_and_lock(tmp_path):
    _write_fixture_tree(tmp_path)
    data = _data_with_current_lock()

    digests = {
        "debian:latest": "sha256:" + "0" * 64,
        "ubuntu:latest": "sha256:" + "2" * 64,
        "fedora:latest": "sha256:" + "3" * 64,
        "chimeralinux/chimera:latest": "sha256:" + "4" * 64,
        "archlinux/archlinux:latest": "sha256:" + "5" * 64,
        "ghcr.io/baerenbude-org/archlinuxarm-arm64v8:latest": "sha256:" + "6" * 64,
    }

    lines, errors = mod.update_all(
        tmp_path,
        dry_run=False,
        resolver=lambda image: digests[image],
        data_loader=lambda _: data,
    )

    assert errors == []
    assert any("test/containers/arch/Dockerfile.amd64: archlinux/archlinux:latest" in line for line in lines)
    arch_amd64 = (tmp_path / "test/containers/arch/Dockerfile.amd64").read_text(encoding="utf-8")
    arch_arm64 = (tmp_path / "test/containers/arch/Dockerfile.arm64").read_text(encoding="utf-8")
    assert "archlinux/archlinux:latest@sha256:" + "5" * 64 in arch_amd64
    assert "ghcr.io/baerenbude-org/archlinuxarm-arm64v8:latest@sha256:" + "6" * 64 in arch_arm64

    lock_text = (tmp_path / "home/.chezmoidata/container-lock.yml").read_text(encoding="utf-8")
    assert 'arch_amd64_latest: "sha256:' + "5" * 64 + '"' in lock_text
