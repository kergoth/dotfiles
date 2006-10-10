#!/usr/bin/env python
import os

class Config(object):
    checkoutspath = os.path.join(os.getenv('HOME'), 'svkco')
    svk = 'svk'
    svn = 'svn'
    mode = 'detached'
    # mode = 'attached'

import commands
class SVKError(Exception):
    def __init__(self, command, exitcode, msg):
        (exitstatus, output) = commands.getstatusoutput('echo %s' % command)
        self.str = 'SVK command %s failed with exit code %s:\n%s' % (output, exitcode, msg)

    def __str__(self):
        return self.str

import time
def runcmd(args):
    args = [ commands.mkarg(arg) for arg in args ]

    cmd = " ".join(args)

    # t = time.time()
    (exitstatus, output) = commands.getstatusoutput(cmd)
    if exitstatus != 0:
        raise SVKError(cmd, exitstatus >> 8, output)
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

def checkout(path, localpath):
    depot = None
    for key in dm.bykey.keys():
        if path.startswith(key):
            depot = key
            depotpath = dm.bykey[depot]
            svnpath = "file://%s" % os.path.join(depotpath, path[len(key):])

    if not depot:
        raise Exception("Unable to locate depot of %s" % path)

    def cocb(arg, dirname, fnames):
        import re
        args = [ Config.svn, 'propget', 'svn:externals', re.sub("^%s" % localpath, svnpath, dirname) ]
        dirext = runcmd(args)

        if dirext == '':
            return

        import re
        for line in re.split('[\n\r]*', dirext):
            if line == '':
                continue
            (dest, src) = line.split()
            arg[os.path.join(dirname, dest)] = src

    # svk co --export PATH LOCALPATH
    print(runcmd([ Config.svk, 'co', path, localpath ]))

    # traverse the new checkout with os.path.walk, checking for externals
    externals = dict()
    os.path.walk(localpath, cocb, externals)

    if Config.mode == 'detached':
        runcmd([ Config.svk, 'co', '--detach', localpath ])

    for ext in externals.keys():
        upstream = externals[ext]

        mipath = None
        for url in mi.byvalue.keys():
            i = upstream.replace('svn.wowace.com', 'dev.wowace.com')
            if i.startswith(url):
                mipath = mi.byvalue[url]
                break

        if not mipath:
            raise Exception("Unable to checkout %s, as %s is not yet mirrored." % (path, upstream))

        rest = upstream[len(url)+1:]
        if rest.endswith('/'):
            rest = rest[:-1]

        extcopath = os.path.join(Config.checkoutspath, rest.replace('/','_'))
        if not updated_cache.get(rest):
            extsvkpath = os.path.join(mipath, rest)

            if os.path.exists(extcopath):
                print(runcmd([Config.svk, 'up', extcopath]))
            else:
                print(runcmd([Config.svk, 'co', extsvkpath, extcopath]))

            updated_cache[rest] = True

        if not os.path.exists(os.path.dirname(ext)):
            os.makedirs(os.path.dirname(ext))

        if Config.mode == 'detached':
            runcmd(['cp', '-av', extcopath, ext])
        else:
            runcmd(['ln', '-sf', extcopath, ext])

updated_cache = {}

print("Querying svk for mirror list")
mi = SVKList('mi')

print("Querying svk for depotmap")
dm = SVKList('depotmap')

import sys
try:
    for n in range(1,len(sys.argv)):
        i = sys.argv[n]
        copath = os.path.join(os.path.abspath(os.curdir), os.path.basename(i))
        runcmd(['rm', '-rf', copath])
        print("Checking out %s" % i)
        checkout(i, copath)
except SVKError:
    import sys
    sys.__stderr__.write(str(sys.exc_value))
    sys.exit(1)
