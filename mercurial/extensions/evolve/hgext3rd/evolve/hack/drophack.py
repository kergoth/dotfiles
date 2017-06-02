# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
'''This extension add a hacky command to drop changeset during review

This extension is intended as a temporary hack to allow Matt Mackall to use
evolve in the Mercurial review it self. You should probably not use it if your
name is not Matt Mackall.
'''

import os
import time
import contextlib

from mercurial.i18n import _
from mercurial import registrar
from mercurial import repair
from mercurial import scmutil
from mercurial import lock as lockmod
from mercurial import util
from mercurial import commands

cmdtable = {}

if util.safehasattr(registrar, 'command'):
    command = registrar.command(cmdtable)
else: # compat with hg < 4.3
    from mercurial import cmdutil
    command = cmdutil.command(cmdtable)


@contextlib.contextmanager
def timed(ui, caption):
    ostart = os.times()
    cstart = time.time()
    yield
    cstop = time.time()
    ostop = os.times()
    wall = cstop - cstart
    user = ostop[0] - ostart[0]
    sys = ostop[1] - ostart[1]
    comb = user + sys
    ui.write("%s: wall %f comb %f user %f sys %f\n"
             % (caption, wall, comb, user, sys))

def obsmarkerchainfrom(obsstore, nodes):
    """return all marker chain starting from node

    Starting from mean "use as successors"."""
    # XXX need something smarter for descendant of bumped changeset
    seennodes = set(nodes)
    seenmarkers = set()
    pendingnodes = set(nodes)
    precursorsmarkers = obsstore.precursors
    while pendingnodes:
        current = pendingnodes.pop()
        new = set()
        for precmark in precursorsmarkers.get(current, ()):
            if precmark in seenmarkers:
                continue
            seenmarkers.add(precmark)
            new.add(precmark[0])
            yield precmark
        new -= seennodes
        pendingnodes |= new

def stripmarker(ui, repo, markers):
    """remove <markers> from the repo obsstore

    The old obsstore content is saved in a `obsstore.prestrip` file
    """
    repo = repo.unfiltered()
    repo.destroying()
    oldmarkers = list(repo.obsstore._all)
    util.rename(repo.svfs.join('obsstore'),
                repo.vfs.join('obsstore.prestrip'))
    del repo.obsstore # drop the cache
    newstore = repo.obsstore
    assert not newstore # should be empty after rename
    newmarkers = [m for m in oldmarkers if m not in markers]
    tr = repo.transaction('drophack')
    try:
        newstore.add(tr, newmarkers)
        tr.close()
    finally:
        tr.release()
    repo.destroyed()


@command('drop', [('r', 'rev', [], 'revision to update')], _('[-r] revs'))
def cmddrop(ui, repo, *revs, **opts):
    """I'm hacky do not use me!

    This command strip a changeset, its precursors and all obsolescence marker
    associated to its chain.

    There is no way to limit the extend of the purge yet. You may have to
    repull from other source to get some changeset and obsolescence marker
    back.

    This intended for Matt Mackall usage only. do not use me.
    """
    revs = list(revs)
    revs.extend(opts['rev'])
    if not revs:
        revs = ['.']
    # get the changeset
    revs = scmutil.revrange(repo, revs)
    if not revs:
        ui.write_err('no revision to drop\n')
        return 1
    # lock from the beginning to prevent race
    wlock = lock = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        # check they have no children
        if repo.revs('%ld and public()', revs):
            ui.write_err('cannot drop public revision')
            return 1
        if repo.revs('children(%ld) - %ld', revs, revs):
            ui.write_err('cannot drop revision with children')
            return 1
        if repo.revs('. and %ld', revs):
            newrevs = repo.revs('max(::. - %ld)', revs)
            if newrevs:
                assert len(newrevs) == 1
                newrev = newrevs.first()
            else:
                newrev = -1
            commands.update(ui, repo, newrev)
            ui.status(_('working directory now at %s\n') % repo[newrev])
        # get all markers and successors up to root
        nodes = [repo[r].node() for r in revs]
        with timed(ui, 'search obsmarker'):
            markers = set(obsmarkerchainfrom(repo.obsstore, nodes))
        ui.write('%i obsmarkers found\n' % len(markers))
        cl = repo.unfiltered().changelog
        with timed(ui, 'search nodes'):
            allnodes = set(nodes)
            allnodes.update(m[0] for m in markers if cl.hasnode(m[0]))
        ui.write('%i nodes found\n' % len(allnodes))
        cl = repo.changelog
        visiblenodes = set(n for n in allnodes if cl.hasnode(n))
        # check constraint again
        if repo.revs('%ln and public()', visiblenodes):
            ui.write_err('cannot drop public revision')
            return 1
        if repo.revs('children(%ln) - %ln', visiblenodes, visiblenodes):
            ui.write_err('cannot drop revision with children')
            return 1

        if markers:
            # strip them
            with timed(ui, 'strip obsmarker'):
                stripmarker(ui, repo, markers)
        # strip the changeset
        with timed(ui, 'strip nodes'):
            repair.strip(ui, repo, list(allnodes), backup="all",
                         topic='drophack')

    finally:
        lockmod.release(lock, wlock)

    # rewrite the whole file.
    # print data.
    # - time to compute the chain
    # - time to strip the changeset
    # - time to strip the obs marker.
