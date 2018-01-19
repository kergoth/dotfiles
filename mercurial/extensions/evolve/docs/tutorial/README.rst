=============================
Training supports
=============================

Contributing
============

The main source for the supports is the `slides.md` but it doesn't contains
all the source.

The `slides.md` file contains several snippets that are replaced by other
files at compilation time.

For example:

.. code:: markdown

  ~~~raw-file
  output/fix-a-bug-base.log
  ~~~

Will replace this three lines by the content of the file `output/fix-a-bug-
base.log` which is generated when running the .t test file (see below for
instruction how to do that).

.. code:: markdown

  ~~~graphviz-file
  graphs/fix-bug-1.dot
  ~~~

Will replace this three lines by the svg rendering of the graphviz definition
in the file `graphs/fix-bug-1.dot`. This file is generated when running the .t
test file (see below for instruction how to do that).


Environment preparation
=======================

This training supports needs pandoc to compile.

You'll need a copy of the Mercurial source in order to generate the training
supports.

You will also needs a functioning Python environment with the possibility to
use `pip install` with your current user. In doubt, you can use a `virtualenv
<https://virtualenv.pypa.io/en/stable/>`.

You can then run the `prepare.sh` script that will configure the environment
for you.

Generating the supports
=======================

First, you need to run a .t test file to generate a bunch of files. You can
run the test file with this command:

`python /PATH/TO/MERCURIAL/tests/run-tests.py -l test-training.t`

It should have generated files in at least two directories: `graphs` and
`output`.

Finally, launch the `compile.sh` to generate the `index.html` output file.
