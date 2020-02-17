#!/usr/bin/python

# hardlink - Goes through a directory structure and creates hardlinks for
# files which are identical.
#
# Copyright (C) 2003 - 2010  John L. Villalovos, Hillsboro, Oregon
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc., 59
# Temple Place, Suite 330, Boston, MA  02111-1307, USA.
#
#
# ------------------------------------------------------------------------
# John Villalovos
# email: john@sodarock.com
# http://www.sodarock.com/
#
# Inspiration for this program came from the hardlink.c code. I liked what it
# did but did not like the code itself, to me it was very unmaintainable.  So I
# rewrote in C++ and then I rewrote it in python.  In reality this code is
# nothing like the original hardlink.c, since I do things quite differently.
# Even though this code is written in python the performance of the python
# version is much faster than the hardlink.c code, in my limited testing.  This
# is mainly due to use of different algorithms.
#
# Original inspirational hardlink.c code was written by:  Jakub Jelinek
# <jakub@redhat.com>
#
# ------------------------------------------------------------------------
#
# TODO:
#   *   Thinking it might make sense to walk the entire tree first and collect
#       up all the file information before starting to do comparisons.  Thought
#       here is we could find all the files which are hardlinked to each other
#       and then do a comparison.  If they are identical then hardlink
#       everything at once.

import os
import re
import stat
import sys
import time
import filecmp
import fnmatch

from optparse import OptionParser


# Hash functions
# Create a hash from a file's size and time values
def hash_size_time(size, time):
    return (size ^ time) & (MAX_HASHES - 1)


def hash_size(size):
    return (size) & (MAX_HASHES - 1)


def hash_value(size, time, notimestamp):
    if notimestamp:
        return hash_size(size)
    else:
        return hash_size_time(size, int(time))


# If two files have the same inode and are on the same device then they are
# already hardlinked.
def is_already_hardlinked(st1,     # first file's status
                          st2):    # second file's status
    result = (st1.st_ino == st2.st_ino and  # Inodes equal
              st1.st_dev == st2.st_dev)     # Devices equal
    return result


# Determine if a file is eligibile for hardlinking.  Files will only be
# considered for hardlinking if this function returns true.
def eligible_for_hardlink(st1,        # first file's status
                          st2,        # second file's status
                          options):

    result = (
        # Must meet the following
        # criteria:
        not is_already_hardlinked(st1, st2) and  # NOT already hard linked

        st1.st_size == st2.st_size and           # size is the same

        st1.st_size != 0 and                     # size is not zero

        (st1.st_mode == st2.st_mode or
         options.contentonly) and                # file mode is the same

        (st1.st_uid == st2.st_uid or             # owner user id is the same
         options.contentonly) and                # OR we are comparing content only

        (st1.st_gid == st2.st_gid or             # owner group id is the same
         options.contentonly) and                # OR we are comparing content only

        (st1.st_mtime == st2.st_mtime or         # modified time is the same
         options.notimestamp or                  # OR date hashing is off
         options.contentonly) and                # OR we are comparing content only

        st1.st_dev == st2.st_dev                 # device is the same
    )
    if None:
    # if not result:
        print("\n***\n%s" % (st1,))
        print("%s" % (st2,))
        print("Already hardlinked: %s" % (not is_already_hardlinked(st1, st2)))
        print("Modes: %s %s" % (st1.st_mode, st2.st_mode))
        print("UIDs: %s %s" % (st1.st_uid, st2.st_uid))
        print("GIDs: %s %s" % (st1.st_gid, st2.st_gid))
        print("SIZE: %s %s" % (st1.st_size, st2.st_size))
        print("MTIME: %s %s" % (st1.st_mtime, st2.st_mtime))
        print("Ignore date: %s" % options.notimestamp)
        print("Device: %s %s" % (st1.st_dev, st2.st_dev))
    return result


def are_file_contents_equal(filename1, filename2, options):
    """Determine if the contents of two files are equal"""
    if options.verbose:
        print("Comparing: %s" % filename1)
        print("     to  : %s" % filename2)
    gStats.did_comparison()
    return filecmp.cmp(filename1, filename2, shallow=False)


