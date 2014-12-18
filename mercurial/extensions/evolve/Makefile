PYTHON=python
HG=`which hg`
VERSION=$(shell python setup.py --version)


help:
	@echo 'Commonly used make targets:'
	@echo '  tests              - run all tests in the automatic test suite'
	@echo '  all-version-tests - run all tests against many hg versions'
	@echo '  tests-%s           - run all tests in the specified hg version'

all: help

tests:
	cd tests && $(PYTHON) run-tests.py --with-hg=$(HG) $(TESTFLAGS)

test-%:
	cd tests && $(PYTHON) run-tests.py --with-hg=$(HG) $(TESTFLAGS) $@

tests-%:
	@echo "Path to crew repo is $(CREW) - set this with CREW= if needed."
	hg -R $(CREW) checkout $$(echo $@ | sed s/tests-//) && \
	(cd $(CREW) ; $(MAKE) clean ) && \
	cd tests && $(PYTHON) $(CREW)/tests/run-tests.py $(TESTFLAGS)

all-version-tests: tests-1.3.1 tests-1.4.3 tests-1.5.4 \
                   tests-1.6.4 tests-1.7.5 tests-1.8 tests-tip

deb-prepare:
	python setup.py sdist --dist-dir ..
	mv -f ../hg-evolve-$(VERSION).tar.gz ../mercurial-evolve_$(VERSION).orig.tar.gz
	tar xf ../mercurial-evolve_$(VERSION).orig.tar.gz
	rm -rf ../mercurial-evolve_$(VERSION).orig
	mv hg-evolve-$(VERSION) ../mercurial-evolve_$(VERSION).orig
	cp -r debian/ ../mercurial-evolve_$(VERSION).orig/
	@cd ../mercurial-evolve_$(VERSION).orig && echo 'debian build directory ready at' `pwd`

.PHONY: tests all-version-tests
