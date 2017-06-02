# Code dedicated to the exchange of obsolescence markers
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

from __future__ import absolute_import

try:
    import StringIO as io
    StringIO = io.StringIO
except ImportError:
    import io
    StringIO = io.StringIO

import errno
import socket

from mercurial import (
    bundle2,
    error,
    exchange,
    extensions,
    httppeer,
    localrepo,
    lock as lockmod,
    node,
    obsolete,
    util,
    wireproto,
)
from mercurial.hgweb import hgweb_mod
from mercurial.i18n import _

from . import (
    exthelper,
    utility,
    obsdiscovery,
)

eh = exthelper.exthelper()
eh.merge(obsdiscovery.eh)
obsexcmsg = utility.obsexcmsg
obsexcprg = utility.obsexcprg


_bestformat = max(obsolete.formats.keys())

#####################################################
### Support for subset specification in getbundle ###
#####################################################

# Adds support for the 'evo_obscommon' argument to getbundle This argument use
# the data recovered from the discovery to request only a subpart of the
# obsolete subtree.

@eh.uisetup
def addgetbundleargs(self):
    wireproto.gboptsmap['evo_obscommon'] = 'nodes'
    wireproto.gboptsmap['evo_missing_nodes'] = 'nodes'

@eh.wrapfunction(exchange, '_pullbundle2extraprepare')
def _addobscommontob2pull(orig, pullop, kwargs):
    ret = orig(pullop, kwargs)
    ui = pullop.repo.ui
    if ('obsmarkers' in kwargs and
        pullop.remote.capable('_evoext_getbundle_obscommon')):
        boundaries = obsdiscovery.buildpullobsmarkersboundaries(pullop)
        if 'common' in boundaries:
            common = boundaries['common']
            if common != pullop.common:
                obsexcmsg(ui, 'request obsmarkers for some common nodes\n')
            if common != [node.nullid]:
                kwargs['evo_obscommon'] = common
        elif 'missing' in boundaries:
            missing = boundaries['missing']
            if missing:
                obsexcmsg(ui, 'request obsmarkers for %d common nodes\n'
                          % len(missing))
            kwargs['evo_missing_nodes'] = missing
    return ret

def _getbundleobsmarkerpart(orig, bundler, repo, source, **kwargs):
    if not (set(['evo_obscommon', 'evo_missing_nodes']) & set(kwargs)):
        return orig(bundler, repo, source, **kwargs)

    if kwargs.get('obsmarkers', False):
        heads = kwargs.get('heads')
        if 'evo_obscommon' in kwargs:
            if heads is None:
                heads = repo.heads()
            obscommon = kwargs.get('evo_obscommon', ())
            assert obscommon
            obsset = repo.unfiltered().set('::%ln - ::%ln', heads, obscommon)
            subset = [c.node() for c in obsset]
        else:
            common = kwargs.get('common')
            subset = [c.node() for c in repo.unfiltered().set('only(%ln, %ln)', heads, common)]
            subset += kwargs['evo_missing_nodes']
        markers = repo.obsstore.relevantmarkers(subset)
        if util.safehasattr(bundle2, 'buildobsmarkerspart'):
            bundle2.buildobsmarkerspart(bundler, markers)
        else:
            exchange.buildobsmarkerspart(bundler, markers)

# manual wrap up in extsetup because of the wireproto.commands mapping
def _obscommon_capabilities(orig, repo, proto):
    """wrapper to advertise new capability"""
    caps = orig(repo, proto)
    if obsolete.isenabled(repo, obsolete.exchangeopt):
        caps = caps.split()
        caps.append('_evoext_getbundle_obscommon')
        caps.sort()
        caps = ' '.join(caps)
    return caps

