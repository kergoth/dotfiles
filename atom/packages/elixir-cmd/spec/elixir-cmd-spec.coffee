ElixirCmd = require '../lib/elixir-cmd'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "ElixirCmd", ->
  activationPromise = null

  describe "when the elixir-cmd:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect("life").not.toBe "easy"
