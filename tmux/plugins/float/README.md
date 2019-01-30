# Float

A plugin to quickly hide (float) and rejoin panes within a session.

This plugin was designed with a Clojure workflow in mind where being able to quickly open and close a repl and editor without losing the state and contents is very useful. The same could be done by
switching between windows / sessions, or just breaking panes into a new window and rejoining them as needed. The former is a bit of a pain, as it broke my workflow for me between hot patching a change
from the code in my editor to switching views to the session / window with my repl in it. With the same issue in reverse when experimenting in my repl and wanting to copy over the code I eventually
settled on back into my editor. The latter is what I ended up doing, but the memorization of pane to window mappings was also it's own kind of pain. As well having all the extra windows cluttered up
my status bar making it more difficult to switch between what ever other windows I had open, and added a constant shuffling of window numbers as I broke panes off and rejoined them. 


## Usage

A session called 'floating' is used to store all the windows used to cache the panes (referred to as floaters). Each session can have up to 3 floaters; repl, editor, and aux.

### Requirements

Tmux: version 2.5

  Earlier versions as far back as 2.2 may work, anything before didn't have hook support, but it has only been tested on 2.5

### Keybindings

To float a pane the following key bindings are used:

 * repl: `prefix + C-r`

 * aux: `prefix + C-h`

 * editor: `prefix + C-e`

To reattach a floater the following key bindings are used:

 * repl: `prefix + M-r`

 * aux: `prefix + M-h`

 * editor: `prefix + M-e`

## Installation

### With Tmux Plugin Manager (recommended)

Add this plugin to the list of TPM plugins in .tmux.conf

```
set -g @plugin 'git@gitlab.com:Jrahme/tmux-hide-pane.git'
```

### Manual Installation

Clone the repo:

```
$ git clone git@gitlab.com:Jrahme/tmux-hide-pane.git /path/to/your/tmux/plugin/directory
```

Add this line to the bottom of your .tmux.conf 

```
run-shell /path/to/your/tmux/plugin/directory/float.tmux
```

Optionally relaod your TMUX environment if you're already connected to a session

```
$ tmux source-file /path/to/your/tmux/plugin/directory/float.tmux
```

## Usage
The demo-screencast.json file is an asciinema screen cast of basic usage for floating panes and attaching floaters to windows. It can be viewed with the asciinema program from the terminal using the 
command.

```
asciinema play demo-screencast.json
```

## Documentation

The code itself is very documented and is - hopefully - easy enough to follow.

### Changing Keybindings

All keybindings are declared in the float.tmux file. They can be modified, removed, or extended upon as needed for your workflow. The codebase is flexible enough that if you were to want to add more
floaters you can.

### Adding Floaters

Floaters are simply windows in the floating session that follow the naming convention of originatingSession_floaterType where the originatingSession name is automatically grabbed from your current
session and the floaterType is determined by the first argument. If no floater type is provided, then aux is used by default.

For example, if you wanted to add a compiler floater bound to `prefix + C-c` and `prefix + M-c` you would add the following lines to the set_bindings function in float.tmux

```
tmux bind-key C-c run-shell "$CURRENT_DIR/scripts/hide_pane.sh compiler"
tmux bind-key M-c run-shell "$CURRENT_DIR/scripts/show_pane.sh compiler"
```

Both hide_pane.sh and show_pane.sh must pass the same argument.

### Float Modes

The default setting for `TMUX_FLOAT_MODE` is `NORMAL`. This can be changed to either `CLOBBER` or `SWAP` by changing the environment variable, or editing the float.tmux file.

The available modes are:

 * `NORMAL` : If a pane is already floated using that float, an error will echo, and nothing will be done.
 * `CLOBBER` : If a pane is already floated using that float, the current floater will be deleted and replaced with the pane that is attempting to be floated.
 * `SWAP` : If a pane is already floated using that float, it will be swapped with the current float.

To change it for just the current session you can use the tmux set-environment command, or to change the setting for all sessions you can use the -g flag for the set-environment command.

### Floating Session

This session should never be interacted with directly, it should always be in a detached state, and manipulated through the hide_pane.sh and show_pane.sh scripts. The plugin will create the
floating session, if it doesn't exist, when it is loaded. This floating session is used between all sessions as well, though the naming convention aims to prevent floaters from bleeding into other
sessions. 

Hooks will eventually be introduced as well that will prevent accidental attachment or switching to the float session. 

### Development

#### Testing

##### Requirements

  * Vagrant is installed

  * `/proc/sys/kernel/random/uuid` is accessible to the scripts

To run tests use the float-test script. It will clone and install the testing framework, run the tests, then remove the testing framework.

If you wish to keep the framework around during active development pass any argument to the float-test script and it will maintain the testing framework.
For testing with this framework afterwards simply call the run_tests script.

#### Branches

The branching strategy for float.tmux uses three branches;
  * master
  	* The master branch is where stable, and released or release ready code is.
  * test
  	* Test is the staging branch, where code presumed to be ready for the master branch can be tested in a clean environment
  * dev
  	* The dev branch is where active development is done. Any further branching for development should be done from this branch, and merged back into it as well.

Dev should always be considered unstable, and is the only branch that should be merged into test. Any child branches of dev must be merged into dev first before being merged into test.

Test is considered unstable, but should be much more reliable than dev and the derivatives of dev. Test is the only branch that can be merged into master

Master is where releases will be tagged, and where code considered stable resides. 


## Reporting Bugs

File them here, no promises on how quickly, or if ever, that I respond and resolve them.

## Credits

Jacob Rahme, DuckDuckGo, and the Man Pages

## License
GNU LESSER GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
Please see included COPYING files for license details
This license applies to all files included in this repository
Copyright Jacob Rahme 2017
