__all__ = [
    "Config",
    "SVKError",
    "SVKList",
    "runcmd",
    "standalones",
    "getexternals",
    "gettocfiles",
    "handleexternals",
    "finddepotpath",
    "findsvnpath",
    "findcopypath",
    "getlastmergepath",
    "mi",
    "dm",
    "populatestandalones",
    "System",
    "Commands",
]

from kergsvk.standalones import all as standalones
import os

class Config(object):
    checkoutspath = os.path.join(os.getenv('HOME'), 'svkco')
    addonsrcpath = '/wow/addons/mirror/trunk/%s'
    svk = 'svk'
    svn = 'svn'
    mode = 'detached'
    # mode = 'attached'
    # standalones = True
    standalones = False
    depot = '/wow'

def populatestandalones(path):
    import addons
    tocfiles = gettocfiles(path)
    for toc in tocfiles:
        a = addons.Addon(os.path.dirname(toc))
        for field in a.keys():
            if field.startswith('X-AceLibrary-'):
                lib = field.replace('X-AceLibrary-', '')
                standalones[lib] = lib

import commands
class SVKError(Exception):
    def __init__(self, command, exitcode, msg):
        (exitstatus, output) = commands.getstatusoutput('echo %s' % command)
        self.str = 'SVK command %s failed with exit code %s:\n%s' % (output, exitcode, msg)

    def __str__(self):
        return self.str

System = 1
Commands = 2

import time
def runcmd(args, mode = Commands):
    args = [ commands.mkarg(arg) for arg in args ]
    output = None
    cmd = " ".join(args)

    # t = time.time()
    # print("Executing '%s'." % cmd)
    if mode == Commands:
        (exitstatus, output) = commands.getstatusoutput(cmd)
        exitstatus >>= 8
    elif mode == System:
        exitstatus = os.system(cmd)

    if exitstatus != 0:
        raise SVKError(cmd, exitstatus, output)
    # print("'%s' executed in %s" % (cmd, time.time() - t))

    return output

class SVKList(list):
    def __init__(self, cmd):
        self.bykey = dict()
        self.byvalue = dict()

        args = [ Config.svk, cmd, '-l' ]

        output = runcmd(args)

        import re
        for line in re.split('[\n\r]*', output):
            linelist = line.split()
            if len(linelist) != 2:
                continue
            (key, value) = line.split()
            self.bykey[key] = value
            self.byvalue[value] = key
            self.append((key, value))

infos = {}

def getsvkinfo(path):
    if not infos.get(path):
        import types, re
        info = runcmd([Config.svk, 'info', path])
        infodict = {}
        for line in info.splitlines():
            m = re.match('([^:]+): (.*)$', line)
            if not m:
                continue
            key = m.group(1)
            value = m.group(2)

            val = infodict.get(key)
            if val:
                if type(val) == types.ListType:
                    val.append(value)
                else:
                    infodict[key] = [val, value]
            else:
                infodict[key] = value
        infos[path] = infodict

    return infos[path]

def findsvnpath(path):
    svnpath = None
    for key in dm.bykey.keys():
        if path.startswith(key):
            depot = key
            depotpath = dm.bykey[depot]
            svnpath = "file://%s" % os.path.join(depotpath, path[len(key):])

    return svnpath

def finddepotpath(path):
    return getsvkinfo(path).get('Depot Path')

def getlastpath(path, fields):
    import re, types

    l = list()
    for field in fields:
        e = getsvkinfo(path).get(field)
        if type(e) == types.StringType:
            l.append(e)
        else:
            if not l or len(l) == 0:
                continue
            l.extend(e)

    if len(l) == 1:
        m = re.match('(.*), Rev. *(\d*)', l[0])
        return Config.depot+m.group(1)

    if not l or len(l) == 0:
        return None

    revs = []
    d = {}
    for val in l:
        m = re.match('(.*), Rev\. *(\d*)', val)
        rev = int(m.group(2))
        path = m.group(1)

        d[rev] = path
        revs.append(rev)

    revs.sort()
    return Config.depot+d[revs.pop()]

