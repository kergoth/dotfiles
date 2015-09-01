# hgshelve.py
#
# Copyright 2007 Bryan O'Sullivan <bos@serpentine.com>
# Copyright 2007 TK Soh <teekaysoh@gmailcom>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

'''interactive change selection to set aside that may be restored later'''

from mercurial.i18n import _
from mercurial import cmdutil, commands, hg, patch, scmutil
from mercurial import util, fancyopts, extensions
import copy, cStringIO, errno, os, re, shutil, tempfile, sys

lines_re = re.compile(r'@@ -(\d+),(\d+) \+(\d+),(\d+) @@\s*(.*)')

def scanpatch(fp):
    """like patch.iterhunks, but yield different events

    - ('file',    [header_lines + fromfile + tofile])
    - ('context', [context_lines])
    - ('hunk',    [hunk_lines])
    - ('range',   (-start,len, +start,len, proc))
    """
    lr = patch.linereader(fp)

    def scanwhile(first, p):
        """scan lr while predicate holds"""
        lines = [first]
        while True:
            line = lr.readline()
            if not line:
                break
            if p(line):
                lines.append(line)
            else:
                lr.push(line)
                break
        return lines

    while True:
        line = lr.readline()
        if not line:
            break
        if line.startswith('diff --git a/') or line.startswith('diff -r '):
            def notheader(line):
                s = line.split(None, 1)
                return not s or s[0] not in ('---', 'diff')
            header = scanwhile(line, notheader)
            fromfile = lr.readline()
            if fromfile.startswith('---'):
                tofile = lr.readline()
                header += [fromfile, tofile]
            else:
                lr.push(fromfile)
            yield 'file', header
        elif line[0] == ' ':
            yield 'context', scanwhile(line, lambda l: l[0] in ' \\')
        elif line[0] in '-+':
            yield 'hunk', scanwhile(line, lambda l: l[0] in '-+\\')
        else:
            m = lines_re.match(line)
            if m:
                yield 'range', m.groups()
            else:
                yield 'other', line

class header(object):
    """patch header

    XXX shouldn't we move this to mercurial/patch.py ?
    """
    diffgit_re = re.compile('diff --git a/(.*) b/(.*)$')
    diff_re = re.compile('diff -r .* (.*)$')
    allhunks_re = re.compile('(?:index|new file|deleted file) ')
    pretty_re = re.compile('(?:new file|deleted file) ')
    special_re = re.compile('(?:index|new|deleted|copy|rename) ')

    def __init__(self, header):
        self.header = header
        self.hunks = []

    def binary(self):
        return any(h.startswith('index ') for h in self.header)

    def pretty(self, fp):
        for h in self.header:
            if h.startswith('index '):
                fp.write(_('this modifies a binary file (all or nothing)\n'))
                break
            if self.pretty_re.match(h):
                fp.write(h)
                if self.binary():
                    fp.write(_('this is a binary file\n'))
                break
            if h.startswith('---'):
                fp.write(_('%d hunks, %d lines changed\n') %
                         (len(self.hunks),
                          sum([max(h.added, h.removed) for h in self.hunks])))
                break
            fp.write(h)

    def write(self, fp):
        fp.write(''.join(self.header))

    def allhunks(self):
        return any(self.allhunks_re.match(h) for h in self.header)

    def files(self):
        match = self.diffgit_re.match(self.header[0])
        if match:
            fromfile, tofile = match.groups()
            if fromfile == tofile:
                return [fromfile]
            return [fromfile, tofile]
        else:
            return self.diff_re.match(self.header[0]).groups()

    def filename(self):
        return self.files()[-1]

    def __repr__(self):
        return '<header %s>' % (' '.join(map(repr, self.files())))

    def special(self):
        return any(self.special_re.match(h) for h in self.header)

def countchanges(hunk):
    """hunk -> (n+,n-)"""
    add = len([h for h in hunk if h[0] == '+'])
    rem = len([h for h in hunk if h[0] == '-'])
    return add, rem

