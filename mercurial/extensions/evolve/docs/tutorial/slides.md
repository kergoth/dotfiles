---
title: Changeset Evolution training
author: |
  <span style="text-transform: none;"><small>Boris Feld<br/><a href="https://octobus.net">octobus.net</a></small></span>
---

# Introduction

## Welcome

Hello everyone, and welcome to this Changeset Evolution training. During this session, you will learn how to safely rewrite history with Mercurial and Evolve, and how to collaborate together with your colleagues while rewriting the history at the same time.

This training is designed to last approximately ¾ hours.

You will use this repository during the training: [https://bitbucket.org/octobus/evolve_training_repo](https://bitbucket.org/octobus/evolve_training_repo). Please clone it somewhere relevant.

```bash
$ hg clone https://bitbucket.org/octobus/evolve_training_repo
$ cd evolve_training_repo
```

Copy the provided hgrc to ensure a smooth training experience:

```bash
$ cp hgrc .hg/hgrc
```

This training support will contains commands you are expected to type and launch. These commands will be in the following format:

```
$ COMMAND YOU ARE EXPECTED TO TYPE
output you are expecting to see
```

## Preliminary checks

#### Mercurial version

First let's use the following command to verify which version of Mercurial you are using:

```
$ hg --version
Mercurial Distributed SCM (version 4.4.2)
(see https://mercurial-scm.org for more information)

Copyright (C) 2005-2017 Matt Mackall and others
This is free software; see the source for copying conditions. There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

You need at least Mercurial version `4.1`. If you don't have a recent enough version, please call your instructor.

In order to activate the Evolve extension, add these lines in your user configuration (using the command `hg config --edit`):

```ini
[extensions]
evolve =
topic =
```

#### Mercurial extensions

Now let's check the version of your extensions. You will need all of these for the training:

```
$ hg --version --verbose
[...]
  evolve       external  7.1.0
  topic        external  0.6.0
  rebase       internal
  histedit     internal
```

# The Basics

<!-- #### What is Changeset Evolution?

With core Mercurial, changesets are permanent and history rewriting has been discouraged for a long time. You can
commit new changesets to modify your source code, but you cannot
modify or remove old changesets.

For years, Mercurial has included various commands that allow
history modification: ``rebase``, ``histedit``, ``commit --amend`` and so forth.
However, there's a catch: until now, Mercurial's various mechanisms for
modifying history have been *unsafe* and expensive, in that changesets were
destroyed (“stripped”) rather than simply hidden and still easy to recover.

Changeset Evolution makes things better by changing the behaviour of most existing
history modification commands so they use a safer mechanism (*changeset
obsolescence*, covered below) rather than the older, less safe *strip*
operation.

``evolve`` is built on infrastructure in core Mercurial:

  * *Phases* (starting in Mercurial 2.1) allow you to distinguish
    mutable and immutable changesets.

  * *Changeset obsolescence* (starting in Mercurial 2.3) is how
    Mercurial knows how history has been modified, specifically when
    one changeset replaces another. In the obsolescence model, a
    changeset is neither removed nor modified, but is instead marked
    *obsolete* and typically replaced by a *successor*. Obsolete
    changesets usually become *hidden* as well. Obsolescence is a
    disabled feature in Mercurial until you start using ``evolve``.

 XXX More than just than obsolescence in core ? XXX

 XXX The part below is a bit overselling XXX

Some of the things you can do with ``evolve`` are:

  * Fix a mistake immediately: “Oops! I just committed a changeset
    with a syntax error—I'll fix that and amend the changeset so no
    one sees my mistake.” (While this is possible using default
    features of core Mercurial, Changeset Evolution makes it safer.)

  * Fix a mistake a little bit later: “Oops! I broke the tests three
    commits back, but only noticed it now—I'll just update back to the
    bad changeset, fix my mistake, amend the changeset, and evolve
    history to update the affected changesets.”

  * Remove unwanted changes: “I hacked in some debug output two
    commits back; everything is working now, so I'll just prune that
    unwanted changeset and evolve history before pushing.”

  * Share mutable history with yourself: say you do most of your
    programming work locally, but need to test on a big remote server
    somewhere before you know everything is good. You can use
    ``evolve`` to share mutable history between two computers, pushing
    finely polished changesets to a public repository only after
    testing on the test server.

  * Share mutable history for code review: you don't want to publish
    unreviewed changesets, but you can't block every commit waiting
    for code review. The solution is to share mutable history with
    your reviewer, amending each changeset until it passes review.

  * Explore and audit the rewrite history of a changeset. Since Mercurial is
    tracking the edits you make to a changeset, you can look at the history of
    these edits. This is similar to Mercurial tracking the history of file
    edits, but at the changeset level. -->

In this section, we are going to learn how to do basic history rewriting like rewriting a changeset or rebasing.

### Amend

The smallest possible history rewriting is rewriting a changeset description message. We often save and close the editor too early, and/or haven't seen a typo.

It is very easy to fix a changeset description message, so let's do that. First be sure that you are in your clone of the `evolve_training_repo`. then update to the `typo` branch:

```
$ hg update typo
```

Check what the current repository looks like:

~~~raw-file
output/fix-a-bug-base.log
~~~

~~~graphviz-file
graphs/fix-bug-1.dot
~~~

We have a root commit and another based on it. Double-check that you are on the right changeset with the `hg summary` command:

~~~raw-file
output/fix-a-bug-base-summary.log
~~~

The current commit description message seems wrong, `Fx bug`, there is definitely a letter missing. Let's fix this typo with the `hg commit` command.

Usually, the `hg commit` is used to create new commit but we can use the ``--amend`` option to instead modify the current commit (see `hg help commit` for more information):

~~~
$ hg commit --amend --message "Fix bug"
~~~

Let's take a look at the repository now:

~~~raw-file
output/amend-after.log
~~~

~~~graphviz-file
graphs/fix-bug-2.dot
~~~

The logs before and after amending looks pretty similar, we are going to analyze the differences later. Did you catch the differences?

### Rebase

<!-- XXX probably needs a sentence about the merge (Why do you want to avoid it) XXX -->

Let's try to rebase something now. Let's say that you have a branch named `build/linuxsupport-v2` which was started on another branch named `build/v2`. Everything was fine until `build/v2` grew a new commit, and now you want to rebase `build/linuxsupport-v2` on top of `build/v2` to be up-to-date with other the changes:

```
$ hg update build/linuxsupport-v2
```

~~~raw-file
output/rebase-before.log
~~~

~~~graphviz-file
graphs/rebase-before.dot
~~~

<!-- XXX-REVIEW: Explain rebase CLI interface -->

Let's rebase our branch on top of `build/v2` with the `hg rebase` command. The `hg rebase` command have many ways to select commits:

1. Explicitly select them using "--rev".
2. Use "--source" to select a root commit and include all of its descendants.
3. Use "--base" to select a commit; rebase will find ancestors and their descendants which are not also ancestors of the destination.
4. If you do not specify any of "--rev", "source", or "--base", rebase  will use "--base ." as above.

For this first example, we are gonna stays simple and explicitly select the commits we want to rebase with the `--rev` option.

The `hg rebase` command also accepts a destination with the ``--dest`` option. And finally, as we are using named branches, don't forget to use the `--keepbranches` or the rebased commits will be on the wrong branch:

~~~raw-file
output/rebase.log
~~~

Now we have a nice, clean and flat history:

~~~raw-file
output/rebase-after.log
~~~

~~~graphviz-file
graphs/rebase-after.dot
~~~

For more details about how to use the `hg rebase` command, see `hg help rebase`.

### Under the hood

What did happened when we just ran the `hg amend` and `hg rebase` commands? What was done exactly to make the whole process work seamlessly?

Let's go back to our previous amend example.

##### Amend

When we did our amend, the status of the repository was:

~~~raw-file
output/behind-the-hood-amend-before-hash-hidden.log
~~~

~~~graphviz-file
graphs/fix-bug-1.dot
~~~

And after the amend, the repository looked like:

~~~raw-file
output/behind-the-hood-amend-after.log
~~~

~~~graphviz-file
graphs/fix-bug-2.dot
~~~

Do you see what is the difference?

The big difference, apart from the fixed changeset message, is the revision hash and revision number. The `Fix bug` revision changed from `d2eb2ac6a5bd` to `708369dc1bfe`. It means that the fixed changeset is a new one. But where did the old changeset go?

It didn't actually go very far, as it just became **hidden**. When we rewrite a changeset with the Evolve extension, instead of blindly delete it, we create a new changeset and hide the old one, which is still there, and we can even see it with the `--hidden` option available on most Mercurial commands:

~~~raw-file
output/under-the-hood-amend-after-log-hidden.log
~~~

Notice the `x` in the log output which shows that a changeset is hidden.

In addition to hiding the original changeset, we are also storing additional information which is recording the relation between a changeset, the **precursor** and its **successor**. It basically stores the information that the commit **X** was rewritten into the commit **Y** by the user **U** at the date **D**. This piece of information is stored in something called an **obsolescence marker**. It will be displayed like this:

~~~graphviz-file
graphs/fix-bug-3.dot
~~~

Here the commit **5d48a444aba7** was rewritten into **708369dc1bfe**. Also please notice the difference of style of the commit **5d48a444aba7**, that's because it have been rewritten.

##### Rebase

**Successors** don't need to share anything with their **precursor**. They could have a different description message, user, date or even parents.

Let's look at our earlier rebase example. The status before the rebase was:

~~~raw-file
output/behind-the-hood-rebase-before-hash-hidden.log
~~~

~~~graphviz-file
graphs/rebase-before.dot
~~~

And after it was:

~~~raw-file
output/behind-the-hood-rebase-after.log
~~~

~~~graphviz-file
graphs/rebase-after.dot
~~~

Did the same thing happen under the hood?

Yes, exactly! The old changesets are still around, and they are just hidden.

~~~raw-file
output/rebase-after-hidden.log
~~~

And we created three **obsolescence markers**, between each rebased commit and its **successor**:

~~~graphviz-file
graphs/rebase-after-hidden.dot
~~~

### Evolution History

Mercurial is designed to track the history of files. Evolution goes beyond, and tracks the history of the history of files. It basically tracks the different versions of your commits.

As it is a new dimension of history, the classical Mercurial commands are not always the best to visualize this new history.

We have seen that we can see the **hidden** changesets with the `--hidden` option on `hg log`:

~~~raw-file
output/under-the-hood-amend-after-log-hidden.log
~~~

To visualize the **obsolescence history** of a particular changeset, we can use the dedicated command `hg obslog`. The option are quite similar to `hg log` (you can read `hg help obslog` for more information):

~~~raw-file
output/under-the-hood-amend-after-obslog.log
~~~

We can even print what changed between the two versions with the `--patch` option:

~~~raw-file
output/under-the-hood-amend-after-obslog-patch.log
~~~

Obslog works both ways, as it can display **precursors** and **successors** with the `--all` option:

```raw-file
output/under-the-hood-amend-after-obslog-no-all.log
```

~~~raw-file
output/under-the-hood-amend-after-obslog-all.log
~~~

~~~graphviz-file
graphs/fix-bug-3.dot
~~~

We can also use obslog on the changesets that we rebased earlier:

~~~raw-file
output/under-the-hood-rebase-after-obslog.log
~~~

Why the `hg obslog` command is only showing two commits while we rebased three of them?

```raw-file
output/under-the-hood-rebase-after-obslog-branch.log
```

And why the `hg obslog` command show disconnected graphs when asking for the obslog of the whole branch?

~~~graphviz-file
graphs/rebase-after-hidden.dot
~~~

While these two obsolescence logs look very similar —because they show a similar change—, the two changesets log histories looked quite different.

Using the `hg log` command to understand the Evolution history is hard because it is designed for displaying the files history, not the Evolution history. The `hg obslog` has been specially designed for this use-case and is more suited for this use-case.

#### TortoiseHG

TortoiseHG should be able to display obsolescence history for your repositories.

To display all the **hidden** commits, we need to click on the **search icon**, then on the **Show/Hide hidden changesets** at the right of the **filter** check box. It is also possible to provide a *revset* to filter the repository, for example `:6 + ::20` to display only the revisions we have been working with until now:

![](img/thg-obs.png)

<!-- #### Deroulement

Travail chacun de son côté pour apprendre à utiliser:

- Réecriture de changeset
- Affichage de l'obsolescence, log, obslog


- Vérifier que chacun sait utiliser les commandes de base
- Vérifier que chacun sait utiliser les commandes de visu, hg log, hg log -G, thg?
=> Pas trop longtemps // répartir

- Créer un commit
- Le amend sans evolve == bundle
- Strip?
- rebase sans evolve?
- Why is it bad? exemple
(Peut-etre pas leur faire pratiquer amend sans evolve, ca prends du temps)

- With evolve, now
- Activate it, check version
- Amend with evolve
- rebase with evolve

- What happened?
- View obs-history, hg log, obslog -->


# Medium level

## More rewriting commands

The `hg amend` and `hg rebase` commands are the foundations for changeset evolution in Mercurial. You could do everything with these, but, luckily for us, the evolve extension provides human-friendly commands for common needs. We are going to see them now:

### Amend

The Evolve extension provides its own `hg amend` command, which is similar to the `hg commit --amend` that we used previously, and adds several nice features:

- The `-e`/`--edit` option edits the commit message in an editor, which is not opened by default any more.
- The user and date can be updated to the current ones with the `-U`/`--current-user` and `-D`/`--current-date` options.
- More capabilities for rewriting the changeset.

The `hg amend` command accepts either file paths, to add all the modifications on these files in the current changeset, or the `-i`/`--interactive` option to select precisely what to add in it.

We are going to use it to rewrite the author of the changeset:

```
$ hg update amend-extract
```

We have two commits on the **amend-extract** branch:

```raw-file
output/amend-extract-before.log
```

The user for the **amend-extract** head seems wrong, so let's fix it with the `hg amend` command:

```raw-file
output/amend-user.log
```

Now let's check that the user has been amended correctly:

```raw-file
output/amend-user-after-export.log
```

The user is the good one, but the diff looks weird. It seems that both a bad file **and** an incorrect line have slipped in this commit. We need to fix that.

There are several solutions here, and we could manually edit the file and amend it. But, luckily for us, the `hg amend` command also has a very helpful option named `--extract` that will help us.

### Amend extract

The `hg amend` command is meant to move file modifications from your working directory to the current changeset (which is considered as the parent of working directory). `hg amend` also provides the option `--extract` that can be used to invert the meaning of the command: with this option, `hg amend` will move the file modifications from your current changeset to your working directory.

This is often used to remove a file or a line that is not meant to be in the current commit.

As usual, we can either pass file paths or use the `-i` option to select which lines to extract.

First, let's extract the badfile:

```raw-file
output/amend-extract-badfile.log
```

Now let's check the status of the changeset and the working directory:

```raw-file
output/amend-extract-badfile-after-export.log
```

The file is not included in the commit anymore! Did it just vanish? What if you wanted to keep it and, for example, put it in another commit?

Don't worry, the extracted files and lines still are in your working directory:

```raw-file
output/amend-extract-badfile-after-status.log
```

As we are not going to need this file anymore, let's forget it with the `hg revert` command:

```raw-file
output/amend-extract-badfile-after-revert.log
```

Also don't forget to remove the file:

```bash
$ rm badfile
```

Ok. Now we still have a line to extract from our commit, so let's use the handy interactive mode of `hg amend --extract` to extract lines:

```raw-file
output/amend-extract.log
```

Much better! One last thing, as the line that we extracted is still in our working directory, just like when we extracted a file:

```raw-file
output/amend-extract-after-status.log
```

```raw-file
output/amend-extract-after-diff.log
```

Don't forget to revert the change, as we are not going to need it any more:

```raw-file
output/amend-extract-after-revert.log
```

Now let's take a look at the obsolescence history:

```raw-file
output/amend-extract-after-obslog.log
```

The obslog is read from bottom to top:

- First we rewrite the user,
- Then we extracted a whole file,
- Then we extracted a line from a file

We have made three changes that generated three **successors**.

```graphviz-file
graphs/amend-extract-after-hidden.dot
```

### Fold

Sometimes we want to group together several consecutive changesets. Evolve has a command for that: `hg fold`. First, let's update to the right branch:

```
$ hg update fold
```

Three changesets change the same file, and they could be folded together. This would make a cleaner and more linear history, and hide those pesky intermediate changesets:

```raw-file
output/fold-before.log
```

```graphviz-file
graphs/fold-before.dot
```

We all have been in a similar situation. Let's make a nice and clean changeset with fold:

```raw-file
output/fold.log
```

That was easy!

```raw-file
output/fold-after.log
```

```raw-file
output/fold-after-hidden.log
```

Can you imagine what the graphs will looks like?

```raw-file
output/fold-after-hidden-obslog.log
```

```graphviz-file
graphs/fold-after-hidden.log
```

### Split

Sometimes you want to `fold` changesets together, and sometimes you want to `split` a changeset into several ones, because it is too big.

```
$ hg update split
```

Evolve also has a command for that, `hg split`:

```raw-file
output/split-before.log
```

```graphviz-file
graphs/split-before.dot
```

Split accepts a list of revisions and will interactively ask you how you want to split them:

```raw-file
output/split.log
```

Now let's check the state of the repository:

```raw-file
output/split-before-after.log
```

```graphviz-file
graphs/split-before-after-hidden.dot
```

It looks good. What about the obsolescence history?

```raw-file
output/split-after-obslog.log
```

```raw-file
output/split-after-obslog-all.log
```

### Prune

After rewriting and rebasing changesets, the next common use case for history rewriting is removing a changeset.

But we can't permanently remove a changeset without leaving a trace. What if other users are working with the changeset that we want to remove?

The common solution is to mark the changeset as removed, and simulate the fact that it has been removed.

This is why the Evolve extension is offering the `prune` command. Let's try to prune a changeset:

```
$ hg update prune
```

```raw-file
output/prune-before.log
```

```graphviz-file
graphs/prune-before.dot
```

`prune` is easy to use, just give it the revisions you want to prune:

```raw-file
output/prune.log
```

Now the changeset is not visible any more:

```raw-file
output/prune-after.log
```

But we can still access it with the `--hidden` option:

```raw-file
output/prune-after-hidden.log
```

The output of `obslog` changes a bit when displaying pruned changesets:

```raw-file
output/prune-after-obslog.log
```

```graphviz-file
graphs/prune-after-hidden.dot
```

### Histedit

The `hg histedit` command is a power-user command. It allows you to edit a linear series of changesets, and applies a combination of operations on them:

- 'pick' to [re]order a changeset
- 'drop' to omit changeset
- 'mess' to reword the changeset commit message
- 'fold' to combine it with the preceding changeset (using the later date)
- 'roll' like fold, but discarding this commit's description and date
- 'edit' to edit this changeset (preserving date)
- 'base' to checkout changeset and apply further changesets from there

It's similar to the `git rebase -i` command.

First, let's update to the right branch:

```
$ hg update histedit
```

```raw-file
output/histedit-before-log.log
```

```graphviz-file
graphs/histedit-before.dot
```

When launching the `hg histedit` command, an editor will show up with the following contents:

```raw-file
output/histedit-no-edit.log
```

Swap the first two lines with your text editor:

```raw-file
output/histedit-commands.log
```

Save and exit. Histedit will apply your instructions and finish.

Let's see the state of the repository:

```raw-file
output/histedit-after-log.log
```

```raw-file
output/histedit-after-log-hidden.log
```

```graphviz-file
graphs/histedit-after-hidden.dot
```

<!-- #### Deroulement

- prune with evolve

- advanced commands
- fold
- split -->

## Stack

### Stack definition

One big problem when working with a DVCS to identify and switch between the different features/bugfixes you are working on.

### Named branches

One solution is to use **named branches**. Named branches are a battle-tested, long-supported solution in Mercurial. Basically, a branch name is stored inside each changeset.

This solution has several advantages:

- It's supported in all recent-ish Mercurial versions.
- It's simple to use.
- Most tools are supporting it.

But it also has several disadvantages:

- Branches do not disappear once they are merged. You need to explicitely close them with `hg commit --close-branch`.
- Branches are lost when rebasing them without the `--keepbranches` option of the `hg rebase` command.
- New branches needs to be explicitly pushed with the `--new-branch` option of the `hg push` command.

We will use named branches for this training, but other solutions are possible, like [topics](https://www.mercurial-scm.org/doc/evolution/tutorials/topic-tutorial.html).

<!-- #### Topics
 -->

### Stack

The `topic` extension provides a command to show your current stack, no matter how you defined it. Let's try it on some changesets that we rewrote earlier:

```
$ hg update typo
```

```raw-file
output/stack-typo.log
```

The stack output shows three important data:

- First, which branch you are working on (a.k.a. the **current** branch).
- Then, all the commits that you are currently working on, with the current one highlighted.
- Finally, which commit your branch is based on (**b0**).

This branch is not very interesting, so let's move to another one.

```
$ hg update build/linuxsupport-v2
```

```raw-file
output/stack-rebase.log
```

This is more interesting, as now we can see all the three changesets grouped together in the same view. The stack view provides a nice and linear view, even if the changesets are not immediate neighbors.

### Stack movement

There is an easy way to navigate in your stack, the `hg next` and `hg prev` commands:

```raw-file
output/stack-rebase-prev-from-b3.log
```

```raw-file
output/stack-rebase-stack-b2.log
```

And now for the `hg next` command:

```raw-file
output/stack-rebase-next-from-b2.log
```

```raw-file
output/stack-rebase.log
```

The stack view also displays nice and easy relative ids for these changesets. You can use theses ids in all commands, for example with the `hg export` command:

```raw-file
output/stack-rebase-export-b1.log
```

Or with the `hg update` command:

```raw-file
output/stack-rebase-update-b2.log
```

These ids are handy because you don't need to manipulate changeset ids or revision numbers: contrary to the latters, the formers won't be affected by history edition. They only depend on their order in the branch.

```raw-file
output/stack-rebase-stack-b2.log
```

### Edit mid-stack

Now that we are in the middle of a stack, let's try amending a commit. The current commit message ends with a dot `.`, and we want to remove it:

```raw-file
output/stack-rebase-stack-b2.log
```

```raw-file
output/edit-mid-stack.log
```

The message `1 new orphan changesets` means that, by amending a changeset having a child, this child is now **unstable**, as we can see with the `hg stack` command:

```raw-file
output/edit-mid-stack-after-stack.log
```

`hg stack` tries to simplify the view for you. We have amended **b2**, and **b3**'s parent is the precursor version of **b2**, so it is not stable any more. It is now **orphan**.

For once, let's use log to see in detail in which situation we are:

```raw-file
output/edit-mid-stack-after-log.log
```

```graphviz-file
graphs/edit-mid-stack-after.dot
```

How can we resolve this situation? It is actually very easy, and we are going to see how in the next section.

<!-- #### Deroulement

Tout seul:

- Topic? stack?

- Comment définir ce sur quoi on travaille?

- Solution possible: named branches
- Avantages des branches nommées
- Inconvénients des branches nommées

- Solution possible: topic
- Avantages des topic
- Inconvénients des topic
- Commands: hg stack, hg topics, hg topics --age, hg topics --verbose
(Pas forcément topic, risque de confusion)

- Visualiser une stack avec hg stack, hg show stack?
- Se déplacer dans une stack avec hg prev/hg next

- Editer au milieu d'une stac

- Absorb? (Pas sous windows dur à installer) -->

## Basic instabilities + stabilization

Instabilities are a normal step when using Evolve-powered workflows. Several tools are provided to fix them smoothly.

#### Log

First, let's clarify some vocabulary. An **obsolete** changeset is a changeset that has been rewritten. In the current stack, only one commit is `obsolete`:

```raw-file
output/basic-stabilize-before-log-obsolete.log
```

A changeset can also be **unstable**, meaning that it could be subject to one or more **instabilities**:

* **orphan**, a changeset whose an ancestor is **obsolete**.
* **content-divergent**, a changeset which has been rewritten in two different versions.
* **phase-divergent**, a changeset which has been both rewritten and published.

For the moment, we will only see the **orphan** instability. We can display the **instabilities** of a commit with the `{instabilities}` template keyword:

```raw-file
output/basic-stabilize-before-log-instabilities.log
```

Here we have also one **orphan** commit, which is the child of the **obsolete** commit.

#### Evolve --list

The `hg evolve` command has a `--list` option which can list all the instabilities of your repository.

```raw-file
output/basic-stabilize-before-evolve-list.log
```

#### TortoiseHG

Tortoise HG also has a nice support for displaying the instabilities of your repository:

![](img/thg-mid-stack.png)

If you want to filter to get a better view, you can use the *revset* `branch(build/linuxsupport-v2)`:

![](img/thg-mid-stack-filter.png)

#### Stabilization using `hg next --evolve`

```raw-file
output/edit-mid-stack-after-stack.log
```

In our current situation, a simple solution to solve the instability is to use the `hg next` command with the `--evolve` option. It will update to the next changeset on the stack, and stabilize it if necessary:

```raw-file
output/basic-stabilize-next-evolve.log
```

Here, it just rebased our old version of `b3` on top of the new version of `b2`.

And now `hg stack` shows us a clean view again:

```raw-file
output/basic-stabilize-after-stack.log
```

That's better!

```graphviz-file
graphs/basic-stabilize-after-stack.dot
```

<!-- #### hg evolve

XXX-REVIEW: Later -->

# Advanced

## Moving change from one commit to another

Create two commits:

- The first one create a new file, add some content in it.
- The second one create another file and modify the first file.

Now try to move the change on the first file present in the second commit back in the first commit so that the first commit contains all change on the first file and the second change contains all changes on the second file.

## Exchange

Coming Soon™

<!-- ## Exchange -->

<!-- #### Obsolescence History Synchronization

XXX Too theoritical (except first sentence maybe) XXX

While obsolescence markers are already useful locally, they unlock their true power when they are exchanged. They are the piece of information that are fundamental to achieve the goal of synchronizing repositories state.

If two people starts with the same repository and they each make some modifications, once exchanging all their obsolescence marker with their partner; they should have the same repository state.

Given a repository state R, if user A creates obs-markers OBSA and user B creates obs-markers OBSB, `R + OBSA + OBSB = R + OBSB + OBSA`.

This characteristic is the foundation to make people confident with their modification as they know that they will be able to synchronize with someone and have exactly the same state. XXX-REVIEW BOF

#### When are exchanged obsolescence markers

Obsolescence markers are exchanges during all usual exchange methods:

- Obsolescence markers related to pushed heads are pushed during `hg push`.
- Obsolescence markers related to pulled heads are also pulled during `hg pull`.
- Obsolescence markers are included in bundles.

New obsolescence markers are automatically applied, so after a `pull` some changesets could become obsolete as they have been rewritten by a new changeset you just pulled.

XXX-REVIEW: Add example?

The obsolescence markers only apply to draft changesets though.

###### Let's exchange obsmarkers

Let's try to push and pull some obsolescence-markers, first copy your repository somewhere else, for example:

```raw-file
output/basic-exchange-clone.log
```

#### Phases

XXX Too theoritical XXX

There is a dimension that have been overlooked until now. **Phases**. What are phases? Phases is an information about a changeset status, a changeset could be in one phase at any time:

* **draft**, the default phase a changeset is just after committing it. This phase denotes that the changeset is still a work in progress. It could be rewritten, rebased, splitted, folded or even pruned before it's considered finished. This state allow a changeset to evolve into another version.
* **public**, the phase a changeset is when it's considered finished. The changeset would likely have been reviewed, tested and even released when they are in this state. This state forbids any rewriting on changeset which are public.
* **secret**, this phase is for changesets that should never be shared. It could be local-only modifications for your environment or a way to commit credentials without sharing it outside. This state allow a changeset to be rewritten, like to be rebased on the most up-to-date head for example.

Phase are about changesets but they are not part of the commit information, meaning that changing the phase of a changeset does not change it's changeset hash.

These phases are ordered (public < draft < secret) and no changeset can be in
a lower phase than its ancestors. For instance, if a changeset is public, all
its ancestors are also public. Lastly, changeset phases should only be changed
towards the public phase.

Changeset are created in the **draft** phase by default and move to the **public** phase in several scenarios.

#### Phase movement

The original scenario for **phases** is to permits local rewriting of changesets that have not been pushed. You create draft changesets, you test them locally, possibly amend them, rebased them or clean it then you push it to a server and they become **public** at this occasion.

While this scenario is pretty sensible, not altering shared commit make a lot of problems disappears, move powerful workflows could be unlocked when decoupling the sharing part with the publishing part.

By default, hg server are in **publishing** mode, meaning that:

- all draft changesets that are pulled or cloned appear in phase public on the client.

- all draft changesets that are pushed appear as public on both client and server.

- secret changesets are neither pushed, pulled, or cloned.

Hg servers could also be configured into **non-publishing** mode with this configuration:

```ini
[phases]
publish = False
```

When pushing to a **non-publishing** mode, draft changesets are not longer made **public** anymore, allowing people and teams to share unfinished works. This way, it's still possible to edit a changeset after sharing it, meaning that:

- a changeset could be updated after it has been reviewed.
- a changeset could be updated after a Continuous Integration tool show that some tests on some platforms are broken.
- a changeset could be updated after a co-worker tried implementing another feature on top of it.

#### Usual phase workflow

While sharing unfinished works is powerful, move **draft** changeset to the **public** phase when pushing them to **publishing** server is powerful by its simplicity. Its easy to understand as **non-publishing** servers could be seen as work-in-progress while **publishing** servers is meant for public, finished work that you commit to never alter. XXX-REVIEW Bof

The usual way of having both advantages is to have both a **non-publishing** server where developers push for sharing work and asking for review and another **non-publishing** server when ready changesets are pushed, marking them as **public**.

This way the **publishing** repository will only contains **public** changesets while the **non-publishing** one will contains all the **public** changesets plus all the **drafts** changesets.

#### Phase visualization

Phase is not shown by default in `hg log`, but we can ask for it with the `{phase}` template:

```raw-file
output/split-after-log-phase.log
```

It's also possible to use `hg phase` to recover the phase of a revision(s):

```raw-file
output/split-after-phase.log
```

You might wondered why you saw different forms in the graphs before, that was the phase that were shown. From now on, public changesets will be shown as circles, drafts changesets will be shown as hexagons and secrets changesets will be shown as squares:

```graphviz-file
graphs/phases.dot
```

#### Phase selection

Phase have a few revsets for selecting changesets by their phases:

- `public()`, select all public changesets.
- `draft()`, select all draft changesets.
- `secrets()`, select all secret changesets.

It could be used to:

- select all non-public changesets with `hg log -r "not public()"`.
- change all secret changesets to draft with `hg phase --draft "secret()"`. -->

<!-- #### Deroulement

Toujours tout seul:

- push / pull
- phases -->

<!-- ## Advanced -->

<!-- #### Deroulement

Advances use-cases:

- Move part of a changeset to another (split+fold) -->

<!-- ## Let's start the fun -->

<!-- #### Deroulement

À deux:

- troubles, divergence, orphan
- troubles visualization
- troubles resolution
- collaboration workflow

Parler du happy path d'abord -->

<!-- ## Content to integrate (presentation old content)

#### Once upon a time

#### You fix a bug

(With a small typo)

~~~graphviz-file
graphs/fix-bug-1.dot
~~~

#### You write more code

<img src="https://media0.giphy.com/media/13GIgrGdslD9oQ/giphy.gif">

#### Urgent merge

<img src="https://media.giphy.com/media/OBnwDJW77acLK/giphy.gif">

#### Fix the fix

But it's easy to fix them:

~~~ {.sh}
hg commit --amend -m "Fix bug"
~~~

~~~graphviz-file
graphs/fix-bug-2.dot
~~~

#### Too fast!

But wait you had local changes! And they get incorporated into the amend.

<img src="https://media1.giphy.com/media/vMiCDfoKdJP0c/giphy.gif">

10 more minutes to unbundle revert the files, relaunch the tests, etc...

#### With evolve now

~~~graphviz-file
graphs/fix-bug-1.dot
~~~

#### Same CLI

With evolve this time:

~~~ {.sh}
hg commit --amend -m "Fix bug"
~~~

~~~graphviz-file
graphs/fix-bug-2.dot
~~~

#### Ok what the difference?

#### Before / After


<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 50%'>
Before:

</div>

<div class='right' style='order:2; width: 50%'>
After:

~~~raw-file
output/fix-a-bug-with-evolve-1.log
~~~

</div>
</div>

#### Difference is hidden


~~~raw-file
output/fix-a-bug-with-evolve-2.log
~~~

The old revision is still there!

#### Impact

* Easier to access obsolete changesets
    - No more `.hg/strip-backup/` expedition
* Respect the append only model of Mercurial
    - No large data movement on edition
    - No cache trauma

#### One more thing

<img src="https://media.giphy.com/media/F3MoHzSjjJ16w/giphy.gif">

#### Track evolution

~~~graphviz-file
graphs/fix-bug-3.dot
~~~
~~~graphviz
    digraph G {
        rankdir="BT";
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fix bug";
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Parent -> "Fx bug";

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "Fx bug" -> "Fix bug";
    }
~~~

#### Obsmarker

Stores relation between evolutions


<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 50%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        node[group=obsolete, style="dotted, filled" fillcolor="#DFDFFF"];
        edge[dir=back, style=dotted, arrowtail=dot];
        "Predecessor" -> "Successor";

        "Successor" [style="filled", fillcolor="#7F7FFF"];
    }
~~~
</div>

<div class='right' style='order:2; width: 50%'>

* And some metas:
    * User
    * Date
    * And others...
</div>
</div>

## Topic

#### Topic

<pre>
$> hg topic myfeature
$> hg topics
<span style="color:green;"> * </span><span style="color:green;">myfeature</span>
</pre>

#### Topic

Topic branches are lightweight branches which disappear when changes are
finalized (move to the public phase). They can help users to organise and share
their unfinished work.

#### Topic storage

Like named-branches, topics are stored on the changeset.

#### Head definition

<pre>
$> hg log -G
@  <span style="color:olive;">changeset:   2:03a68957ddd8</span>
|  tag:         tip
|  parent:      0:478309adfd3c
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Mon Jul 24 22:39:27 2017 +0200
|  summary:     default
|
| o  <span style="color:olive;">changeset:   1:3d2362d21bb4</span>
|/   <span style="background-color:green;">topic:       myfeature</span>
|    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|    date:        Mon Jul 24 22:39:55 2017 +0200
|    summary:     myfeature
|
o  <span style="color:olive;">changeset:   0:478309adfd3c</span>
   user:        Boris Feld &lt;boris.feld@octobus.net&gt;
   date:        Mon Jul 24 16:01:32 2017 +0200
   summary:     ROOT
</pre>

#### Heads

<pre>
$> hg log -r 'head() and branch(default)'
<span style="color:olive;">changeset:   2:03a68957ddd8</span>
tag:         tip
parent:      0:478309adfd3c
user:        Boris Feld &lt;boris.feld@octobus.net&gt;
date:        Mon Jul 24 22:39:27 2017 +0200
summary:     default
</pre>

#### Name definition

We can update to a topic directly:

<pre>
$> hg update myfeature
switching to topic myfeature
1 files updated, 0 files merged, 2 files removed, 0 files unresolved
</pre>

#### Pre-rebase

<pre>
$> hg log -G
o  <span style="color:olive;">changeset:   2:03a68957ddd8</span>
|  tag:         tip
|  parent:      0:478309adfd3c
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Mon Jul 24 22:39:27 2017 +0200
|  summary:     default
|
| @  <span style="color:olive;">changeset:   1:3d2362d21bb4</span>
|/   <span style="background-color:green;">topic:       myfeature</span>
|    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|    date:        Mon Jul 24 22:39:55 2017 +0200
|    summary:     myfeature
|
o  <span style="color:olive;">changeset:   0:478309adfd3c</span>
   user:        Boris Feld &lt;boris.feld@octobus.net&gt;
   date:        Mon Jul 24 16:01:32 2017 +0200
   summary:     ROOT
</pre>

#### Topic rebase

Topics can be rebased easily on their base branch

<pre>
$> hg rebase
rebasing 1:3d2362d21bb4 &quot;myfeature&quot;
switching to topic myfeature
</pre>

#### Result

<pre>
$> hg log -G
@  <span style="color:olive;">changeset:   3:0a51e0d4d460</span>
|  tag:         tip
|  <span style="background-color:green;">topic:       myfeature</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Mon Jul 24 22:39:55 2017 +0200
|  summary:     myfeature
|
o  <span style="color:olive;">changeset:   2:03a68957ddd8</span>
|  parent:      0:478309adfd3c
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Mon Jul 24 22:39:27 2017 +0200
|  summary:     default
|
o  <span style="color:olive;">changeset:   0:478309adfd3c</span>
   user:        Boris Feld &lt;boris.feld@octobus.net&gt;
   date:        Mon Jul 24 16:01:32 2017 +0200
   summary:     ROOT
</pre>

#### Topic push

You can push topic without -f if you push only 1 head:

<pre>
hg push -r myfeature
</pre>

Even if the topic is not up-to-date to its branch.

## Stack Workflow

#### Stack

<pre>
$> hg stack
###### topic: <span style="color:green;">myfeature</span>
###### branch: feature
<span style="color:teal;">t4</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Step4</span><span style="color:teal;font-weight:bold;"> (current)</span>
<span style="color:olive;">t3</span><span style="color:green;">:</span> Step3
<span style="color:olive;">t2</span><span style="color:green;">:</span> Step2
<span style="color:olive;">t1</span><span style="color:green;">:</span> Step
<span style="color:grey;">t0^ Trunk</span>
</pre>

#### Why Stack?

* Feature = multiple steps,

* Smaller = Simpler

* Simpler = Earlier merge in trunk

* Ease experiment with Alternative

* etc…

#### Prev

<pre>
$> hg prev
1 files updated, 0 files merged, 0 files removed, 0 files unresolved
[<span style="color:blue;">7</span>] Step3
$> hg stack
###### topic: <span style="color:green;">myfeature</span>
###### branch: feature
<span style="color:olive;">t4</span><span style="color:green;">:</span> Step4
<span style="color:teal;">t3</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Step3</span><span style="color:teal;font-weight:bold;"> (current)</span>
<span style="color:olive;">t2</span><span style="color:green;">:</span> Step2
<span style="color:olive;">t1</span><span style="color:green;">:</span> Step
<span style="color:grey;">t0^ Trunk</span>
</pre>

#### Next

<pre>
$> hg next
1 files updated, 0 files merged, 0 files removed, 0 files unresolved
[<span style="color:blue;">8</span>] Step4
$> hg stack
###### topic: <span style="color:green;">myfeature</span>
###### branch: feature
<span style="color:teal;">t4</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Step4</span><span style="color:teal;font-weight:bold;"> (current)</span>
<span style="color:olive;">t3</span><span style="color:green;">:</span> Step3
<span style="color:olive;">t2</span><span style="color:green;">:</span> Step2
<span style="color:olive;">t1</span><span style="color:green;">:</span> Step
<span style="color:grey;">t0^ Trunk</span>
</pre>

#### T\#

<pre>
$> hg update --rev t2
1 files updated, 0 files merged, 0 files removed, 0 files unresolved
[<span style="color:blue;">8</span>] Step4
$> hg stack
###### topic: <span style="color:green;">myfeature</span>
###### branch: feature
<span style="color:olive;">t4</span><span style="color:green;">:</span> Step4
<span style="color:olive;">t3</span><span style="color:green;">:</span> Step3
<span style="color:teal;">t2</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Step2</span><span style="color:teal;font-weight:bold;"> (current)</span>
<span style="color:olive;">t1</span><span style="color:green;">:</span> Step
<span style="color:grey;">t0^ Trunk</span>
</pre>

#### Editing mid-stack

<pre>
$> hg update --rev t1
1 files updated, 0 files merged, 0 files removed, 0 files unresolved
$> hg commit --amend -m "Step1"
<span style="color:gold;">3 new unstable changesets</span>
</pre>

#### What have we done?

<pre>
$> hg log -G -T compact
@  <span style="color:olive;">9</span>[tip]     1aa1be5ada40    Step1
|
| o  <span style="color:olive;">8</span>        cf90b2de7e65    Step4 <span style="color:red;">(unstable)</span>
| |
| o  <span style="color:olive;">7</span>        e208d4205c8e    Step3 <span style="color:red;">(unstable)</span>
| |
| o  <span style="color:olive;">6</span>        673ff300cf3a    Step2 <span style="color:red;">(unstable)</span>
| |
| <span style="color:grey;">x  5        8bb88a31dd28    Step</span>
|/
o  <span style="color:olive;">4</span>          3294c1730df7    Trunk
~
</pre>

#### Stack to the rescue!

<pre>
$> hg stack
###### topic: <span style="color:green;">myfeature</span>
###### branch: feature
<span style="color:olive;">t4</span><span style="color:red;">$</span> Step4<span style="color:red;"> (unstable)</span>
<span style="color:olive;">t3</span><span style="color:red;">$</span> Step3<span style="color:red;"> (unstable)</span>
<span style="color:olive;">t2</span><span style="color:red;">$</span> Step2<span style="color:red;"> (unstable)</span>
<span style="color:teal;">t1</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Step1</span><span style="color:teal;font-weight:bold;"> (current)</span>
<span style="color:grey;">t0^ Trunk</span>
</pre>

#### Don't panic

<pre>
$> hg next --evolve
move:[<span style="color:blue;">6</span>] Step2
atop:[<span style="color:blue;">9</span>] Step1
working directory now at <span style="color:olive;">d72473cbf9a6</span>
$> hg stack
###### topic: <span style="color:green;">myfeature</span>
###### branch: feature
<span style="color:olive;">t4</span><span style="color:red;">$</span> Step4<span style="color:red;"> (unstable)</span>
<span style="color:olive;">t3</span><span style="color:red;">$</span> Step3<span style="color:red;"> (unstable)</span>
<span style="color:teal;">t2</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Step2</span><span style="color:teal;font-weight:bold;"> (current)</span>
<span style="color:olive;">t1</span><span style="color:green;">:</span> Step1
<span style="color:grey;">t0^ Trunk</span>
</pre>

#### Go on

<img src="https://media.giphy.com/media/KBx7fQoLxuV7G/giphy.gif">

#### Go on

<pre>
$> hg next --evolve
move:[<span style="color:blue;">7</span>] Step3
atop:[<span style="color:blue;">10</span>] Step2
working directory now at <span style="color:olive;">4062d6ecd214</span>
$> hg stack
###### topic: <span style="color:green;">myfeature</span>
###### branch: feature
<span style="color:olive;">t4</span><span style="color:red;">$</span> Step4<span style="color:red;"> (unstable)</span>
<span style="color:teal;">t3</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Step3</span><span style="color:teal;font-weight:bold;"> (current)</span>
<span style="color:olive;">t2</span><span style="color:green;">:</span> Step2
<span style="color:olive;">t1</span><span style="color:green;">:</span> Step1
<span style="color:grey;">t0^ Trunk</span>
</pre>

#### Go on

<pre>
$> hg next --evolve
move:[<span style="color:blue;">8</span>] Step4
atop:[<span style="color:blue;">11</span>] Step3
working directory now at <span style="color:olive;">4dcd9dfedf1b</span>
$> hg stack
###### topic: <span style="color:green;">myfeature</span>
###### branch: feature
<span style="color:teal;">t4</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Step4</span><span style="color:teal;font-weight:bold;"> (current)</span>
<span style="color:olive;">t3</span><span style="color:green;">:</span> Step3
<span style="color:olive;">t2</span><span style="color:green;">:</span> Step2
<span style="color:olive;">t1</span><span style="color:green;">:</span> Step1
<span style="color:grey;">t0^ Trunk</span>
</pre>

#### Go on

<pre>
$> hg next --evolve
no children
</pre>

#### Better!

<pre>
$> hg log -G -T compact
@  <span style="color:olive;">12</span>[tip]    4dcd9dfedf1b    Step4
|
o  <span style="color:olive;">11</span>         4062d6ecd214    Step3
|
o  <span style="color:olive;">10</span>         d72473cbf9a6    Step2
|
o  <span style="color:olive;">9</span>          1aa1be5ada40    Step1
|
o  <span style="color:olive;">4</span>          3294c1730df7    Trunk
~
</pre>

#### More Rewrite Tools

<table>
<tr>
<th>Operation</th>
<th>command</th>
</tr>
<tr>
<td>Modify</td>
<td>`hg amend`<br></td>
</tr>
<tr>
<td>Remove</td>
<td>`hg prune`<br></td>
</tr>
<tr>
<td>Move</td>
<td>`hg grab`<br></td>
</tr>
<tr>
<td>Split</td>
<td>`hg split`<br></td>
</tr>
<tr>
<td>Fold</td>
<td>`hg fold`<br></td>
</tr>
</table>

#### Multi headed stack

<pre>
$> hg log -G -T compact
@  <span style="color:olive;">6</span>[tip]   189f54192937   Step4.5
|
| o  <span style="color:olive;">5</span>   c1a91e7c74f5   Step5
|/
o  <span style="color:olive;">4</span>   826d2fbb601a   Step4
|
o  <span style="color:olive;">3</span>   08bcdd8d972b   Step3
|
o  <span style="color:olive;">2</span>   06cb53532f1b   Step2
|
o  <span style="color:olive;">1</span>   3eb38d10980d   Step1
~

</pre>

#### Multi headed stack

<pre>
$> hg stack
###### topic: <span style="color:green;">myfeature</span> (<span style="color:olive;">2 heads</span>)
###### branch: feature
<span style="color:teal;">t6</span><span style="color:teal;font-weight:bold;">@</span> <span style="color:teal;">Step4.5</span><span style="color:teal;font-weight:bold;"> (current)</span>
<span style="color:grey;">t4^ Step4 (base)</span>
<span style="color:olive;">t5</span><span style="color:green;">:</span> Step5
<span style="color:olive;">t4</span><span style="color:green;">:</span> Step4
<span style="color:olive;">t3</span><span style="color:green;">:</span> Step3
<span style="color:olive;">t2</span><span style="color:green;">:</span> Step2
<span style="color:olive;">t1</span><span style="color:green;">:</span> Step1
<span style="color:grey;">t0^ Trunk</span>
</pre>

## Distributed Workflow

#### propagation

Obsolescence can be exchanged:

* push, pull
* bundle / unbundle (hg 4.3+)

(affects draft history only)

#### Exchanging draft

 * Works on multiple machines

 * Collaborate with others

 * Whole new play field == new traps

#### Example

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 50%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=main];
        Root -> "A";
        Root [shape="circle"];
    }
~~~
</div>

<div class='right' style='order:2; width: 50%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=main];
        Root -> "A";
        Root [shape="circle"];
    }
~~~
</div>
</div>

#### time pass

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 50%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=main];
        Root -> "A1";
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A";

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "A1";

        Root [shape="circle"];
    }
~~~
</div>

<div class='right' style='order:2; width: 50%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=main];
        Root -> "A" -> B;

        Root [shape="circle"];
    }
~~~
</div>
</div>

#### Instability

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=main];
        Root -> "A1";
        "B";
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A" -> "B";

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "A1";

        Root [shape="circle"];
        B [fillcolor="#FF3535"];
    }
~~~

#### It's smart

<img src="https://media2.giphy.com/media/ZThQqlxY5BXMc/giphy.gif">

#### Stabilization

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=main];
        Root -> "A1" -> "B1";
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A" -> "B";

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "A1";
        "B" -> "B1";

        Root [shape="circle"];
    }
~~~

#### rewrite anything?

Phases enforce a reliable history:

* **draft**: can we rewritten
* **public**: immutable part of the history

Contact your local workflow manager.

## Helpfull Tooling

#### Summary

<pre>
$> hg summary
<span style="color:olive;">parent: 10:890ac95deb83 </span>tip (unstable)
 Head
branch: feature
commit: (clean)
update: (current)
phases: 9 draft
unstable: <span style="color:red;">1 changesets</span>
topic:  <span style="color:green;">myfeature</span>
</pre>

#### Topics

<pre>
$> hg topics
   4.3compat
   doc
   evolvecolor
   import-checker
   more-output
   obscache
   obsfatefixes
   obsmarkerbitfield
   obsrangecacheiterative
   packaging
   prev-next
   split
   stack_unstable_bug
   tutorial
 * tutorialtypos
</pre>

#### Topics age

<pre>
$> hg topics --age
   tutorial               (5 hours ago)
<span style="color:green;"> * </span><span style="color:green;">tutorialtypos         </span> (5 hours ago)
   4.3compat              (4 days ago)
   prev-next              (12 days ago)
   obsfatefixes           (2 weeks ago)
   more-output            (3 weeks ago)
   obsmarkerbitfield      (2 months ago)
   obscache               (2 months ago)
   evolvecolor            (2 months ago)
   obsrangecacheiterative (2 months ago)
   stack_unstable_bug     (2 months ago)
   doc                    (3 months ago)
   split                  (3 months ago)
   import-checker         (4 months ago)
   packaging              (4 months ago)
</pre>

#### Topics verbose

<pre class="shell_output">
$> hg topics --verbose
   4.3compat              (on branch: default, 1 changesets, <span style="color:teal;">43 behind</span>)
   doc                    (on branch: stable, 1 changesets, <span style="color:teal;">415 behind</span>)
   evolvecolor            (on branch: default, 1 changesets, <span style="color:teal;">369 behind</span>)
   import-checker         (on branch: default, 1 changesets, <span style="color:teal;">637 behind</span>)
   more-output            (on branch: default, 1 changesets, <span style="color:teal;">104 behind</span>)
   obscache               (on branch: default, 1 changesets, <span style="color:teal;">325 behind</span>)
   obsfatefixes           (on branch: default, 1 changesets, <span style="color:teal;">82 behind</span>)
   obsmarkerbitfield      (on branch: default, 1 changesets, <span style="color:teal;">324 behind</span>)
   obsrangecacheiterative (on branch: default, 1 changesets, <span style="color:teal;">461 behind</span>)
   packaging              (on branch: default, 1 changesets, <span style="color:teal;">2521 behind</span>)
   prev-next              (on branch: default, 4 changesets, <span style="color:teal;">72 behind</span>)
   split                  (on branch: default, 1 changesets, <span style="color:teal;">492 behind</span>)
   stack_unstable_bug     (on branch: default, 1 changesets, <span style="color:teal;">474 behind</span>)
   tutorial               (on branch: default, 2 changesets, <span style="color:teal;">492 behind</span>)
<span style="color:green;"> * </span><span style="color:green;">tutorialtypos         </span> (on branch: default, 3 changesets, <span style="color:red;">1 troubled</span>, <span style="color:olive;">2 heads</span>, <span style="color:teal;">2 behind</span>)
</pre>

#### Log

<pre>
$ hg log -G --hidden -T '{node|short}\n{obsfate}\n'
@  c55cb2ee8a91
|
o  23abfc79b7ce
|
| o  4302274177b9 <span style="color:red;">(unstable)</span>
| |
| <span style="color:grey;">x  fba593aaaa10</span>
|/   rewritten as c55cb2ee8a91;
o  2ff53d8bf7d7
</pre>

#### Evolve --list

<pre>
$> hg evolve --list
<span style="color:gold;">9ac0d376e01c</span>: changelog: introduce a 'tiprev' method
  <span style="color:red;">unstable</span>: <span style="color:grey;">52ec3072fe46</span> (obsolete parent)

<span style="color:gold;">3efd3eab9860</span>: changelog: use 'tiprev()' in 'tip()'
  <span style="color:red;">unstable</span>: <span style="color:red;">9ac0d376e01c</span> (unstable parent)
</pre>

(see also `hg evolve --list --rev`)

#### Obslog

<pre>
$> hg obslog
@  <span style="color:olive;">c55cb2ee8a91</span> <span style="color:blue;">(4)</span> A2
|
| o  <span style="color:olive;">4302274177b9</span> <span style="color:blue;">(2)</span> A1
|/
x  <span style="color:olive;">fba593aaaa10</span> <span style="color:blue;">(1)</span> A
     rewritten(description, parent) as <span style="color:olive;">c55cb2ee8a91</span>
       by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span>
       <span style="color:teal;">(Thu Jun 22 00:00:29 2017 +0200)</span>
     rewritten(description) as <span style="color:olive;">4302274177b9</span>
       by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span>
       <span style="color:teal;">(Thu Jun 22 00:00:28 2017 +0200)</span>

</pre>

#### Obslog --patch

<pre>
$> hg obslog -p
@  <span style="color:olive;">f6b1dded9e95</span> <span style="color:blue;">(2)</span> A1
|
x  <span style="color:olive;">364e589e2bac</span> <span style="color:blue;">(1)</span> A
     rewritten(description, parent) as <span style="color:olive;">a6be771bedcf</span>
       by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span>
       <span style="color:teal;">(Thu Jun 22 00:00:29 2017 +0200)</span>
       (No patch available yet, changesets rebased)
     rewritten(description) as <span style="color:olive;">f6b1dded9e95</span>
       by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span>
       <span style="color:teal;">(Thu Jun 22 00:00:28 2017 +0200)</span>
       --- a/364e589e2bac-changeset-description
       +++ b/f6b1dded9e95-changeset-description
       @@ -1,1 +1,1 @@
       -A
       +A1
</pre>

#### Journal

<pre>
$> hg journal
previous locations of '.':
2fb6d364d453  commit --amend -m Step1
701fb5d73e07  update --rev t1
ae11635effb7  commit -A -m Step2
701fb5d73e07  commit -A -m Step
</pre>

## Semantic

#### Use the right commands!

<img src="https://media.giphy.com/media/uRb2p09vY8lEs/giphy.gif">

#### smart commands

<table>
<tr>
<th>Operation</th>
<th>command</th>
</tr>
<tr>
<td>Modify</td>
<td>`hg amend`<br></td>
</tr>
<tr>
<td>Remove</td>
<td>`hg prune`<br></td>
</tr>
<tr>
<td>Move</td>
<td>`hg grab`<br></td>
</tr>
<tr>
<td>Split</td>
<td>`hg split`<br></td>
</tr>
<tr>
<td>Fold</td>
<td>`hg fold`<br></td>
</tr>
</table>


## Troubles

#### Evolution

* Unlock powerful unique features

* Hide **most** of the complexity

* Help with unstable situations

    - Automatic detection

    - Automated resolution `hg help evolve`

#### instability

(currently: *troubles*)

* **Orphans:** ancestors were rewritten

* **Divergence:** branching in evolutions

    - Content-divergence: independent rewrites

    - Phase-divergence: older version got published

## Conclusion

#### Work in progress

* Concepts are solid
* Implementation in progress
* Common case works fine
* Some rough edges
* Feedback → priority

#### Use Evolution Today

install `hg-evolve`

<pre>
[extensions]
evolve=
topic= ## provides hg stack
</pre>

#### Helps

* Mailing-list: `evolve-testers@mercurial-scm.org`
* IRC channel: `#mercurial`

#### Documentation

* Documentation: <br/><small><https://www.mercurial-scm.org/doc/evolution/index.html></small>
* Wiki: <br/><small><https://www.mercurial-scm.org/wiki/EvolveExtension></small>

## Conclusion

#### Rewrite all the things!

<img src="https://cdn.meme.am/cache/instances/folder258/500x/54913258.jpg">

#### Safety first!

<img src="https://media.giphy.com/media/46vrhWWOJ4wHC/giphy.gif">

## extra - Troubles

#### Obsolete

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, style="filled", width=1, height=1, fillcolor="#7F7FFF", shape="pentagon"];


        node[group=main];
        Root -> New;
        node[group=obsolete];
        Root -> Obsolete;

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        Obsolete -> New;

        Obsolete [fillcolor="#DFDFFF"];
        Root[shape="circle"];
    }
