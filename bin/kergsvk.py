__all__ = [
    "Config",
    "SVKError",
    "SVKList",
    "runcmd",
]

import os

class Config(object):
    checkoutspath = os.path.join(os.getenv('HOME'), 'svkco')
    svk = 'svk'
    svn = 'svn'
    # mode = 'detached'
    mode = 'attached'
    standalones = True

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