# Determines if two files should be hard linked together.
def are_files_hardlinkable(filestat1_pair, filestat2_pair, options):
    filename1,stat1 = filestat1_pair
    filename2,stat2 = filestat2_pair
    if options.samename and os.path.basename(filename1) != os.path.basename(filename2):
        result = False
    elif not eligible_for_hardlink(stat1, stat2, options):
        result = False
    else:
        result = are_file_contents_equal(filename1, filename2, options)
    return result


# Hardlink two files together
def hardlink_files(sourcefile, destfile, stat_info, options):
    # rename the destination file to save it
    temp_name = destfile + ".$$$___cleanit___$$$"
    try:
        if not options.dryrun:
            os.rename(destfile, temp_name)
    except OSError:
        error = sys.exc_info()[1]
        print("Failed to rename: %s to %s: %s" % (destfile, temp_name, error))
        result = False
    else:
        # Now link the sourcefile to the destination file
        try:
            if not options.dryrun:
                os.link(sourcefile, destfile)
        except Exception:
            error = sys.exc_info()[1]
            print("Failed to hardlink: %s to %s: %s" % (sourcefile, destfile, error))
            # Try to recover
            try:
                os.rename(temp_name, destfile)
            except Exception:
                error = sys.exc_info()[1]
                print("BAD BAD - failed to rename back %s to %s: %s" % (temp_name, destfile, error))
            result = False
        else:
            # hard link succeeded
            # Delete the renamed version since we don't need it.
            if not options.dryrun:
                os.unlink(temp_name)
            # update our stats
            gStats.did_hardlink(sourcefile, destfile, stat_info)
            if options.verbose >= 1:
                if options.dryrun:
                    print("Did NOT link.  Dry run")
                print("Linked: %s" % sourcefile)
                print("     to: %s, saved %s" % (destfile, stat_info.st_size))
            result = True
    return result


def hardlink_identical_files(directories, filename, options):
    """
    The purpose of this function is to hardlink files together if the files are
    the same.  To be considered the same they must be equal in the following
    criteria:
          * file size
          * file contents
          * file mode (default)
          * owner user id (default)
          * owner group id (default)
          * modified time (default)

    Also, files will only be hardlinked if they are on the same device.  This
    is because hardlink does not allow you to hardlink across file systems.

    The basic idea on how this is done is as follows:

        Walk the directory tree building up a list of the files.

     For each file, generate a simple hash based on the size and modified time.

     For any other files which share this hash make sure that they are not
     identical to this file.  If they are identical then hardlink the files.

     Add the file info to the list of files that have the same hash value."""

    for exclude in options.excludes:
        if re.search(exclude, filename):
            return
    try:
        stat_info = os.stat(filename)
    except OSError:
        error = sys.exc_info()[1]
        print("Unable to get stat info for: %s: %s" % (filename, error))
        return

    # Is it a directory?
    if stat.S_ISDIR(stat_info.st_mode):
        # If it is a directory then add it to the list of directories.
        directories.append(filename)
    # Is it a regular file?
    elif stat.S_ISREG(stat_info.st_mode):
        if options.match:
            if not fnmatch.fnmatch(filename, options.match):
                return
        # Create the hash for the file.
        file_hash = hash_value(stat_info.st_size, stat_info.st_mtime,
                               options.notimestamp or options.contentonly)
        # Bump statistics count of regular files found.
        gStats.found_regular_file()
        if options.verbose >= 2:
            print("File: %s" % filename)
        work_file_info = (filename, stat_info)
        if file_hash in file_hashes:
            # We have file(s) that have the same hash as our current file.
            # Let's go through the list of files with the same hash and see if
            # we are already hardlinked to any of them.
            for (temp_filename, temp_stat_info) in file_hashes[file_hash]:
                if is_already_hardlinked(stat_info, temp_stat_info):
                    gStats.found_hardlink(temp_filename, filename,
                                          temp_stat_info)
                    break
            else:
                # We did not find this file as hardlinked to any other file
                # yet.  So now lets see if our file should be hardlinked to any
                # of the other files with the same hash.
                for (temp_filename, temp_stat_info) in file_hashes[file_hash]:
                    if are_files_hardlinkable(work_file_info, (temp_filename, temp_stat_info),
                                              options):
                        hardlink_files(temp_filename, filename, temp_stat_info, options)
                        break
                else:
                    # The file should NOT be hardlinked to any of the other
                    # files with the same hash.  So we will add it to the list
                    # of files.
                    file_hashes[file_hash].append(work_file_info)
        else:
            # There weren't any other files with the same hash value so we will
            # create a new entry and store our file.
            file_hashes[file_hash] = [work_file_info]


