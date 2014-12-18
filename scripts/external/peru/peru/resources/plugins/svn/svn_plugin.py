#! /usr/bin/env python3

import os
import subprocess
import sys


def svn(*args, svn_dir=None, capture_output=False):
    # Avoid forgetting this arg.
    assert svn_dir is None or os.path.isdir(svn_dir)

    command = ['svn', '--non-interactive']
    command.extend(args)

    stdout = subprocess.PIPE if capture_output else None
    stderr = subprocess.STDOUT if capture_output else None
    process = subprocess.Popen(
        command, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
        cwd=svn_dir, universal_newlines=True)
    output, _ = process.communicate()
    if process.returncode != 0:
        raise RuntimeError(
            'Command exited with error code {0}:\n$ {1}\n{2}'.format(
                process.returncode,
                ' '.join(command),
                output))

    return output


def remote_head_rev(url):
    print('svn info', url)
    info = svn('info', url, capture_output=True).split('\n')
    for item in info:
        if item.startswith('Revision: '):
            return item.split()[1]

    print('svn revision info not found', file=sys.stderr)
    sys.exit(1)


def plugin_fetch():
    # Just fetch the target revision and strip the metadata.
    # Plugin-level caching for Subversion is futile.
    svn(
        'export',
        '--force',
        '--revision',
        os.environ['PERU_MODULE_REV'] or 'HEAD',
        os.environ['PERU_MODULE_URL'],
        os.environ['PERU_FETCH_DEST'])


def plugin_reup():
    url = os.environ['PERU_MODULE_URL']
    rev = remote_head_rev(url)
    output_file = os.environ['PERU_REUP_OUTPUT']
    with open(output_file, 'w') as f:
        # Quote Subversion revisions to prevent integer intepretation.
        print('rev:', '"{}"'.format(rev), file=f)


command = os.environ['PERU_PLUGIN_COMMAND']
if command == 'fetch':
    plugin_fetch()
elif command == 'reup':
    plugin_reup()
else:
    raise RuntimeError('Unknown command: ' + repr(command))
