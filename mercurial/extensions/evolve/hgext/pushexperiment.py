"""Small extension altering some push behavior

- Add a new wire protocol command to exchange obsolescence markers. Sending the
  raw file as a binary instead of using pushkey hack.
- Add a "push done" notification
- Push obsolescence marker before anything else (This works around the lack
of global transaction)

"""

import errno
from StringIO import StringIO

from mercurial.i18n import _
from mercurial import extensions
from mercurial import wireproto
from mercurial import obsolete
from mercurial import localrepo


def client_pushobsmarkers(self, obsfile):
    """wireprotocol peer method"""
    self.requirecap('_push_experiment_pushobsmarkers_0',
                    _('push obsolete markers faster'))
    ret, output = self._callpush('push_experiment_pushobsmarkers_0', obsfile)
    for l in output.splitlines(True):
        self.ui.status(_('remote: '), l)
    return ret


def srv_pushobsmarkers(repo, proto):
    """wireprotocol command"""
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
    return wireproto.pushres(0)


def syncpush(orig, repo, remote):
    """wraper for obsolete.syncpush to use the fast way if possible"""
    if not (obsolete.isenabled(repo, obsolete.exchangeopt) and
            repo.obsstore):
        return
    if remote.capable('_push_experiment_pushobsmarkers_0'):
        return # already pushed before changeset
        remote.push_experiment_pushobsmarkers_0(obsfp)
        return
    return orig(repo, remote)


def client_notifypushend(self):
    """wire peer  command to notify a push is done"""
    self.requirecap('_push_experiment_notifypushend_0',
                    _('hook once push is all done'))
    return self._call('push_experiment_notifypushend_0')


def srv_notifypushend(repo, proto):
    """wire protocol command to notify a push is done"""
    proto.redirect()
    repo.hook('notifypushend')
    return wireproto.pushres(0)


def augmented_push(orig, repo, remote, *args, **kwargs):
    """push wrapped that call the wire protocol command"""
    if not remote.canpush():
        raise error.Abort(_("destination does not support push"))
    if (obsolete.isenabled(repo, obsolete.exchangeopt) and repo.obsstore
        and remote.capable('_push_experiment_pushobsmarkers_0')):
        # push marker early to limit damage of pushing too early.
        try:
            obsfp = repo.svfs('obsstore')
        except IOError as e:
            if e.errno != errno.ENOENT:
                raise
        else:
            remote.push_experiment_pushobsmarkers_0(obsfp)
    ret = orig(repo, remote, *args, **kwargs)
    if remote.capable('_push_experiment_notifypushend_0'):
        remote.push_experiment_notifypushend_0()
    return ret


def capabilities(orig, repo, proto):
    """wrapper to advertise new capability"""
    caps = orig(repo, proto)
    if obsolete.isenabled(repo, obsolete.exchangeopt):
        caps += ' _push_experiment_pushobsmarkers_0'
    caps += ' _push_experiment_notifypushend_0'
    return caps


def extsetup(ui):
    wireproto.wirepeer.push_experiment_pushobsmarkers_0 = client_pushobsmarkers
    wireproto.wirepeer.push_experiment_notifypushend_0 = client_notifypushend
    wireproto.commands['push_experiment_pushobsmarkers_0'] = \
        (srv_pushobsmarkers, '')
    wireproto.commands['push_experiment_notifypushend_0'] = \
        (srv_notifypushend, '')
    extensions.wrapfunction(wireproto, 'capabilities', capabilities)
    extensions.wrapfunction(obsolete, 'syncpush', syncpush)
    extensions.wrapfunction(localrepo.localrepository, 'push', augmented_push)


