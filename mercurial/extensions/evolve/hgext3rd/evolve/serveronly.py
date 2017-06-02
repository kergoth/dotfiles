'''enable experimental obsolescence feature of Mercurial

OBSOLESCENCE IS AN EXPERIMENTAL FEATURE MAKE SURE YOU UNDERSTOOD THE INVOLVED
CONCEPT BEFORE USING IT.

/!\ THIS EXTENSION IS INTENDED FOR SERVER SIDE ONLY USAGE /!\

For client side usages it is recommended to use the evolve extension for
improved user interface.'''

from __future__ import absolute_import

import sys
import os

try:
    from . import (
        compat,
        exthelper,
        metadata,
        obscache,
        obsexchange,
    )
except ValueError as exc:
    if str(exc) != 'Attempted relative import in non-package':
        raise
    # extension imported using direct path
    sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
    from evolve import (
        compat,
        exthelper,
        metadata,
        obscache,
        obsexchange,
    )

__version__ = metadata.__version__
testedwith = metadata.testedwith
minimumhgversion = metadata.minimumhgversion
buglink = metadata.buglink

eh = exthelper.exthelper()
eh.merge(compat.eh)
eh.merge(obscache.eh)
eh.merge(obsexchange.eh)
uisetup = eh.final_uisetup
extsetup = eh.final_extsetup
reposetup = eh.final_reposetup
cmdtable = eh.cmdtable

@eh.reposetup
def default2evolution(ui, repo):
    evolveopts = ui.configlist('experimental', 'evolution')
    if not evolveopts:
        evolveopts = 'all'
        ui.setconfig('experimental', 'evolution', evolveopts)
