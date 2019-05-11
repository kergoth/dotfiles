# linter-elixir-credo

This linter plugin for [Linter][linter] provides an interface to mix [Credo][credo].
It will be used with files that have the "source.elixir" syntax
(ie. `*.ex; *.exs`).

## Installation

Plugin requires Linter package and it should install it by itself.
If it did not, please follow Linter instructions [here][linter].

### Method 1: In console

```ShellSession
$ apm install linter-elixir-credo
```

### Method 2: In Atom

1.  Edit > Preferences (Ctrl+,)
2.  Install > Search "linter-elixir-credo" > Install

[linter]: https://github.com/AtomLinter/Linter "Linter"
[credo]: https://github.com/rrrene/credo "Credo"

## Configuration
You can add other flags (like `--strict`) to the `mix credo` command in the settings.
