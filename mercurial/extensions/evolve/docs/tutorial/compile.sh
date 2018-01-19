#!/bin/bash
set -eox pipefail


function compile {
    pandoc \
    -s $1 \
    -o $2 \
    --toc --toc-depth=4 \
    -F pandocfilters/examples/graphviz.py -F mypandocfilters/graphviz-file.py -F mypandocfilters/raw-file.py \
    -t html5 \
    --template standalone.html --variable=template_css:uikit.css

}

compile slides.md index.html
