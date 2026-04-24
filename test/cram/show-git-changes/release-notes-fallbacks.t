Fallback coverage for GitHub release-note fetching:

  $ . "$TESTDIR/helpers.sh"
  $ setup_review_env
  $ setup_local_repo() {
  >   local_repo="$WORKDIR/local-repo"
  >   cache_repo="$REPO_ROOT/.cache/git-clones/codex_cli"
  >   rm -rf "$local_repo" "$cache_repo"
  >   mkdir -p "$REPO_ROOT/.cache/git-clones"
  >   git init -q "$local_repo"
  >   git -C "$local_repo" config user.name "Test User"
  >   git -C "$local_repo" config user.email "test@example.com"
  >   git -C "$local_repo" config commit.gpgsign false
  >   printf 'base\n' >"$local_repo/history.txt"
  >   git -C "$local_repo" add history.txt
  >   git -C "$local_repo" commit -q -m "base"
  >   git -C "$local_repo" tag rust-v0.121.0
  >   printf 'update 122\n' >>"$local_repo/history.txt"
  >   git -C "$local_repo" commit -q -am "update 122"
  >   git -C "$local_repo" tag rust-v0.122.0
  >   printf 'update 123\n' >>"$local_repo/history.txt"
  >   git -C "$local_repo" commit -q -am "update 123"
  >   git -C "$local_repo" tag rust-v0.123.0
  >   printf 'update 124\n' >>"$local_repo/history.txt"
  >   git -C "$local_repo" commit -q -am "update 124"
  >   git -C "$local_repo" tag rust-v0.124.0
  >   rm -rf "$cache_repo"
  >   git clone -q --bare --single-branch --branch main "$local_repo" "$cache_repo"
  > }
  $ setup_local_repo

No gh binary on PATH:

  $ rm -f "$BINDIR/gh"
  $ write_fake_agent "$WORKDIR/no-gh-prompt.txt"
  $ run_show_git_changes https://github.com/openai/codex rust-v0.121.0 rust-v0.124.0 \
  >     --kind tag --tag-pattern '^rust-v[0-9]+[.][0-9]+[.][0-9]+$' --name codex_cli \
  >     >"$WORKDIR/no-gh.out" 2>"$WORKDIR/no-gh.err"
  $ echo $?
  0
  $ ! grep -q '^--- RELEASE NOTES' "$WORKDIR/no-gh-prompt.txt"

Non-GitHub host does not call gh:

  $ marker="$WORKDIR/gh-called"
  $ cat >"$BINDIR/gh" <<'EOF'
  > #!/usr/bin/env sh
  > set -eu
  > : >"$FAKE_GH_MARKER"
  > exit 2
  > EOF
  $ chmod +x "$BINDIR/gh"
  $ export FAKE_GH_MARKER="$marker"
  $ write_fake_agent "$WORKDIR/non-gh-prompt.txt"
  $ run_show_git_changes https://gitlab.com/wavexx/git-assembler rust-v0.121.0 rust-v0.124.0 \
  >     --kind tag --tag-pattern '^rust-v[0-9]+[.][0-9]+[.][0-9]+$' --name codex_cli \
  >     >"$WORKDIR/non-gh.out" 2>"$WORKDIR/non-gh.err"
  $ echo $?
  0
  $ ! test -e "$marker"
  $ ! grep -q '^--- RELEASE NOTES' "$WORKDIR/non-gh-prompt.txt"

Range endpoint not in the release list:

  $ write_fake_gh "$WORKDIR/missing-old.json"
  $ cat >"$WORKDIR/missing-old.json" <<'JSON'
  > {
  >   "compare": {
  >     "commits": [],
  >     "files": []
  >   },
  >   "releases_pages": {
  >     "1": [
  >       {
  >         "tag_name": "rust-v0.124.0",
  >         "draft": false,
  >         "published_at": "2026-04-20T00:00:00Z",
  >         "body": "New feature A\\n"
  >       },
  >       {
  >         "tag_name": "rust-v0.123.0",
  >         "draft": false,
  >         "published_at": "2026-04-18T00:00:00Z",
  >         "body": "Fix B\\n"
  >       },
  >       {
  >         "tag_name": "rust-v0.122.0",
  >         "draft": false,
  >         "published_at": "2026-04-17T00:00:00Z",
  >         "body": "Breaking change C\\n"
  >       },
  >       {
  >         "tag_name": "rust-v0.121.0",
  >         "draft": false,
  >         "published_at": "2026-04-16T00:00:00Z",
  >         "body": "Old release\\n"
  >       }
  >     ]
  >   },
  >   "releases_by_tag": {}
  > }
  > JSON
  $ write_fake_agent "$WORKDIR/missing-old-prompt.txt"
  $ run_show_git_changes https://github.com/openai/codex rust-v0.120.0 rust-v0.124.0 \
  >     --kind tag --tag-pattern '^rust-v[0-9]+[.][0-9]+[.][0-9]+$' --name codex_cli \
  >     >"$WORKDIR/missing-old.out" 2>"$WORKDIR/missing-old.err"
  $ echo $?
  0
  $ ! grep -q '^--- RELEASE NOTES' "$WORKDIR/missing-old-prompt.txt"
  $ grep -q 'Warning: could not resolve release notes' "$WORKDIR/missing-old.err"

