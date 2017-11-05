# Copyright 2017 FUJIWARA Katsunori <foozy@lares.dti.ne.jp>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""
Compatibility module
"""
from __future__ import absolute_import

from mercurial import (
    obsolete,
    scmutil,
    util,
)

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

def startpager(ui, cmd):
    """function to start a pager in case ui.pager() exists"""
    try:
        ui.pager(cmd)
    except AttributeError:
        pass

def cleanupnodes(repo, replacements, operation, moves=None):
    # create obsmarkers and move bookmarks
    # XXX we should be creating marker as we go instead of only at the end,
    # this makes the operations more modulars
    if util.safehasattr(scmutil, 'cleanupnodes'):
        scmutil.cleanupnodes(repo, replacements, 'changetopics',
                             moves=moves)
    else:
        relations = [(repo[o], tuple(repo[n] for n in new))
                     for (o, new) in replacements.iteritems()]
        obsolete.createmarkers(repo, relations)
