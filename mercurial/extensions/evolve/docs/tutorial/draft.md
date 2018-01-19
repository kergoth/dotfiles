---
author: Boris Feld <boris.feld@octobus.net>
title: Changeset evolution
date: June 23, 2017
---

# Why Evolve is the future? (TO CHANGE)

Use hexagon or drop all of themes
Use old names
Replace hg amend by commit --amend

Flow

Basic - Feature - Tool / instability - command semantic

Basic (local amend + local rebase)

Stabilization -> Evolution

Feature

# Local amend

## Amending commits

We all makes mistake:

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fx bug[case";
    }
~~~

## Some times pass

## Urgent Amend needed

But it's easy to fix the fix:

~~~ {.sh}
hg commit --amend -m "Fix bug"
~~~

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fix bug";
    }
~~~

## So easy to do something wrong

But wait you had local changes! And they get incorporated into the amend.

## Too bad

It's too late, they are gone!

<img src="https://media1.giphy.com/media/vMiCDfoKdJP0c/giphy.gif">

## HARD

UNbundle, get the rev, strip

## Never without Evolve!

<img src="https://media3.giphy.com/media/EVbEdEW3kuu0o/giphy.gif">


## Let's try again!

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fx bug";
    }
~~~

## Evolve powa

With evolve this time:

~~~ {.sh}
hg commit --amend -m "Fix bug"
~~~

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fix bug";
    }
~~~

## Ok what the difference?

<pre class="shell_output">
$> hg log -G
@  <span style="color:olive;">changeset:   3:467de638a224</span>
|  tag:         tip
|  parent:      0:852811e0e2a8
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:15:55 2017 +0200
|  summary:     Fix bug
|
o  <span style="color:olive;">changeset:   0:852811e0e2a8</span>
   user:        Boris Feld &lt;boris.feld@octobus.net&gt;
   date:        Wed Jun 21 14:15:55 2017 +0200
   summary:     Root

</pre>

## The difference

<pre class="shell_output">
$> hg log -G --hidden
@  <span style="color:olive;">changeset:   3:467de638a224</span>
|  tag:         tip
|  parent:      0:852811e0e2a8
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:15:55 2017 +0200
|  summary:     Fix bug
|
| x  <span style="color:olive;">changeset:   2:614cb09cc83d</span>
| |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
| |  date:        Wed Jun 21 14:15:55 2017 +0200
| |  summary:     temporary amend commit for e46245132d3d
| |
| x  <span style="color:olive;">changeset:   1:e46245132d3d</span>
|/   user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|    date:        Wed Jun 21 14:15:55 2017 +0200
|    summary:     Fx bug
|
o  <span style="color:olive;">changeset:   0:852811e0e2a8</span>
   user:        Boris Feld &lt;boris.feld@octobus.net&gt;
   date:        Wed Jun 21 14:15:55 2017 +0200
   summary:     Root

</pre>

## Perf impact

No strip == no cache bust, == faster

# Local rebase

## You are working on your branch

~~~graphviz
    digraph G {
        rankdir="LR";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=feature];
        Parent -> "Feature";
    }
~~~

## More work

~~~graphviz
    digraph G {
        rankdir="LR";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=feature];
        Parent -> "Feature" -> "Feature 2";
    }
~~~

## Pull

~~~graphviz
    digraph G {
        rankdir="LR";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Trunk" -> "Trunk 2";

        node[group=feature];
        Parent -> "Feature" -> "Feature 2";
    }
~~~

## Time to rebase

~~~graphviz
    digraph G {
        rankdir="LR";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Trunk" -> "Trunk 2";

        node[group=feature];
        "Trunk 2" -> "Feature" -> "Feature 2";
    }
~~~

## Without evolve

<pre class="shell_output">
@  <span style="color:olive;">changeset:   6:105f743d81c8</span>
|  tag:         tip
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:47:48 2017 +0200
|  summary:     Feature2
|
o  <span style="color:olive;">changeset:   5:3966a515e569</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:47:48 2017 +0200
|  summary:     Feature
|
o  <span style="color:olive;">changeset:   4:bd3d94325819</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:47:49 2017 +0200
|  summary:     Trunk2
|
o  <span style="color:olive;">changeset:   3:120d3e4ce8b7</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:47:49 2017 +0200
|  summary:     Trunk
|
o  <span style="color:olive;">changeset:   2:36db121866a2</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
~  date:        Wed Jun 21 14:47:48 2017 +0200
   summary:     Parent

