from assume import have, assumed, simple_assumptions
import os.path
try:
    from bb.process import CmdError
    import bb.process as process
    import subprocess
    def run(*args, **kwargs):
        kwargs['stderr'] = subprocess.STDOUT
        return process.run(*args, **kwargs)[0]
except ImportError:
    from bb.process import CmdError
    import oe.process as process
    run = process.run

simple_assumptions(have,
    'fakeroot',
    # 'pseudo',
    'sed',
    'grep',
    'unzip',
    'patch',
    'diffstat',
    'cvs',
    'bzip2',
    'bc',
    'chrpath',
    'quilt',
    'git',

    'bison',
    'flex',
    'gperf',
    'gzip',
    'gperf',
    # 'gettext', - not safe atm, some recipes grab config.rpath directly from
    # the oe sysroot

    **{
        'svn': 'subversion-native',
        'makeinfo': 'texinfo-native',
        'eu-strip': 'elfutils-native',
    }
)

simple_assumptions(check=os.path.exists, **{
    # '/usr/lib/libz.a': 'zlib-native',
    '/usr/lib/libcurl.a': 'curl-native',
    '/usr/lib/libreadline.a': 'readline-native',
    # '/usr/lib/libsqlite3.a': 'sqlite3-native',
    '/usr/lib/libuuid.a': 'util-linux-native',
})

def gnu_version(name, minversion):
    try:
        veroutput = run([name, '--version'])
    except CmdError:
        return None

    firstline = veroutput.splitlines()[0]
    strversion = firstline.split()[-1]

    version = [int(c) for c in strversion.split('.')]
    if version >= minversion:
        return '%s-native' % name

@assumed
def m4():
    return gnu_version('m4', [1, 4, 6])

@assumed
def tar():
    return gnu_version('tar', [1, 20])
