# Copyright 2011 Peter Arrenbrecht <peter.arrenbrecht@gmail.com>
#                Logilab SA        <contact@logilab.fr>
#                Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#                Patrick Mezard <patrick@mezard.eu>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""evolve templates
"""

from . import (
    error,
    exthelper,
    obshistory
)

from mercurial import (
    cmdutil,
    templatekw,
    node,
    util
)

eh = exthelper.exthelper()

### template keywords
# XXX it does not handle troubles well :-/

@eh.templatekw('obsolete')
def obsoletekw(repo, ctx, templ, **args):
    """String. Whether the changeset is ``obsolete``.
    """
    if ctx.obsolete():
        return 'obsolete'
    return ''

@eh.templatekw('troubles')
def showtroubles(**args):
    """List of strings. Evolution troubles affecting the changeset
    (zero or more of "unstable", "divergent" or "bumped")."""
    ctx = args['ctx']
    try:
        # specify plural= explicitly to trigger TypeError on hg < 4.2
        return templatekw.showlist('trouble', ctx.instabilities(), args,
                                   plural='troubles')
    except TypeError:
        return templatekw.showlist('trouble', ctx.instabilities(), plural='troubles',
                                   **args)

if util.safehasattr(templatekw, 'showpredecessors'):
    eh.templatekw("precursors")(templatekw.showpredecessors)
else:
    # for version <= hg4.3
    def closestprecursors(repo, nodeid):
        """ Yield the list of next precursors pointing on visible changectx nodes
        """

        precursors = repo.obsstore.predecessors
        stack = [nodeid]

        while stack:
            current = stack.pop()
            currentpreccs = precursors.get(current, ())

            for prec in currentpreccs:
                precnodeid = prec[0]

                if precnodeid in repo:
                    yield precnodeid
                else:
                    stack.append(precnodeid)

    @eh.templatekw("precursors")
    def shownextvisibleprecursors(repo, ctx, **args):
        """Returns a string containing the list of the closest precursors
        """
        precursors = sorted(closestprecursors(repo, ctx.node()))
        precursors = [node.hex(p) for p in precursors]

        # <= hg-4.1 requires an explicite gen.
        # we can use None once the support is dropped
        #
        # They also requires an iterator instead of an iterable.
        gen = iter(" ".join(p[:12] for p in precursors))
        return templatekw._hybrid(gen.__iter__(), precursors, lambda x: {'precursor': x},
                                  lambda d: d['precursor'][:12])

def closestsuccessors(repo, nodeid):
    """ returns the closest visible successors sets instead.
    """
    return directsuccessorssets(repo, nodeid)

if util.safehasattr(templatekw, 'showsuccessorssets'):
    eh.templatekw("successors")(templatekw.showsuccessorssets)
else:
    # for version <= hg4.3

    @eh.templatekw("successors")
    def shownextvisiblesuccessors(repo, ctx, templ, **args):
        """Returns a string of sets of successors for a changectx

        Format used is: [ctx1, ctx2], [ctx3] if ctx has been splitted into ctx1 and
        ctx2 while also diverged into ctx3"""
        if not ctx.obsolete():
            return ''

        ssets, _ = closestsuccessors(repo, ctx.node())
        ssets = [[node.hex(n) for n in ss] for ss in ssets]

        data = []
        gen = []
        for ss in ssets:
            subgen = '[%s]' % ', '.join(n[:12] for n in ss)
            gen.append(subgen)
            h = templatekw._hybrid(iter(subgen), ss, lambda x: {'successor': x},
                                   lambda d: "%s" % d["successor"])
            data.append(h)

        gen = ', '.join(gen)
        return templatekw._hybrid(iter(gen), data, lambda x: {'successorset': x},
                                  lambda d: d["successorset"])

def _getusername(ui):
    """the default username in the config or None"""
    try:
        return ui.username()
    except error.Abort: # no easy way to avoid ui raising Abort here :-/
        return None

def obsfatedefaulttempl(ui):
    """ Returns a dict with the default templates for obs fate
    """
    # Prepare templates
    verbtempl = '{verb}'
    usertempl = '{if(users, " by {join(users, ", ")}")}'
    succtempl = '{if(successors, " as ")}{successors}' # Bypass if limitation
    datetempleq = ' (at {min_date|isodate})'
    datetemplnoteq = ' (between {min_date|isodate} and {max_date|isodate})'
    datetempl = '{if(max_date, "{ifeq(min_date, max_date, "%s", "%s")}")}' % (datetempleq, datetemplnoteq)

    optionalusertempl = usertempl
    username = _getusername(ui)
    if username is not None:
        optionalusertempl = ('{ifeq(join(users, "\0"), "%s", "", "%s")}'
                             % (username, usertempl))

    # Assemble them
    return {
        'obsfate_quiet': verbtempl + succtempl,
        'obsfate': verbtempl + succtempl + optionalusertempl,
        'obsfate_verbose': verbtempl + succtempl + usertempl + datetempl,
    }

def obsfatedata(repo, ctx):
    """compute the raw data needed for computing obsfate
    Returns a list of dict
    """
    if not ctx.obsolete():
        return None

    successorssets, pathcache = closestsuccessors(repo, ctx.node())

    # closestsuccessors returns an empty list for pruned revisions, remap it
    # into a list containing en empty list for future processing
    if successorssets == []:
        successorssets = [[]]

    succsmap = repo.obsstore.successors
    fullsuccessorsets = [] # successor set + markers
    for sset in successorssets:
        if sset:
            markers = obshistory.successorsetallmarkers(sset, pathcache)
            fullsuccessorsets.append((sset, markers))
        else:
            # XXX we do not catch all prune markers (eg rewritten then pruned)
            # (fix me later)
            foundany = False
            for mark in succsmap.get(ctx.node(), ()):
                if not mark[1]:
                    foundany = True
                    fullsuccessorsets.append((sset, [mark]))
            if not foundany:
                fullsuccessorsets.append(([], []))

    values = []
    for sset, rawmarkers in fullsuccessorsets:
        raw = obshistory.preparesuccessorset(sset, rawmarkers)
        values.append(raw)

    return values

def obsfatelineprinter(obsfateline, ui):
    quiet = ui.quiet
    verbose = ui.verbose
    normal = not verbose and not quiet

    # Build the line step by step
    line = []

    # Verb
    line.append(obsfateline['verb'])

    # Successors
    successors = obsfateline["successors"]

    if successors:
        fmtsuccessors = map(lambda s: s[:12], successors)
        line.append(" as %s" % ", ".join(fmtsuccessors))

    # Users
    if (verbose or normal) and 'users' in obsfateline:
        users = obsfateline['users']

        if not verbose:
            # If current user is the only user, do not show anything if not in
            # verbose mode
            username = _getusername(ui)
            if len(users) == 1 and users[0] == username:
                users = None

        if users:
            line.append(" by %s" % ", ".join(users))

    # Date
    if verbose:
        min_date = obsfateline['min_date']
        max_date = obsfateline['max_date']

        if min_date == max_date:
            fmtmin_date = util.datestr(min_date, '%Y-%m-%d %H:%M %1%2')
            line.append(" (at %s)" % fmtmin_date)
        else:
            fmtmin_date = util.datestr(min_date, '%Y-%m-%d %H:%M %1%2')
            fmtmax_date = util.datestr(max_date, '%Y-%m-%d %H:%M %1%2')
            line.append(" (between %s and %s)" % (fmtmin_date, fmtmax_date))

    return "".join(line)

def obsfateprinter(obsfate, ui, prefix=""):
    lines = []
    for raw in obsfate:
        lines.append(obsfatelineprinter(raw, ui))

    if prefix:
        lines = [prefix + line for line in lines]

    return "\n".join(lines)

@eh.templatekw("obsfatedata")
def showobsfatedata(repo, ctx, **args):
    # Get the needed obsfate data
    values = obsfatedata(repo, ctx)

    if values is None:
        return templatekw.showlist("obsfatedata", [], args)

    # Format each successorset successors list
    for raw in values:
        # As we can't do something like
        # "{join(map(nodeshort, successors), ', '}" in template, manually
        # create a correct textual representation
        gen = ', '.join(n[:12] for n in raw['successors'])

        makemap = lambda x: {'successor': x}
        joinfmt = lambda d: "%s" % d['successor']
        raw['successors'] = templatekw._hybrid(gen, raw['successors'], makemap,
                                               joinfmt)

    # And then format them
    # Insert default obsfate templates
    args['templ'].cache.update(obsfatedefaulttempl(repo.ui))

    if repo.ui.quiet:
        name = "obsfate_quiet"
    elif repo.ui.verbose:
        name = "obsfate_verbose"
    elif repo.ui.debugflag:
        name = "obsfate_debug"
    else:
        name = "obsfate"

    # Format a single value
    def fmt(d):
        nargs = args.copy()
        nargs.update(d[name])
        return args['templ'](name, **nargs)

    # Generate a good enough string representation using templater
    gen = []
    for d in values:
        chunk = fmt({name: d})
        chunkstr = []

        # Empty the generator
        try:
            while True:
                chunkstr.append(chunk.next())
        except StopIteration:
            pass

        gen.append("".join(chunkstr))
    gen = "; ".join(gen)

    return templatekw._hybrid(gen, values, lambda x: {name: x}, fmt)

# rely on core mercurial starting from 4.4 for the obsfate template
if not util.safehasattr(templatekw, 'showobsfate'):

    @eh.templatekw("obsfate")
    def showobsfate(*args, **kwargs):
        return showobsfatedata(*args, **kwargs)

if util.safehasattr(cmdutil.changeset_printer, '_showobsfate'):
    pass # already included by default
elif util.safehasattr(cmdutil.changeset_printer, '_exthook'):
    @eh.wrapfunction(cmdutil.changeset_printer, '_exthook')
    def exthook(original, self, ctx):
        # Call potential other extensions
        original(self, ctx)

        obsfate = obsfatedata(self.repo, ctx)
        if obsfate is None:
            return ""

        output = obsfateprinter(obsfate, self.ui, prefix="obsolete:    ")

        self.ui.write(output, label='log.obsfate')
        self.ui.write("\n")

# copy from mercurial.obsolete with a small change to stop at first known changeset.

def directsuccessorssets(repo, initialnode, cache=None):
    """return set of all direct successors of initial nodes
    """

    succmarkers = repo.obsstore.successors

    # Stack of nodes we search successors sets for
    toproceed = [initialnode]
    # set version of above list for fast loop detection
    # element added to "toproceed" must be added here
    stackedset = set(toproceed)

    pathscache = {}

    if cache is None:
        cache = {}
    while toproceed:
        current = toproceed[-1]
        if current in cache:
            stackedset.remove(toproceed.pop())
        elif current != initialnode and current in repo:
            # We have a valid direct successors.
            cache[current] = [(current,)]
        elif current not in succmarkers:
            if current in repo:
                # We have a valid last successors.
                cache[current] = [(current,)]
            else:
                # Final obsolete version is unknown locally.
                # Do not count that as a valid successors
                cache[current] = []
        else:
            for mark in sorted(succmarkers[current]):
                for suc in mark[1]:
                    if suc not in cache:
                        if suc in stackedset:
                            # cycle breaking
                            cache[suc] = []
                        else:
                            # case (3) If we have not computed successors sets
                            # of one of those successors we add it to the
                            # `toproceed` stack and stop all work for this
                            # iteration.
                            pathscache.setdefault(suc, []).append((current, mark))
                            toproceed.append(suc)
                            stackedset.add(suc)
                            break
                else:
                    continue
                break
            else:
                succssets = []
                for mark in sorted(succmarkers[current]):
                    # successors sets contributed by this marker
                    markss = [[]]
                    for suc in mark[1]:
                        # cardinal product with previous successors
                        productresult = []
                        for prefix in markss:
                            for suffix in cache[suc]:
                                newss = list(prefix)
                                for part in suffix:
                                    # do not duplicated entry in successors set
                                    # first entry wins.
                                    if part not in newss:
                                        newss.append(part)
                                productresult.append(newss)
                        markss = productresult
                    succssets.extend(markss)
                # remove duplicated and subset
                seen = []
                final = []
                candidate = sorted(((set(s), s) for s in succssets if s),
                                   key=lambda x: len(x[1]), reverse=True)
                for setversion, listversion in candidate:
                    for seenset in seen:
                        if setversion.issubset(seenset):
                            break
                    else:
                        final.append(listversion)
                        seen.append(setversion)
                final.reverse() # put small successors set first
                cache[current] = final

    return cache[initialnode], pathscache