</pre>

## With evolve

<pre style="font-size: 0.25em !important;">
@  <span style="color:olive;">changeset:   10:2c1a992b87c3</span>
|  tag:         tip
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Feature2
|
o  <span style="color:olive;">changeset:   9:751113c206d0</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Feature
|
o  <span style="color:olive;">changeset:   8:9f9f3db01630</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Trunk2
|
o  <span style="color:olive;">changeset:   7:a5e9a3060e20</span>
|  parent:      4:32253567b531
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Trunk
|
| x  <span style="color:olive;">changeset:   6:a57f1852d740</span>
| |  branch:      feature
| |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
| |  date:        Wed Jun 21 14:50:39 2017 +0200
| |  summary:     Feature2
| |
| x  <span style="color:olive;">changeset:   5:896dc0771e5e</span>
|/   branch:      feature
|    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|    date:        Wed Jun 21 14:50:39 2017 +0200
|    summary:     Feature
|
o  <span style="color:olive;">changeset:   4:32253567b531</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
~  date:        Wed Jun 21 14:50:39 2017 +0200
   summary:     Parent

</pre>

# How does it works?

## It's smart

<img src="https://media2.giphy.com/media/ZThQqlxY5BXMc/giphy.gif">

## Does Evolve only stores more changesets? (CHANGE)

## Not only

Remember our amend?

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 50%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fx bug";
    }
~~~
</div>

<div class='right' style='order:2; width: 50%'>

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fix bug";
    }
~~~
</div>
</div>

## More revisions

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 50%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fx bug";
    }
~~~
</div>

<div class='right' style='order:2; width: 50%'>

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fix bug";
        node[group=obsolete];
        Parent -> "Fx bug";
    }
~~~
</div>
</div>

## But hidden

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 50%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fx bug";
    }
~~~
</div>

<div class='right' style='order:2; width: 50%'>

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Parent -> "Fix bug";
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Parent -> "Fx bug";
    }
~~~
</div>
</div>

## Here is the smartness (change word)!

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

## Obs markers

Obs markers stores the relation between a changeset and its evolutions.

XXX: Speak about META

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


# Phases

## 3 phases

Changesets can be in one of three phases:

* Public
* Draft
* Secrets

## Public

The public phase holds changesets that have been exchanged publicly.

Changesets in the public phase are expected to remain in your repository history and are said to be immutable.

## Drafts

The draft phase holds changesets that are not yet considered a part of the repository's permanent history.

You can safely rewrite them.

New commits are in the draft phase by default.

## Secrets (hide)

The secret phase holds changesets that you do not want to exchange with other repositories.

Secret changesets are hidden from remote peers and will not be included in push operations.

Manual operations or extensions may move a changeset into the secret phase.

## Representation

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF"];

        // Revisions
        node[group=main];
        Public -> Draft -> Secret;

        Draft [shape="pentagon"];
        Secret [shape="square"];
    }
~~~

# Instability (add sub-titles, obsolete -> orphan, etc...)

## Obsolete

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

## Unstable

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

## Bumped

## Divergent

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

# Topic

# CHANGE TITLE (LATER IN THE FLOW)

## Log on obsolete

<pre style="font-size: 0.25em;">
$> hg log -G
o  <span style="color:olive;">changeset:   10:2c1a992b87c3</span>
|  tag:         tip
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Feature2
|
o  <span style="color:olive;">changeset:   9:751113c206d0</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Feature
|
o  <span style="color:olive;">changeset:   8:9f9f3db01630</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Trunk2
|
o  <span style="color:olive;">changeset:   7:a5e9a3060e20</span>
|  parent:      4:32253567b531
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Trunk
|
| @  <span style="color:olive;">changeset:   6:a57f1852d740</span>
| |  branch:      feature
| |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
| |  date:        Wed Jun 21 14:50:39 2017 +0200
| |  summary:     Feature2
| |
| x  <span style="color:olive;">changeset:   5:896dc0771e5e</span>
|/   branch:      feature
|    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|    date:        Wed Jun 21 14:50:39 2017 +0200
|    summary:     Feature
|
o  <span style="color:olive;">changeset:   4:32253567b531</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
~  date:        Wed Jun 21 14:50:39 2017 +0200
   summary:     Parent

