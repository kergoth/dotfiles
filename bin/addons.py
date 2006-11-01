# ex:ts=4:sw=4:sts=4:et
# -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*-

import re
rx=re.compile(u"([\u2e80-\uffff])", re.UNICODE)
def cjkwrap(text, width = 78, encoding="utf8"):
    return reduce(lambda line, word, width=width: '%s%s%s' %
               (line,
                [' ','\n', ''][(len(line)-line.rfind('\n')-1
                      + len(word.split('\n',1)[0] ) >= width) or
                     line[-1:] == '\0' and 2],
                word),
               rx.sub(r'\1\0 ', unicode(text,encoding)).split(' ')
           ).replace('\0', '').encode(encoding)

class Addon(dict):
    """
    A single World of Warcraft addon in the Addon set.
    """

    def __init__(self, tocpath):
        import os

        path = os.path.abspath(os.path.dirname(tocpath))
        toc = os.path.basename(tocpath)

        self.fullpath = path
        self.path = os.path.basename(path)

        if not os.path.isdir(self.fullpath):
            return

        if not os.access(self.fullpath, os.R_OK):
            return

        if not os.access(tocpath, os.R_OK):
            return

        self.name = toc[:-4]
        self.lines = []
        self.order = []

        f = file(tocpath, 'rU')
        lines = f.readlines()

        for l in lines:
            l = l.strip()
            if not l.startswith('##'):
                self.lines.append(l)
                continue

            l = l[2:]
            fields = l.split(':')
            if len(fields) != 0:
                key = fields[0].strip()
                value = ':'.join(fields[1:]).strip()
                import re
                #self[key] = re.sub('\|r', '', re.sub('\|c[0-9a-fA-F]{8}', '', value))
                self[key] = value
                self.order.append(key)
            else:
                self.lines.insert(0, '##%s' % l)

        self.newlines = f.newlines

        import types
        if type(self.newlines) != types.StringType:
            self.newlines = '\n'

        desc = self.get("Description")
        if not desc:
            desc = self.get("Notes")
            if not desc:
                desc = ""
        self.desc = desc

    def write(self, path):
        f = file(path, "w")
        nl = self.newlines

        for key in self.order:
            f.write('## %s: %s%s' % (key, self[key], nl))

        for line in self.lines:
            f.write('%s%s' % (line, nl))

        f.close()

    def isvalid(self):
        try:
            self.__getattribute__('name')
            return True
        except AttributeError:
            return False

    def __str__(self):
        return cjkwrap("%s: %s" % (self.name, self.desc))
