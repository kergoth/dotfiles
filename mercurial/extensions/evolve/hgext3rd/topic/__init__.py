# __init__.py - topic extension
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""support for topic branches

Topic branches are lightweight branches which disappear when changes are
finalized (move to the public phase).

Compared to bookmark, topic is reference carried by each changesets of the
series instead of just the single head revision.  Topic are quite similar to
the way named branch work, except they eventualy fade away when the changeset
becomes part of the immutable history. Changeset can belong to both a topic and
a named branch, but as long as it is mutable, its topic identity will prevail.
As a result, default destination for 'update', 'merge', etc...  will take topic
into account. When a topic is active these operations will only consider other
changesets on that topic (and, in some occurence, bare changeset on same
branch).  When no topic is active, changeset with topic will be ignored and
only bare one on the same branch will be taken in account.

There is currently two commands to be used with that extension: 'topics' and
'stack'.

The 'hg topics' command is used to set the current topic, change and list
existing one. 'hg topics --verbose' will list various information related to
each topic.

The 'stack' will show you information about the stack of commit belonging to
your current topic.

Topic is offering you aliases reference to changeset in your current topic
stack as 't#'. For example, 't1' refers to the root of your stack, 't2' to the
second commits, etc. The 'hg stack' command show these number.

Push behavior will change a bit with topic. When pushing to a publishing
repository the changesets will turn public and the topic data on them will fade
away. The logic regarding pushing new heads will behave has before, ignore any
topic related data. When pushing to a non-publishing repository (supporting
topic), the head checking will be done taking topic data into account.
Push will complain about multiple heads on a branch if you push multiple heads
with no topic information on them (or multiple public heads). But pushing a new
topic will not requires any specific flag. However, pushing multiple heads on a
topic will be met with the usual warning.

The 'evolve' extension takes 'topic' into account. 'hg evolve --all'
will evolve all changesets in the active topic. In addition, by default. 'hg
next' and 'hg prev' will stick to the current topic.

