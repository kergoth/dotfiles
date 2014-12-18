try:
    from setuptools import setup
except:
    from distutils.core import setup

requires = []
try:
    import mercurial
except ImportError:
    requires.append('mercurial')

setup(
    name='hg-histedit',
    version='1.0.0',
    author='Augie Fackler',
    maintainer='Augie Fackler',
    maintainer_email='durin42@gmail.com',
    url='http://bitbucket.org/durin42/histedit/',
    description='Interactively edit history in Mercurial.',
    long_description=open('README').read(),
    keywords='hg mercurial',
    license='GPLv2+',
    py_modules=['hg_histedit'],
    install_requires=requires,
)
