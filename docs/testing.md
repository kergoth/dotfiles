# Testing and Verification

The repository separates automated regression suites from Docker-backed host
setup tests. This guide describes what each check covers and where it fits in
the change workflow.

## Automated Test Dispatcher

`script/test` dispatches the pytest, Cram, and Node suites. With no suite
option it runs all three:

```console
./script/test
```

Select one suite with `-p`, `-t`, or `-j`. A path can be passed when exactly
one suite is selected:

```console
./script/test -p test/pytest/test_update_git_lock.py
./script/test -t test/cram/statusline
./script/test -j test/node/pi-statusline.test.mjs
```

`-n` prints the selected commands without running them. It does not select the
Node suite:

```console
./script/test -n
```

Use `./script/test -h` for verbosity and other dispatcher options.

### Direct Test Runners

The dispatcher delegates to these wrappers:

```console
./test/run-pytest test/pytest/test_update_git_lock.py
./test/run-cram test/cram/statusline
./test/run-node test/node/pi-statusline.test.mjs
```

With no path, each wrapper runs its complete suite under `test/pytest/`,
`test/cram/`, or `test/node/`.

## Container Setup Tests

`test/run-container` builds a distro image and runs selected setup phases as a
test user. Supported distro names are `arch`, `chimera`, `debian`, `fedora`,
and `ubuntu`.

Representative commands:

```console
# Test one distribution.
./test/run-container arch

# Test every distribution that has a container definition.
./test/run-container -a

# Preserve the terminal and enter a user shell after setup.
./test/run-container -i -s debian

# Exercise GUI-related installation conditions.
./test/run-container -w arch

# Show the selected work without invoking Docker.
./test/run-container -n arch
```

Use `./test/run-container -h` for setup-phase controls, image-only builds,
post-setup commands, secret seeding, and cache options.

Container tests are appropriate for Linux setup, distro package behavior, and
changes that depend on an installed system. They require Docker and may build
large images. A single distribution is usually enough for focused iteration.
The full matrix is most useful before adopting cross-distribution setup
changes.

## Test Environment Overrides

`test/run-container` accepts environment variables for controlled test cases:

| Variable | Intent |
| --- | --- |
| `DOTFILES_EPHEMERAL` | Override ephemeral-host detection. Workstation mode sets it to false. |
| `DOTFILES_HEADLESS` | Override headless-host detection. Workstation mode sets it to false. |
| `DOTFILES_PERSONAL` | Force or disable the personal-machine role. |
| `DOTFILES_WORK` | Force or disable the work-machine role. |
| `DOTFILES_SECRETS` | Force secret access on or off. Enabling it may mount host secret material. |
| `DOTFILES_SKIP_GPG_SECRET_IMPORT` | Skip GPG secret-key import to avoid interactive or unavailable key setup. |
| `DOTFILES_SKIP_CACHE` | Skip the shared Nix store and cache volumes. The `-C` option sets the same behavior. |
| `DOCKER_SERVER_ARCH` | Override Docker server architecture for tests of Arch Dockerfile selection. |
| `GITHUB_TOKEN` | Pass GitHub authentication into setup when a private dependency requires it. |
| `CLAUDE_CODE_OAUTH_TOKEN` | Pass Claude Code authentication into setup paths that require it. |
| `RUN_TEST_TRACE` | Enable shell tracing in the container test helper. |

Secret-bearing overrides are not routine defaults. Use them only for a test
that requires those credentials and account for the resulting host-to-container
exposure.

## Verification by Change Type

| Change | Focused check |
| --- | --- |
| Markdown documentation | Inspect `git diff`, run `git diff --check`, and verify changed local links |
| Chezmoi template syntax | `scripts/chezmoi-execute-template <template>` |
| Managed target rendering | `chezmoi cat --source-path <source-path>` |
| Final rendered home-directory change | `chezmoi diff`, and optionally `chezmoi apply` followed by live target inspection |
| Shell script | `sh -n <script>` and ShellCheck when available |
| PowerShell script | Render the template and run PSScriptAnalyzer when available |
| Python helper | `./script/test -p test/pytest/<test_file>.py` |
| Cram scenario | `./script/test -t test/cram/<suite>` |
| Node helper | `./script/test -j test/node/<test_file>.mjs` |
| Linux setup or package flow | `./test/run-container <distro>` |
| GUI installation path | `./test/run-container -w <distro>` |
| Cross-platform package change | Relevant renders plus the matching automated or container test |

`chezmoi apply`, setup scripts, Home Manager switching, and update scripts
change live state. They belong at the point where the live machine should be
updated.

## Troubleshooting

If a path is rejected by `script/test`, select exactly one suite. Paths cannot
be combined with multiple suite selectors.

For interactive setup failures, preserve stdin with `-i` and open a shell with
`-s`. Use `-r` to stop after `setup-root`, skipping `setup` and `setup-full`.
Use `-S` to skip `setup-system` and run only `setup`.

Arch has separate AMD64 and ARM64 Dockerfiles. Selection follows the Docker
server architecture, not necessarily the client host. Use
`DOCKER_SERVER_ARCH` only when testing that selection behavior.

A container build failure caused by unavailable registries, Docker storage, or
host disk space is an environment failure. Record it separately from failures
in the setup assertions.

## Related Documentation

- [Repository Architecture](repository-architecture.md)
- [Authoring Chezmoi Configuration](chezmoi-authoring.md)
- [Adding Software](contributing-software.md)
- [Contributor Guide](../CONTRIBUTING.md)
