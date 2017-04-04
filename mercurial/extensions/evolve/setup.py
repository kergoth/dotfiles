import os
from distutils.core import setup
from os.path import dirname, join

META_PATH = 'hgext3rd/evolve/metadata.py'

def get_metadata():
    meta = {}
    fullpath = join(dirname(__file__), META_PATH)
    execfile(fullpath, meta)
    return meta

def get_version():
    '''Read version info from a file without importing it'''
    return get_metadata()['__version__']

def min_hg_version():
    '''Read version info from a file without importing it'''
    return get_metadata()['minimumhgversion']

py_modules = [
]
py_packages = [
    'hgext3rd',
    'hgext3rd.evolve',
    'hgext3rd.topic',
]

if os.environ.get('INCLUDE_INHIBIT'):
    py_modules.append('hgext3rd.evolve.hack.inhibit')
    py_modules.append('hgext3rd.evolve.hack.directaccess')

setup(
    name='hg-evolve',
    version=get_version(),
    author='Pierre-Yves David',
    author_email='pierre-yves.david@ens-lyon.org',
    maintainer='Pierre-Yves David',
    maintainer_email='pierre-yves.david@ens-lyon.org',
    url='https://www.mercurial-scm.org/doc/evolution/',
    description='Flexible evolution of Mercurial history.',
    long_description=open('README').read(),
    keywords='hg mercurial',
    license='GPLv2+',
    py_modules=py_modules,
    packages=py_packages
)
