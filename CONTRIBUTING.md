# Contributor Guide

Thank you for your interest in improving this project. This project is open-source under the [BlueOak 1.0.0 Model License](https://spdx.org/licenses/BlueOak-1.0.0) and welcomes contributions in the form of bug reports, feature requests, and pull requests.

Here is a list of important resources for contributors:

- [Source Code](https://github.com/kergoth/dotfiles)
- [Issue Tracker](https://github.com/kergoth/dotfiles/issues)
- [Code of Conduct](CODE_OF_CONDUCT.md)

## How to report a bug

Report bugs on the [Issue Tracker](https://github.com/kergoth/dotfiles/issues).

When filing an issue, make sure to answer these questions:

- Which operating system (and powershell version, for Windows) are you using?
- Which version of this project are you using?
- What did you do?
- What did you expect to see?
- What did you see instead?

The best way to get your bug fixed is to provide a test case, and/or steps to reproduce the issue.

## How to request a feature

Request features on the [Issue Tracker](https://github.com/kergoth/dotfiles/issues).

## How to submit changes

Open a [Pull Request](https://github.com/kergoth/dotfiles/pulls) to submit changes to this project.

Your pull request needs to meet the following guidelines for acceptance:

- shellcheck should pass against all shell scripts
- PSScriptAnalyzer should pass against all powershell scripts

It is recommended to open an issue before starting work on anything. This will allow a chance to talk it over with the maintainers and validate your approach.

## Development and testing

The repository has two complementary test entrypoints:

- **`./script/test`**: manual container bring-up and debugging for Linux setup flows.
- **`./test/run-cram`**: structured Cram regression suites for repeatable scenario coverage.

Both rely on Docker for the container-backed Linux setup tests.

```console
# Run all distros through the manual container test entrypoint
./script/test

# Run a specific distro
./script/test arch

# Drop into a user shell after setup (useful for debugging)
./script/test -i debian

# Stop after setup-root, then drop into a shell
./script/test -r -i debian

# Run a command as the test user after setup
./script/test -c 'chezmoi data | grep -E "work|personal"' debian

# Run all structured Cram suites
./test/run-cram

# Run only the container-backed dotfiles scenarios
./test/run-cram test/cram/container

# Run only the statusline transcript tests
./test/run-cram test/cram/statusline
```

Supported distros: `arch`, `chimera`, `debian`, `fedora`, `ubuntu`.

Pass `GITHUB_TOKEN` in the environment to authenticate private dependency downloads
during setup.

The container Cram suite currently lives under `test/cram/container/`. These
tests keep `./script/test` as the human-facing container entrypoint, but define
named scenarios in Cram with helper scripts for matrix coverage and assertions.
