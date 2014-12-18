
all: tutorials/tutorial.rst static/logo-evolve.ico
	sphinx-build . ../html/

tutorials/tutorial.rst: tutorials/tutorial.t
	python test2rst.py tutorials/

static/logo-evolve.ico: static/logo-evolve.svg
	convert -resize 36x36 static/logo-evolve.svg static/logo-evolve.ico


