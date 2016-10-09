'''Test evaluation of prompt template in HGRC.'''

from nose import *
from util import *


@with_setup(setup_sandbox, teardown_sandbox)
def test_hgrc():

    with open(os.path.join(sandbox_path, '.hg', 'hgrc'), 'w') as fp:
        fp.write('[prompt]\ntemplate = foo\n')

    output = prompt(fs='')
    assert output == 'foo'

    output = prompt(fs='bar')
    assert output == 'bar'  # command line overwrites hgrc

    with open(os.path.join(sandbox_path, '.hg', 'hgrc'), 'w') as fp:
        fp.write('[prompt]\ntemplate = { at node {node}}\n')

    output = prompt(fs='')
    assert output == ' at node 0000000000000000000000000000000000000000'
