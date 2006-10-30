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
    svk = 'svk'
    svn = 'svn'
    mode = 'detached'
    # mode = 'attached'
    standalones = True

def populatestandalones(path):
    import addons
    tocfiles = gettocfiles(path)
    print(tocfiles)
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

def findsvnpath(path):
    svnpath = None
    for key in dm.bykey.keys():
        if path.startswith(key):
            depot = key
            depotpath = dm.bykey[depot]
            svnpath = "file://%s" % os.path.join(depotpath, path[len(key):])

    return svnpath

def finddepotpath(path):
    info = runcmd([Config.svk, 'info', path])
    infodict = {}
    for line in info.splitlines():
        (key, value) = line.split(": ")
        infodict[key] = value
    return infodict['Depot Path']

def findcopypath(path):
    info = runcmd([Config.svk, 'info', path])
    infodict = {}
    for line in info.splitlines():
        (key, value) = line.split(": ")
        infodict[key] = value
    return '/'+infodict['Copied From'].split(', ')[0]

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

def handleexternals(path, handler, depotpath):
    extcache = []
    toclist = gettocfiles(path)
    for toc in toclist:
        tocdir = os.path.dirname(toc)
        extdestdir = os.path.dirname(tocdir)
        externals = getexternals(tocdir, tocdir.replace(path, depotpath))
        if not externals:
            continue

        for ext,upstream in externals:
            if upstream in extcache:
                continue

            mipath = None
            for url in mi.byvalue.keys():
                i = upstream.replace('svn.wowace.com', 'dev.wowace.com')
                i = i.replace('www.wowace.com/svn/ace', 'dev.wowace.com/wowace')
                i = i.replace('www.wowace.com/svn/wowace', 'dev.wowace.com/wowace')
                # print('i is "%s", url is "%s"' % (i, url))
                if i.startswith(url):
                    mipath = mi.byvalue[url]
                    rest = i[len(url)+1:]
                    if rest.endswith('/'):
                        rest = rest[:-1]
                    break

            if not mipath:
                raise Exception("Unable to checkout %s, as %s is not yet mirrored." % (path, upstream))

            extstandalone = None
            for st in standalones.keys():
                if rest.startswith(st):
                    extstandalone = standalones[st]

            if not extstandalone:
                print("Error: the standalone lib translation table does not have an")
                print("entry for '%s'." % rest)
                return

            if not extstandalone in extcache:
                rest = extstandalone
                extdest = os.path.join(extdestdir, os.path.basename(extstandalone))
                handler(os.path.join(mipath, rest), extdest)
                extcache.append(extstandalone)

print("Querying svk for mirror list")
mi = SVKList('mi')

print("Querying svk for depotmap")
dm = SVKList('depotmap')