</pre>

## Log with hidden

<pre style="font-size: 0.25em;">
$ hg log -G --hidden
@  <span style="color:olive;">changeset:   10:2c1a992b87c3</span>
|  tag:         tip
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Feature2
|
o  <span style="color:olive;">changeset:   9:751113c206d0</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Feature
|
o  <span style="color:olive;">changeset:   8:9f9f3db01630</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Trunk2
|
o  <span style="color:olive;">changeset:   7:a5e9a3060e20</span>
|  parent:      4:32253567b531
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|  date:        Wed Jun 21 14:50:39 2017 +0200
|  summary:     Trunk
|
| x  <span style="color:olive;">changeset:   6:a57f1852d740</span>
| |  branch:      feature
| |  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
| |  date:        Wed Jun 21 14:50:39 2017 +0200
| |  summary:     Feature2
| |
| x  <span style="color:olive;">changeset:   5:896dc0771e5e</span>
|/   branch:      feature
|    user:        Boris Feld &lt;boris.feld@octobus.net&gt;
|    date:        Wed Jun 21 14:50:39 2017 +0200
|    summary:     Feature
|
o  <span style="color:olive;">changeset:   4:32253567b531</span>
|  user:        Boris Feld &lt;boris.feld@octobus.net&gt;
~  date:        Wed Jun 21 14:50:39 2017 +0200
   summary:     Parent

</pre>

## Obslog

Behold our savior Obslog!

## Obslog

<pre class="shell_output">
$> hg obslog -r 3
o  <span style="color:olive;">c4414d4a5955</span> <span style="color:blue;">(3)</span> Fix bug
|
x  <span style="color:olive;">9b5b4aa63d51</span> <span style="color:blue;">(1)</span> Fx bug
     rewritten by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span> <span style="color:teal;">(Wed Jun 21 14:50:38 2017 +0200)</span> as <span style="color:olive;">c4414d4a5955</span>

</pre>

<pre class="shell_output">
$> hg obslog -r 6 --all --hidden
@  <span style="color:olive;">2c1a992b87c3</span> <span style="color:blue;">(10)</span> Feature2
|
x  <span style="color:olive;">a57f1852d740</span> <span style="color:blue;">(6)</span> Feature2
     rewritten by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span> <span style="color:teal;">(Wed Jun 21 14:50:39 2017 +0200)</span> as <span style="color:olive;">2c1a992b87c3</span>

</pre>

Obslog is your next best friend!

## Obslog

<img src="https://media4.giphy.com/media/LxPsfUhFxwRRC/giphy.gif">

# Evolve Basics behind the hood

## Amend

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

## Amend bis

It also works with:

    hg commit --amend -m 'A1'


## Prune

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



## Rebase

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


# More advanced

## Fold

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


## Split

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


# Warning zone

## Divergence

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=branch];
        Root -> "A";

        Root [shape="circle"];
    }
~~~

## Divergence

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 30%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        // Revisions
        node[group=branch];
        Root -> "B";

        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A";

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "B";

        Root [shape="circle"];
    }
~~~
</div>

<div class="middle" style='order:2; width: 70%'>

First amend:

    hg amend -m B;

</div>
</div>


## Divergence 2

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>

<div class="middle" style='order:1; width: 70%'>

Second amend:

    hg amend -m C

</div>

<div class='left' style='order:2; width: 30%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, width=1, height=1, style="filled", fillcolor="#7F7FFF", shape="pentagon"];

        Root;

        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A";

        // Revisions
        node[group=branch, fillcolor="#7F7FFF", style="filled"];
        Root -> "C";

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "C";

        Root [shape="circle"];
    }
~~~
</div>
</div>