~~~

#### Unstable

Now called `orphan`

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, style="filled", width=1, height=1, fillcolor="#7F7FFF", shape="pentagon"];

        node[group=main];
        Root -> New;
        node[group=obsolete];
        Root -> Obsolete -> Unstable;

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        Obsolete -> New;

        Obsolete [fillcolor="#DFDFFF"];
        Unstable [fillcolor="#FF3535"];
        Root[shape="circle"];
    }
~~~

#### Bumped

Now called `Phase-divergent`

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, style="filled", width=1, height=1, fillcolor="#7F7FFF", shape="pentagon"];

        node[group=main];
        Root -> New;
        node[group=obsolete];
        Root -> Obsolete;
        node[group=bumped];
        Root -> Bumped;

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        Obsolete -> New;
        Obsolete -> Bumped;

        New [shape="circle"];
        Obsolete [fillcolor="#DFDFFF"];
        Bumped [fillcolor="#FF3535"];
        Root[shape="circle"];
    }
~~~

#### Divergent

Now called `Content-divergent`

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, style="filled", width=1, height=1, fillcolor="#7F7FFF", shape="pentagon"];

        Root -> Base;
        Root -> Divergent1;
        Root -> Divergent2;

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        Base -> Divergent1;
        Base -> Divergent2;

        Base [shape="pentagon", fillcolor="#DFDFFF"];
        Divergent1 [fillcolor="#FF3535"];
        Divergent2 [fillcolor="#FF3535"];
        Root[shape="circle"];
    }
