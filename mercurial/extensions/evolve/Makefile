VERSION=$(shell python setup.py --version)


help:
	@echo 'Commonly used make targets:'
	@echo '  deb-prepare - prepare the build of a debian package'

all: help

deb-prepare:
	python setup.py sdist --dist-dir ..
	mv -f ../hg-evolve-$(VERSION).tar.gz ../mercurial-evolve_$(VERSION).orig.tar.gz
	tar xf ../mercurial-evolve_$(VERSION).orig.tar.gz
	rm -rf ../mercurial-evolve_$(VERSION).orig
	mv hg-evolve-$(VERSION) ../mercurial-evolve_$(VERSION).orig
	cp -r debian/ ../mercurial-evolve_$(VERSION).orig/
	@cd ../mercurial-evolve_$(VERSION).orig && echo 'debian build directory ready at' `pwd`
