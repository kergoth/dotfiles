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

from mercurial import (
    bundle2,
    error,
    exchange,
    extensions,
    lock as lockmod,
    node,
    obsolete,
    pushkey,
    util,
    wireproto,
)

from . import (
    exthelper,
    utility,
    obsdiscovery,
)

eh = exthelper.exthelper()
eh.merge(obsdiscovery.eh)
obsexcmsg = utility.obsexcmsg
obsexcprg = utility.obsexcprg

eh.configitem('experimental', 'verbose-obsolescence-exchange')

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
    return wireproto.streamres(reader=finaldata, v1compressible=True)

abortmsg = "won't exchange obsmarkers through pushkey"
hint = "upgrade your client or server to use the bundle2 protocol"

def forbidpushkey(repo=None, key=None, old=None, new=None):
    """prevent exchange through pushkey"""
    raise error.Abort(abortmsg, hint=hint)

@eh.uisetup
def setuppushkeyforbidding(ui):
    pushkey._namespaces['obsolete'] = (forbidpushkey, forbidpushkey)
