#!/usr/bin/env python
import os

class Config(object):
    checkoutspath = os.path.join(os.getenv('HOME'), 'svkco')
    svk = 'svk'
    mode = 'detached'
    # mode = 'attached'
    depot = '//'

import commands
class SVKError(Exception):
    def __init__(self, command, depot, exitcode, msg):
        (exitstatus, output) = commands.getstatusoutput('echo %s' % command)
        self.str = 'SVK command %s on depot %s failed with exit code %s:\n%s' % (output, depot, exitcode, msg)

    def __str__(self):
        return self.str

def runcmd(args):
    args = [ commands.mkarg(arg) for arg in args ]

    cmd = " ".join(args)

    (exitstatus, output) = commands.getstatusoutput(cmd)
    if exitstatus != 0:
        raise SVKError(cmd, Config.depot, exitstatus >> 8, output)

    return output

class Mirrors(list):
    def __init__(self, depot = None):
        self.bypath = dict()
        self.bysource = dict()
        self.depot = depot

        if not depot:
            depot = '//'
        args = [ Config.svk, 'mi', '-l', depot ]

        output = runcmd(args)

        import re
        for line in re.split('[\n\r]*', output):
            if not line.startswith(depot):
                continue

            (path, source) = line.split()
            self.bypath[path] = source
            self.bysource[source] = path
            self.append((path, source))


def checkout(path, localpath):
    def cocb(arg, dirname, fnames):
        args = [ Config.svk, 'propget', 'svn:externals', dirname ]
        dirext = runcmd(args)

        if dirext == '':
            return

        import re
        for line in re.split('[\n\r]*', dirext):
            if line == '':
                continue
            (dest, src) = line.split()
            arg[os.path.join(dirname, dest)] = src

    mi = Mirrors(Config.depot)

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
        for url in mi.bysource.keys():
            if upstream.startswith(url):
                mipath = mi.bysource[url]
                break

        if not mipath:
            raise Exception("Unable to checkout, as %s is not yet mirrored for depot %s." % (upstream, Config.depot))

        rest = upstream[len(url)+1:]
        extsvkpath = os.path.join(mipath, rest)
        extcopath = os.path.join(Config.checkoutspath, rest.replace('/','_'))

        if os.path.exists(extcopath):
            print(runcmd([Config.svk, 'up', extcopath]))
        else:
            print(runcmd([Config.svk, 'co', extsvkpath, extcopath]))

        if Config.mode == 'detached':
            runcmd(['cp', '-av', extcopath, ext])
        else:
            runcmd(['ln', '-sf', extcopath, ext])

import sys
try:
    copath = os.path.join(os.path.abspath(os.curdir), os.path.basename(sys.argv[1]))
    runcmd(['rm', '-rf', copath])
    checkout(sys.argv[1], copath)
except SVKError:
    import sys
    sys.__stderr__.write(str(sys.exc_value))
