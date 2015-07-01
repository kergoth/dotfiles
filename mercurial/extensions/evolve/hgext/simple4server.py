'''enable experimental obsolescence feature of Mercurial

OBSOLESCENCE IS AN EXPERIMENTAL FEATURE MAKE SURE YOU UNDERSTOOD THE INVOLVED
CONCEPT BEFORE USING IT.

/!\ THIS EXTENSION IS INTENDED FOR SERVER SIDE ONLY USAGE /!\

For client side usages it is recommended to use the evolve extension for
improved user interface.'''

testedwith = '3.3.3 3.4-rc'
buglink = 'http://bz.selenic.com/'

import mercurial.obsolete

import struct
from mercurial import util
from mercurial import wireproto
from mercurial import extensions
from mercurial import obsolete
from cStringIO import StringIO
from mercurial import node
from mercurial.hgweb import hgweb_mod
from mercurial import bundle2
from mercurial import localrepo
from mercurial import exchange
from mercurial import node
_pack = struct.pack

gboptslist = gboptsmap = None
try:
    from mercurial import obsolete
    from mercurial import wireproto
    gboptslist = getattr(wireproto, 'gboptslist', None)
    gboptsmap = getattr(wireproto, 'gboptsmap', None)
except (ImportError, AttributeError):
    raise util.Abort('Your Mercurial is too old for this version of Evolve\n'
                     'requires version 3.0.1 or above')

# Start of simple4server specific content

from mercurial import pushkey

# specific content also include the wrapping int extsetup
def _nslist(orig, repo):
    rep = orig(repo)
    if not repo.ui.configbool('__temporary__', 'advertiseobsolete', True):
        rep.pop('obsolete')
    return rep

# End of simple4server specific content



# from evolve extension: 1a23c7c52a43
def srv_pushobsmarkers(repo, proto):
    """That receives a stream of markers and apply then to the repo"""
    fp = StringIO()
    proto.redirect()
    proto.getfile(fp)
    data = fp.getvalue()
    fp.close()
    lock = repo.lock()
    try:
        tr = repo.transaction('pushkey: obsolete markers')
        try:
            repo.obsstore.mergemarkers(tr, data)
            tr.close()
        finally:
            tr.release()
    finally:
        lock.release()
    repo.hook('evolve_pushobsmarkers')
    return wireproto.pushres(0)

# from evolve extension: 1a23c7c52a43
def _getobsmarkersstream(repo, heads=None, common=None):
    """Get a binary stream for all markers relevant to `::<heads> - ::<common>`
    """
    revset = ''
    args = []
    repo = repo.unfiltered()
    if heads is None:
        revset = 'all()'
    elif heads:
        revset += "(::%ln)"
        args.append(heads)
    else:
        assert False, 'pulling no heads?'
    if common:
        revset += ' - (::%ln)'
        args.append(common)
    nodes = [c.node() for c in repo.set(revset, *args)]
    markers = repo.obsstore.relevantmarkers(nodes)
    obsdata = StringIO()
    for chunk in obsolete.encodemarkers(markers, True):
        obsdata.write(chunk)
    obsdata.seek(0)
    return obsdata

if not util.safehasattr(obsolete.obsstore, 'relevantmarkers'):
    # from evolve extension: 1a23c7c52a43
    class pruneobsstore(obsolete.obsstore):
        """And extended obsstore class that read parent information from v1 format

        Evolve extension adds parent information in prune marker. We use it to make
        markers relevant to pushed changeset."""

        def __init__(self, *args, **kwargs):
            self.prunedchildren = {}
            return super(pruneobsstore, self).__init__(*args, **kwargs)

        def _load(self, markers):
            markers = self._prunedetectingmarkers(markers)
            return super(pruneobsstore, self)._load(markers)


        def _prunedetectingmarkers(self, markers):
            for m in markers:
                if not m[1]: # no successors
                    meta = obsolete.decodemeta(m[3])
                    if 'p1' in meta:
                        p1 = node.bin(meta['p1'])
                        self.prunedchildren.setdefault(p1, set()).add(m)
                    if 'p2' in meta:
                        p2 = node.bin(meta['p2'])
                        self.prunedchildren.setdefault(p2, set()).add(m)
                yield m

    # from evolve extension: 1a23c7c52a43
    def relevantmarkers(self, nodes):
        """return a set of all obsolescence marker relevant to a set of node.

        "relevant" to a set of node mean:

        - marker that use this changeset as successors
        - prune marker of direct children on this changeset.
        - recursive application of the two rules on precursors of these markers

        It is a set so you cannot rely on order"""
        seennodes = set(nodes)
        seenmarkers = set()
        pendingnodes = set(nodes)
        precursorsmarkers = self.precursors
        prunedchildren = self.prunedchildren
        while pendingnodes:
            direct = set()
            for current in pendingnodes:
                direct.update(precursorsmarkers.get(current, ()))
                direct.update(prunedchildren.get(current, ()))
            direct -= seenmarkers
            pendingnodes = set([m[0] for m in direct])
            seenmarkers |= direct
            pendingnodes -= seennodes
            seennodes |= pendingnodes
        return seenmarkers

# from evolve extension: cf35f38d6a10
def srv_pullobsmarkers(repo, proto, others):
    """serves a binary stream of markers.

    Serves relevant to changeset between heads and common. The stream is prefix
    by a -string- representation of an integer. This integer is the size of the
    stream."""
    opts = wireproto.options('', ['heads', 'common'], others)
    for k, v in opts.iteritems():
        if k in ('heads', 'common'):
            opts[k] = wireproto.decodelist(v)
    obsdata = _getobsmarkersstream(repo, **opts)
    finaldata = StringIO()
    obsdata = obsdata.getvalue()
    finaldata.write('%20i' % len(obsdata))
    finaldata.write(obsdata)
    finaldata.seek(0)
    return wireproto.streamres(proto.groupchunks(finaldata))


