Default discovery uses chezmoi's real source and destination mapping.

  $ command -v chezmoi >/dev/null 2>&1 || exit 80
  $ chezmoi_bin=$(command -v chezmoi)
  $ mkdir -p bin source destination
  $ : >chezmoi.toml
  $ cat >bin/chezmoi <<EOF
  > #!/usr/bin/env bash
  > exec "$chezmoi_bin" -c "$PWD/chezmoi.toml" -S "$PWD/source" -D "$PWD/destination" "\$@"
  > EOF
  $ cat >bin/difft <<'EOF'
  > #!/usr/bin/env bash
  > printf '%s %s\n' "${1##*/}" "${2##*/}"
  > EOF
  $ chmod +x bin/chezmoi bin/difft
  $ printf 'managed\n' >source/example
  $ printf 'local\n' >destination/example

  $ PATH="$PWD/bin:$PATH" bash "$TESTDIR/../../../scripts/chezmoi-diff-managed"
  == managed (rendered): */source/example == (glob)
  == destination: */destination/example == (glob)
  
  src example
