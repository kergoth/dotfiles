#####################################################################
### Extension helper                                              ###
#####################################################################

from mercurial import (
    commands,
    extensions,
    registrar,
    revset,
    templatekw,
    util,
)

if util.safehasattr(registrar, 'command'):
    command = registrar.command
else: # compat with hg < 4.3
    from mercurial import cmdutil
    command = cmdutil.command

class exthelper(object):
    """Helper for modular extension setup

    A single helper should be instantiated for each extension. Helper
    methods are then used as decorators for various purpose.

    All decorators return the original function and may be chained.
    """

    def __init__(self):
        self._uicallables = []
        self._extcallables = []
        self._repocallables = []
        self._revsetsymbols = []
        self._templatekws = []
        self._commandwrappers = []
        self._extcommandwrappers = []
        self._functionwrappers = []
        self._duckpunchers = []
        self.cmdtable = {}
        self.command = command(self.cmdtable)

    def merge(self, other):
        self._uicallables.extend(other._uicallables)
        self._extcallables.extend(other._extcallables)
        self._repocallables.extend(other._repocallables)
        self._revsetsymbols.extend(other._revsetsymbols)
        self._templatekws.extend(other._templatekws)
        self._commandwrappers.extend(other._commandwrappers)
        self._extcommandwrappers.extend(other._extcommandwrappers)
        self._functionwrappers.extend(other._functionwrappers)
        self._duckpunchers.extend(other._duckpunchers)
        self.cmdtable.update(other.cmdtable)

    def final_uisetup(self, ui):
        """Method to be used as the extension uisetup

        The following operations belong here:

        - Changes to ui.__class__ . The ui object that will be used to run the
          command has not yet been created. Changes made here will affect ui
          objects created after this, and in particular the ui that will be
          passed to runcommand
        - Command wraps (extensions.wrapcommand)
        - Changes that need to be visible to other extensions: because
          initialization occurs in phases (all extensions run uisetup, then all
          run extsetup), a change made here will be visible to other extensions
          during extsetup
        - Monkeypatch or wrap function (extensions.wrapfunction) of dispatch
          module members
        - Setup of pre-* and post-* hooks
        - pushkey setup
        """
        for cont, funcname, func in self._duckpunchers:
            setattr(cont, funcname, func)
        for command, wrapper, opts in self._commandwrappers:
            entry = extensions.wrapcommand(commands.table, command, wrapper)
            if opts:
                for short, long, val, msg in opts:
                    entry[1].append((short, long, val, msg))
        for cont, funcname, wrapper in self._functionwrappers:
            extensions.wrapfunction(cont, funcname, wrapper)
        for c in self._uicallables:
            c(ui)

    def final_extsetup(self, ui):
        """Method to be used as a the extension extsetup

        The following operations belong here:

        - Changes depending on the status of other extensions. (if
          extensions.find('mq'))
        - Add a global option to all commands
        - Register revset functions
        """
        knownexts = {}
        for name, symbol in self._revsetsymbols:
            revset.symbols[name] = symbol
        for name, kw in self._templatekws:
            templatekw.keywords[name] = kw
        for ext, command, wrapper, opts in self._extcommandwrappers:
            if ext not in knownexts:
                try:
                    e = extensions.find(ext)
                except KeyError:
                    # Extension isn't enabled, so don't bother trying to wrap
                    # it.
                    continue
                knownexts[ext] = e.cmdtable
            entry = extensions.wrapcommand(knownexts[ext], command, wrapper)
            if opts:
                for short, long, val, msg in opts:
                    entry[1].append((short, long, val, msg))

        for c in self._extcallables:
            c(ui)

    def final_reposetup(self, ui, repo):
        """Method to be used as the extension reposetup

        The following operations belong here:

        - All hooks but pre-* and post-*
        - Modify configuration variables
        - Changes to repo.__class__, repo.dirstate.__class__
        """
        for c in self._repocallables:
            c(ui, repo)

    def uisetup(self, call):
        """Decorated function will be executed during uisetup

        example::

            @eh.uisetup
            def setupbabar(ui):
                print 'this is uisetup!'
        """
        self._uicallables.append(call)
        return call

    def extsetup(self, call):
        """Decorated function will be executed during extsetup

        example::

            @eh.extsetup
            def setupcelestine(ui):
                print 'this is extsetup!'
        """
        self._extcallables.append(call)
        return call

    def reposetup(self, call):
        """Decorated function will be executed during reposetup

        example::

            @eh.reposetup
            def setupzephir(ui, repo):
                print 'this is reposetup!'
        """
        self._repocallables.append(call)
        return call

    def revset(self, symbolname):
        """Decorated function is a revset symbol

        The name of the symbol must be given as the decorator argument.
        The symbol is added during `extsetup`.

        example::

            @eh.revset('hidden')
            def revsetbabar(repo, subset, x):
                args = revset.getargs(x, 0, 0, 'babar accept no argument')
                return [r for r in subset if 'babar' in repo[r].description()]
        """
        def dec(symbol):
            self._revsetsymbols.append((symbolname, symbol))
            return symbol
        return dec

    def templatekw(self, keywordname):
        """Decorated function is a template keyword

        The name of the keyword must be given as the decorator argument.
        The symbol is added during `extsetup`.

        example::

            @eh.templatekw('babar')
            def kwbabar(ctx):
                return 'babar'
        """
        def dec(keyword):
            self._templatekws.append((keywordname, keyword))
            return keyword
        return dec

    def wrapcommand(self, command, extension=None, opts=[]):
        """Decorated function is a command wrapper

        The name of the command must be given as the decorator argument.
        The wrapping is installed during `uisetup`.

        If the second option `extension` argument is provided, the wrapping
        will be applied in the extension commandtable. This argument must be a
        string that will be searched using `extension.find` if not found and
        Abort error is raised. If the wrapping applies to an extension, it is
        installed during `extsetup`.

        example::

            @eh.wrapcommand('summary')
            def wrapsummary(orig, ui, repo, *args, **kwargs):
                ui.note('Barry!')
                return orig(ui, repo, *args, **kwargs)

        The `opts` argument allows specifying additional arguments for the
        command.

        """
        def dec(wrapper):
            if extension is None:
                self._commandwrappers.append((command, wrapper, opts))
            else:
                self._extcommandwrappers.append((extension, command, wrapper,
                                                 opts))
            return wrapper
        return dec

    def wrapfunction(self, container, funcname):
        """Decorated function is a function wrapper

        This function takes two arguments, the container and the name of the
        function to wrap. The wrapping is performed during `uisetup`.
        (there is no extension support)

        example::

            @eh.function(discovery, 'checkheads')
            def wrapfunction(orig, *args, **kwargs):
                ui.note('His head smashed in and his heart cut out')
                return orig(*args, **kwargs)
        """
        def dec(wrapper):
            self._functionwrappers.append((container, funcname, wrapper))
            return wrapper
        return dec

    def addattr(self, container, funcname):
        """Decorated function is to be added to the container

        This function takes two arguments, the container and the name of the
        function to wrap. The wrapping is performed during `uisetup`.

        example::

            @eh.function(context.changectx, 'babar')
            def babar(ctx):
                return 'babar' in ctx.description
        """
        def dec(func):
            self._duckpunchers.append((container, funcname, func))
            return func
        return dec