class Statistics:
    def __init__(self):
        self.dircount = 0                   # how many directories we find
        self.regularfiles = 0               # how many regular files we find
        self.comparisons = 0                # how many file content comparisons
        self.hardlinked_thisrun = 0         # hardlinks done this run
        self.hardlinked_previously = 0      # hardlinks that are already existing
        self.bytes_saved_thisrun = 0        # bytes saved by hardlinking this run
        self.bytes_saved_previously = 0     # bytes saved by previous hardlinks
        self.hardlinkstats = []             # list of files hardlinked this run
        self.starttime = time.time()        # track how long it takes
        self.previouslyhardlinked = {}      # list of files hardlinked previously

    def found_directory(self):
        self.dircount = self.dircount + 1

    def found_regular_file(self):
        self.regularfiles = self.regularfiles + 1

    def did_comparison(self):
        self.comparisons = self.comparisons + 1

    def found_hardlink(self, sourcefile, destfile, stat_info):
        filesize = stat_info.st_size
        self.hardlinked_previously = self.hardlinked_previously + 1
        self.bytes_saved_previously = self.bytes_saved_previously + filesize
        if not sourcefile in self.previouslyhardlinked:
            self.previouslyhardlinked[sourcefile] = (stat_info, [destfile])
        else:
            self.previouslyhardlinked[sourcefile][1].append(destfile)

    def did_hardlink(self, sourcefile, destfile, stat_info):
        filesize = stat_info.st_size
        self.hardlinked_thisrun = self.hardlinked_thisrun + 1
        self.bytes_saved_thisrun = self.bytes_saved_thisrun + filesize
        self.hardlinkstats.append((sourcefile, destfile))

    def print_stats(self, options):
        print("\n")
        print("Hard linking Statistics:")
        # Print out the stats for the files we hardlinked, if any
        if self.previouslyhardlinked and options.printprevious:
            keys = list(self.previouslyhardlinked.keys())
            keys.sort()  # Could use sorted() once we only support >= Python 2.4
            print("Files Previously Hardlinked:")
            for key in keys:
                stat_info, file_list = self.previouslyhardlinked[key]
                size = stat_info.st_size
                print("Hardlinked together: %s" % key)
                for filename in file_list:
                    print("                   : %s" % filename)
                print("Size per file: %s  Total saved: %s" % (size,
                                                              size * len(file_list)))
            print("")
        if self.hardlinkstats:
            if options.dryrun:
                print("Statistics reflect what would have happened if not a dry run")
            print("Files Hardlinked this run:")
            for (source, dest) in self.hardlinkstats:
                print("Hardlinked: %s" % source)
                print("        to: %s" % dest)
            print("")
        print("Directories           : %s" % self.dircount)
        print("Regular files         : %s" % self.regularfiles)
        print("Comparisons           : %s" % self.comparisons)
        print("Hardlinked this run   : %s" % self.hardlinked_thisrun)
        print("Total hardlinks       : %s" % (self.hardlinked_previously + self.hardlinked_thisrun))
        print("Bytes saved this run  : %s (%s)" % (self.bytes_saved_thisrun, humanize_number(self.bytes_saved_thisrun)))
        totalbytes = self.bytes_saved_thisrun + self.bytes_saved_previously
        print("Total bytes saved     : %s (%s)" % (totalbytes, humanize_number(totalbytes)))
        print("Total run time        : %s seconds" % (time.time() - self.starttime))


def humanize_number(number):
    if number > 1024 ** 3:
        return ("%.3f gibibytes" % (number / (1024.0 ** 3)))
    if number > 1024 ** 2:
        return ("%.3f mebibytes" % (number / (1024.0 ** 2)))
    if number > 1024:
        return ("%.3f KiB" % (number / 1024.0))
    return ("%d bytes" % number)


