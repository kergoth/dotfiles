Default selection includes changed targets and managed modifiers only.

  $ mkdir -p bin source destination
  $ export PATH="$PWD/bin:$PATH"
  $ export HOME="$PWD/home"
  $ export LOG="$PWD/log"
  $ mkdir "$LOG"
  $ cat >bin/chezmoi <<'EOF'
  > #!/usr/bin/env bash
  > set -eu
  > case "$1" in
  > data)
  >     printf '{"chezmoi":{"sourceDir":"%s/source","destDir":"%s/destination"}}\n' "$PWD" "$PWD"
  >     ;;
  > status)
  >     if [[ " $* " = *"/destination/config"* ]]; then
  >         printf ' M %s/destination/config/changed.txt\n' "$PWD"
  >     else
  >         printf ' M %s/destination/changed.txt\nM  %s/destination/first-column-only.txt\n' "$PWD" "$PWD"
  >     fi
  >     ;;
  > managed)
  >     if [[ " $* " = *source-absolute* ]]; then
  >         if [[ " $* " = *"/destination/config"* ]]; then
  >             printf '%s/source/modify_config.json\n' "$PWD"
  >         else
  >             printf '%s/source/modify_modified.json\n' "$PWD"
  >         fi
  >     else
  >         printf '%s/destination/changed.txt\n%s/destination/ignored.txt\n%s/destination/modified.json\n' "$PWD" "$PWD" "$PWD"
  >     fi
  >     ;;
  > target-path)
  >     shift 2
  >     for path; do
  >         case "$path" in
  >         */modify_modified.json) printf '%s/destination/modified.json\n' "$PWD" ;;
  >         */modify_config.json) printf '%s/destination/config/modified.json\n' "$PWD" ;;
  >         esac
  >     done
  >     ;;
  > source-path)
  >     case "$2" in
  >     */config/changed.txt) printf '%s/source/config-changed.txt.tmpl\n' "$PWD" ;;
  >     */changed.txt) printf '%s/source/changed.txt.tmpl\n' "$PWD" ;;
  >     */ignored.txt) printf '%s/source/ignored.txt.tmpl\n' "$PWD" ;;
  >     */first-column-only.txt) printf '%s/source/first-column-only.txt.tmpl\n' "$PWD" ;;
  >     */config/modified.json) printf '%s/source/modify_config.json\n' "$PWD" ;;
  >     */modified.json) printf '%s/source/modify_modified.json\n' "$PWD" ;;
  >     */regular.json) printf '%s/source/regular.json\n' "$PWD" ;;
  >     */zed-settings.json) printf '%s/source/zed-settings.json\n' "$PWD" ;;
  >     */identical.txt) printf '%s/source/identical.txt\n' "$PWD" ;;
  >     esac
  >     ;;
  > execute-template)
  >     cat "${@: -1}"
  >     ;;
  > cat)
  >     case "$3" in
  >     */regular.json) cat "$PWD/source/regular.json" ;;
  >     */zed-settings.json) cat "$PWD/source/zed-settings.json" ;;
  >     */identical.txt) cat "$PWD/source/identical.txt" ;;
  >     esac
  >     ;;
  > esac
  > EOF
  $ cat >bin/difft <<'EOF'
  > #!/usr/bin/env bash
  > printf '%s %s\n' "${1##*/}" "${2##*/}"
  > exit 1
  > EOF
  $ cat >bin/jd <<'EOF'
  > #!/usr/bin/env bash
  > printf 'src.json modified.json\n'
  > EOF
  $ chmod +x bin/chezmoi bin/difft bin/jd
  $ printf 'managed\n' >source/changed.txt.tmpl
  $ printf 'ignored managed\n' >source/ignored.txt.tmpl
  $ printf 'first-column managed\n' >source/first-column-only.txt.tmpl
  $ printf '{{- /* chezmoi:modify-template */ -}}\nmanaged json\n' >source/modify_modified.json
  $ printf 'local\n' >destination/changed.txt
  $ printf 'local\n' >destination/ignored.txt
  $ printf 'local\n' >destination/first-column-only.txt
  $ printf 'local json\n' >destination/modified.json
  $ mkdir -p destination/config
  $ printf 'managed config\n' >source/config-changed.txt.tmpl
  $ printf '{{- /* chezmoi:modify-template */ -}}\nmanaged config json\n' >source/modify_config.json
  $ printf 'local config\n' >destination/config/changed.txt
  $ printf 'local config json\n' >destination/config/modified.json

  $ bash "$TESTDIR/../../../scripts/chezmoi-diff-managed" | awk 'NF'
  == managed (rendered): */source/changed.txt.tmpl == (glob)
  == destination: */destination/changed.txt == (glob)
  src.txt changed.txt
  == managed (rendered): */source/modify_modified.json == (glob)
  == destination: */destination/modified.json == (glob)
  src.json modified.json

