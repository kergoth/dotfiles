run-test dry-run output separates setup interactivity from shell spawning:

  $ . "$TESTDIR/../helpers.sh"

Parser checks use the Docker attach flag position and original command argument:

  $ log_file="${CRAMTMP}/dry-parser-command.log"
  $ printf "%s\n" "dry docker run --entrypoint /bin/sh -i --rm -e 'TEST_ACTION=command' -e 'TEST_INTERACTIVE=0' -e 'TEST_COMMAND=printf '\''docker run --entrypoint /bin/sh -it --rm later'\''' dotfiles-test-debian /home/testuser/.dotfiles/test/containers/run-test-container.sh" >"$log_file"
  $ print_run_test_dry_contract "$log_file" -r -c "printf 'docker run --entrypoint /bin/sh -it --rm later'" debian
  docker-tty=-i
  TEST_ACTION=command
  TEST_INTERACTIVE=0
  TEST_COMMAND=printf 'docker run --entrypoint /bin/sh -it --rm later'

Default runs keep stdin non-interactive and do not allocate a TTY:

  $ run_container_runner_dry_contract -r debian
  docker-tty=-i
  TEST_ACTION=run
  TEST_INTERACTIVE=0

The shell flag uses the post-setup shell action but keeps setup stdin closed:

  $ run_container_runner_dry_contract -r -s debian
  docker-tty=-it
  TEST_ACTION=shell
  TEST_INTERACTIVE=0

The interactive flag keeps the normal action and marks setup as interactive:

  $ run_container_runner_dry_contract -r -i debian
  docker-tty=-it
  TEST_ACTION=run
  TEST_INTERACTIVE=1

The interactive flag can be combined with the shell action:

  $ run_container_runner_dry_contract -r -i -s debian
  docker-tty=-it
  TEST_ACTION=shell
  TEST_INTERACTIVE=1

The interactive flag can also be combined with one-shot command mode:

  $ run_container_runner_dry_contract -r -i -c 'printf ok' debian
  docker-tty=-it
  TEST_ACTION=command
  TEST_INTERACTIVE=1
  TEST_COMMAND=printf ok

Interactive or action modes are intentionally limited to one distro:

  $ run_container_runner_dry_fails_with 'Error: -a cannot be combined with -i, -s, or -c' -a -i
  Error: -a cannot be combined with -i, -s, or -c
  $ run_container_runner_dry_fails_with 'Error: Multiple distros cannot be combined with -i, -s, or -c' -i debian fedora
  Error: Multiple distros cannot be combined with -i, -s, or -c
