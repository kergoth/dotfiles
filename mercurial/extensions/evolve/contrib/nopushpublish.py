# Extension which prevent changeset to be turn public by push operation
#
# Copyright 2011 Logilab SA        <contact@logilab.fr>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.


from mercurial import extensions, util
from mercurial import discovery

def checkpublish(orig, repo, remote, outgoing, *args):

    # is remote publishing?
    publish = True
    if 'phases' in remote.listkeys('namespaces'):
        remotephases = remote.listkeys('phases')
        publish = remotephases.get('publishing', False)

    npublish = 0
    if publish:
        for rev in outgoing.missing:
            if repo[rev].phase():
                npublish += 1
    if npublish:
        repo.ui.warn("Push would publish %s changesets" % npublish)

    ret = orig(repo, remote, outgoing, *args)
    if npublish:
        raise util.Abort("Publishing push forbiden",
                         hint="Use `hg phase -p <rev>` to manually publish them")

    return ret

def uisetup(ui):
    extensions.wrapfunction(discovery, 'checkheads', checkpublish)
