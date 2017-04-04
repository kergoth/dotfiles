import contextlib
import hashlib

from mercurial.node import hex, bin, nullid
from mercurial import (
    branchmap,
    changegroup,
    cmdutil,
    encoding,
    error,
    extensions,
    scmutil,
)

def _filename(repo):
    """name of a branchcache file for a given repo or repoview"""
    filename = "cache/topicmap"
    if repo.filtername:
        filename = '%s-%s' % (filename, repo.filtername)
    return filename

oldbranchcache = branchmap.branchcache

def _phaseshash(repo, maxrev):
    revs = set()
    cl = repo.changelog
    fr = cl.filteredrevs
    nm = cl.nodemap
    for roots in repo._phasecache.phaseroots[1:]:
        for n in roots:
            r = nm.get(n)
            if r not in fr and r < maxrev:
                revs.add(r)
    key = nullid
    revs = sorted(revs)
    if revs:
        s = hashlib.sha1()
        for rev in revs:
            s.update('%s;' % rev)
        key = s.digest()
    return key

@contextlib.contextmanager
def usetopicmap(repo):
    """use awful monkey patching to ensure topic map usage

    During the extend of the context block, The topicmap should be used and
    updated instead of the branchmap."""
    oldbranchcache = branchmap.branchcache
    oldfilename = branchmap._filename
    oldread = branchmap.read
    oldcaches = getattr(repo, '_branchcaches', {})
    try:
        branchmap.branchcache = topiccache
        branchmap._filename = _filename
        branchmap.read = readtopicmap
        repo._branchcaches = getattr(repo, '_topiccaches', {})
        yield
        repo._topiccaches = repo._branchcaches
    finally:
        repo._branchcaches = oldcaches
        branchmap.branchcache = oldbranchcache
        branchmap._filename = oldfilename
        branchmap.read = oldread

def cgapply(orig, repo, *args, **kwargs):
    """make sure a topicmap is used when applying a changegroup"""
    with usetopicmap(repo):
        return orig(repo, *args, **kwargs)

def commitstatus(orig, repo, node, branch, bheads=None, opts=None):
    # wrap commit status use the topic branch heads
    ctx = repo[node]
    if ctx.topic() and ctx.branch() == branch:
        bheads = repo.branchheads("%s:%s" % (branch, ctx.topic()))
    return orig(repo, node, branch, bheads=bheads, opts=opts)

