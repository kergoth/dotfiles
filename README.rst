My personal dotfiles and scripts, essentially the core contents of my home
directory. Largely self explanatory. One item worth mentioning is that one can
either use symlinks or detached (aka 'fake bare') git repositories to utilize
this in one's home directory. A 'link-homefiles' script exists for the former,
and a 'setup-homefiles' script for the latter. To setup from scratch::

$ curl https://raw.github.com/kergoth/homefiles/master/bin/setup-homefiles|sh
