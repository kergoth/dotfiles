import os


assumptions = {}


def have(cmd):
    for subdir in os.environ.get('PATH', '').split(':'):
        if os.path.exists(os.path.join(subdir, cmd)):
            return True
    return False

def simple_assumptions(check, *cmds, **kwcmds):
    def check_assumption(cmd, provide):
        if check(cmd):
            return provide

    def new_check_assumption(provide):
        return lambda cmd: check_assumption(cmd, provide)

    native_check = lambda cmd: check_assumption(cmd, '%s-native' % cmd)
    for cmd in cmds:
        assumptions[cmd] = native_check

    for cmd, provide in kwcmds.iteritems():
        assumptions[cmd] = new_check_assumption(provide)

call = lambda x: x()
def assumed(func):
    assumptions[func] = call
    return func

def test_assumptions():
    for arg, testfunc in assumptions.iteritems():
        result = testfunc(arg)
        if result:
            yield result