class topiccache(oldbranchcache):

    def __init__(self, *args, **kwargs):
        otherbranchcache = branchmap.branchcache
        try:
            # super() call may fail otherwise
            branchmap.branchcache = oldbranchcache
            super(topiccache, self).__init__(*args, **kwargs)
            if self.filteredhash is None:
                self.filteredhash = nullid
            self.phaseshash = nullid
        finally:
            branchmap.branchcache = otherbranchcache

    def copy(self):
        """return an deep copy of the branchcache object"""
        new = topiccache(self, self.tipnode, self.tiprev, self.filteredhash,
                         self._closednodes)
        if self.filteredhash is None:
            self.filteredhash = nullid
        new.phaseshash = self.phaseshash
        return new

    def branchtip(self, branch, topic=''):
        '''Return the tipmost open head on branch head, otherwise return the
        tipmost closed head on branch.
        Raise KeyError for unknown branch.'''
        if topic:
            branch = '%s:%s' % (branch, topic)
        return super(topiccache, self).branchtip(branch)

    def branchheads(self, branch, closed=False, topic=''):
        if topic:
            branch = '%s:%s' % (branch, topic)
        return super(topiccache, self).branchheads(branch, closed=closed)

    def validfor(self, repo):
        """Is the cache content valid regarding a repo

        - False when cached tipnode is unknown or if we detect a strip.
        - True when cache is up to date or a subset of current repo."""
        # This is copy paste of mercurial.branchmap.branchcache.validfor in
        # 69077c65919d With a small changes to the cache key handling to
        # include phase information that impact the topic cache.
        #
        # All code changes should be flagged on site.
        try:
            if (self.tipnode == repo.changelog.node(self.tiprev)):
                fh = scmutil.filteredhash(repo, self.tiprev)
                if fh is None:
                    fh = nullid
                if ((self.filteredhash == fh)
                    and (self.phaseshash == _phaseshash(repo, self.tiprev))):
                    return True
            return False
        except IndexError:
            return False

    def write(self, repo):
        # This is copy paste of mercurial.branchmap.branchcache.write in
        # 69077c65919d With a small changes to the cache key handling to
        # include phase information that impact the topic cache.
        #
        # All code changes should be flagged on site.
        try:
            f = repo.vfs(_filename(repo), "w", atomictemp=True)
            cachekey = [hex(self.tipnode), str(self.tiprev)]
            # [CHANGE] we need a hash in all cases
            assert self.filteredhash is not None
            cachekey.append(hex(self.filteredhash))
            cachekey.append(hex(self.phaseshash))
            f.write(" ".join(cachekey) + '\n')
            nodecount = 0
            for label, nodes in sorted(self.iteritems()):
                for node in nodes:
                    nodecount += 1
                    if node in self._closednodes:
                        state = 'c'
                    else:
                        state = 'o'
                    f.write("%s %s %s\n" % (hex(node), state,
                                            encoding.fromlocal(label)))
            f.close()
            repo.ui.log('branchcache',
                        'wrote %s branch cache with %d labels and %d nodes\n',
                        repo.filtername, len(self), nodecount)
        except (IOError, OSError, error.Abort) as inst:
            repo.ui.debug("couldn't write branch cache: %s\n" % inst)
            # Abort may be raise by read only opener
            pass

    def update(self, repo, revgen):
        """Given a branchhead cache, self, that may have extra nodes or be
        missing heads, and a generator of nodes that are strictly a superset of
        heads missing, this function updates self to be correct.
        """
        oldgetbranchinfo = repo.revbranchcache().branchinfo
        try:
            def branchinfo(r):
                info = oldgetbranchinfo(r)
                topic = ''
                ctx = repo[r]
                if ctx.mutable():
                    topic = ctx.topic()
                branch = info[0]
                if topic:
                    branch = '%s:%s' % (branch, topic)
                return (branch, info[1])
            repo.revbranchcache().branchinfo = branchinfo
            super(topiccache, self).update(repo, revgen)
            if self.filteredhash is None:
                self.filteredhash = nullid
            self.phaseshash = _phaseshash(repo, self.tiprev)
        finally:
            repo.revbranchcache().branchinfo = oldgetbranchinfo

def readtopicmap(repo):
    # This is copy paste of mercurial.branchmap.read in 69077c65919d
    # With a small changes to the cache key handling to include phase
    # information that impact the topic cache.
    #
    # All code changes should be flagged on site.
    try:
        f = repo.vfs(_filename(repo))
        lines = f.read().split('\n')
        f.close()
    except (IOError, OSError):
        return None

    try:
        cachekey = lines.pop(0).split(" ", 2)
        last, lrev = cachekey[:2]
        last, lrev = bin(last), int(lrev)
        filteredhash = bin(cachekey[2]) # [CHANGE] unconditional filteredhash
        partial = topiccache(tipnode=last, tiprev=lrev,
                             filteredhash=filteredhash)
        partial.phaseshash = bin(cachekey[3]) # [CHANGE] read phaseshash
        if not partial.validfor(repo):
            # invalidate the cache
            raise ValueError('tip differs')
        cl = repo.changelog
        for l in lines:
            if not l:
                continue
            node, state, label = l.split(" ", 2)
            if state not in 'oc':
                raise ValueError('invalid branch state')
            label = encoding.tolocal(label.strip())
            node = bin(node)
            if not cl.hasnode(node):
                raise ValueError('node %s does not exist' % hex(node))
            partial.setdefault(label, []).append(node)
            if state == 'c':
                partial._closednodes.add(node)
    except KeyboardInterrupt:
        raise
    except Exception as inst:
        if repo.ui.debugflag:
            msg = 'invalid branchheads cache'
            if repo.filtername is not None:
                msg += ' (%s)' % repo.filtername
            msg += ': %s\n'
            repo.ui.debug(msg % inst)
        partial = None
    return partial

def modsetup(ui):
    """call at uisetup time to install various wrappings"""
    extensions.wrapfunction(changegroup.cg1unpacker, 'apply', cgapply)
    extensions.wrapfunction(cmdutil, 'commitstatus', commitstatus)
