# linter-elixirc

This linter plugin for [Linter][linter] provides an interface to elixirc/mix.
It will be used with files that have the "source.elixir" syntax
(ie. `*.ex; *.exs`).

There are limitations with Elixirc that:

-   In case of compilation error, it will only show first error
-   It does not work with buffers, so linting on fly is disabled

## Installation

Plugin requires Linter package and it should install it by itself.
If it did not, please follow Linter instructions [here][linter].

### Method 1: In console

```ShellSession
$ apm install linter-elixirc
```

### Method 2: In Atom

1.  Edit > Preferences (Ctrl+, or Cmd+,)
2.  Install > Search "linter-elixirc" > Install

## Settings

Plugin should work with default settings. If not:

1.  Edit > Preferences (Ctrl+, or Cmd+,)

2.  Packages > Search "linter-elixirc" > Settings

3.  `elixirc path` option - use `which elixirc` to find path. ie.
    `/usr/local/bin/elixirc`

4.  `mix path` option - use `which mix` to find path. ie. `/usr/local/bin/mix`

5.  `always use elixirc` option - leave it disabled, unless `mix compile` is too slow.

6.  `mix env` option - Allows changing the Mix environment for lint runs. If using IEx at the same time as Atom this can be changed to allow IEx to pick up code changes.

## Usage

The operation of the linter is dependent on the type of Elixir files you are working with:

### Mix Projects

If you open a folder containing a Mix project (i.e. the file `mix.exs` exists
in the root folder of the project), the linter will use `mix compile` to
include all dependencies, unless you enable "Always use elixirc" setting.

### Single .ex Files

If you open a single `.ex` file, the linter will use `elixirc`. This will try
to find dependency build artifacts in the location where Mix projects normally
output to (`\_build/dev/lib/\*/ebin`). If your build output path is different,
then every external dependency will trigger a compile error.

### Elixir Scripts

Since `.exs` files are not compiled by `mix compile`, they are always linted
using `elixirc`, even if they appear within a Mix project.

### ExUnit Test files

ExUnit tests are always organised within `.exs` files, so they will also be
linted using `elixirc`. Test files can have extra dependencies that will not
be found within the normal dev build artifact directory. Instead, test files
are linted using the test build artifact directory (`\_build/test/lib/\*/ebin`).

## Why Do I Still See Dependency Errors?

Whether you're using the Mix or `elixirc` options for linting, it is still
possible to encounter false positive errors in your lint output, particularly
relating to dependencies. It can help to perform a `mix compile` from a
terminal to keep the project build output directory fresh, and a `mix test`
will help if you are seeing particular problems with errors in ExUnit test
files.

Sometimes Mix can get confused when files are renamed, so it can also help
to perform the occasional `mix do clean, compile`.

[linter]: https://github.com/AtomLinter/Linter "Linter"
