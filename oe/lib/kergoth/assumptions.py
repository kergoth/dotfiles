from assume import have, assumed, simple_assumptions, assumptions
import os.path
import subprocess
try:
    run = subprocess.check_output
    CmdError = subprocess.CalledProcessError
except AttributeError:
    try:
        import bb.process
        from bb.process import CmdError
        def run(*args, **kwargs):
            return bb.process.run(*args, **kwargs)[0]
    except ImportError:
        from bb.process import CmdError
        from oe.process import run


def gnu_version(name, minversion):
    try:
        veroutput = run([name, '--version'])
    except (OSError, CmdError):
        return

    firstline = veroutput.splitlines()[0]
    strversion = firstline.split()[-1]

    version = [int(c) for c in strversion.split('.')]
    if version >= minversion:
        return '%s-native' % name


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
    'pigz',

    'bison',
    'flex',
    'gperf',
    'gzip',
    'gperf',

    **{
        'svn': 'subversion-native',
        'hg': 'mercurial-native',
        'makeinfo': 'texinfo-native',
        'eu-strip': 'elfutils-native',
    }
)

simple_assumptions(check=os.path.exists, **{
    '/usr/lib/libcurl.a': 'curl-native',
    '/usr/lib/libreadline.a': 'readline-native',
    '/usr/lib/libiberty.a': 'binutils-native',
})

assumptions['m4'] = lambda c: gnu_version(c, [1, 4, 6])
assumptions['git'] = lambda c: gnu_version(c, [1, 7, 5])
assumptions['tar'] = lambda c: gnu_version(c, [1, 24])
