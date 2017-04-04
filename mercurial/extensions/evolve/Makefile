VERSION=$(shell python setup.py --version)

PYTHON=python

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

install-home:
	$(PYTHON) setup.py install --home="$(HOME)" --prefix="" --force

# test targets
TESTFLAGS ?= $(shell echo $$HGTESTFLAGS)

HGTESTS=$(HGROOT)/tests

help:
	@echo 'Commonly used make targets:'
	@echo '  tests              - run all tests in the automatic test suite'
	@echo '  all-version-tests - run all tests against many hg versions'
	@echo '  tests-%s           - run all tests in the specified hg version'

all: help

_check_hgroot:
	ifeq ($(HGROOT),)
	  $(error HGROOT is not set to the root of the hg source tree)
	endif

tests: _check_hgroot
	cd tests && $(PYTHON) $(HGTESTS)/run-tests.py $(TESTFLAGS)

# /!\ run outside of the compatibility branch output test will likely fails

test-%: _check_hgroot
	cd tests && $(PYTHON) $(HGTESTS)/run-tests.py $(TESTFLAGS) $@

tests-%: _check_hgroot
	hg -R $(HGROOT) checkout $$(echo $@ | sed s/tests-//) && \
	(cd $(HGROOT) ; $(MAKE) clean ) && \
	cd tests && $(PYTHON) $(HGTESTS)/run-tests.py $(TESTFLAGS)

# build a script to extract declared version
all-version-tests: tests-@

.PHONY: tests all-version-tests
