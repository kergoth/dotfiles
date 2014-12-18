#! /usr/bin/env python3

import configparser
import os
import shutil
import subprocess
import urllib.parse

URL = os.environ['PERU_MODULE_URL']
REV = os.environ['PERU_MODULE_REV'] or 'master'
REUP = os.environ['PERU_MODULE_REUP'] or 'master'

# Because peru gives each plugin a unique cache dir based on its cacheable
# fields (in this case, url) we could clone directly into cache_root. However,
# because the git plugin needs to handle subrepos as well, it still has to
# separate things out by repo url.
CACHE_ROOT = os.environ['PERU_PLUGIN_CACHE']


def git(*args, git_dir=None, capture_output=False):
    # Avoid forgetting this arg.
    assert git_dir is None or os.path.isdir(git_dir)

    command = ['git']
    if git_dir:
        command.append('--git-dir={0}'.format(git_dir))
    command.extend(args)

    stdout = subprocess.PIPE if capture_output else None
    stderr = subprocess.STDOUT if capture_output else None
    process = subprocess.Popen(
        command,
        stdin=subprocess.DEVNULL,
        stdout=stdout,
        stderr=stderr,
        universal_newlines=True)
    output, _ = process.communicate()
    if process.returncode != 0:
        raise RuntimeError(
            'Command exited with error code {0}:\n$ {1}\n{2}'.format(
                process.returncode,
                ' '.join(command),
                output))

    return output


def has_clone(url):
    return os.path.exists(repo_cache_path(url))


def clone_if_needed(url, capture_output=False):
    repo_path = repo_cache_path(url)
    if not has_clone(url):
        try:
            git('clone', '--mirror', '--progress', url, repo_path,
                capture_output=capture_output)
        except:
            # Delete the whole thing if the clone failed to avoid confusing the
            # cache.
            shutil.rmtree(repo_path)
            raise
    return repo_path


def repo_cache_path(url):
    escaped = urllib.parse.quote(url, safe='')
    return os.path.join(CACHE_ROOT, escaped)


def clone_and_maybe_print(url):
    if not has_clone(url):
        print('git clone ' + url)
    return clone_if_needed(url)


def git_fetch(url, repo_path):
    print('git fetch ' + url)
    git('fetch', '--prune', git_dir=repo_path)


def already_has_rev(repo, rev):
    try:
        # Make sure the rev exists.
        git('cat-file', '-e', rev, git_dir=repo)
        # Get the hash for the rev.
        output = git('rev-parse', rev, git_dir=repo, capture_output=True)
    except:
        return False

    # Only return True for revs that are absolute hashes.
    # We could consider treating tags the way, but...
    # 1) Tags actually can change.
    # 2) It's not clear at a glance if something is a branch or a hash.
    # Keep it simple.
    return output.strip() == rev


def checkout_tree(url, rev, dest):
    repo_path = clone_and_maybe_print(url)
    if not already_has_rev(repo_path, rev):
        git_fetch(url, repo_path)
    # If we just use `git checkout rev -- .` here, we get an error when rev is
    # an empty commit.
    git('--work-tree=' + dest, 'read-tree', rev, git_dir=repo_path)
    git('--work-tree=' + dest, 'checkout-index', '--all', git_dir=repo_path)
    checkout_subrepos(repo_path, rev, dest)


def checkout_subrepos(repo_path, rev, work_tree):
    gitmodules = os.path.join(work_tree, '.gitmodules')
    if not os.path.exists(gitmodules):
        return

    parser = configparser.ConfigParser()
    parser.read(gitmodules)
    for section in parser.sections():
        sub_relative_path = parser[section]['path']
        sub_full_path = os.path.join(work_tree, sub_relative_path)
        sub_url = parser[section]['url']
        ls_tree = git('ls-tree', '-r', rev, sub_relative_path,
                      git_dir=repo_path, capture_output=True)
        sub_rev = ls_tree.split()[2]
        checkout_tree(sub_url, sub_rev, sub_full_path)


def plugin_fetch():
    checkout_tree(URL, REV, os.environ['PERU_FETCH_DEST'])


def plugin_reup():
    reup_output = os.environ['PERU_REUP_OUTPUT']
    repo_path = clone_if_needed(URL)
    git_fetch(URL, repo_path)
    output = git('rev-parse', REUP, git_dir=repo_path, capture_output=True)
    with open(reup_output, 'w') as out_file:
        print('rev:', output.strip(), file=out_file)

command = os.environ['PERU_PLUGIN_COMMAND']
if command == 'fetch':
    plugin_fetch()
elif command == 'reup':
    plugin_reup()
else:
    raise RuntimeError('Unknown command: ' + repr(command))
