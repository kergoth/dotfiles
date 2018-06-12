#!/usr/bin/env python

'''
Description
===========

Takes LS_COLORS environment variable, converts it to a format suitable for
BSD's LSCOLOR variable, and prints that to stdout.

Formats
=======

BSD
---

In BSD, LSCOLORS is a string made up of color designator pairs, where the Nth
color designator pair configures the Nth filetype in the FILE_TYPE_LABELS
variable below. The actual pairs are of the form "<f><b>", where <f> and <b>
are letters in [a-h] representing <f>oreground and <b>ackground colors. A
foreground color can be made bold by capitalizing its letter. Either <f> or <b>
can be set to 'x' to use the default color. See BSD ``man ls`` for more
details.

GNU
---

This program uses a simplified version of GNU's syntax, since BSD only uses a
subset of GNU's available features.

In GNU, LS_COLORS is a list delimited by ':'. Each element in the list is a
key-value pair of the form '<label>=<sequence>':

    + <label>: Though there are other kinds of labels, including file
    extensions, this program ignores elements whose label is not supported by
    BSD (i.e., not in the FILE_TYPE_LABELS variable below).

    + <sequence>: A sequence of escape codes representing colors, delimited by
    ';'. As with <label>, GNU supports using many different types of codes
    (including non-ANSI codes; see ``man dir_colors`` for more details).
    However, only a small subset are used by BSD LSCOLORS (and therefore this
    program; see the ANSI_*_TO_BSD variables below). The rest are ignored.
'''

import os

# The values of this list are file type labels used by GNU ls (as seen in the
# ``ls.c`` source code) in the order used by BSD: The Nth color designator pair
# of BSD's LSCOLORS configures the Nth file type in this list.
FILE_TYPE_LABELS = [
    'di', # directory
    'ln', # symbolic link
    'so', # socket
    'pi', # pipe
    'ex', # executable
    'bd', # block device
    'cd', # character device
    'su', # executable, setuid set
    'sg', # executable, setgid set
    'tw', # directory writeable by others, sticky bit set
    'ow', # directory writeable by others, sticky bit unset
]

# <ANSI/GNU-foreground-code> : <BSD-color-designator> # <ANSI-color>
ANSI_FG_TO_BSD = {
    30 : 'a', # black
    31 : 'b', # red
    32 : 'c', # green
    33 : 'd', # brown
    34 : 'e', # blue
    35 : 'f', # magenta
    36 : 'g', # cyan
    37 : 'h', # light grey
}

# <ANSI/GNU-background-code> : <BSD-color-designator> # <ANSI-color>
ANSI_BG_TO_BSD = {
    40 : 'a', # black
    41 : 'b', # red
    42 : 'c', # green
    43 : 'd', # brown
    44 : 'e', # blue
    45 : 'f', # magenta
    46 : 'g', # cyan
    47 : 'h', # light grey
}

# Other ANSI SGR codes
ANSI_RESET = 0        # all attributes off
ANSI_BOLD = 1         # foreground bold
ANSI_NEGATIVE = 7     # bg and fg color swap
ANSI_BOLD_OFF = 21    # foreground bold off
ANSI_REGULAR = 22     # foreground bold off
ANSI_POSITIVE = 27    # bg and fg color swap off
ANSI_FG_EXTENDED = 38 # extended fg color options
ANSI_BG_EXTENDED = 48 # extended bg color options

# After an ANSI_*_EXTENDED code, there is a second code choosing what kind of
# parameters to expect, followed by those parameters. This is a map of the
# possible second codes to the number of parameters that they expect. (Though
# gnu2bsd will ignore these codes, it needs to know how many parameters to
# skip.)
ANSI_COLOR_TYPE_PARAMS = {
    # <type-code> : <number-of-parameters>
    5 : 1, # one parameter representing a 256-bit color
    2 : 3, # three parameters representing an RGB color
}

# Acceptable codes not used by BSD
ANSI_IGNORE = range(0, 65+1)

