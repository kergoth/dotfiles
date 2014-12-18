#! /usr/bin/env python3

import os
import shutil
import subprocess
import textwrap

CACHE_PATH = os.environ['PERU_PLUGIN_CACHE']
URL = os.environ['PERU_MODULE_URL']
REV = os.environ['PERU_MODULE_REV'] or 'default'
REUP = os.environ['PERU_MODULE_REUP'] or 'default'


def hg(*args, hg_dir=None, capture_output=False):
    # Avoid forgetting this arg.
    assert hg_dir is None or os.path.isdir(hg_dir)

    command = ['hg']
    if hg_dir:
        command.append('--repository')
        command.append(hg_dir)
    command.extend(args)

    stdout = subprocess.PIPE if capture_output else None
    stderr = subprocess.STDOUT if capture_output else None
    process = subprocess.Popen(command, stdin=subprocess.DEVNULL,
                               stdout=stdout, stderr=stderr,
                               universal_newlines=True)
    output, _ = process.communicate()
    if process.returncode != 0:
        raise RuntimeError(
            'Command exited with error code {0}:\n$ {1}\n{2}'.format(
                process.returncode,
                ' '.join(command),
                output))

    return output


def clone_if_needed(url, verbose=False):
    if not os.path.exists(os.path.join(CACHE_PATH, '.hg')):
        try:
            if verbose:
                print('hg clone', url)
            hg('clone', '--noupdate', url, CACHE_PATH)
        except:
            # Delete the whole thing if the clone failed to avoid confusing the
            # cache.
            shutil.rmtree(CACHE_PATH)
            raise
        configure(CACHE_PATH)


def configure(repo_path):
    # Set configs needed for cached repos.
    hgrc_path = os.path.join(repo_path, '.hg', 'hgrc')
    with open(hgrc_path, 'a') as f:
        f.write(textwrap.dedent('''\
            [ui]
            # prevent 'hg archive' from creating '.hg_archival.txt' files.
            archivemeta = false
            '''))


def hg_pull(url, repo_path):
    print('hg pull', url)
    hg('pull', hg_dir=repo_path)


def already_has_rev(repo, rev):
    try:
        output = hg('identify', '--debug', '--rev', rev, hg_dir=repo,
                    capture_output=True)
    except:
        return False

    # Only return True for revs that are absolute hashes.
    # We could consider treating tags the way, but...
    # 1) Tags actually can change.
    # 2) It's not clear at a glance whether something is a branch or a hash.
    # Keep it simple.
    return output.split()[0] == rev


def plugin_fetch():
    dest = os.environ['PERU_FETCH_DEST']
    clone_if_needed(URL, verbose=True)
    if not already_has_rev(CACHE_PATH, REV):
        hg_pull(URL, CACHE_PATH)
    # TODO: Should this handle subrepos?
    hg('archive', '--type', 'files', '--rev', REV, dest, hg_dir=CACHE_PATH)


def plugin_reup():
    reup_output = os.environ['PERU_REUP_OUTPUT']

    clone_if_needed(URL, CACHE_PATH)
    hg_pull(URL, CACHE_PATH)
    output = hg('identify', '--debug', '--rev', REUP, hg_dir=CACHE_PATH,
                capture_output=True)

    with open(reup_output, 'w') as output_file:
        print('rev:', output.split()[0], file=output_file)


command = os.environ['PERU_PLUGIN_COMMAND']
if command == 'fetch':
    plugin_fetch()
elif command == 'reup':
    plugin_reup()
else:
    raise RuntimeError('Unknown command: ' + repr(command))
