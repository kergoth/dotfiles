#!/usr/bin/env python

import os
import os.path as op
import sys

INDEX = '''
Mercurial tests
===============

.. toctree::
   :maxdepth: 1
'''


def rstify(orig, name):
    newlines = []

    code_block_mode = False

    for line in orig.splitlines():

        # Emtpy lines doesn't change output
        if not line:
            newlines.append(line)
            continue

        codeline = line.startswith('  ')
        if codeline:
            if code_block_mode is False:
                newlines.extend(['::', ''])

            code_block_mode = True
        else:
            code_block_mode = False

        newlines.append(line)

    return "\n".join(newlines)


def main(base):
    if os.path.isdir(base):
        one_dir(base)
    else:
        one_file(base)


def one_dir(base):
    index = INDEX
    # doc = lambda x: op.join(op.dirname(__file__), 'docs', x)

    for fn in sorted(os.listdir(base)):
        if not fn.endswith('.t'):
            continue
        name = os.path.splitext(fn)[0]
        content = one_file(op.join(base, fn))
        target = op.join(base, name + '.rst')
        # with file(doc(name + '.rst'), 'w') as f:
        with open(target, 'w') as f:
            f.write(content)

        index += '\n   ' + name

    # with file(doc('index.rst'), 'w') as f:
    #     f.write(index)


def one_file(path):
    name = os.path.basename(path)[:-2]
    return rstify(open(path).read(), name)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Please supply a path to tests dir as parameter')
        sys.exit()
    main(sys.argv[1])
