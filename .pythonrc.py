import sys

try:
    import readline
except ImportError:
    print("Module readline not available.")
else:
    import rlcompleter
    readline.parse_and_bind("tab: complete")

# Enable Pretty Printing for stdout
import pprint
def display_pretty(value):
    if value is not None:
        try:
            import __builtin__
            __builtin__._ = value
        except ImportError:
            __builtins__._ = value

        pprint.pprint(value)

sys.displayhook = display_pretty

#import os
#import sys
#from code import InteractiveConsole
#from tempfile import mkstemp
#
#EDITOR = os.environ.get('EDITOR', 'vim')
#EDIT_CMD = '\e'
#
#class EditableBufferInteractiveConsole(InteractiveConsole):
#    def __init__(self, *args, **kwargs):
#        self.last_buffer = [] # This holds the last executed statement
#        InteractiveConsole.__init__(self, *args, **kwargs)
#
#    def runsource(self, source, *args):
#        self.last_buffer = [ source.encode('latin-1') ]
#        return InteractiveConsole.runsource(self, source, *args)
#
#    def raw_input(self, *args):
#        line = InteractiveConsole.raw_input(self, *args)
#        if line == EDIT_CMD:
#            fd, tmpfl = mkstemp('.py')
#            os.write(fd, b'\n'.join(self.last_buffer))
#            os.close(fd)
#            os.system('%s %s' % (EDITOR, tmpfl))
#            line = open(tmpfl).read()
#            os.unlink(tmpfl)
#            tmpfl = ''
#            lines = line.split( '\n' )
#            for i in range(len(lines) - 1): self.push( lines[i] )
#            line = lines[-1]
#        return line
#
#c = EditableBufferInteractiveConsole(locals=locals())
#c.interact(banner='')
#
## Exit the Python shell on exiting the InteractiveConsole
#sys.exit()