class hunk(object):
    """patch hunk

    XXX shouldn't we merge this with patch.hunk ?
    """
    maxcontext = 3

    def __init__(self, header, fromline, toline, proc, before, hunk, after):
        def trimcontext(number, lines):
            delta = len(lines) - self.maxcontext
            if False and delta > 0:
                return number + delta, lines[:self.maxcontext]
            return number, lines

        self.header = header
        self.fromline, self.before = trimcontext(fromline, before)
        self.toline, self.after = trimcontext(toline, after)
        self.proc = proc
        self.hunk = hunk
        self.added, self.removed = countchanges(self.hunk)

    def __cmp__(self, rhs):
        # since the hunk().fromline needs to be adjusted when hunks are
        # removed/added, we can't take it into account when we cmp
        attrs = ['header', 'toline', 'proc', 'hunk', 'added', 'removed']
        for attr in attrs:
            selfattr = getattr(self, attr, None)
            rhsattr = getattr(rhs, attr, None)

            if selfattr is None or rhsattr is None:
                raise util.Abort(_('non-existant attribute %s') % attr)

            rv = cmp(selfattr, rhsattr)
            if rv != 0:
                return rv
        return rv

    def write(self, fp):
        delta = len(self.before) + len(self.after)
        if self.after and self.after[-1] == '\\ No newline at end of file\n':
            delta -= 1
        fromlen = delta + self.removed
        tolen = delta + self.added
        fp.write('@@ -%d,%d +%d,%d @@%s\n' %
                 (self.fromline, fromlen, self.toline, tolen,
                  self.proc and (' ' + self.proc)))
        fp.write(''.join(self.before + self.hunk + self.after))

    pretty = write

    def filename(self):
        return self.header.filename()

    def __repr__(self):
        return '<hunk %r@%d>' % (self.filename(), self.fromline)

def parsepatch(fp):
    """patch -> [] of headers -> [] of hunks """
    class parser(object):
        """patch parsing state machine"""
        def __init__(self):
            self.fromline = 0
            self.toline = 0
            self.proc = ''
            self.header = None
            self.context = []
            self.before = []
            self.hunk = []
            self.headers = []

        def addrange(self, limits):
            fromstart, fromend, tostart, toend, proc = limits
            self.fromline = int(fromstart)
            self.toline = int(tostart)
            self.proc = proc

        def addcontext(self, context):
            if self.hunk:
                h = hunk(self.header, self.fromline, self.toline, self.proc,
                         self.before, self.hunk, context)
                self.header.hunks.append(h)
                self.fromline += len(self.before) + h.removed
                self.toline += len(self.before) + h.added
                self.before = []
                self.hunk = []
                self.proc = ''
            self.context = context

        def addhunk(self, hunk):
            if self.context:
                self.before = self.context
                self.context = []
            self.hunk = hunk

        def newfile(self, hdr):
            self.addcontext([])
            h = header(hdr)
            self.headers.append(h)
            self.header = h

        def addother(self, line):
            pass # 'other' lines are ignored

        def finished(self):
            self.addcontext([])
            return self.headers

        transitions = {
            'file': {'context': addcontext,
                     'file': newfile,
                     'hunk': addhunk,
                     'range': addrange},
            'context': {'file': newfile,
                        'hunk': addhunk,
                        'range': addrange,
                        'other': addother},
            'hunk': {'context': addcontext,
                     'file': newfile,
                     'range': addrange},
            'range': {'context': addcontext,
                      'hunk': addhunk},
            'other': {'other': addother},
            }

    p = parser()

    state = 'context'
    for newstate, data in scanpatch(fp):
        try:
            p.transitions[state][newstate](p, data)
        except KeyError:
            raise patch.PatchError('unhandled transition: %s -> %s' %
                                   (state, newstate))
        state = newstate
    return p.finished()