~~~

## extra-commands

#### Amend

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 20%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=main];
        Root -> "A";
        Root [shape="circle"];
    }
~~~
</div>

<div class="middle" style='order:2; width: 60%'>
To amend A:

    hg amend -m 'A1'
</div>

<div class='right' style='order:2; width: 20%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=main];
        Root -> "A1";
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A";

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "A1";
        Root [shape="circle"];
    }
~~~
</div>
</div>

#### Prune

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 20%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=main];
        Root -> "A";
        Root [shape="circle"];
    }
~~~
</div>

<div class="middle" style='order:2; width: 60%'>

To prune A:

    hg prune -r "desc(A)"
</div>

<div class='right' style='order:2; width: 20%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        Root [shape="circle"];

        // Revisions
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A";
    }
~~~
</div>
</div>

#### Rebase

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 20%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=branch];
        Root -> B;
        node[group=main];
        Root -> "A";

        Root [shape="circle"];
    }
~~~
</div>

<div class="middle" style='order:2; width: 60%'>

In order to rebase A on top of B;

    hg rebase -r "desc(A)" -d "desc(B)"

</div>

<div class='right' style='order:2; width: 20%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=branch];
        Root -> B -> "A'";

        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A";

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "A'";

        Root [shape="circle"];
    }
~~~
</div>
</div>

#### Fold

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 15%'>

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=branch];
        Root -> A -> B;

        Root [shape="circle"];
    }
~~~
</div>

<div class="middle" style='order:2; width: 70%'>

To fold A and B:

    hg fold -r "desc(A)" -r "desc(B)" -m "C"

</div>

<div class='right' style='order:2; width: 15%'>

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=branch];
        Root -> C;

        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> A -> B;

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "C";
        "B" -> "C";

        Root [shape="circle"];
    }
~~~

</div>
</div>

#### Split

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 20%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=branch];
        Root -> A;

        Root [shape="circle"];
    }
~~~
</div>

<div class="middle" style='order:2; width: 60%'>

Split in two:

    hg split -r "desc(A)"
</div>

<div class='right' style='order:2; width: 20%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=branch];
        Root -> B -> C;

        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> A;

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "C";
        "A" -> "B";

        Root [shape="circle"];
    }
~~~
</div>
</div>
 -->