@eh.extsetup
def extsetup_obscommon(ui):
    wireproto.gboptsmap['evo_obscommon'] = 'nodes'

    # wrap module content
    origfunc = exchange.getbundle2partsmapping['obsmarkers']

    def newfunc(*args, **kwargs):
        return _getbundleobsmarkerpart(origfunc, *args, **kwargs)
    exchange.getbundle2partsmapping['obsmarkers'] = newfunc

    extensions.wrapfunction(wireproto, 'capabilities', _obscommon_capabilities)
    # wrap command content
    oldcap, args = wireproto.commands['capabilities']

    def newcap(repo, proto):
        return _obscommon_capabilities(oldcap, repo, proto)
    wireproto.commands['capabilities'] = (newcap, args)

def _pushobsmarkers(repo, data):
    tr = lock = None
    try:
        lock = repo.lock()
        tr = repo.transaction('pushkey: obsolete markers')
        new = repo.obsstore.mergemarkers(tr, data)
        if new is not None:
            obsexcmsg(repo.ui, "%i obsolescence markers added\n" % new, True)
        tr.close()
    finally:
        lockmod.release(tr, lock)
    repo.hook('evolve_pushobsmarkers')

def srv_pushobsmarkers(repo, proto):
    """wireprotocol command"""
    fp = StringIO()
    proto.redirect()
    proto.getfile(fp)
    data = fp.getvalue()
    fp.close()
    _pushobsmarkers(repo, data)
    return wireproto.pushres(0)

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

# The wireproto.streamres API changed, handling chunking and compression
# directly. Handle either case.
if util.safehasattr(wireproto.abstractserverproto, 'groupchunks'):
    # We need to handle chunking and compression directly
    def streamres(d, proto):
        return wireproto.streamres(proto.groupchunks(d))
else:
    # Leave chunking and compression to streamres
    def streamres(d, proto):
        return wireproto.streamres(reader=d, v1compressible=True)

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
    return streamres(finaldata, proto)

###############################################
### Support for old legacy exchange methods ###
###############################################

class pushobsmarkerStringIO(StringIO):
    """hacky string io for progress"""

    @util.propertycache
    def length(self):
        return len(self.getvalue())

    def read(self, size=None):
        obsexcprg(self.ui, self.tell(), unit=_("bytes"), total=self.length)
        return StringIO.read(self, size)

    def __iter__(self):
        d = self.read(4096)
        while d:
            yield d
            d = self.read(4096)

# compat-code: _pushobsolete
#
# the _pushobsolete function is a core function used to exchange
# obsmarker with repository that does not support bundle2

@eh.wrapfunction(exchange, '_pushobsolete')
def _pushobsolete(orig, pushop):
    """utility function to push obsolete markers to a remote"""
    if not obsolete.isenabled(pushop.repo, obsolete.exchangeopt):
        return
    if 'obsmarkers' in pushop.stepsdone:
        return
    pushop.stepsdone.add('obsmarkers')
    if pushop.cgresult == 0:
        return
    pushop.ui.debug('try to push obsolete markers to remote\n')
    repo = pushop.repo
    remote = pushop.remote
    if (repo.obsstore and 'obsolete' in remote.listkeys('namespaces')):
        markers = pushop.outobsmarkers
        if not markers:
            obsexcmsg(repo.ui, "no marker to push\n")
        elif remote.capable('_evoext_pushobsmarkers_0'):
            msg = ('the remote repository use years old versions of Mercurial'
                   ' and evolve\npushing obsmarker using legacy method\n')
            repo.ui.warn(msg)
            repo.ui.warn('(please upgrade your server)\n')
            obsdata = pushobsmarkerStringIO()
            for chunk in obsolete.encodemarkers(markers, True):
                obsdata.write(chunk)
            obsdata.seek(0)
            obsdata.ui = repo.ui
            obsexcmsg(repo.ui, "pushing %i obsolescence markers (%i bytes)\n"
                               % (len(markers), len(obsdata.getvalue())),
                      True)
            remote.evoext_pushobsmarkers_0(obsdata)
            obsexcprg(repo.ui, None)

        else:
            # XXX core could be able do the same things but without the debug
            # and progress output.
            msg = ('the remote repository usea years old version of Mercurial'
                   ' and not evolve extension\n')
            repo.ui.warn(msg)
            msg = 'pushing obsmarker using and extremely slow legacy method\n'
            repo.ui.warn(msg)
            repo.ui.warn('(please upgrade your server and enable evolve.serveronly on it)\n')
            rslts = []
            remotedata = obsolete._pushkeyescape(markers).items()
            totalbytes = sum(len(d) for k, d in remotedata)
            sentbytes = 0
            obsexcmsg(repo.ui, "pushing %i obsolescence markers in %i "
                               "pushkey payload (%i bytes)\n"
                               % (len(markers), len(remotedata), totalbytes),
                      True)
            for key, data in remotedata:
                obsexcprg(repo.ui, sentbytes, item=key, unit=_("bytes"),
                          total=totalbytes)
                rslts.append(remote.pushkey('obsolete', key, '', data))
                sentbytes += len(data)
                obsexcprg(repo.ui, sentbytes, item=key, unit=_("bytes"),
                          total=totalbytes)
            obsexcprg(repo.ui, None)
            if [r for r in rslts if not r]:
                msg = _('failed to push some obsolete markers!\n')
                repo.ui.warn(msg)
        obsexcmsg(repo.ui, "DONE\n")