def filterpatch(ui, headers, shouldprompt=True):
    """Interactively filter patch chunks into applied-only chunks"""

    def prompt(skipfile, skipall, query):
        """prompt query, and process base inputs

        - y/n for the rest of file
        - y/n for the rest
        - ? (help)
        - q (quit)

        Return True/False and possibly updated skipfile and skipall.
        """
        if skipall is not None:
            return skipall, skipfile, skipall
        if skipfile is not None:
            return skipfile, skipfile, skipall
        while True:
            resps = _('[Ynsfdaq?]'
                      '$$ &Yes, shelve this change'
                      '$$ &No, skip this change'
                      '$$ &Skip remaining changes to this file'
                      '$$ Shelve remaining changes to this &file'
                      '$$ &Done, skip remaining changes and files'
                      '$$ Shelve &all changes to all remaining files'
                      '$$ &Quit, shelving no changes'
                      '$$ &? (display help)')
            r = ui.promptchoice("%s %s" % (query, resps))
            ui.write("\n")
            if r == 7: # ?
                for c, t in ui.extractchoices(resps)[1]:
                    ui.write('%s - %s\n' % (c, t.lower()))
                continue
            elif r == 0: # yes
                ret = True
            elif r == 1: # no
                ret = False
            elif r == 2: # Skip
                ret = skipfile = False
            elif r == 3: # file (shelve remaining)
                ret = skipfile = True
            elif r == 4: # done, skip remaining
                ret = skipall = False
            elif r == 5: # all
                ret = skipall = True
            elif r == 6: # quit
                raise util.Abort(_('user quit'))
            return ret, skipfile, skipall

    seen = set()
    applied = {}        # 'filename' -> [] of chunks
    skipfile, skipall = None, None

    # If we're not to prompt (i.e. they specified the --all flag)
    # we pre-emptively set the 'all' flag
    if not shouldprompt:
        skipall = True

    pos, total = 1, sum(len(h.hunks) for h in headers)
    for h in headers:
        pos += len(h.hunks)
        skipfile = None
        fixoffset = 0
        hdr = ''.join(h.header)
        if hdr in seen:
            continue
        seen.add(hdr)
        if skipall is None:
            h.pretty(ui)
        msg = (_('examine changes to %s?') %
               _(' and ').join("'%s'" % f for f in h.files()))
        r, skipfile, skipall = prompt(skipfile, skipall, msg)
        if not r:
            continue
        applied[h.filename()] = [h]
        if h.allhunks():
            applied[h.filename()] += h.hunks
            continue
        for i, chunk in enumerate(h.hunks):
            if skipfile is None and skipall is None:
                chunk.pretty(ui)
            if total == 1:
                msg = _("shelve this change to '%s'?") % chunk.filename()
            else:
                idx = pos - len(h.hunks) + i
                msg = _("shelve change %d/%d to '%s'?") % (idx, total,
                                                           chunk.filename())
            r, skipfile, skipall = prompt(skipfile, skipall, msg)
            if r:
                if fixoffset:
                    chunk = copy.copy(chunk)
                    chunk.fromline += fixoffset
                applied[chunk.filename()].append(chunk)
            else:
                fixoffset += chunk.added - chunk.removed
    return sum([h for h in applied.itervalues()
               if h[0].special() or len(h) > 1], [])

def refilterpatch(allheaders, selected):
    """Return unshelved chunks of files to be shelved."""
    l = []
    fil = []
    for h in allheaders:
        if h not in selected:
            continue
        if len(l) > 1:
            fil += l
        l = [h]
        for c in h.hunks:
            if c not in selected:
                l.append(c)
    if len(l) > 1:
        fil += l
    return fil

def makebackup(ui, repo, dir, files):
    try:
        os.mkdir(dir)
    except OSError, err:
        if err.errno != errno.EEXIST:
            raise

    backups = {}
    for f in files:
        if os.path.isfile(repo.wjoin(f)):
            fd, tmpname = tempfile.mkstemp(prefix=f.replace('/', '_')+'.',
                                           dir=dir)
            os.close(fd)
            ui.debug('backup %r as %r\n' % (f, tmpname))
            util.copyfile(repo.wjoin(f), tmpname)
            shutil.copystat(repo.wjoin(f), tmpname)
            backups[f] = tmpname

    return backups

def getshelfpath(repo, name):
    if name:
        shelfpath = "shelves/" + name
    else:
        # Check if a shelf from an older version exists
        if os.path.isfile(repo.join('shelve')):
            shelfpath = 'shelve'
        else:
            shelfpath = "shelves/default"

    return shelfpath