Be aware that this extension is still an experiment, commands and other features
are likely to be change/adjusted/dropped over time as we refine the concept.
"""

from __future__ import absolute_import

import re

from mercurial.i18n import _
from mercurial import (
    cmdutil,
    commands,
    context,
    error,
    extensions,
    hg,
    localrepo,
    lock,
    merge,
    namespaces,
    node,
    obsolete,
    patch,
    phases,
    registrar,
    util,
)

from . import (
    constants,
    revset as topicrevset,
    destination,
    stack,
    topicmap,
    discovery,
)

if util.safehasattr(registrar, 'command'):
    commandfunc = registrar.command
else: # compat with hg < 4.3
    commandfunc = cmdutil.command

cmdtable = {}
command = commandfunc(cmdtable)
colortable = {'topic.active': 'green',
              'topic.list.troubledcount': 'red',
              'topic.list.headcount.multiple': 'yellow',
              'topic.list.behindcount': 'cyan',
              'topic.list.behinderror': 'red',
              'topic.stack.index': 'yellow',
              'topic.stack.index.base': 'none dim',
              'topic.stack.desc.base': 'none dim',
              'topic.stack.state.base': 'dim',
              'topic.stack.state.clean': 'green',
              'topic.stack.index.current': 'cyan',       # random pick
              'topic.stack.state.current': 'cyan bold',  # random pick
              'topic.stack.desc.current': 'cyan',        # random pick
              'topic.stack.state.unstable': 'red',
              'topic.stack.summary.behindcount': 'cyan',
              'topic.stack.summary.behinderror': 'red',
              'topic.stack.summary.headcount.multiple': 'yellow',
              # default color to help log output and thg
              # (first pick I could think off, update as needed
              'log.topic': 'green_background',
              'topic.active': 'green',
             }

version = '0.1.1.dev'
testedwith = '4.0.2 4.1.3 4.2.1'
minimumhgversion = '4.0'
buglink = 'https://bz.mercurial-scm.org/'

def _contexttopic(self, force=False):
    if not (force or self.mutable()):
        return ''
    return self.extra().get(constants.extrakey, '')
context.basectx.topic = _contexttopic

topicrev = re.compile(r'^t\d+$')
branchrev = re.compile(r'^b\d+$')

def _namemap(repo, name):
    revs = None
    if topicrev.match(name):
        idx = int(name[1:])
        ttype = 'topic'
        tname = topic = repo.currenttopic
        if not tname:
            raise error.Abort(_('cannot resolve "%s": no active topic') % name)
        revs = list(stack.getstack(repo, topic=topic))
    elif branchrev.match(name):
        ttype = 'branch'
        idx = int(name[1:])
        tname = branch = repo[None].branch()
        revs = list(stack.getstack(repo, branch=branch))

    if revs is not None:
        try:
            r = revs[idx - 1]
        except IndexError:
            msg = _('cannot resolve "%s": %s "%s" has only %d changesets')
            raise error.Abort(msg % (name, ttype, tname, len(revs)))
        return [repo[r].node()]
    if name not in repo.topics:
        return []
    node = repo.changelog.node
    return [node(rev) for rev in repo.revs('topic(%s)', name)]

def _nodemap(repo, node):
    ctx = repo[node]
    t = ctx.topic()
    if t and ctx.phase() > phases.public:
        return [t]
    return []

def uisetup(ui):
    destination.modsetup(ui)
    topicrevset.modsetup(ui)
    discovery.modsetup(ui)
    topicmap.modsetup(ui)
    setupimportexport(ui)

    extensions.afterloaded('rebase', _fixrebase)

    entry = extensions.wrapcommand(commands.table, 'commit', commitwrap)
    entry[1].append(('t', 'topic', '',
                     _("use specified topic"), _('TOPIC')))

    extensions.wrapfunction(cmdutil, 'buildcommittext', committextwrap)
    extensions.wrapfunction(merge, 'update', mergeupdatewrap)

    try:
        evolve = extensions.find('evolve')
        extensions.wrapfunction(evolve, "presplitupdate", presplitupdatetopic)
    except (KeyError, AttributeError):
        pass

    cmdutil.summaryhooks.add('topic', summaryhook)


def reposetup(ui, repo):
    if not isinstance(repo, localrepo.localrepository):
        return # this can be a peer in the ssh case (puzzling)

    repo = repo.unfiltered()

    if repo.ui.config('experimental', 'thg.displaynames', None) is None:
        repo.ui.setconfig('experimental', 'thg.displaynames', 'topics',
                          source='topic-extension')

    class topicrepo(repo.__class__):

        def _restrictcapabilities(self, caps):
            caps = super(topicrepo, self)._restrictcapabilities(caps)
            caps.add('topics')
            return caps

        def commit(self, *args, **kwargs):
            backup = self.ui.backupconfig('ui', 'allowemptycommit')
            try:
                if repo.currenttopic != repo['.'].topic():
                    # bypass the core "nothing changed" logic
                    self.ui.setconfig('ui', 'allowemptycommit', True)
                return super(topicrepo, self).commit(*args, **kwargs)
            finally:
                self.ui.restoreconfig(backup)

        def commitctx(self, ctx, error=None):
            topicfilter = topicmap.topicfilter(self.filtername)
            if topicfilter != self.filtername:
                other = repo.filtered(topicmap.topicfilter(repo.filtername))
                other.commitctx(ctx, error=error)

            if isinstance(ctx, context.workingcommitctx):
                current = self.currenttopic
                if current:
                    ctx.extra()[constants.extrakey] = current
            if (isinstance(ctx, context.memctx) and
                ctx.extra().get('amend_source') and
                ctx.topic() and
                not self.currenttopic):
                # we are amending and need to remove a topic
                del ctx.extra()[constants.extrakey]
            return super(topicrepo, self).commitctx(ctx, error=error)

        @property
        def topics(self):
            if self._topics is not None:
                return self._topics
            topics = set(['', self.currenttopic])
            for c in self.set('not public()'):
                topics.add(c.topic())
            topics.remove('')
            self._topics = topics
            return topics

        @property
        def currenttopic(self):
            return self.vfs.tryread('topic')

        # overwritten at the instance level by topicmap.py
        _autobranchmaptopic = True

        def branchmap(self, topic=None):
            if topic is None:
                topic = getattr(repo, '_autobranchmaptopic', False)
            topicfilter = topicmap.topicfilter(self.filtername)
            if not topic or topicfilter == self.filtername:
                return super(topicrepo, self).branchmap()
            return self.filtered(topicfilter).branchmap()

        def invalidatevolatilesets(self):
            # XXX we might be able to move this to something invalidated less often
            super(topicrepo, self).invalidatevolatilesets()
            self._topics = None

        def peer(self):
            peer = super(topicrepo, self).peer()
            if getattr(peer, '_repo', None) is not None: # localpeer
                class topicpeer(peer.__class__):
                    def branchmap(self):
                        usetopic = not self._repo.publishing()
                        return self._repo.branchmap(topic=usetopic)
                peer.__class__ = topicpeer
            return peer

    repo.__class__ = topicrepo
    repo._topics = None
    if util.safehasattr(repo, 'names'):
        repo.names.addnamespace(namespaces.namespace(
            'topics', 'topic', namemap=_namemap, nodemap=_nodemap,
            listnames=lambda repo: repo.topics))

@command('topics [TOPIC]', [
        ('', 'clear', False, 'clear active topic if any'),
        ('r', 'rev', '', 'revset of existing revisions', _('REV')),
        ('l', 'list', False, 'show the stack of changeset in the topic'),
    ] + commands.formatteropts)
def topics(ui, repo, topic='', clear=False, rev=None, list=False, **opts):
    """View current topic, set current topic, or see all topics.

    The --verbose version of this command display various information on the state of each topic."""
    if list:
        if clear or rev:
            raise error.Abort(_("cannot use --clear or --rev with --list"))
        if not topic:
            topic = repo.currenttopic
        if not topic:
            raise error.Abort(_('no active topic to list'))
        return stack.showstack(ui, repo, topic=topic, opts=opts)

    if rev:
        if not obsolete.isenabled(repo, obsolete.createmarkersopt):
            raise error.Abort(_('must have obsolete enabled to change topics'))
        if clear:
            topic = None
        elif not topic:
            raise error.Abort('changing topic requires a topic name or --clear')
        if any(not c.mutable() for c in repo.set('%r and public()', rev)):
            raise error.Abort("can't change topic of a public change")
        return _changetopics(ui, repo, rev, topic)

    if clear:
        return _changecurrenttopic(repo, None)

    if topic:
        return _changecurrenttopic(repo, topic)

    _listtopics(ui, repo, opts)

@command('stack [TOPIC]', [] + commands.formatteropts)
def cmdstack(ui, repo, topic='', **opts):
    """list all changesets in a topic and other information

    List the current topic by default."""
    if not topic:
        topic = None
    branch = None
    if topic is None and repo.currenttopic:
        topic = repo.currenttopic
    if topic is None:
        branch = repo[None].branch()
    return stack.showstack(ui, repo, branch=branch, topic=topic, opts=opts)

def _changecurrenttopic(repo, newtopic):
    """changes the current topic."""

    if newtopic:
        with repo.wlock():
            with repo.vfs.open('topic', 'w') as f:
                f.write(newtopic)
    else:
        if repo.vfs.exists('topic'):
            repo.vfs.unlink('topic')

def _changetopics(ui, repo, revset, newtopic):
    rewrote = 0
    wl = l = txn = None
    try:
        wl = repo.wlock()
        l = repo.lock()
        txn = repo.transaction('rewrite-topics')
        p1 = None
        p2 = None
        successors = {}
        for c in repo.set('%r', revset):
            def filectxfn(repo, ctx, path):
                try:
                    return c[path]
                except error.ManifestLookupError:
                    return None
            fixedextra = dict(c.extra())
            ui.debug('old node id is %s\n' % node.hex(c.node()))
            ui.debug('origextra: %r\n' % fixedextra)
            oldtopic = fixedextra.get(constants.extrakey, None)
            if oldtopic == newtopic:
                continue
            if newtopic is None:
                del fixedextra[constants.extrakey]
            else:
                fixedextra[constants.extrakey] = newtopic
            fixedextra[constants.changekey] = c.hex()
            if 'amend_source' in fixedextra:
                # TODO: right now the commitctx wrapper in
                # topicrepo overwrites the topic in extra if
                # amend_source is set to support 'hg commit
                # --amend'. Support for amend should be adjusted
                # to not be so invasive.
                del fixedextra['amend_source']
            ui.debug('changing topic of %s from %s to %s\n' % (
                c, oldtopic, newtopic))
            ui.debug('fixedextra: %r\n' % fixedextra)
            # While changing topic of set of linear commits, make sure that
            # we base our commits on new parent rather than old parent which
            # was obsoleted while changing the topic
            p1 = c.p1().node()
            p2 = c.p2().node()
            if p1 in successors:
                p1 = successors[p1]
            if p2 in successors:
                p2 = successors[p2]
            mc = context.memctx(
                repo, (p1, p2), c.description(),
                c.files(), filectxfn,
                user=c.user(), date=c.date(), extra=fixedextra)
            newnode = repo.commitctx(mc)
            successors[c.node()] = newnode
            ui.debug('new node id is %s\n' % node.hex(newnode))
            obsolete.createmarkers(repo, [(c, (repo[newnode],))])
            rewrote += 1
        # move the working copy too
        wctx = repo[None]
        # in-progress merge is a bit too complex for now.
        if len(wctx.parents()) == 1:
            newid = successors.get(wctx.p1().node())
            if newid is not None:
                hg.update(repo, newid, quietempty=True)
        txn.close()
    finally:
        lock.release(txn, l, wl)
        repo.invalidate()
    ui.status('changed topic on %d changes\n' % rewrote)

def _listtopics(ui, repo, opts):
    fm = ui.formatter('topics', opts)
    activetopic = repo.currenttopic
    namemask = '%s'
    if repo.topics and ui.verbose:
        maxwidth = max(len(t) for t in repo.topics)
        namemask = '%%-%is' % maxwidth
    for topic in sorted(repo.topics):
        fm.startitem()
        marker = ' '
        label = 'topic'
        active = (topic == activetopic)
        if active:
            marker = '*'
            label = 'topic.active'
        if not ui.quiet:
            # registering the active data is made explicitly later
            fm.plain(' %s ' % marker, label=label)
        fm.write('topic', namemask, topic, label=label)
        fm.data(active=active)
        if ui.verbose:
            # XXX we should include the data even when not verbose
            data = stack.stackdata(repo, topic=topic)
            fm.plain(' (')
            fm.write('branches+', 'on branch: %s',
                     '+'.join(data['branches']), # XXX use list directly after 4.0 is released
                     label='topic.list.branches')
            fm.plain(', ')
            fm.write('changesetcount', '%d changesets', data['changesetcount'],
                     label='topic.list.changesetcount')
            if data['troubledcount']:
                fm.plain(', ')
                fm.write('troubledcount', '%d troubled',
                         data['troubledcount'],
                         label='topic.list.troubledcount')
            if 1 < data['headcount']:
                fm.plain(', ')
                fm.write('headcount', '%d heads',
                         data['headcount'],
                         label='topic.list.headcount.multiple')
            if 0 < data['behindcount']:
                fm.plain(', ')
                fm.write('behindcount', '%d behind',
                         data['behindcount'],
                         label='topic.list.behindcount')
            elif -1 == data['behindcount']:
                fm.plain(', ')
                fm.write('behinderror', '%s',
                         _('ambiguous destination'),
                         label='topic.list.behinderror')
            fm.plain(')')
        fm.plain('\n')
    fm.end()

def summaryhook(ui, repo):
    t = repo.currenttopic
    if not t:
        return
    # i18n: column positioning for "hg summary"
    ui.write(_("topic:  %s\n") % ui.label(t, 'topic.active'))

def commitwrap(orig, ui, repo, *args, **opts):
    with repo.wlock():
        if opts.get('topic'):
            t = opts['topic']
            with repo.vfs.open('topic', 'w') as f:
                f.write(t)
        return orig(ui, repo, *args, **opts)

def committextwrap(orig, repo, ctx, subs, extramsg):
    ret = orig(repo, ctx, subs, extramsg)
    t = repo.currenttopic
    if t:
        ret = ret.replace("\nHG: branch",
                          "\nHG: topic '%s'\nHG: branch" % t)
    return ret

def mergeupdatewrap(orig, repo, node, branchmerge, force, *args, **kwargs):
    matcher = kwargs.get('matcher')
    partial = not (matcher is None or matcher.always())
    wlock = repo.wlock()
    isrebase = False
    try:
        ret = orig(repo, node, branchmerge, force, *args, **kwargs)
        # The mergeupdatewrap function makes the destination's topic as the
        # current topic. This is right for merge but wrong for rebase. We check
        # if rebase is running and update the currenttopic to topic of new
        # rebased commit. We have explicitly stored in config if rebase is
        # running.
        if repo.ui.hasconfig('experimental', 'topicrebase'):
            isrebase = True
        if (not partial and not branchmerge) or isrebase:
            ot = repo.currenttopic
            t = ''
            pctx = repo[node]
            if pctx.phase() > phases.public:
                t = pctx.topic()
            with repo.vfs.open('topic', 'w') as f:
                f.write(t)
            if t and t != ot:
                repo.ui.status(_("switching to topic %s\n") % t)
        return ret
    finally:
        wlock.release()

def _fixrebase(loaded):
    if not loaded:
        return

    def savetopic(ctx, extra):
        if ctx.topic():
            extra[constants.extrakey] = ctx.topic()

    def newmakeextrafn(orig, copiers):
        return orig(copiers + [savetopic])

    def setrebaseconfig(orig, ui, repo, **opts):
        repo.ui.setconfig('experimental', 'topicrebase', 'yes',
                          source='topic-extension')
        return orig(ui, repo, **opts)

    try:
        rebase = extensions.find("rebase")
        extensions.wrapfunction(rebase, '_makeextrafn', newmakeextrafn)
        # This exists to store in the config that rebase is running so that we can
        # update the topic according to rebase. This is a hack and should be removed
        # when we have better options.
        extensions.wrapcommand(rebase.cmdtable, 'rebase', setrebaseconfig)
    except KeyError:
        pass

## preserve topic during import/export

def _exporttopic(seq, ctx):
    topic = ctx.topic()
    if topic:
        return 'EXP-Topic %s' % topic
    return None

def _importtopic(repo, patchdata, extra, opts):
    if 'topic' in patchdata:
        extra['topic'] = patchdata['topic']

def setupimportexport(ui):
    """run at ui setup time to install import/export logic"""
    cmdutil.extraexport.append('topic')
    cmdutil.extraexportmap['topic'] = _exporttopic
    cmdutil.extrapreimport.append('topic')
    cmdutil.extrapreimportmap['topic'] = _importtopic
    patch.patchheadermap.append(('EXP-Topic', 'topic'))

## preserve topic during split

def presplitupdatetopic(original, repo, ui, prev, ctx):
    # Save topic of revision
    topic = None
    if util.safehasattr(ctx, 'topic'):
        topic = ctx.topic()

    # Update the working directory
    original(repo, ui, prev, ctx)

    # Restore the topic if need
    if topic:
        _changecurrenttopic(repo, topic)
