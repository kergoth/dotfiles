# Various utility function for the evolve extension
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

import collections

from mercurial.i18n import _

from mercurial.node import nullrev

from . import (
    compat,
)

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

    autocase = False
    if tr is None:
        autocase = True
    elif desc.startswith('serve'):
        autocase = True
    elif desc.startswith('push') and not desc.startswith('push-response'):
        autocase = True

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

class MultipleSuccessorsError(RuntimeError):
    """Exception raised by _singlesuccessor when multiple successor sets exists

    The object contains the list of successorssets in its 'successorssets'
    attribute to call to easily recover.
    """

    def __init__(self, successorssets):
        self.successorssets = successorssets

def builddependencies(repo, revs):
    """returns dependency graphs giving an order to solve instability of revs
    (see _orderrevs for more information on usage)"""

    # For each troubled revision we keep track of what instability if any should
    # be resolved in order to resolve it. Example:
    # dependencies = {3: [6], 6:[]}
    # Means that: 6 has no dependency, 3 depends on 6 to be solved
    dependencies = {}
    # rdependencies is the inverted dict of dependencies
    rdependencies = collections.defaultdict(set)

    for r in revs:
        dependencies[r] = set()
        for p in repo[r].parents():
            try:
                succ = _singlesuccessor(repo, p)
            except MultipleSuccessorsError as exc:
                dependencies[r] = exc.successorssets
                continue
            if succ in revs:
                dependencies[r].add(succ)
                rdependencies[succ].add(r)
    return dependencies, rdependencies

def _singlesuccessor(repo, p):
    """returns p (as rev) if not obsolete or its unique latest successors

    fail if there are no such successor"""

    if not p.obsolete():
        return p.rev()
    obs = repo[p]
    ui = repo.ui
    newer = compat.successorssets(repo, obs.node())
    # search of a parent which is not killed
    while not newer:
        ui.debug("stabilize target %s is plain dead,"
                 " trying to stabilize on its parent\n" %
                 obs)
        obs = obs.parents()[0]
        newer = compat.successorssets(repo, obs.node())
    if len(newer) > 1 or len(newer[0]) > 1:
        raise MultipleSuccessorsError(newer)

    return repo[newer[0][0]].rev()

def revselectionprompt(ui, repo, revs, customheader=""):
    """function to prompt user to choose a revision from all the revs and return
    that revision for further tasks

    revs is a list of rev number of revision from which one revision should be
    choosed by the user
    customheader is a text which the caller wants as the header of the prompt
    which will list revisions to select

    returns value is:
        rev number of revision choosed: if user choose a revision
        None: if user entered a wrong input, user quit the prompt,
              ui.interactive is not set
    """

    # ui.interactive is not set, fallback to default behavior and avoid showing
    # the prompt
    if not ui.configbool('ui', 'interactive'):
        return None

    promptmsg = customheader + "\n"
    for idx, rev in enumerate(revs):
        curctx = repo[rev]
        revmsg = _("%d: [%s] %s\n" % (idx, curctx,
                                      curctx.description().split("\n")[0]))
        promptmsg += revmsg

    promptmsg += _("q: quit the prompt\n")
    promptmsg += _("enter the index of the revision you want to select:")
    idxselected = ui.prompt(promptmsg)

    intidx = None
    try:
        intidx = int(idxselected)
    except ValueError:
        if idxselected == 'q':
            return None
        ui.write_err(_("invalid value '%s' entered for index\n") % idxselected)
        return None

    if intidx >= len(revs) or intidx < 0:
        # we can make this error message better
        ui.write_err(_("invalid value '%d' entered for index\n") % intidx)
        return None

    return revs[intidx]