def shelve(ui, repo, *pats, **opts):
    '''interactively select changes to set aside

    If a list of files is omitted, all changes reported by :hg:` status`
    will be candidates for shelving.

    You will be prompted for whether to shelve changes to each
    modified file, and for files with multiple changes, for each
    change to use.

    The shelve command works with the Color extension to display
    diffs in color.

    On each prompt, the following responses are possible::

      y - shelve this change
      n - skip this change

      s - skip remaining changes to this file
      f - shelve remaining changes to this file

      d - done, skip remaining changes and files
      a - shelve all changes to all remaining files
      q - quit, shelving no changes

      ? - display help
    '''

    if not ui.interactive() and not (opts['all'] or opts['list']):
        raise util.Abort(_('shelve can only be run interactively'))

    # List all the active shelves by name and return '
    if opts['list']:
        listshelves(ui, repo)
        return

    forced = opts['force'] or opts['append']

    # Shelf name and path
    shelfname = opts.get('name')
    shelfpath = getshelfpath(repo, shelfname)

    if os.path.exists(repo.join(shelfpath)) and not forced:
        raise util.Abort(_('shelve data already exists'))

    def shelvefunc(ui, repo, message, match, opts):
        parents = repo.dirstate.parents()
        changes = repo.status(match=match)[:3]
        modified, added, removed = changes
        diffopts = patch.diffopts(ui, opts={'git': True, 'nodates': True})
        chunks = patch.diff(repo, changes=changes, opts=diffopts)
        fp = cStringIO.StringIO(''.join(chunks))

        try:
            ac = parsepatch(fp)
        except patch.PatchError, err:
            raise util.Abort(_('error parsing patch: %s') % err)

        del fp

        # 1. filter patch, so we have intending-to apply subset of it
        chunks = filterpatch(ui, ac, not opts['all'])
        rc = refilterpatch(ac, chunks)

        # set of files to be processed
        contenders = set()
        for h in chunks:
            try:
                contenders.update(set(h.files()))
            except AttributeError:
                pass

        # exclude sources of copies that are otherwise untouched
        changed = modified + added + removed
        newfiles = set(f for f in changed if f in contenders)
        if not newfiles:
            ui.status(_('no changes to shelve\n'))
            return 0

        # 2. backup changed files, so we can restore them in case of error
        backupdir = repo.join('shelve-backups')
        try:
            backups = makebackup(ui, repo, backupdir, newfiles)

            # patch to shelve
            sp = cStringIO.StringIO()
            for c in chunks:
                c.write(sp)

            # patch to apply to shelved files
            fp = cStringIO.StringIO()
            for c in rc:
                # skip files not selected for shelving
                if c.filename() in newfiles:
                    c.write(fp)
            dopatch = fp.tell()
            fp.seek(0)

            try:
                # 3a. apply filtered patch to clean repo  (clean)
                opts['no_backup'] = True
                cmdutil.revert(ui, repo, repo['.'], parents,
                               *[repo.wjoin(f) for f in newfiles], **opts)
                for f in added:
                    if f in newfiles:
                        util.unlinkpath(repo.wjoin(f))

                # 3b. (apply)
                if dopatch:
                    try:
                        ui.debug('applying patch\n')
                        ui.debug(fp.getvalue())
                        patch.internalpatch(ui, repo, fp, 1, eolmode=None)
                    except patch.PatchError, err:
                        raise util.Abort(str(err))
                del fp

                # 4. We prepared working directory according to filtered
                #    patch. Now is the time to save the shelved changes!
                ui.debug("saving patch to shelve\n")
                if opts['append']:
                    sp.write(repo.opener(shelfpath).read())
                sp.seek(0)
                f = repo.opener(shelfpath, "w")
                f.write(sp.getvalue())
                del f, sp
            except:
                ui.warn("shelving failed: %s\n" % sys.exc_info()[1])
                try:
                    # re-schedule remove
                    matchremoved = scmutil.matchfiles(repo, removed)
                    cmdutil.forget(ui, repo, matchremoved, "", True)
                    for f in removed:
                        if f in newfiles and os.path.isfile(repo.wjoin(f)):
                            os.unlink(repo.wjoin(f))
                    # copy back backups
                    for realname, tmpname in backups.iteritems():
                        ui.debug('restoring %r to %r\n' % (tmpname, realname))
                        util.copyfile(tmpname, repo.wjoin(realname))
                        # Our calls to copystat() here and above are a
                        # hack to trick any editors that have f open that
                        # we haven't modified them.
                        #
                        # Also note that this racy as an editor could
                        # notice the file's mtime before we've finished
                        # writing it.
                        shutil.copystat(tmpname, repo.wjoin(realname))
                    # re-schedule add
                    matchadded = scmutil.matchfiles(repo, added)
                    cmdutil.add(ui, repo, matchadded, False, False, "", True)

                    ui.debug('removing shelve file\n')
                    if os.path.isfile(repo.join(shelfpath)):
                        os.unlink(repo.join(shelfpath))
                except OSError, err:
                    ui.warn("restoring backup failed: %s\n" % err)

            return 0
        finally:
            try:
                for realname, tmpname in backups.iteritems():
                    ui.debug('removing backup for %r : %r\n' % (realname, tmpname))
                    os.unlink(tmpname)
                os.rmdir(backupdir)
            except OSError, err:
                ui.warn("removing backup failed: %s\n" % err)
    fancyopts.fancyopts([], commands.commitopts, opts)

    # wrap ui.write so diff output can be labeled/colorized
    def wrapwrite(orig, *args, **kw):
        label = kw.pop('label', '')
        if label:
            label += ' '
        for chunk, l in patch.difflabel(lambda: args):
            orig(chunk, label=label + l)
    oldwrite = ui.write
    extensions.wrapfunction(ui, 'write', wrapwrite)
    try:
        return cmdutil.commit(ui, repo, shelvefunc, pats, opts)
    finally:
        ui.write = oldwrite

