from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
CONTAINERS = REPO_ROOT / "test" / "containers"


def test_all_container_from_lines_are_pinned():
    dockerfiles = sorted(CONTAINERS.glob("*/Dockerfile"))
    dockerfiles += sorted(CONTAINERS.glob("*/Dockerfile.*"))
    assert dockerfiles, "expected test container Dockerfiles"

    for dockerfile in dockerfiles:
        lines = dockerfile.read_text(encoding="utf-8").splitlines()
        from_lines = [line.strip() for line in lines if line.strip().startswith("FROM ")]
        assert from_lines, f"{dockerfile} has no FROM line"
        for line in from_lines:
            if line == "FROM ${BASE_IMAGE}":
                assert "ARG BASE_IMAGE=" in "\n".join(lines), f"missing ARG BASE_IMAGE in {dockerfile}"
                assert "ARG BASE_IMAGE=" in "\n".join(lines) and "@sha256:" in "\n".join(lines), (
                    f"unpinned BASE_IMAGE arg in {dockerfile}"
                )
                continue
            assert "@sha256:" in line, f"unpinned base image in {dockerfile}: {line}"


def test_arch_split_dockerfiles_exist():
    assert (CONTAINERS / "arch" / "Dockerfile.amd64").exists()
    assert (CONTAINERS / "arch" / "Dockerfile.arm64").exists()
