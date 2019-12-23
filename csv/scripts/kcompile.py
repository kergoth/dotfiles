#!/usr/bin/env python
"""Utility functions for compiling python functions from strings, and
for dealing with exceptions from them"""

import ast
import inspect
import sys
import traceback
from collections import namedtuple
try:
    from pygments import highlight
    from pygments.lexers import PythonLexer
    from pygments.formatters.terminal import TerminalFormatter as Formatter
except ImportError:
    pygments = False
else:
    pygments = True


class TracebackEntry(namedtuple('Traceback',
                           ('filename', 'lineno', 'function', 'args',
                            'code_context', 'index'))):
    def format(self, formatter=None):
        formatted = []
        formatted.append('  File "%s", line %d, in %s%s:\n' %
                         (self.filename, self.lineno, self.function,
                          self.args))

        for lineindex, line in enumerate(self.code_context):
            if formatter:
                line = formatter(line)

            if lineindex == self.index:
                formatted.append('    >%s' % line)
            else:
                formatted.append('     %s' % line)
        return formatted

    def __str__(self):
        return ''.join(self.format())


def extract_traceback(tb, context=1):
    frames = inspect.getinnerframes(tb, context)
    for frame, filename, lineno, function, code_context, index in frames:
        args = inspect.formatargvalues(*inspect.getargvalues(frame))
        yield TracebackEntry(filename, lineno, function, args, code_context, index)


def format_extracted(extracted, formatter=None):
    formatted = []
    for tracebackinfo in extracted:
        formatted.extend(tracebackinfo.format(formatter))
    return formatted


def format_exception(etype, value, tb, context=1, formatter=None):
    formatted = []
    formatted.append('Traceback (most recent call last):\n')

    frames = extract_traceback(tb, context)
    formatted.extend(format_extracted(frames, formatter))
    formatted.extend(traceback.format_exception_only(etype, value))
    return formatted


def _syntaxerror_offset(value, lineoffset):
    """Adjust the line number in a SyntaxError exception"""
    if lineoffset:
        msg, (efname, elineno, eoffset, badline) = value.args
        value.args = (msg, (efname, elineno + lineoffset, eoffset, badline))
        value.lineno = elineno + lineoffset

def compile_offset(source, filename, mode, flags=0, dont_inherit=False, optimize=-1, lineoffset=0):
    """Compile the python source and adjust its line numbers by lineoffset"""
    try:
        compiled = compile(source, filename, mode, flags | ast.PyCF_ONLY_AST, dont_inherit, optimize)
    except SyntaxError as exc:
        _syntaxerror_offset(exc, lineoffset)
        raise

    if lineoffset:
        ast.increment_lineno(compiled, lineoffset)

    return compile(compiled, filename, mode, flags, dont_inherit, optimize)

def compile_func(source, name, argspec='', filename='<string>', lineoffset=0,
                 env=None):
    """Compile the python source, wrap it in a function definition and
    compile it, and return the function object"""
    # Adjust for 'def' line
    lineoffset -= 1

    code = source.rstrip().replace('\t', '    ')
    lines = ('    ' + line for line in code.split('\n'))
    code = '\n'.join(lines)
    defined = 'def {name}({argspec}):\n{body}'.format(name=name,
                                                      argspec=argspec,
                                                      body=code)
    compiled = compile_offset(defined, filename, 'exec', lineoffset=lineoffset)

    if env is None:
        env = {}
    tmpenv = {}
    exec(compiled, env, tmpenv)
    return eval(name, env, tmpenv)


if __name__ == '__main__':
    filename = 'testfile'
    offset = 3
    context = 3

    code = ''.join(list(open(filename, 'r'))[offset:])
    try:
        function = compile_func(code.format('foo bar baz'), name='testfunc',
                                filename=filename, lineoffset=offset)
    except SyntaxError:
        traceback.print_exc(limit=0, file=sys.stderr)

    print('')

    function = compile_func(code.format(''), name='testfunc',
                            filename=filename, lineoffset=offset)
    try:
        function()
    except Exception:
        if pygments:
            lexer, formatter = PythonLexer(), Formatter()
            formatline = lambda line: highlight(line, lexer, formatter)
        else:
            formatline = None

        etype, value, tb = sys.exc_info()
        formatted = format_exception(etype, value, tb.tb_next, context=context,
                                     formatter=formatline)
        print(''.join(formatted))