def printversion(self):
    print("hardlink.py, Version %s" % VERSION)
    print("Copyright (C) 2003 - 2010 John L. Villalovos.")
    print("email: software@sodarock.com")
    print("web: http://www.sodarock.com/")
    print("""
This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; version 2 of the License.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA  02111-1307, USA.
""")


def parse_command_line():
    usage = "usage: %prog [options] directory [ directory ... ]"
    version = "%prog: " + VERSION
    parser = OptionParser(usage=usage, version=version)
    parser.add_option("-f", "--filenames-equal", help="Filenames have to be identical",
                      action="store_true", dest="samename", default=False,)

    parser.add_option("-n", "--dry-run", help="Do NOT actually hardlink files",
                      action="store_true", dest="dryrun", default=False,)

    parser.add_option("-p", "--print-previous", help="Print previously created hardlinks",
                      action="store_true", dest="printprevious", default=False,)

    parser.add_option("-q", "--no-stats", help="Do not print the statistics",
                      action="store_false", dest="printstats", default=True,)

    parser.add_option("-t", "--timestamp-ignore",
                      help="File modification times do NOT have to be identical",
                      action="store_true", dest="notimestamp", default=False,)

    parser.add_option("-c", "--content-only",
                      help="Only file contents have to match",
                      action="store_true", dest="contentonly", default=False,)

    parser.add_option("-v", "--verbose",
                      help="Verbosity level (default: %default)", metavar="LEVEL",
                      action="store", dest="verbose", type="int", default=1,)

    parser.add_option("-x", "--exclude", metavar="REGEX",
                      help="Regular expression used to exclude files/dirs (may specify multiple times)",
                      action="append", dest="excludes", default=[],)

    parser.add_option("-m", "--match",
        help="Shell pattern used to match files", metavar="PATTERN",
        action="store", dest="match", default=None,)

    (options, args) = parser.parse_args()
    if not args:
        parser.print_help()
        print("")
        print("Error: Must supply one or more directories")
        sys.exit(1)
    args = [os.path.abspath(os.path.expanduser(dirname)) for dirname in args]
    for dirname in args:
        if not os.path.isdir(dirname):
            parser.print_help()
            print("")
            print("Error: %s is NOT a directory" % dirname)
            sys.exit(1)
    return options, args


# Start of global declarations
debug1 = None

MAX_HASHES = 128 * 1024

gStats = None

file_hashes = None

VERSION = "0.05 - 2010-01-07 (07-Jan-2010)"


def main():
    global gStats, file_hashes

    gStats = Statistics()
    file_hashes = {}

    # Parse our argument list and get our list of directories
    options, directories = parse_command_line()
    # Compile up our regexes ahead of time
    MIRROR_PL_REGEX = re.compile(r'^\.in\.')
    RSYNC_TEMP_REGEX = re.compile((r'^\..*\.\?{6,6}$'))
    # Now go through all the directories that have been added.
    # NOTE: hardlink_identical_files() will add more directories to the
    #       directories list as it finds them.
    while directories:
        # Get the last directory in the list
        directory = directories.pop() + '/'
        assert os.path.isdir(directory)

        gStats.found_directory()
        # Loop through all the files in the directory
        try:
            dir_entries = os.listdir(directory)
        except OSError:
            print("Error: Unable to do an os.listdir on: %s  Skipping..." % directory)
            continue
        for entry in dir_entries:
            pathname = os.path.normpath(os.path.join(directory, entry))
            # Look at files/dirs beginning with "."
            if entry[0] == ".":
                # Ignore any mirror.pl files.  These are the files that
                # start with ".in."
                if MIRROR_PL_REGEX.match(entry):
                    continue
                # Ignore any RSYNC files.  These are files that have the
                # format .FILENAME.??????
                if RSYNC_TEMP_REGEX.match(entry):
                    continue
            if os.path.islink(pathname):
                if debug1:
                    print("%s: is a symbolic link, ignoring" % pathname)
                continue
            if debug1 and os.path.isdir(pathname):
                print("%s is a directory!" % pathname)
            hardlink_identical_files(directories, pathname, options)
    if options.printstats:
        gStats.print_stats(options)

if __name__ == '__main__':
    main()
