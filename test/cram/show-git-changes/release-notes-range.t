Happy path scaffolding for release-notes range (expected to fail until `--kind/--tag-pattern` exist):

  $ . "$TESTDIR/helpers.sh"
  $ setup_review_env
  $ cat >"$WORKDIR/range.json" <<'JSON'
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
  >         "tag_name": "rust-v0.123.0-alpha.1",
  >         "draft": false,
  >         "published_at": "2026-04-19T00:00:00Z",
  >         "body": "Alpha notes\\n"
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
  >   "releases_by_tag": {
  >     "rust-v0.124.0": {
  >       "tag_name": "rust-v0.124.0",
  >       "draft": false,
  >       "published_at": "2026-04-20T00:00:00Z",
  >       "body": "New feature A\\n"
  >     },
  >     "rust-v0.123.0": {
  >       "tag_name": "rust-v0.123.0",
  >       "draft": false,
  >       "published_at": "2026-04-18T00:00:00Z",
  >       "body": "Fix B\\n"
  >     },
  >     "rust-v0.122.0": {
  >       "tag_name": "rust-v0.122.0",
  >       "draft": false,
  >       "published_at": "2026-04-17T00:00:00Z",
  >       "body": "Breaking change C\\n"
  >     },
  >     "rust-v0.121.0": {
  >       "tag_name": "rust-v0.121.0",
  >       "draft": false,
  >       "published_at": "2026-04-16T00:00:00Z",
  >       "body": "Old release\\n"
  >     }
  >   }
  > }
  > JSON
  $ write_fake_gh "$WORKDIR/range.json"
  $ write_fake_agent "$WORKDIR/prompt.txt"
  $ run_show_git_changes https://github.com/openai/codex rust-v0.121.0 rust-v0.124.0 \
  >     --kind tag --tag-pattern '^rust-v[0-9]+[.][0-9]+[.][0-9]+$' --name codex_cli > /dev/null 2>&1
  $ grep -c '^--- RELEASE NOTES' "$WORKDIR/prompt.txt"
  1
  $ grep -c 'rust-v0.124.0' "$WORKDIR/prompt.txt"
  1
  $ grep -c '^## rust-v0.123.0 ' "$WORKDIR/prompt.txt"
  1
  $ grep -c '^## rust-v0.122.0 ' "$WORKDIR/prompt.txt"
  1
  $ ! grep -q '^## rust-v0.121.0 ' "$WORKDIR/prompt.txt"
  $ ! grep -q 'rust-v0.123.0-alpha' "$WORKDIR/prompt.txt"
