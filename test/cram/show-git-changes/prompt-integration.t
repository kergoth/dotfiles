Prompt integration for release-note gating:

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

Tagged GitHub source includes release notes first:

  $ cat >"$WORKDIR/tagged.json" <<'JSON'
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
  $ write_fake_gh "$WORKDIR/tagged.json"
  $ write_fake_agent "$WORKDIR/tagged-prompt.txt"
  $ run_show_git_changes https://github.com/openai/codex rust-v0.121.0 rust-v0.124.0 \
  >     --kind tag --tag-pattern '^rust-v[0-9]+[.][0-9]+[.][0-9]+$' --name codex_cli \
  >     >"$WORKDIR/tagged.out" 2>"$WORKDIR/tagged.err"
  $ grep -c '^--- RELEASE NOTES' "$WORKDIR/tagged-prompt.txt"
  1
  $ grep -c '^--- GIT LOG' "$WORKDIR/tagged-prompt.txt"
  1
  $ grep -c '^--- GIT DIFF' "$WORKDIR/tagged-prompt.txt"
  1
  $ grep -c 'Release notes describe the maintainer'"'"'s stated intent' "$WORKDIR/tagged-prompt.txt"
  1
  $ awk '
  >   /^--- RELEASE NOTES/{ rn = NR }
  >   /^--- GIT LOG/{ lg = NR }
  >   /^--- GIT DIFF/{ df = NR }
  >   END {
  >     if (rn < lg && lg < df) print "ordered";
  >     else print "unordered";
  >   }
  > ' "$WORKDIR/tagged-prompt.txt"
  ordered

Branch-based source omits release notes:

  $ rm -f "$BINDIR/gh"
  $ write_fake_agent "$WORKDIR/branch-prompt.txt"
  $ run_show_git_changes https://github.com/openai/codex rust-v0.121.0 rust-v0.124.0 \
  >     --kind branch --name codex_cli >"$WORKDIR/branch.out" 2>"$WORKDIR/branch.err"
  $ ! grep -q '^--- RELEASE NOTES' "$WORKDIR/branch-prompt.txt"
  $ ! grep -q 'Release notes describe the maintainer'"'"'s stated intent' "$WORKDIR/branch-prompt.txt"

Non-GitHub tagged source omits release notes:

  $ marker="$WORKDIR/gh-marker"
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
  $ ! test -e "$marker"
  $ ! grep -q '^--- RELEASE NOTES' "$WORKDIR/non-gh-prompt.txt"
  $ ! grep -q 'Release notes describe the maintainer'"'"'s stated intent' "$WORKDIR/non-gh-prompt.txt"
