Setup remains idempotent on the focused distro subset:

  $ . "$TESTDIR/../helpers.sh"
  $ run_matrix idempotent idempotent_distros run_idempotent_scenario
  ==> idempotent debian
  ok idempotent debian
  ==> idempotent fedora
  ok idempotent fedora
