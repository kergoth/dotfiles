#!/usr/bin/env python
#This file is part of hgshelve.  The COPYRIGHT file at the top level of
#this repository contains the full copyright notices and license terms.

from setuptools import setup

setup(name='hgshelve',
      version='0.1',
      author='TK Soh',
      author_email='teekaysoh@gmail.com',
      maintainer='Oleg Oshmyan',
      maintainer_email='chortos@inbox.lv',
      url="http://mercurial.selenic.com/wiki/ShelveExtension",
      description="Shelve Extension for Mercurial",
      long_description=open('README.rst').read(),
      download_url="https://bitbucket.org/astiob/hgshelve",
      py_modules=['hgshelve'],
      classifiers=[
          'Development Status :: 5 - Production/Stable',
          'Environment :: Plugins',
          'Intended Audience :: Developers',
          'License :: OSI Approved :: GNU General Public License (GPL)',
          'Operating System :: OS Independent',
          'Programming Language :: Python',
          'Topic :: Software Development :: Version Control',
      ],
      license='GNU GPLv2 or any later version',
      install_requires=[
          'Mercurial >= 2.7',
      ],
     )
