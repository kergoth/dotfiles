import os
import subprocess
import oe.terminal

class ScreenIfSsh(object):
    """If DISPLAY is unset, or we're running over ssh, use screen"""
    priority = 5
    returncode = -1
    name = 'screenifssh'

    def __init__(self, sh_cmd, title=None, env=None):
        if not os.getenv('DISPLAY') or os.getenv('SSH_AUTH_SOCK'):
            self.terminal = oe.terminal.Screen(sh_cmd, title, env)
        else:
            raise oe.terminal.UnsupportedTerminal(self.name)

    def communicate(self, input=None):
        ret = self.terminal.communicate(input)
        self.returncode = self.terminal.returncode
        return ret

# Oddly, using the metaclass isn't behaving right now..
oe.terminal.Registry.registry[ScreenIfSsh.name] = ScreenIfSsh
