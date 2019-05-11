# iex package

This package provides Elixir developers with the ability to run an Elixir IEx
(REPL) session in an Atom window. It has only been tested on OS X and is
unlikely to work properly (or at all) on other platforms.

![iex Screenshot](https://github.com/indiejames/atom-iex/raw/master/atom-iex.gif)


### Installation

```
apm install iex
```

It is _highly recommended_ that you add the key bindings below. These can be
customized as desired. They are not set by default to avoid conflicts with
other packages.

### Features

Aside from typing directly in the IEx session, the plugin provides actions
to improve workflow:

* Reset the project, restarting the application and compiling any files that
have changed since the last restart
* Run all tests in the project
* Run all tests in the currently open editor
* Run the test in the open editor in which the cursor resides
* Execute the currently selected text

These actions depend on `mix`, so they only work for `mix` generated projects
and require a `mix.exs` file at the top level.

### Key Bindings

Customizing Key Bindings:

```cson
'atom-workspace':
  'cmd-alt-l': 'iex:open'
  'cmd-alt-l down': 'iex:open-split-down'
  'cmd-alt-l up': 'iex:open-split-up'
  'cmd-alt-l left': 'iex:open-split-left'
  'cmd-alt-l right': 'iex:open-split-right'
  'cmd-alt-e': 'iex:reset'
  'cmd-alt-a': 'iex:run-all-tests'
  'cmd-alt-p': 'iex:pretty-print'

'atom-text-editor':
  'cmd-alt-h': 'iex:help'
  'cmd-alt-o': 'iex:gotoDefinition'
  'cmd-alt-x': 'iex:run-tests'
  'cmd-alt-j': 'iex:run-test'
  'cmd-alt-b': 'iex:pipe'
```

Adding these will provide the following:

#### Key Bindings and Events

| key binding | event | action |
| ----------- | ----- | ------ |
| `cmd + alt + l` | `iex:open` | Opens new IEx in new tab pane |
| `cmd + alt + l down` | `iex:open-split-up` | Opens new IEx tab pane in up split |
| `cmd + alt + l right` | `iex:open-split-right` | Opens new IEx tab pane in right split |
| `cmd + alt + l down` | `iex:open-split-down` | Opens new IEx tab pane in down split |
| `cmd + alt + l left` | `iex:open-split-left` | Opens new IEx tab pane in left split |
| `cmd + alt + e` | `iex:reset` | Stops the application, compiles any changed files with mix, then restarts the application. |
| `cmd + alt + a` | `iex:run-all-tests` | Run all the test in the project |
| `cmd + alt + x` | `iex:run-tests` | Run all the tests in the active editor |
| `cmd + alt + j` | `iex:run-test` | Run the test in which the cursor lies |
| `cmd + alt + h` | `iex:help` | Print the docstring for the function or module under the cursor |
| `cmd + alt + o` | `iex:gotoDefinition`| Jump to the definition of the function or module under the cursor |
| `cmd + alt + b` | `iex:pipe` | Pipe the currently selected text to the REPL and execute it |
| `cmd + alt + p` | `iex:pretty-print` | Pretty print the last evaluated expression |

### Fonts
The REPL defaults to using the same font family/size as Atom. Independent settings for the REPL will be available in the next release.

### Contributions

This package is originally based on the [Term2 Atom package](https://atom.io/packages/term2) with heavy modifications. Feel free to submit bugs or issue pull requests.