# from evolve extension: 3249814dabd1
def _obsrelsethashtreefm0(repo):
    return _obsrelsethashtree(repo, obsolete._fm0encodeonemarker)

# from evolve extension: 3249814dabd1
def _obsrelsethashtreefm1(repo):
    return _obsrelsethashtree(repo, obsolete._fm1encodeonemarker)

# from evolve extension: 3249814dabd1
def _obsrelsethashtree(repo, encodeonemarker):
    cache = []
    unfi = repo.unfiltered()
    markercache = {}
    for i in unfi:
        ctx = unfi[i]
        entry = 0
        sha = util.sha1()
        # add data from p1
        for p in ctx.parents():
            p = p.rev()
            if p < 0:
                p = node.nullid
            else:
                p = cache[p][1]
            if p != node.nullid:
                entry += 1
                sha.update(p)
        tmarkers = repo.obsstore.relevantmarkers([ctx.node()])
        if tmarkers:
            bmarkers = []
            for m in tmarkers:
                if not m in markercache:
                    markercache[m] = encodeonemarker(m)
                bmarkers.append(markercache[m])
            bmarkers.sort()
            for m in bmarkers:
                entry += 1
                sha.update(m)
        if entry:
            cache.append((ctx.node(), sha.digest()))
        else:
            cache.append((ctx.node(), node.nullid))
    return cache

# from evolve extension: 3249814dabd1
def _obshash(repo, nodes, version=0):
    if version == 0:
        hashs = _obsrelsethashtreefm0(repo)
    elif version ==1:
        hashs = _obsrelsethashtreefm1(repo)
    else:
        assert False
    nm = repo.changelog.nodemap
    revs = [nm.get(n) for n in nodes]
    return [r is None and node.nullid or hashs[r][1] for r in revs]

# from evolve extension: 3249814dabd1
def srv_obshash(repo, proto, nodes):
    return wireproto.encodelist(_obshash(repo, wireproto.decodelist(nodes)))

# from evolve extension: 3249814dabd1
def srv_obshash1(repo, proto, nodes):
    return wireproto.encodelist(_obshash(repo, wireproto.decodelist(nodes), version=1))

# from evolve extension: 3249814dabd1
def capabilities(orig, repo, proto):
    """wrapper to advertise new capability"""
    caps = orig(repo, proto)
    advertise = repo.ui.configbool('__temporary__', 'advertiseobsolete', True)
    if obsolete.isenabled(repo, obsolete.exchangeopt) and advertise:
        caps += ' _evoext_pushobsmarkers_0'
        caps += ' _evoext_pullobsmarkers_0'
        caps += ' _evoext_obshash_0'
        caps += ' _evoext_obshash_1'
        caps += ' _evoext_getbundle_obscommon'
    return caps

def _getbundleobsmarkerpart(orig, bundler, repo, source, **kwargs):
    if 'evo_obscommon' not in kwargs:
        return orig(bundler, repo, source, **kwargs)

    heads = kwargs.get('heads')
    if 'evo_obscommon' not in kwargs:
        return orig(bundler, repo, source, **kwargs)

    if kwargs.get('obsmarkers', False):
        if heads is None:
            heads = repo.heads()
        obscommon = kwargs.get('evo_obscommon', ())
        obsset = repo.set('::%ln - ::%ln', heads, obscommon)
        subset = [c.node() for c in obsset]
        markers = repo.obsstore.relevantmarkers(subset)
        exchange.buildobsmarkerspart(bundler, markers)

# from evolve extension: 10867a8e27c6
# heavily modified
def extsetup(ui):
    localrepo.moderncaps.add('_evoext_b2x_obsmarkers_0')
    gboptsmap['evo_obscommon'] = 'nodes'
    if not util.safehasattr(obsolete.obsstore, 'relevantmarkers'):
        obsolete.obsstore = pruneobsstore
        obsolete.obsstore.relevantmarkers = relevantmarkers
    hgweb_mod.perms['evoext_pushobsmarkers_0'] = 'push'
    hgweb_mod.perms['evoext_pullobsmarkers_0'] = 'pull'
    hgweb_mod.perms['evoext_obshash'] = 'pull'
    wireproto.commands['evoext_pushobsmarkers_0'] = (srv_pushobsmarkers, '')
    wireproto.commands['evoext_pullobsmarkers_0'] = (srv_pullobsmarkers, '*')
    # wrap module content
    origfunc = exchange.getbundle2partsmapping['obsmarkers']
    def newfunc(*args, **kwargs):
        return _getbundleobsmarkerpart(origfunc, *args, **kwargs)
    exchange.getbundle2partsmapping['obsmarkers'] = newfunc
    extensions.wrapfunction(wireproto, 'capabilities', capabilities)
    # wrap command content
    oldcap, args = wireproto.commands['capabilities']
    def newcap(repo, proto):
        return capabilities(oldcap, repo, proto)
    wireproto.commands['capabilities'] = (newcap, args)
    wireproto.commands['evoext_obshash'] = (srv_obshash, 'nodes')
    wireproto.commands['evoext_obshash1'] = (srv_obshash1, 'nodes')
    # specific simple4server content
    extensions.wrapfunction(pushkey, '_nslist', _nslist)
    pushkey._namespaces['namespaces'] = (lambda *x: False, pushkey._nslist)

def reposetup(ui, repo):
    evolveopts = ui.configlist('experimental', 'evolution')
    if not evolveopts:
        evolveopts = 'all'
        ui.setconfig('experimental', 'evolution', evolveopts)