# Supporting legacy way to push obsmarker so that old client can still push
# them somewhat efficiently

@eh.addattr(wireproto.wirepeer, 'evoext_pushobsmarkers_0')
def client_pushobsmarkers(self, obsfile):
    """wireprotocol peer method"""
    self.requirecap('_evoext_pushobsmarkers_0',
                    _('push obsolete markers faster'))
    ret, output = self._callpush('evoext_pushobsmarkers_0', obsfile)
    for l in output.splitlines(True):
        self.ui.status(_('remote: '), l)
    return ret

@eh.addattr(httppeer.httppeer, 'evoext_pushobsmarkers_0')
def httpclient_pushobsmarkers(self, obsfile):
    """httpprotocol peer method
    (Cannot simply use _callpush as http is doing some special handling)"""
    self.requirecap('_evoext_pushobsmarkers_0',
                    _('push obsolete markers faster'))
    try:
        r = self._call('evoext_pushobsmarkers_0', data=obsfile)
        vals = r.split('\n', 1)
        if len(vals) < 2:
            raise error.ResponseError(_("unexpected response:"), r)

        for l in vals[1].splitlines(True):
            if l.strip():
                self.ui.status(_('remote: '), l)
        return vals[0]
    except socket.error as err:
        if err.args[0] in (errno.ECONNRESET, errno.EPIPE):
            raise error.Abort(_('push failed: %s') % err.args[1])
        raise error.Abort(err.args[1])

@eh.wrapfunction(localrepo.localrepository, '_restrictcapabilities')
def local_pushobsmarker_capabilities(orig, repo, caps):
    caps = orig(repo, caps)
    caps.add('_evoext_pushobsmarkers_0')
    return caps

@eh.addattr(localrepo.localpeer, 'evoext_pushobsmarkers_0')
def local_pushobsmarkers(peer, obsfile):
    data = obsfile.read()
    _pushobsmarkers(peer._repo, data)

# compat-code: _pullobsolete
#
# the _pullobsolete function is a core function used to exchange
# obsmarker with repository that does not support bundle2