def findcopypath(path):
    return getlastpath(path, 'Copied From')

def getlastmergepath(path):
    return getlastpath(path, 'Merged From')

def getexternals(path, depotpath):
    if not depotpath:
        depotpath = finddepotpath(path)
    svnpath = findsvnpath(depotpath)

    if not svnpath:
        return

    def findexternals(arg, dirname, fnames):
        import re
        args = [ Config.svn, 'propget', 'svn:externals', re.sub("^%s" % path, svnpath, dirname) ]
        try:
            dirext = runcmd(args)
        except SVKError:
            return

        if dirext == '':
            return

        import re
        for line in re.split('[\n\r]*', dirext):
            if line == '':
                continue
            (dest, src) = line.split()
            dest = dest.replace('\\', '/')
            arg.append((os.path.join(dirname, dest), src))

    externals = []
    os.path.walk(path, findexternals, externals)
    return externals

def gettocfiles(path):
    def findtoc(arg, dirname, fnames):
        for file in fnames:
            if file.endswith('.toc'):
                arg.append(os.path.join(dirname, file))

    toclist = []
    os.path.walk(path, findtoc, toclist)
    return toclist

def getextpaths(standalone, mipath, rest, standalonebasedir, embeddir):
    extstandalone = None
    if standalone:
        for st in standalones.keys():
            if rest.startswith(st):
                extstandalone = standalones[st]

        if not extstandalone:
            print("Error: the standalone lib translation table does not have an")
            print("entry for '%s'.  Not operating standalone." % rest)

    if extstandalone:
        src = os.path.join(mipath, extstandalone)
        extdest = os.path.join(standalonebasedir, os.path.basename(extstandalone))
    else:
        src = os.path.join(mipath, rest)
        extdest = embeddir

    return src, extdest

def splitupstream(path):
    rest = None
    mipath = None
    for url in mi.byvalue.keys():
        i = path.replace('www.wowace.com/svn/ace', 'dev.wowace.com/wowace')
        i = i.replace('www.wowace.com/svn/wowace', 'dev.wowace.com/wowace')
        l = [i, i.replace('svn.wowace.com', 'dev.wowace.com'), path.replace('https://', 'http://'), path.replace('http://', 'https://')]
        for j in l:
            if j.startswith(url):
                mipath = mi.byvalue[url]
                rest = j[len(url)+1:]
                if rest.endswith('/'):
                    rest = rest[:-1]
                break
    return mipath, rest

def handleexternals(path, handler, depotpath):
    extcache = []
    toclist = gettocfiles(path)
    for toc in toclist:
        tocdir = os.path.dirname(toc)
        standalonebasedir = os.path.dirname(tocdir)
        externals = getexternals(tocdir, tocdir.replace(path, depotpath))
        if not externals:
            continue

        print("Processing externals for %s..." % os.path.basename(tocdir))
        for embeddir,upstream in externals:
            if Config.standalones and upstream in extcache:
                continue

            mipath, rest = splitupstream(upstream)

            if not mipath:
                raise Exception("Unable to checkout %s, as %s is not yet mirrored." % (path, upstream))

            src, extdest = getextpaths(Config.standalones, mipath, rest, standalonebasedir, embeddir)
            src2, extdest2 = getextpaths(not Config.standalones, mipath, rest, standalonebasedir, embeddir)

            # print('src: %s' % src)
            # print('extdest: %s' % extdest)
            # print('src2: %s' % src2)
            # print('extdest2: %s' % extdest2)

            if not src in extcache or not Config.standalones:
                handler(src, extdest, src2, extdest2)
                extcache.append(src)

print("Querying svk for mirror list")
mi = SVKList('mi')

print("Querying svk for depotmap")
dm = SVKList('depotmap')
