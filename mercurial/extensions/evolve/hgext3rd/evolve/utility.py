# Various utility function for the evolve extension
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

from mercurial.node import nullrev

shorttemplate = "[{label('evolve.rev', rev)}] {desc|firstline}\n"

def obsexcmsg(ui, message, important=False):
    verbose = ui.configbool('experimental', 'verbose-obsolescence-exchange',
                            False)
    if verbose:
        message = 'OBSEXC: ' + message
    if important or verbose:
        ui.status(message)

def obsexcprg(ui, *args, **kwargs):
    topic = 'obsmarkers exchange'
    if ui.configbool('experimental', 'verbose-obsolescence-exchange', False):
        topic = 'OBSEXC'
    ui.progress(topic, *args, **kwargs)

def filterparents(parents):
    """filter nullrev parents

    (and other crazyness)"""
    p1, p2 = parents
    if p1 == nullrev and p2 == nullrev:
        return ()
    elif p1 != nullrev and (p2 == nullrev or p1 == p2):
        return (p1,)
    elif p1 == nullrev and p2 != nullrev:
        return (p2,)
    else:
        return parents

def shouldwarmcache(repo, tr):
    configbool = repo.ui.configbool
    config = repo.ui.config
    desc = getattr(tr, 'desc', '')

    autocase = tr is None or desc.startswith('push') or desc.startswith('serve')
    autocache = config('experimental', 'obshashrange.warm-cache',
                       'auto') == 'auto'
    if autocache:
        warm = autocase
    else:
        # note: we should not get to the default case
        warm = configbool('experimental', 'obshashrange.warm-cache', True)

    if not configbool('experimental', 'obshashrange', False):
        return False
    if not warm:
        return False
    maxrevs = repo.ui.configint('experimental', 'obshashrange.max-revs', None)
    if maxrevs is not None and maxrevs < len(repo.unfiltered()):
        return False
    return True