Directory arguments use scoped managed discovery.

  $ bash "$TESTDIR/../../../scripts/chezmoi-diff-managed" "$PWD/destination/config" | awk 'NF'
  == managed (rendered): */source/config-changed.txt.tmpl == (glob)
  == destination: */destination/config/changed.txt == (glob)
  src.txt changed.txt
  == managed (rendered): */source/modify_config.json == (glob)
  == destination: */destination/config/modified.json == (glob)
  src.json modified.json

Comparator errors continue later comparisons and preserve a failing exit status.

  $ cat >bin/difft <<'EOF'
  > #!/usr/bin/env bash
  > printf '%s %s\n' "${1##*/}" "${2##*/}"
  > exit 2
  > EOF
  $ chmod +x bin/difft
  $ (set -o pipefail; bash "$TESTDIR/../../../scripts/chezmoi-diff-managed" "$PWD/destination/changed.txt" "$PWD/destination/modified.json" | awk 'NF')
  == managed (rendered): */source/changed.txt.tmpl == (glob)
  == destination: */destination/changed.txt == (glob)
  src.txt changed.txt
  == managed (rendered): */source/modify_modified.json == (glob)
  == destination: */destination/modified.json == (glob)
  src.json modified.json
  [2]

The plain diff fallback continues after expected differences.

  $ rm bin/difft bin/jd
  $ cat >bin/jq <<'EOF'
  > #!/usr/bin/env bash
  > printf '%s/destination\n' "$PWD"
  > EOF
  $ cat >bin/diff <<'EOF'
  > #!/usr/bin/env bash
  > src=${@: -2:1}
  > target=${@: -1}
  > printf '%s %s\n' "${src##*/}" "${target##*/}"
  > exit 1
  > EOF
  $ chmod +x bin/jq bin/diff
  $ PATH="$PWD/bin:/usr/bin:/bin" bash "$TESTDIR/../../../scripts/chezmoi-diff-managed" "$PWD/destination/changed.txt" "$PWD/destination/modified.json" | awk 'NF'
  == managed (rendered): */source/changed.txt.tmpl == (glob)
  == destination: */destination/changed.txt == (glob)
  src.txt changed.txt
  == managed (rendered): */source/modify_modified.json == (glob)
  == destination: */destination/modified.json == (glob)
  src.json modified.json

JSON with comments falls back to a syntax-aware text diff.

  $ cat >bin/jq <<'EOF'
  > #!/usr/bin/env bash
  > case "$1" in
  > -r) printf '%s/destination\n' "$PWD" ;;
  > empty) exit 1 ;;
  > esac
  > EOF
  $ cat >bin/jd <<'EOF'
  > #!/usr/bin/env bash
  > echo unexpected jd invocation >&2
  > exit 2
  > EOF
  $ cat >bin/difft <<'EOF'
  > #!/usr/bin/env bash
  > printf '%s %s' "${1##*/}" "${2##*/}"
  > exit 1
  > EOF
  $ chmod +x bin/jq bin/jd bin/difft
  $ printf '// managed\n{ "key": "managed" }\n' >source/zed-settings.json
  $ printf '// local\n{ "key": "local" }\n' >destination/zed-settings.json
  $ bash "$TESTDIR/../../../scripts/chezmoi-diff-managed" "$PWD/destination/zed-settings.json" | awk 'NF'
  == managed (rendered): */source/zed-settings.json == (glob)
  == destination: */destination/zed-settings.json == (glob)
  src.json zed-settings.json

Structured differences do not stop later comparisons.

  $ cat >bin/jd <<'EOF'
  > #!/usr/bin/env bash
  > src=${@: -2:1}
  > target=${@: -1}
  > printf '%s %s\n' "${src##*/}" "${target##*/}"
  > exit 1
  > EOF
  $ chmod +x bin/jd
  $ printf 'managed regular json\n' >source/regular.json
  $ printf 'local regular json\n' >destination/regular.json
  $ bash "$TESTDIR/../../../scripts/chezmoi-diff-managed" "$PWD/destination/modified.json" "$PWD/destination/regular.json" | awk 'NF'
  == managed (rendered): */source/modify_modified.json == (glob)
  == destination: */destination/modified.json == (glob)
  src.json modified.json
  == managed (rendered): */source/regular.json == (glob)
  == destination: */destination/regular.json == (glob)
  src.json regular.json

Identical rendered baselines do not invoke semantic diffing.

  $ cat >bin/cmp <<'EOF'
  > #!/usr/bin/env bash
  > /usr/bin/cmp "$@"
  > EOF
  $ cat >bin/difft <<'EOF'
  > #!/usr/bin/env bash
  > echo unexpected
  > EOF
  $ chmod +x bin/cmp bin/difft
  $ printf 'same\n' >source/identical.txt
  $ printf 'same\n' >destination/identical.txt
  $ bash "$TESTDIR/../../../scripts/chezmoi-diff-managed" "$PWD/destination/identical.txt"