## Result

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, style="filled", width=1, height=1, fillcolor="#7F7FFF", shape="pentagon"];

        node[group=main];
        Root -> "B";
        node[group=divergence];
        Root -> "C";
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A";

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        A -> B;
        A -> C;

        Root [shape="pentagon"];
        B [fillcolor="#FF3535"];
        C [fillcolor="#FF3535"];
        Root[shape="circle"];
    }
~~~

## That's gonna hurt!

# Stabilization

## Stabilization with amend

~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, style="filled", width=1, height=1, fillcolor="#7F7FFF", shape="pentagon"];

        node[group=main];
        Root -> "A'";
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A" -> B;

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "A'";

        B[fillcolor="#FF3535"];
        Root[shape="circle"];
    }
~~~

## Evolve!

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class="middle" style='order:2; width: 50%'>

Stabilize repo:

    hg evolve --all
</div>
<div class='right' style='order:2; width: 50%'>
~~~graphviz
    digraph G {
        rankdir="BT";
        graph[splines=polyline];
        node[fixedsize=true, style="filled", width=1, height=1, fillcolor="#7F7FFF", shape="pentagon"];

        node[group=main];
        Root -> "A'" -> "B'";
        node[group=obsolete, style="dotted, filled", fillcolor="#DFDFFF"];
        Root -> "A" -> B;

        // Obsolescence links
        edge[dir=back, style=dotted, arrowtail=dot];
        "A" -> "A'";
        "B" -> "B'";

        Root[shape="circle"];
    }
~~~

</div>
</div>

# Future is near!

## Effect-flag

Remember our obs-markers?

They are great for evolution, but how do you know what changed between two evolutions?

## Effect-flag

Effect-flag are storing what changed between evolutions. You can view them with `obslog`, who else?

## Effect-flag

Does the meta only changed?

<pre class="shell_output">
o  <span style="color:olive;">5732d5ea6aa2</span> <span style="color:blue;">(2)</span> Fix bug
|
@  <span style="color:olive;">aa3cd7ee52fc</span> <span style="color:blue;">(1)</span> Fx bug
     rewritten(description) by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span> <span style="color:teal;">(Wed Jun 21 15:49:54 2017 +0200)</span> as <span style="color:olive;">5732d5ea6aa2</span>

</pre>

## Or did the code changed?

<pre class="shell_output">
@  <span style="color:olive;">8f824718f3f7</span> <span style="color:blue;">(12)</span> Fix the build
|
x  <span style="color:olive;">f9310b4b05e1</span> <span style="color:blue;">(10)</span> Fix the build
     rewritten(content) by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span> <span style="color:teal;">(Wed Jun 21 15:53:07 2017 +0200)</span> as <span style="color:olive;">8f824718f3f7</span>

</pre>

## Or was rebased?

<pre class="shell_output">
o  <span style="color:olive;">ab709059df38</span> <span style="color:blue;">(9)</span> Feature2
|
@  <span style="color:olive;">3d61cb9ab34f</span> <span style="color:blue;">(5)</span> Feature2
     rewritten(branch, parent) by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span> <span style="color:teal;">(Wed Jun 21 15:53:06 2017 +0200)</span> as <span style="color:olive;">ab709059df38</span>

</pre>

## Obslog

<img src="https://media0.giphy.com/media/3oriO13KTkzPwTykp2/giphy.gif">

## Obsfate

<pre class="shell_output">
o  8f824718f3f7
|
| x  f39472eb8519
| |    Obsfate: pruned by Boris Feld &lt;boris.feld@octobus.net&gt; (at 2017-06-21 15:53 +0200)
| |
| x  f9310b4b05e1
|/     Obsfate: rewritten by Boris Feld &lt;boris.feld@octobus.net&gt; as 8f824718f3f7 (at 2017-06-21 15:53 +0200)
|
o  ab709059df38
|
o  b0d7c614e47d
|
o  d61083b45bba
|
o  50ebd46e2452
|
| @  3d61cb9ab34f
| |    Obsfate: rewritten by Boris Feld &lt;boris.feld@octobus.net&gt; as ab709059df38 (at 2017-06-21 15:53 +0200)
| |
| x  1c6a75c00a45
|/     Obsfate: rewritten by Boris Feld &lt;boris.feld@octobus.net&gt; as b0d7c614e47d (at 2017-06-21 15:53 +0200)
|
o  c1bdb750ab80
|
o  39752c0e48a4
|
| x  36744bfd9d65
|/     Obsfate: rewritten by Boris Feld &lt;boris.feld@octobus.net&gt; as 39752c0e48a4 (at 2017-06-21 15:53 +0200)
|
o  7d12a4681f84
</pre>

