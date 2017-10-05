# Copyright 2017 FUJIWARA Katsunori <foozy@lares.dti.ne.jp>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""
Compatibility module
"""
from __future__ import absolute_import

from mercurial import obsolete

getmarkers = None
successorssets = None
try:
    from mercurial import obsutil
    getmarkers = getattr(obsutil, 'getmarkers', None)
    successorssets = getattr(obsutil, 'successorssets', None)
except ImportError:
    pass

if getmarkers is None:
    getmarkers = obsolete.getmarkers
if successorssets is None:
    successorssets = obsolete.successorssets
