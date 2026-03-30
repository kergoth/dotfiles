Headless full setup succeeds across the full Linux container matrix:

  $ . "$TESTDIR/../helpers.sh"
  $ run_matrix headless-full all_headless_full_distros run_headless_full_scenario
  ==> headless-full arch
  ok headless-full arch
  ==> headless-full chimera
  ok headless-full chimera
  ==> headless-full debian
  ok headless-full debian
  ==> headless-full fedora
  ok headless-full fedora
  ==> headless-full ubuntu
  ok headless-full ubuntu