def listshelves(ui, repo):
    # Check for shelve file at old location first
    if os.path.isfile(repo.join('shelve')):
        ui.status('default\n')

    # Now go through all the files in the shelves folder and list them out
    dirname = repo.join('shelves')
    if os.path.isdir(dirname):
        for filename in sorted(os.listdir(repo.join('shelves'))):
            ui.status(filename + '\n')

def unshelve(ui, repo, **opts):
    '''restore shelved changes'''

    # Shelf name and path
    shelfname = opts.get('name')
    shelfpath = getshelfpath(repo, shelfname)

    # List all the active shelves by name and return '
    if opts['list']:
        listshelves(ui, repo)
        return

    try:
        patch_diff = repo.opener(shelfpath).read()
        fp = cStringIO.StringIO(patch_diff)
        if opts['inspect']:
            # wrap ui.write so diff output can be labeled/colorized
            def wrapwrite(orig, *args, **kw):
                label = kw.pop('label', '')
                if label:
                    label += ' '
                for chunk, l in patch.difflabel(lambda: args):
                    orig(chunk, label=label + l)
            oldwrite = ui.write
            extensions.wrapfunction(ui, 'write', wrapwrite)
            try:
                ui.status(fp.getvalue())
            finally:
                ui.write = oldwrite
        else:
            files = []
            ac = parsepatch(fp)
            for chunk in ac:
                if isinstance(chunk, header):
                    files += chunk.files()
            backupdir = repo.join('shelve-backups')
            backups = makebackup(ui, repo, backupdir, set(files))

            ui.debug('applying shelved patch\n')
            patchdone = 0
            try:
                try:
                    fp.seek(0)
                    patch.internalpatch(ui, repo, fp, 1, eolmode=None)
                    patchdone = 1
                except:
                    if opts['force']:
                        patchdone = 1
                    else:
                        ui.status('restoring backup files\n')
                        for realname, tmpname in backups.iteritems():
                            ui.debug('restoring %r to %r\n' %
                                     (tmpname, realname))
                            util.copyfile(tmpname, repo.wjoin(realname))
            finally:
                try:
                    ui.debug('removing backup files\n')
                    shutil.rmtree(backupdir, True)
                except OSError:
                    pass

            if patchdone:
                ui.debug("removing shelved patches\n")
                os.unlink(repo.join(shelfpath))
                ui.status("unshelve completed\n")
    except IOError:
        ui.warn('nothing to unshelve\n')

cmdtable = {
    "shelve":
        (shelve,
         [('A', 'addremove', None,
           _('mark new/missing files as added/removed before shelving')),
          ('f', 'force', None, _('overwrite existing shelve data')),
          ('a', 'append', None, _('append to existing shelve data')),
          ('', 'all', None, _('shelve all changes')),
          ('n', 'name', '', _('shelve changes to specified shelf name')),
          ('l', 'list', None, _('list active shelves')),
         ] + commands.walkopts,
         _('hg shelve [OPTION]... [FILE]...')),
    "unshelve":
        (unshelve,
         [('i', 'inspect', None, _('inspect shelved changes only')),
          ('f', 'force', None,
           _('proceed even if patches do not unshelve cleanly')),
          ('n', 'name', '', _('unshelve changes from specified shelf name')),
          ('l', 'list', None, _('list active shelves')),
         ],
         _('hg unshelve [OPTION]...')),
}

commands.inferrepo += " shelve"
