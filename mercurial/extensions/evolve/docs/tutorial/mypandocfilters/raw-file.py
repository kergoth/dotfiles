#!/usr/bin/env python
"""
Insert a raw-file as HTML code block
"""

import panflute as pf


def action(elem, doc):
    if isinstance(elem, pf.CodeBlock) and 'raw-file' in elem.classes:
        filepath = elem.text

        with open(filepath, 'r') as fd:
            content = fd.read()

        return pf.RawBlock('<pre>%s</pre>' % content, "html")
        # elem.text = content

def main(doc=None):
    return pf.run_filter(action, doc=doc)


if __name__ == '__main__':
    main()
