# Code dedicated to adding various "safeguard" around evolution
#
# Some of these will be pollished and upstream when mature. Some other will be
# replaced by better alternative later.
#
# Copyright 2017 Pierre-Yves David <pierre-yves.david@ens-lyon.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

from mercurial import error

from mercurial.i18n import _

from . import exthelper

eh = exthelper.exthelper()

@eh.reposetup
def setuppublishprevention(ui, repo):

    class noautopublishrepo(repo.__class__):

        def checkpush(self, pushop):
            super(noautopublishrepo, self).checkpush(pushop)
            behavior = repo.ui.config('experimental', 'auto-publish', 'default')
            remotephases = pushop.remote.listkeys('phases')
            publishing = remotephases.get('publishing', False)
            if behavior in ('warn', 'abort') and publishing:
                if pushop.revs is None:
                    published = repo.filtered('served').revs("not public()")
                else:
                    published = repo.revs("::%ln - public()", pushop.revs)
                if published:
                    if behavior == 'warn':
                        repo.ui.warn(_('%i changesets about to be published\n') % len(published))
                    elif behavior == 'abort':
                        msg = _('push would publish 1 changesets')
                        hint = _("behavior controlled by 'experimental.auto-publish' config")
                        raise error.Abort(msg, hint=hint)

    repo.__class__ = noautopublishrepo
