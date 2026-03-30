Chezmoi scripts survive forced replay on the focused distro subset:

  $ . "$TESTDIR/../helpers.sh"
  $ run_matrix replay replay_distros run_replay_scenario
  ==> replay debian
  ok replay debian
  ==> replay fedora
  ok replay fedora
