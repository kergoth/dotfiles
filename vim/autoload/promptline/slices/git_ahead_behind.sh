function __promptline_git_ahead_behind {
  [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true ]] || return 1

  local ahead_symbol="↑"
  local behind_symbol="↓"

  set -- $(git rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null)
  local behind_count=$1
  local ahead_count=$2

  local leading_whitespace=""
  [[ $ahead_count -gt 0 ]]         && { printf "%s" "$leading_whitespace$ahead_symbol$ahead_count"; leading_whitespace=" "; }
  [[ $behind_count -gt 0 ]]        && { printf "%s" "$leading_whitespace$behind_symbol$behind_count"; leading_whitespace=" "; }
}
