# Copied from histedit setup.py
# Credit to Augie Fackler <durin42@gmail.com>

import os
from distutils.core import setup
from os.path import dirname, join

def get_version(relpath):
    '''Read version info from a file without importing it'''
    for line in open(join(dirname(__file__), relpath), 'rb'):
        # Decode to a fail-safe string for PY3
        # (gives unicode object in PY2)
        line = line.decode('utf8')
        if '__version__' in line:
          if "'" in line:
            return line.split("'")[1]

py_modules = [
    'hgext.evolve',
]

if os.environ.get('INCLUDE_INHIBIT'):
    py_modules.append('hgext.inhibit')
    py_modules.append('hgext.directaccess')

setup(
    name='hg-evolve',
    version=get_version('hgext/evolve.py'),
    author='Pierre-Yves David',
    maintainer='Pierre-Yves David',
    maintainer_email='pierre-yves.david@ens-lyon.org',
    url='https://bitbucket.org/marmoute/mutable-history',
    description='Flexible evolution of Mercurial history.',
    long_description=open('README').read(),
    keywords='hg mercurial',
    license='GPLv2+',
    py_modules=py_modules
)