gh api failure falls back silently:

  $ cat >"$BINDIR/gh" <<'EOF'
  > #!/usr/bin/env sh
  > set -eu
  > exit 1
  > EOF
  $ chmod +x "$BINDIR/gh"
  $ write_fake_agent "$WORKDIR/gh-fail-prompt.txt"
  $ run_show_git_changes https://github.com/openai/codex rust-v0.121.0 rust-v0.124.0 \
  >     --kind tag --tag-pattern '^rust-v[0-9]+[.][0-9]+[.][0-9]+$' --name codex_cli \
  >     >"$WORKDIR/gh-fail.out" 2>"$WORKDIR/gh-fail.err"
  $ echo $?
  0
  $ ! grep -q '^--- RELEASE NOTES' "$WORKDIR/gh-fail-prompt.txt"

More than 20 releases are capped:

  $ "$PYTHON_BIN" - <<'PY' >"$WORKDIR/cap.json"
  > import json
  > pages = []
  > releases = []
  > for version in range(125, 99, -1):
  >     releases.append({
  >         "tag_name": f"rust-v0.{version}.0",
  >         "draft": False,
  >         "published_at": f"2026-04-{(126 - version):02d}T00:00:00Z",
  >         "body": f"Release {version}\\n",
  >     })
  > print(json.dumps({
  >     "compare": {"commits": [], "files": []},
  >     "releases_pages": {"1": releases},
  >     "releases_by_tag": {},
  > }, indent=2))
  > PY
  $ write_fake_gh "$WORKDIR/cap.json"
  $ write_fake_agent "$WORKDIR/cap-prompt.txt"
  $ run_show_git_changes https://github.com/openai/codex rust-v0.100.0 rust-v0.125.0 \
  >     --kind tag --tag-pattern '^rust-v[0-9]+[.][0-9]+[.][0-9]+$' --name codex_cli \
  >     >"$WORKDIR/cap.out" 2>"$WORKDIR/cap.err"
  $ echo $?
  0
  $ grep -c '^## rust-v0\.' "$WORKDIR/cap-prompt.txt"
  20
  $ grep -c 'Showing 20 most recent releases' "$WORKDIR/cap-prompt.txt"
  1

Oversize bodies are truncated:

  $ "$PYTHON_BIN" - <<'PY' >"$WORKDIR/trunc.json"
  > import json
  > body = "X" * 9000
  > print(json.dumps({
  >     "compare": {"commits": [], "files": []},
  >     "releases_pages": {
  >         "1": [
  >             {
  >                 "tag_name": "rust-v0.124.0",
  >                 "draft": False,
  >                 "published_at": "2026-04-20T00:00:00Z",
  >                 "body": body,
  >             },
  >             {
  >                 "tag_name": "rust-v0.123.0",
  >                 "draft": False,
  >                 "published_at": "2026-04-18T00:00:00Z",
  >                 "body": "Old release\\n",
  >             },
  >         ]
  >     },
  >     "releases_by_tag": {},
  > }, indent=2))
  > PY
  $ write_fake_gh "$WORKDIR/trunc.json"
  $ write_fake_agent "$WORKDIR/trunc-prompt.txt"
  $ run_show_git_changes https://github.com/openai/codex rust-v0.123.0 rust-v0.124.0 \
  >     --kind tag --tag-pattern '^rust-v[0-9]+[.][0-9]+[.][0-9]+$' --name codex_cli \
  >     >"$WORKDIR/trunc.out" 2>"$WORKDIR/trunc.err"
  $ echo $?
  0
  $ grep -c '\[... release notes truncated ...\]' "$WORKDIR/trunc-prompt.txt"
  1
  $ awk 'prev && /\[\.\.\. release notes truncated \.\.\.\]/ { print length(prev); exit } { prev = $0 }' "$WORKDIR/trunc-prompt.txt"
  8000
