run-container should select arch-specific Dockerfiles and reject unknown docker arch:

  $ . "$TESTDIR/../helpers.sh"

  $ DOCKER_SERVER_ARCH=amd64 run_container_runner_dry_raw arch 2>&1 | grep 'Dockerfile.amd64'
  *Dockerfile.amd64* (glob)

  $ DOCKER_SERVER_ARCH=arm64 run_container_runner_dry_raw arch 2>&1 | grep 'Dockerfile.arm64'
  *Dockerfile.arm64* (glob)

  $ DOCKER_SERVER_ARCH=s390x run_container_runner_dry_raw arch || true
  Building dotfiles-test-arch...
  Error: unsupported docker server arch for arch test container: s390x
