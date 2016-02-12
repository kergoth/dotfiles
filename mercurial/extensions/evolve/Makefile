VERSION=$(shell python setup.py --version)


help:
	@echo 'Commonly used make targets:'
	@echo '  tests              - run all tests in the automatic test suite'
	@echo '  all-version-tests - run all tests against many hg versions'
	@echo '  tests-%s           - run all tests in the specified hg version'

all: help

deb-prepare:
	python setup.py sdist --dist-dir ..
	mv -f ../hg-evolve-$(VERSION).tar.gz ../mercurial-evolve_$(VERSION).orig.tar.gz
	tar xf ../mercurial-evolve_$(VERSION).orig.tar.gz
	rm -rf ../mercurial-evolve_$(VERSION).orig
	mv hg-evolve-$(VERSION) ../mercurial-evolve_$(VERSION).orig
	cp -r debian/ ../mercurial-evolve_$(VERSION).orig/
	@cd ../mercurial-evolve_$(VERSION).orig && echo 'debian build directory ready at' `pwd`