def gnu_to_bsd_color(ansi_sequence):
    '''
    Convert a ANSI/GNU LS_COLOR sequence into a BSD LSCOLOR color designator
    pair. Later ANSI codes override earlier ones, when applicable. Codes not
    supported will be ignored. Examples:

    >>> # blue (fg), bold (fg), blue (bg)
    >>> gnu_to_bsd_color('34;01;44')
    'Ee'
    >>> # blue (bg), magenta (fg)
    >>> gnu_to_bsd_color('34;35')
    'fx'
    >>> # blue (fg), green (bg), extended RGB (bg, ignored), green (fg)
    >>> gnu_to_bsd_color('34;42;48;2;255;255;255;32')
    'cc'
    >>> # blue (fg), green(bg), swap fg and bg
    >>> gnu_to_bsd_color('34;42;7')
    'ce'
    '''

    ansi_codes = [ANSI_RESET]
    if ansi_sequence:
        try:
            ansi_codes.extend(int(c) for c in ansi_sequence.split(';'))
        except ValueError:
            # use the defaults
            pass

    i = 0
    while i < len(ansi_codes):
        ansi_code = ansi_codes[i]
        if ansi_code == ANSI_RESET:
            bold, swap = False, False
            bsd_bg, bsd_fg = 'x', 'x'
        elif ansi_code == ANSI_BOLD:
            bold = True
        elif ansi_code == ANSI_NEGATIVE:
            swap = True
        elif ansi_code in {ANSI_BOLD_OFF, ANSI_REGULAR}:
            bold = False
        elif ansi_code == ANSI_POSITIVE:
            swap = False
        elif ansi_code in ANSI_FG_TO_BSD:
            bsd_fg = ANSI_FG_TO_BSD[ansi_code]
        elif ansi_code in ANSI_BG_TO_BSD:
            bsd_bg = ANSI_BG_TO_BSD[ansi_code]
        elif ansi_code in {ANSI_FG_EXTENDED, ANSI_BG_EXTENDED}:
            # find out how many extra parameters we need to ignore
            try:
                i += 1
                ansi_color_type = ansi_codes[i]
                skip = ANSI_COLOR_TYPE_PARAMS[ansi_color_type]
                i += skip
            except (IndexError, KeyError):
                raise ValueError('Invalid extended color sequence')
        elif ansi_code in ANSI_IGNORE:
            pass
        else:
            raise ValueError('Invalid ANSI SGR code: {}'.format(ansi_code))
        i += 1

    if bold and bsd_fg != 'x':
        bsd_fg = bsd_fg.upper()
    if swap:
        bsd_fg, bsd_bg = bsd_bg, bsd_fg

    return bsd_fg + bsd_bg

def LS_COLORS_to_LSCOLORS(LS_COLORS):
    '''
    Take the value of the GNU LS_COLORS variable and return a corresponding
    value for the BSD LSCOLORS variable. Example:

    >>> LS_COLORS_to_LSCOLORS('rs=0:di=01;34:ln=01;36:mh=00:tw=40:*.txt=44')
    'ExGxxxxxxxxxxxxxxxxaxx'
    '''

    # Parse LS_COLORS into a more manageable dict, ignoring empty entries
    ls_colors = {}
    for item in filter(bool, LS_COLORS.split(':')):
        # Assume the label has no equals sign; split the first occurrence
        label, ansi_sequence = item.split('=', 1)
        ls_colors[label] = ansi_sequence

    # Convert to BSD format
    lscolors = []
    for label in FILE_TYPE_LABELS:
        ansi_sequence = ls_colors.get(label, '')
        bsd_color_designators = gnu_to_bsd_color(ansi_sequence)
        lscolors.append(bsd_color_designators)

    LSCOLORS = ''.join(lscolors)
    return LSCOLORS

def main():
    LS_COLORS = os.environ.get('LS_COLORS')
    LSCOLORS = LS_COLORS_to_LSCOLORS(LS_COLORS)
    print(LSCOLORS)

if __name__ == '__main__':
    main()