@eh.wrapfunction(exchange, '_pullobsolete')
def _pullobsolete(orig, pullop):
    if not obsolete.isenabled(pullop.repo, obsolete.exchangeopt):
        return None
    if 'obsmarkers' in pullop.stepsdone:
        return None
    wirepull = pullop.remote.capable('_evoext_pullobsmarkers_0')
    if 'obsolete' not in pullop.remote.listkeys('namespaces'):
        return None # remote opted out of obsolescence marker exchange
    if not wirepull:
        return orig(pullop)
    tr = None
    ui = pullop.repo.ui
    boundaries = obsdiscovery.buildpullobsmarkersboundaries(pullop, bundle2=False)
    if 'missing' in boundaries and not boundaries['missing']:
        obsexcmsg(ui, "nothing to pull\n")
        return None
    elif not set(boundaries['heads']) - set(boundaries['common']):
        obsexcmsg(ui, "nothing to pull\n")
        return None

    obsexcmsg(ui, "pull obsolescence markers\n", True)
    new = 0

    msg = ('the remote repository use years old versions of Mercurial and evolve\n'
           'pulling obsmarker using legacy method\n')
    ui.warn(msg)
    ui.warn('(please upgrade your server)\n')

    obsdata = pullop.remote.evoext_pullobsmarkers_0(**boundaries)
    obsdata = obsdata.read()
    if len(obsdata) > 5:
        msg = "merging obsolescence markers (%i bytes)\n" % len(obsdata)
        obsexcmsg(ui, msg)
        tr = pullop.gettransaction()
        old = len(pullop.repo.obsstore._all)
        pullop.repo.obsstore.mergemarkers(tr, obsdata)
        new = len(pullop.repo.obsstore._all) - old
        obsexcmsg(ui, "%i obsolescence markers added\n" % new, True)
    else:
        obsexcmsg(ui, "no unknown remote markers\n")
    obsexcmsg(ui, "DONE\n")
    if new:
        pullop.repo.invalidatevolatilesets()
    return tr

@eh.addattr(wireproto.wirepeer, 'evoext_pullobsmarkers_0')
def client_pullobsmarkers(self, heads=None, common=None):
    self.requirecap('_evoext_pullobsmarkers_0', _('look up remote obsmarkers'))
    opts = {}
    if heads is not None:
        opts['heads'] = wireproto.encodelist(heads)
    if common is not None:
        opts['common'] = wireproto.encodelist(common)
    f = self._callcompressable("evoext_pullobsmarkers_0", **opts)
    length = int(f.read(20))
    chunk = 4096
    current = 0
    data = StringIO()
    ui = self.ui
    obsexcprg(ui, current, unit=_("bytes"), total=length)
    while current < length:
        readsize = min(length - current, chunk)
        data.write(f.read(readsize))
        current += readsize
        obsexcprg(ui, current, unit=_("bytes"), total=length)
    obsexcprg(ui, None)
    data.seek(0)
    return data

@eh.addattr(localrepo.localpeer, 'evoext_pullobsmarkers_0')
def local_pullobsmarkers(self, heads=None, common=None):
    return _getobsmarkersstream(self._repo, heads=heads,
                                common=common)

def _legacypush_capabilities(orig, repo, proto):
    """wrapper to advertise new capability"""
    caps = orig(repo, proto)
    if obsolete.isenabled(repo, obsolete.exchangeopt):
        caps = caps.split()
        caps.append('_evoext_pushobsmarkers_0')
        caps.append('_evoext_pullobsmarkers_0')
        caps.sort()
        caps = ' '.join(caps)
    return caps

@eh.extsetup
def extsetup(ui):
    # legacy standalone method
    hgweb_mod.perms['evoext_pushobsmarkers_0'] = 'push'
    hgweb_mod.perms['evoext_pullobsmarkers_0'] = 'pull'
    wireproto.commands['evoext_pushobsmarkers_0'] = (srv_pushobsmarkers, '')
    wireproto.commands['evoext_pullobsmarkers_0'] = (srv_pullobsmarkers, '*')

    extensions.wrapfunction(wireproto, 'capabilities', _legacypush_capabilities)
    # wrap command content
    oldcap, args = wireproto.commands['capabilities']

    def newcap(repo, proto):
        return _legacypush_capabilities(oldcap, repo, proto)
    wireproto.commands['capabilities'] = (newcap, args)
