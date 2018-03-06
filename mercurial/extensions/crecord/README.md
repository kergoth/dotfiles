## Crecord is Now Built-in to Mercurial ##
Since Mercurial version 3.5, crecord has been integrated into the Mercurial core.  In order to use it, add the following to your hgrc file:

```
[ui]
interface = curses
```

In recent versions of mercurial, it is also possible to use `interface.chunkselector` in your hgrc file instead of `interface`, if you only wish use curses for interactive commits, etc.

In order to use crecord after configuring your hgrc as shown above, you can use the `--interactive` flag with different hg commands.  For example:

```
hg ci -i
```

----

## crecord ##

The crecord mercurial extension allows you to interactively choose among the changes you have made (with line-level granularity), and commit only those changes you select.  After committing the selected changes, the unselected changes are still present in your working copy, so you can use crecord multiple times to split large changes into several smaller changesets.

![crecord screenshot](http://www.bitbucket.org/edgimar/crecord/wiki/images/main_window_screenshot.png "")

To get an idea of how (a slightly older version of) crecord works, see the [demonstration video](http://vimeo.com/13353810) prepared by Harvey Chapman.

### Installation ###

To install crecord, simply [download](http://bitbucket.org/edgimar/crecord/get/tip.zip) the latest archive of the extension, extract it into the folder of your choosing (e. g. `$HOME/.hgext`), and add the following to the `$HOME/.hgrc` (or the system-wide hgrc) file:

```
[extensions]
crecord = <path/to/crecord/package>
```

(if `[extensions]` is already present in this file, just add the crecord line somewhere below it.)  The path should be to the package directory (i.e. the one containing the `__init__.py` file).


Now you should have three new hg commands available to you:  crecord, qcrecord, and qcrefresh.  Use crecord for committing a changeset, use qcrecord for creating a new mq patch, and use qcrefresh for refreshing your current mq patch.  If you like analogies, 'crecord' is to 'commit', as 'qcrecord' is to 'qnew -f', as 'qcrefresh' is to 'qrefresh'.

When you're ready to commit some of your changes, type
```
hg crecord
```

This will bring up a window where you can view all of your changes, and select/de-select changes.  You can get more information on how to use it with the built-in help (press the '?' key).

Any feedback, bug-reports, and feature-requests are welcome.

**NOTE: crecord requires mercurial 2.1 or newer.  Earlier hg versions >= 1.7 will work with crecord revisions up to 55cf805**.