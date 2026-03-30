Secrets-enabled setup succeeds on the focused secrets distro subset when the host
age key is available:

  $ . "$TESTDIR/../helpers.sh"
  $ require_host_age_key
  $ run_matrix secrets secrets_distros run_secrets_scenario
  ==> secrets fedora
  ok secrets fedora
