#!/usr/bin/env python

import os
import os.path as op
import re
import sys

# line starts with two chars one of which is not a space (and both are not
# newlines obviously) and ends with one or more newlines followed by two spaces
# on a next line (indented text)
CODEBLOCK = re.compile(r'()\n(([^ \n][^\n]|[^\n][^ \n])[^\n]*)\n+  ')

INDEX = '''
Mercurial tests
===============

.. toctree::
   :maxdepth: 1
'''


def rstify(orig, name):
    header = '%s\n%s\n\n' % (name, '=' * len(name))
    content = header + orig
    content = CODEBLOCK.sub(r'\n\1\n\n::\n\n  ', content)
    return content


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
