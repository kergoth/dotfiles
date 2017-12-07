# __init__.py - topic extension
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""support for topic branches

Topic branches are lightweight branches which disappear when changes are
finalized (move to the public phase).

Compared to bookmark, topic is reference carried by each changesets of the
series instead of just the single head revision.  Topic are quite similar to
the way named branch work, except they eventually fade away when the changeset
becomes part of the immutable history. Changeset can belong to both a topic and
a named branch, but as long as it is mutable, its topic identity will prevail.
As a result, default destination for 'update', 'merge', etc...  will take topic
into account. When a topic is active these operations will only consider other
changesets on that topic (and, in some occurrence, bare changeset on same
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

topic-mode
==========

The topic extension can be configured to ensure the user do not forget to add
a topic when committing a new topic::

    [experimental]
    # behavior when commit is made without an active topic
    topic-mode = ignore # do nothing special (default)
    topic-mode = warning # print a warning
    topic-mode = enforce # abort the commit (except for merge)
    topic-mode = enforce-all # abort the commit (even for merge)
    topic-mode = random # use a randomized generated topic (except for merge)
    topic-mode = random-all # use a randomized generated topic (even for merge)

Single head enforcing
=====================

The extensions come with an option to enforce that there is only one heads for
each name in the repository at any time.

    [experimental]
    enforce-single-head = yes

Publishing behavior
===================

Topic vanish when changeset move to the public phases. Moving to the public
phase usually happens on push, but it is possible to update that behavior. The
server needs to have specific config for this.

    # everything pushed become public (the default)
    [phase]
    publish = yes

    # nothing push turned public
    [phase]
    publish = no

    # topic branches are not published, changeset without topic are
    [phase]
    publish = no
    [experimental]
    topic.publish-bare-branch = yes

In addition, the topic extension adds a ``--publish`` flag on :hg:`push`. When
used, the pushed revisions are published if the push succeeds. It also applies
to common revisions selected by the push.
"""

from __future__ import absolute_import

import functools
import re
import time
import weakref

from mercurial.i18n import _
from mercurial import (
    bookmarks,
    changelog,
    cmdutil,
    commands,
    context,
    error,
    extensions,
    hg,
    localrepo,
    lock as lockmod,
    merge,
    namespaces,
    node,
    obsolete,
    patch,
    phases,
    registrar,
    scmutil,
    templatefilters,
    util,
)

from . import (
    compat,
    constants,
    flow,
    revset as topicrevset,
    destination,
    stack,
    topicmap,
    discovery,
    randomname
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
              'topic.stack.shortnode.base': 'none dim',
              'topic.stack.state.base': 'dim',
              'topic.stack.state.clean': 'green',
              'topic.stack.index.current': 'cyan',       # random pick
              'topic.stack.state.current': 'cyan bold',  # random pick
              'topic.stack.desc.current': 'cyan',        # random pick
              'topic.stack.shortnode.current': 'cyan',   # random pick
              'topic.stack.state.unstable': 'red',
              'topic.stack.summary.behindcount': 'cyan',
              'topic.stack.summary.behinderror': 'red',
              'topic.stack.summary.headcount.multiple': 'yellow',
              # default color to help log output and thg
              # (first pick I could think off, update as needed
              'log.topic': 'green_background',
              'topic.active': 'green',
             }

__version__ = '0.5.2.dev'

testedwith = '4.1.3 4.2.3 4.3.3 4.4.1'
minimumhgversion = '4.1'
buglink = 'https://bz.mercurial-scm.org/'

if util.safehasattr(registrar, 'configitem'):
    configtable = {}
    configitem = registrar.configitem(configtable)

    configitem('experimental', 'enforce-topic',
               default=False,
    )
    configitem('experimental', 'enforce-single-head',
               default=False,
    )
    configitem('experimental', 'topic-mode',
               default=None,
    )
    configitem('experimental', 'topic.publish-bare-branch',
               default=False,
    )
    configitem('_internal', 'keep-topic',
               default=False,
    )

    def extsetup(ui):
        # register config that strictly belong to other code (thg, core, etc)
        #
        # To ensure all config items we used are registered, we register them if
        # nobody else did so far.
        from mercurial import configitems
        extraitem = functools.partial(configitems._register, ui._knownconfig)
        if ('experimental' not in ui._knownconfig
                or not ui._knownconfig['experimental'].get('thg.displaynames')):
            extraitem('experimental', 'thg.displaynames',
                      default=None,
            )
        if ('devel' not in ui._knownconfig
                or not ui._knownconfig['devel'].get('random')):
            extraitem('devel', 'randomseed',
                      default=None,
            )

def _contexttopic(self, force=False):
    if not (force or self.mutable()):
        return ''
    return self.extra().get(constants.extrakey, '')
context.basectx.topic = _contexttopic
def _contexttopicidx(self):
    topic = self.topic()
    if not topic:
        # XXX we might want to include t0 here,
        # however t0 is related to  'currenttopic' which has no place here.
        return None
    revlist = stack.stack(self._repo, topic=topic)
    try:
        return revlist.index(self.rev())
    except IndexError:
        # Lets move to the last ctx of the current topic
        return None
context.basectx.topicidx = _contexttopicidx

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
        revs = list(stack.stack(repo, topic=topic))
    elif branchrev.match(name):
        ttype = 'branch'
        idx = int(name[1:])
        tname = branch = repo[None].branch()
        revs = list(stack.stack(repo, branch=branch))

    if revs is not None:
        try:
            r = revs[idx]
        except IndexError:
            msg = _('cannot resolve "%s": %s "%s" has only %d changesets')
            raise error.Abort(msg % (name, ttype, tname, len(revs) - 1))
        # b0 or t0 can be None
        if r == -1 and idx == 0:
            msg = _('the %s "%s" has no %s')
            raise error.Abort(msg % (ttype, tname, name))
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
    discovery.modsetup(ui)
    topicmap.modsetup(ui)
    setupimportexport(ui)

    extensions.afterloaded('rebase', _fixrebase)

    flow.installpushflag(ui)

    entry = extensions.wrapcommand(commands.table, 'commit', commitwrap)
    entry[1].append(('t', 'topic', '',
                     _("use specified topic"), _('TOPIC')))

    entry = extensions.wrapcommand(commands.table, 'push', pushoutgoingwrap)
    entry[1].append(('t', 'topic', '',
                     _("topic to push"), _('TOPIC')))

    entry = extensions.wrapcommand(commands.table, 'outgoing',
                                   pushoutgoingwrap)
    entry[1].append(('t', 'topic', '',
                     _("topic to push"), _('TOPIC')))

    extensions.wrapfunction(cmdutil, 'buildcommittext', committextwrap)
    extensions.wrapfunction(merge, 'update', mergeupdatewrap)
    # We need to check whether t0 or b0 is passed to override the default update
    # behaviour of changing topic and I can't find a better way
    # to do that as scmutil.revsingle returns the rev number and hence we can't
    # plug into logic for this into mergemod.update().
    extensions.wrapcommand(commands.table, 'update', checkt0)

    try:
        evolve = extensions.find('evolve')
        extensions.wrapfunction(evolve.rewriteutil, "presplitupdate",
                                presplitupdatetopic)
    except (KeyError, AttributeError):
        pass

    cmdutil.summaryhooks.add('topic', summaryhook)


def reposetup(ui, repo):
    if not isinstance(repo, localrepo.localrepository):
        return # this can be a peer in the ssh case (puzzling)

    repo = repo.unfiltered()

    if repo.ui.config('experimental', 'thg.displaynames') is None:
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

        def transaction(self, desc, *a, **k):
            ctr = self.currenttransaction()
            tr = super(topicrepo, self).transaction(desc, *a, **k)
            if desc in ('strip', 'repair') or ctr is not None:
                return tr

            reporef = weakref.ref(self)
            if repo.ui.configbool('experimental', 'enforce-single-head'):
                origvalidator = tr.validator

                def validator(tr2):
                    repo = reporef()
                    flow.enforcesinglehead(repo, tr2)
                    origvalidator(tr2)
                tr.validator = validator

            if (repo.ui.configbool('experimental', 'topic.publish-bare-branch')
                    and (desc.startswith('push')
                         or desc.startswith('serve'))
                    ):
                origclose = tr.close
                trref = weakref.ref(tr)

                def close():
                    repo = reporef()
                    tr2 = trref()
                    flow.publishbarebranch(repo, tr2)
                    origclose()
                tr.close = close

            # real transaction start
            ct = self.currenttopic
            if not ct:
                return tr
            ctwasempty = stack.stack(self, topic=ct).changesetcount == 0

            reporef = weakref.ref(self)

            def currenttopicempty(tr):
                # check active topic emptiness
                repo = reporef()
                csetcount = stack.stack(repo, topic=ct).changesetcount
                empty = csetcount == 0
                if empty and not ctwasempty:
                    ui.status('active topic %r is now empty\n' % ct)
                if ctwasempty and not empty:
                    if csetcount == 1:
                        msg = _('active topic %r grew its first changeset\n')
                        ui.status(msg % ct)
                    else:
                        msg = _('active topic %r grew its %s first changesets\n')
                        ui.status(msg % (ct, csetcount))

            tr.addpostclose('signalcurrenttopicempty', currenttopicempty)
            return tr

    repo.__class__ = topicrepo
    repo._topics = None
    if util.safehasattr(repo, 'names'):
        repo.names.addnamespace(namespaces.namespace(
            'topics', 'topic', namemap=_namemap, nodemap=_nodemap,
            listnames=lambda repo: repo.topics))
    # Wrap workingctx extra to return the topic name
    extensions.wrapfunction(context.workingctx, '__init__', wrapinit)
    # Wrap changelog.add to drop empty topic
    extensions.wrapfunction(changelog.changelog, 'add', wrapadd)

def wrapinit(orig, self, repo, *args, **kwargs):
    orig(self, repo, *args, **kwargs)
    if getattr(repo, 'currenttopic', ''):
        self._extra[constants.extrakey] = repo.currenttopic
    else:
        # Empty key will be dropped from extra by another hack at the changegroup level
        self._extra[constants.extrakey] = ''

def wrapadd(orig, cl, manifest, files, desc, transaction, p1, p2, user,
            date=None, extra=None):
    if constants.extrakey in extra and not extra[constants.extrakey]:
        extra = extra.copy()
        del extra[constants.extrakey]
    return orig(cl, manifest, files, desc, transaction, p1, p2, user,
                date=date, extra=extra)

# revset predicates are automatically registered at loading via this symbol
revsetpredicate = topicrevset.revsetpredicate

@command('topics', [
        ('', 'clear', False, 'clear active topic if any'),
        ('r', 'rev', [], 'revset of existing revisions', _('REV')),
        ('l', 'list', False, 'show the stack of changeset in the topic'),
        ('', 'age', False, 'show when you last touched the topics'),
        ('', 'current', None, 'display the current topic only'),
    ] + commands.formatteropts,
    _('hg topics [TOPIC]'))
def topics(ui, repo, topic=None, **opts):
    """View current topic, set current topic, change topic for a set of revisions, or see all topics.

    Clear topic on existing topiced revisions::

      hg topics --rev <related revset> --clear

    Change topic on some revisions::

      hg topics <newtopicname> --rev <related revset>

    Clear current topic::

      hg topics --clear

    Set current topic::

      hg topics <topicname>

    List of topics::

      hg topics

    List of topics sorted according to their last touched time displaying last
    touched time and the user who last touched the topic::

      hg topics --age

    The active topic (if any) will be prepended with a "*".

    The `--current` flag helps to take active topic into account. For
    example, if you want to set the topic on all the draft changesets to the
    active topic, you can do:
        `hg topics -r "draft()" --current`

    The --verbose version of this command display various information on the state of each topic."""

    clear = opts.get('clear')
    list = opts.get('list')
    rev = opts.get('rev')
    current = opts.get('current')
    age = opts.get('age')

    if current and topic:
        raise error.Abort(_("cannot use --current when setting a topic"))
    if current and clear:
        raise error.Abort(_("cannot use --current and --clear"))
    if clear and topic:
        raise error.Abort(_("cannot use --clear when setting a topic"))
    if age and topic:
        raise error.Abort(_("cannot use --age while setting a topic"))

    touchedrevs = set()
    if rev:
        touchedrevs = scmutil.revrange(repo, rev)

    if topic:
        topic = topic.strip()
        if not topic:
            raise error.Abort(_("topic name cannot consist entirely of whitespaces"))
        # Have some restrictions on the topic name just like bookmark name
        scmutil.checknewlabel(repo, topic, 'topic')

    compat.startpager(ui, 'topics')

    if list:
        if clear or rev:
            raise error.Abort(_("cannot use --clear or --rev with --list"))
        if not topic:
            topic = repo.currenttopic
        if not topic:
            raise error.Abort(_('no active topic to list'))
        return stack.showstack(ui, repo, topic=topic, opts=opts)

    if touchedrevs:
        if not obsolete.isenabled(repo, obsolete.createmarkersopt):
            raise error.Abort(_('must have obsolete enabled to change topics'))
        if clear:
            topic = None
        elif opts.get('current'):
            topic = repo.currenttopic
        elif not topic:
            raise error.Abort('changing topic requires a topic name or --clear')
        if repo.revs('%ld and public()', touchedrevs):
            raise error.Abort("can't change topic of a public change")
        wl = lock = txn = None
        try:
            wl = repo.wlock()
            lock = repo.lock()
            txn = repo.transaction('rewrite-topics')
            rewrote = _changetopics(ui, repo, touchedrevs, topic)
            txn.close()
            ui.status('changed topic on %d changes\n' % rewrote)
        finally:
            lockmod.release(txn, lock, wl)
            repo.invalidate()
        return

    ct = repo.currenttopic
    if clear:
        empty = stack.stack(repo, topic=ct).changesetcount == 0
        if empty:
            if ct:
                ui.status(_('clearing empty topic "%s"\n') % ct)
        return _changecurrenttopic(repo, None)

    if topic:
        if not ct:
            ui.status(_('marked working directory as topic: %s\n') % topic)
        return _changecurrenttopic(repo, topic)

    # `hg topic --current`
    ret = 0
    if current and not ct:
        ui.write_err(_('no active topic\n'))
        ret = 1
    elif current:
        fm = ui.formatter('topic', opts)
        namemask = '%s\n'
        label = 'topic.active'
        fm.startitem()
        fm.write('topic', namemask, ct, label=label)
        fm.end()
    else:
        _listtopics(ui, repo, opts)
    return ret

@command('stack', [
    ] + commands.formatteropts,
    _('hg stack [TOPIC]'))
def cmdstack(ui, repo, topic='', **opts):
    """list all changesets in a topic and other information

    List the current topic by default.

    The --verbose version shows short nodes for the commits also.
    """
    if not topic:
        topic = None
    branch = None
    if topic is None and repo.currenttopic:
        topic = repo.currenttopic
    if topic is None:
        branch = repo[None].branch()
    compat.startpager(ui, 'stack')
    return stack.showstack(ui, repo, branch=branch, topic=topic, opts=opts)

@command('debugcb|debugconvertbookmark', [
        ('b', 'bookmark', '', _('bookmark to convert to topic')),
        ('', 'all', None, _('convert all bookmarks to topics')),
    ],
    _('[-b BOOKMARK] [--all]'))
def debugconvertbookmark(ui, repo, **opts):
    """Converts a bookmark to a topic with the same name.
    """

    bookmark = opts.get('bookmark')
    convertall = opts.get('all')

    if convertall and bookmark:
        raise error.Abort(_("cannot use '--all' and '-b' together"))
    if not (convertall or bookmark):
        raise error.Abort(_("you must specify either '--all' or '-b'"))

    bmstore = repo._bookmarks

    nodetobook = {}
    for book, revnode in bmstore.iteritems():
        if nodetobook.get(revnode):
            nodetobook[revnode].append(book)
        else:
            nodetobook[revnode] = [book]

    # a list of nodes which we have skipped so that we don't print the skip
    # warning repeatedly
    skipped = []

    actions = {}

    lock = wlock = tr = None
    try:
        wlock = repo.wlock()
        lock = repo.lock()
        if bookmark:
            try:
                node = bmstore[bookmark]
            except KeyError:
                raise error.Abort(_("no such bookmark exists: '%s'") % bookmark)

            revnum = repo[node].rev()
            if len(nodetobook[node]) > 1:
                ui.status(_("skipping revision '%d' as it has multiple bookmarks "
                          "on it\n") % revnum)
                return
            targetrevs = _findconvertbmarktopic(repo, bookmark)
            if targetrevs:
                actions[(bookmark, revnum)] = targetrevs

        elif convertall:
            for bmark, revnode in sorted(bmstore.iteritems()):
                revnum = repo[revnode].rev()
                if revnum in skipped:
                    continue
                if len(nodetobook[revnode]) > 1:
                    ui.status(_("skipping '%d' as it has multiple bookmarks on"
                              " it\n") % revnum)
                    skipped.append(revnum)
                    continue
                if bmark == '@':
                    continue
                targetrevs = _findconvertbmarktopic(repo, bmark)
                if targetrevs:
                    actions[(bmark, revnum)] = targetrevs

        if actions:
            try:
                tr = repo.transaction('debugconvertbookmark')
                for ((bmark, revnum), targetrevs) in sorted(actions.iteritems()):
                    _applyconvertbmarktopic(ui, repo, targetrevs, revnum, bmark, tr)
                tr.close()
            finally:
                tr.release()
    finally:
        lockmod.release(lock, wlock)

# inspired from mercurial.repair.stripbmrevset
CONVERTBOOKREVSET = """
not public() and (
    ancestors(bookmark(%s))
    and not ancestors(
        (
            (head() and not bookmark(%s))
            or (bookmark() - bookmark(%s))
        ) - (
            descendants(bookmark(%s))
            - bookmark(%s)
        )
    )
)
"""

def _findconvertbmarktopic(repo, bmark):
    """find revisions unambiguously defined by a bookmark

    find all changesets under the bookmark and under that bookmark only.
    """
    return repo.revs(CONVERTBOOKREVSET, bmark, bmark, bmark, bmark, bmark)

def _applyconvertbmarktopic(ui, repo, revs, old, bmark, tr):
    """apply bookmark conversion to topic

    Sets a topic as same as bname to all the changesets under the bookmark
    and delete the bookmark, if topic is set to any changeset

    old is the revision on which bookmark bmark is and tr is transaction object.
    """

    rewrote = _changetopics(ui, repo, revs, bmark)
    # We didn't changed topic to any changesets because the revset
    # returned an empty set of revisions, so let's skip deleting the
    # bookmark corresponding to which we didn't put a topic on any
    # changeset
    if rewrote == 0:
        return
    ui.status(_('changed topic to "%s" on %d revisions\n') % (bmark,
              rewrote))
    ui.debug('removing bookmark "%s" from "%d"' % (bmark, old))
    bookmarks.delete(repo, tr, [bmark])

def _changecurrenttopic(repo, newtopic):
    """changes the current topic."""

    if newtopic:
        with repo.wlock():
            with repo.vfs.open('topic', 'w') as f:
                f.write(newtopic)
    else:
        if repo.vfs.exists('topic'):
            repo.vfs.unlink('topic')

def _changetopics(ui, repo, revs, newtopic):
    """ Changes topic to newtopic of all the revisions in the revset and return
    the count of revisions whose topic has been changed.
    """
    rewrote = 0
    p1 = None
    p2 = None
    successors = {}
    for r in revs:
        c = repo[r]

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
            p1 = successors[p1][0]
        if p2 in successors:
            p2 = successors[p2][0]
        mc = context.memctx(repo,
                            (p1, p2),
                            c.description(),
                            c.files(),
                            filectxfn,
                            user=c.user(),
                            date=c.date(),
                            extra=fixedextra)

        # phase handling
        commitphase = c.phase()
        overrides = {('phases', 'new-commit'): commitphase}
        with repo.ui.configoverride(overrides, 'changetopic'):
            newnode = repo.commitctx(mc)

        successors[c.node()] = (newnode,)
        ui.debug('new node id is %s\n' % node.hex(newnode))
        rewrote += 1

    # create obsmarkers and move bookmarks
    # XXX we should be creating marker as we go instead of only at the end,
    # this makes the operations more modulars
    compat.cleanupnodes(repo, successors, 'changetopics')

    # move the working copy too
    wctx = repo[None]
    # in-progress merge is a bit too complex for now.
    if len(wctx.parents()) == 1:
        newid = successors.get(wctx.p1().node())
        if newid is not None:
            hg.update(repo, newid[0], quietempty=True)
    return rewrote

def _listtopics(ui, repo, opts):
    fm = ui.formatter('topics', opts)
    showlast = opts.get('age')
    if showlast:
        # we have a new function as plugging logic into existing function is
        # pretty much difficult
        return _showlasttouched(repo, fm, opts)
    activetopic = repo.currenttopic
    namemask = '%s'
    if repo.topics:
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

        data = stack.stack(repo, topic=topic)
        fm.plain(' (')
        if ui.verbose:
            fm.write('branches+', 'on branch: %s',
                     '+'.join(data.branches), # XXX use list directly after 4.0 is released
                     label='topic.list.branches')

            fm.plain(', ')
        fm.write('changesetcount', '%d changesets', data.changesetcount,
                 label='topic.list.changesetcount')

        if data.troubledcount:
            fm.plain(', ')
            fm.write('troubledcount', '%d troubled',
                     data.troubledcount,
                     label='topic.list.troubledcount')

        headcount = len(data.heads)
        if 1 < headcount:
            fm.plain(', ')
            fm.write('headcount', '%d heads',
                     headcount,
                     label='topic.list.headcount.multiple')

        if ui.verbose:
            # XXX we should include the data even when not verbose

            behindcount = data.behindcount
            if 0 < behindcount:
                fm.plain(', ')
                fm.write('behindcount', '%d behind',
                         behindcount,
                         label='topic.list.behindcount')
            elif -1 == behindcount:
                fm.plain(', ')
                fm.write('behinderror', '%s',
                         _('ambiguous destination: %s') % data.behinderror,
                         label='topic.list.behinderror')
        fm.plain(')\n')
    fm.end()

def _showlasttouched(repo, fm, opts):
    topics = repo.topics
    timedict = _getlasttouched(repo, topics)
    times = timedict.keys()
    times.sort()
    if topics:
        maxwidth = max(len(t) for t in topics)
        namemask = '%%-%is' % maxwidth
    activetopic = repo.currenttopic
    for timevalue in times:
        curtopics = sorted(timedict[timevalue][1])
        for topic, user in curtopics:
            fm.startitem()
            marker = ' '
            label = 'topic'
            active = (topic == activetopic)
            if active:
                marker = '*'
                label = 'topic.active'
            fm.plain(' %s ' % marker, label=label)
            fm.write('topic', namemask, topic, label=label)
            fm.data(active=active)
            fm.plain(' (')
            if timevalue == -1:
                timestr = 'empty and active'
            else:
                timestr = templatefilters.age(timedict[timevalue][0])
            fm.write('lasttouched', '%s', timestr, label='topic.list.time')
            if user:
                fm.write('usertouched', ' by %s', user, label='topic.list.user')
            fm.plain(')')
            fm.plain('\n')
    fm.end()

def _getlasttouched(repo, topics):
    """
    Calculates the last time a topic was used. Returns a dictionary of seconds
    passed from current time for a topic as keys and topic name as values.
    """
    topicstime = {}
    curtime = time.time()
    for t in topics:
        secspassed = -1
        user = None
        maxtime = (0, 0)
        trevs = repo.revs("topic(%s)", t)
        # Need to check for the time of all changesets in the topic, whether
        # they are obsolete of non-heads
        # XXX: can we just rely on the max rev number for this
        for revs in trevs:
            rt = repo[revs].date()
            if rt[0] >= maxtime[0]:
                # Can store the rev to gather more info
                # latesthead = revs
                maxtime = rt
                user = repo[revs].user()
            # looking on the markers also to get more information and accurate
            # last touch time.
            obsmarkers = compat.getmarkers(repo, [repo[revs].node()])
            for marker in obsmarkers:
                rt = marker.date()
                if rt[0] > maxtime[0]:
                    user = marker.metadata().get('user', user)
                    maxtime = rt

        # Making the username more better
        username = None
        if user:
            # user is of form "abc <abc@xyz.com>"
            username = user.split('<')[0]
            if not username:
                # user is of form "<abc@xyz.com>"
                username = user[1:-1]
            username = username.strip()

        topicuser = (t, username)

        if trevs:
            secspassed = (curtime - maxtime[0])
        try:
            topicstime[secspassed][1].append(topicuser)
        except KeyError:
            topicstime[secspassed] = (maxtime, [topicuser])

    return topicstime

def summaryhook(ui, repo):
    t = getattr(repo, 'currenttopic', '')
    if not t:
        return
    # i18n: column positioning for "hg summary"
    ui.write(_("topic:  %s\n") % ui.label(t, 'topic.active'))

_validmode = [
    'ignore',
    'warning',
    'enforce',
    'enforce-all',
    'random',
    'random-all',
]

def _configtopicmode(ui):
    """ Parse the config to get the topicmode
    """
    topicmode = ui.config('experimental', 'topic-mode')

    # Fallback to read enforce-topic
    if topicmode is None:
        enforcetopic = ui.configbool('experimental', 'enforce-topic')
        if enforcetopic:
            topicmode = "enforce"
    if topicmode not in _validmode:
        topicmode = _validmode[0]

    return topicmode

def commitwrap(orig, ui, repo, *args, **opts):
    with repo.wlock():
        topicmode = _configtopicmode(ui)
        ismergecommit = len(repo[None].parents()) == 2

        notopic = not repo.currenttopic
        mayabort = (topicmode == "enforce" and not ismergecommit)
        maywarn = (topicmode == "warning"
                   or (topicmode == "enforce" and ismergecommit))

        mayrandom = False
        if topicmode == "random":
            mayrandom = not ismergecommit
        elif topicmode == "random-all":
            mayrandom = True

        if topicmode == 'enforce-all':
            ismergecommit = False
            mayabort = True
            maywarn = False

        hint = _("see 'hg help -e topic.topic-mode' for details")
        if opts.get('topic'):
            t = opts['topic']
            with repo.vfs.open('topic', 'w') as f:
                f.write(t)
        elif opts.get('amend'):
            pass
        elif notopic and mayabort:
            msg = _("no active topic")
            raise error.Abort(msg, hint=hint)
        elif notopic and maywarn:
            ui.warn(_("warning: new draft commit without topic\n"))
            if not ui.quiet:
                ui.warn(("(%s)\n") % hint)
        elif notopic and mayrandom:
            with repo.vfs.open('topic', 'w') as f:
                f.write(randomname.randomtopicname(ui))
        return orig(ui, repo, *args, **opts)

def committextwrap(orig, repo, ctx, subs, extramsg):
    ret = orig(repo, ctx, subs, extramsg)
    t = repo.currenttopic
    if t:
        ret = ret.replace("\nHG: branch",
                          "\nHG: topic '%s'\nHG: branch" % t)
    return ret

def pushoutgoingwrap(orig, ui, repo, *args, **opts):
    if opts.get('topic'):
        topicrevs = repo.revs('topic(%s) - obsolete()', opts['topic'])
        opts.setdefault('rev', []).extend(topicrevs)
    return orig(ui, repo, *args, **opts)

def mergeupdatewrap(orig, repo, node, branchmerge, force, *args, **kwargs):
    matcher = kwargs.get('matcher')
    partial = not (matcher is None or matcher.always())
    wlock = repo.wlock()
    isrebase = False
    ist0 = False
    try:
        ret = orig(repo, node, branchmerge, force, *args, **kwargs)
        # The mergeupdatewrap function makes the destination's topic as the
        # current topic. This is right for merge but wrong for rebase. We check
        # if rebase is running and update the currenttopic to topic of new
        # rebased commit. We have explicitly stored in config if rebase is
        # running.
        ot = repo.currenttopic
        empty = stack.stack(repo, topic=ot).changesetcount == 0
        if repo.ui.hasconfig('experimental', 'topicrebase'):
            isrebase = True
        if repo.ui.configbool('_internal', 'keep-topic'):
            ist0 = True
        if ((not partial and not branchmerge) or isrebase) and not ist0:
            t = ''
            pctx = repo[node]
            if pctx.phase() > phases.public:
                t = pctx.topic()
            with repo.vfs.open('topic', 'w') as f:
                f.write(t)
            if t and t != ot:
                repo.ui.status(_("switching to topic %s\n") % t)
            if ot and not t and empty:
                repo.ui.status(_('clearing empty topic "%s"\n') % ot)
        elif ist0:
            repo.ui.status(_("preserving the current topic '%s'\n") % ot)
        return ret
    finally:
        wlock.release()

def checkt0(orig, ui, repo, node=None, rev=None, *args, **kwargs):

    thezeros = set(['t0', 'b0'])
    backup = repo.ui.backupconfig('_internal', 'keep-topic')
    try:
        if node in thezeros or rev in thezeros:
            repo.ui.setconfig('_internal', 'keep-topic', 'yes',
                              source='topic-extension')
        return orig(ui, repo, node, rev, *args, **kwargs)
    finally:
        repo.ui.restoreconfig(backup)

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
