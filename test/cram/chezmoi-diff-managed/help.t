Help describes the managed-baseline comparison and accepted targets.

  $ bash "$TESTDIR/../../../scripts/chezmoi-diff-managed" --help
  Usage: chezmoi-diff-managed [options] [target ...]
  
  Compare destination files with their managed baselines. Unlike chezmoi diff,
  modify_ sources are rendered without the current destination as input.
  
  Without target arguments, compare files that chezmoi would modify and all
  active managed modify_ targets. File arguments are compared directly;
  directory arguments use managed discovery within that subtree.
  
  Examples:
    chezmoi-diff-managed
    chezmoi-diff-managed ~/.claude/
    chezmoi-diff-managed ~/.claude/settings.json
  
  Options:
    -h, --help    Show this help message

Unknown options fail with usage guidance.

  $ bash "$TESTDIR/../../../scripts/chezmoi-diff-managed" --unknown
  Unknown option: --unknown
  Usage: chezmoi-diff-managed [options] [target ...]
  
  Compare destination files with their managed baselines. Unlike chezmoi diff,
  modify_ sources are rendered without the current destination as input.
  
  Without target arguments, compare files that chezmoi would modify and all
  active managed modify_ targets. File arguments are compared directly;
  directory arguments use managed discovery within that subtree.
  
  Examples:
    chezmoi-diff-managed
    chezmoi-diff-managed ~/.claude/
    chezmoi-diff-managed ~/.claude/settings.json
  
  Options:
    -h, --help    Show this help message
  [1]