## Obslog --patch

<pre class="shell_output">
$> hg obslog --patch
x  <span style="color:olive;">19fb99aaa0d5</span> <span style="color:blue;">(3594)</span> obslog: add a patch option
|    rewritten(content) by <span style="color:green;">Pierre-Yves David &lt;pierre-yves.david@octobus.net&gt;</span> <span style="color:teal;">(Mon Jun 19 19:25:18 2017 +0200)</span> as <span style="color:olive;">81b01fe6db3b</span>
|      diff -r 19fb99aaa0d5 -r 81b01fe6db3b hgext3rd/evolve/obshistory.py
|      --- a/hgext3rd/evolve/obshistory.py  Mon Jun 19 19:00:36 2017 +0200
|      +++ b/hgext3rd/evolve/obshistory.py  Mon Jun 19 19:00:36 2017 +0200
|      @@ -105,6 +105,10 @@
|                   markerfm.plain('\n')
|
|                   # Patch
|      +
|      +# XXX-review: I find it a bit hacky always call showpatch and expect it to not
|      +# XXX-review: show anything without --patch. I would prefer and explicite condition for
|      +# XXX-review: calling showpatch.
|                   self.showpatch(ctx, matchfn)
|
|                   self.hunk[ctx.node()] = self.ui.popbuffer()
|      ...
|
| o  <span style="color:olive;">a788967aa800</span> <span style="color:blue;">(3593)</span> obslog: clarify some sorting code
| |
x |  <span style="color:olive;">4c2be5027b23</span>
|/     rewritten(user) by <span style="color:green;">Pierre-Yves David &lt;pierre-yves.david@octobus.net&gt;</span> <span style="color:teal;">(Mon Jun 19 19:00:54 2017 +0200)</span> as <span style="color:olive;">19fb99aaa0d5</span>
|        (No patch available yet, context is not local)
|
x  <span style="color:olive;">5d04c9bfac7e</span>
|    rewritten(description, user, date, parent, content) by <span style="color:green;">Pierre-Yves David &lt;pierre-yves.david@octobus.net&gt;</span> <span style="color:teal;">(Mon Jun 19 19:00:36 2017 +0200)</span> as <span style="color:olive;">4c2be5027b23, a788967aa800</span>
|      (No patch available yet, context is not local)
|
x  <span style="color:olive;">8ddfd687cf57</span> <span style="color:blue;">(3559)</span> obslog: add a patch option
|    rewritten(parent) by <span style="color:green;">Pierre-Yves David &lt;pierre-yves.david@octobus.net&gt;</span> <span style="color:teal;">(Mon Jun 19 18:59:02 2017 +0200)</span> as <span style="color:olive;">5d04c9bfac7e</span>
|      (No patch available yet, succ is unknown locally)
|
x  <span style="color:olive;">27d388000e90</span> <span style="color:blue;">(3541)</span> obslog: add a patch option
     rewritten(content) by <span style="color:green;">Boris Feld &lt;boris.feld@octobus.net&gt;</span> <span style="color:teal;">(Mon Jun 19 18:40:16 2017 +0200)</span> as <span style="color:olive;">8ddfd687cf57</span>
</pre>


# Conclusion

<div class='graph' style='display: flex ;align-items: stretch ;flex-flow: row wrap ; align-items: center;'>
<div class='left' style='order:1; width: 20%'>
~~~graphviz
 digraph G{}
~~~
</div>

<div class="middle" style='order:2; width: 60%'>
To stuff:

    hg
</div>

<div class='right' style='order:2; width: 20%'>
~~~graphviz
 digraph G{}
~~~
</div>
</div>
