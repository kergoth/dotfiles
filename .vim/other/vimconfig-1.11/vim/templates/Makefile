
# XXX XXX XXX  THIS IS A NEW FILE XXX XXX XXX

#
# @FILE_EXT@
#
# Developed by @AUTHOR@ <@EMAIL@>
# Copyright (c) @YEAR@ @COMPANY@
# Licensed under terms of GNU General Public License.
# All rights reserved.
#
# Changelog:
# @DATE@ - created
#

# $Platon$ 

# Makefile for creating distribution of test package
# Type 'make dist' for create tar-gziped archiv. 

PACKAGE = test
VERSION = 1.0

unexport SUBDIRS
unexport SUBDIR_OBJECTS
unexport MAKEFILES
unexport CONFIGURE_SCRIPTS
export PACKAGE
export VERSION

# Directories {{{

srcdir       = .
top_srcdir   = .
distdir      = $(PACKAGE)-$(VERSION)
top_distdir  = $(distdir)
top_builddir = .

# }}} Directories

# Targets {{{

# if you have subdirectories with Makefiles,
# add names of directories here
SUBDIRS   =

PROGRAM   = test

# here add names of your source codes
SOURCES   = $(srcdir)/test.c

# name of objects and header files is created
# _automaticaly_ from $(SOURCES) -- you don't need
# change this
OBJECTS         = $(sort $(patsubst %.c,%.o,$(SOURCES)))
include_HEADERS = $(sort $(patsubst %.c,%.h,$(SOURCES)))
DEP_FILES       = $(sort $(patsubst %.c,.deps/%.P,$(SOURCES)))

DISTFILES = Makefile \
			$(SOURCES) $(include_HEADERS)

CONFIG_HEADER   = $(top_builddir)/config.h

# }}} Targets

# Programs {{{

TAR      = tar
ZIP      = zip
ZIP_ENV  = -r9
GZIP_ENV = --best

CC       =
CPP      =
CXX      =
#DEBUG_FLAGS = -g -ggdb -DDEBUG
CFLAGS   = -O2 -Wall -Wshadow -pedantic $(DEBUG_FLAGS)
CPPFLAGS =
LDFLAGS  =
DEFS     =
INCLUDES = -I$(srcdir) -I$(top_builddir)
LIBS     =


COMPILE  = $(CC) $(DEFS) $(INCLUDES) $(CPPFLAGS) $(CFLAGS)
CCLD     = $(CC)
LINK     = $(CCLD) $(CFLAGS) $(LDFLAGS) -o $@

# }}} Programs

all: $(PROGRAM)
	
$(PROGRAM): $(OBJECTS)
	$(LINK) $(OBJECTS) $(LIBS)

DEPS_MAGIC := $(shell mkdir .deps > /dev/null 2>&1 || :)
#-include $(DEP_FILES)

.s.o:
	$(COMPILE) -c $<

%.o: %.c %.h $(CONFIG_HEADER)
	@echo '$(COMPILE) -c $<'; \
	$(COMPILE) -Wp,-MD,.deps/$(*F).pp -o $@ -c $<
	@-cp .deps/$(*F).pp .deps/$(*F).P; \
	tr ' ' '\012' < .deps/$(*F).pp \
	  | sed -e 's/^\\$$//' -e '/^$$/ d' -e '/:$$/ d' -e 's/$$/ :/' \
	    >> .deps/$(*F).P; \
	rm .deps/$(*F).pp

#
# False targets.
#
.PHONY: dummy

#
# A rule to do nothing
#
dummy:
	
clean: clean-subdirs
	-rm -f *.o core

#
# A rule to make subdirectories
#
subdir-list-all = $(sort $(patsubst %,_subdir_%,$(SUBDIRS)))
all-subdirs: dummy $(subdir-list-all)

ifdef SUBDIRS
$(subdir-list-all) : dummy
	$(MAKE) -C $(patsubst _subdir_%,%,$@)
endif

#
# A rule to make clean in subdirectories
#
subdir-list-clean = $(sort $(patsubst %,_subdir_clean_%,$(SUBDIRS)))
clean-subdirs: dummy $(subdir-list-clean)

ifdef SUBDIRS
$(subdir-list-clean) : dummy
	$(MAKE) -C $(patsubst _subdir_clean_%,%,$@) clean
endif

# Distribution targets {{{
dist: distdir
	GZIP=$(GZIP_ENV) $(TAR) chozf $(distdir).tar.gz $(distdir)
	ZIP=$(ZIP_ENV) $(ZIP) $(distdir).zip $(distdir)
	-rm -rf $(distdir)

dist-all: distdir
	GZIP=$(GZIP_ENV) $(TAR) chozf $(distdir).tar.gz $(distdir)
	ZIP=$(ZIP_ENV) $(ZIP) $(distdir).zip $(distdir)
	-rm -rf $(distdir)

distdir: $(DISTFILES)
	-rm -rf $(distdir)
	mkdir $(distdir)
	@here=`cd $(top_builddir) && pwd`; \
	top_distdir=`cd $(distdir) && pwd`; \
	distdir=`cd $(distdir) && pwd`;
	@FILES=`echo "$(DISTFILES)" | awk 'BEGIN{RS=" "}{print}' | sort -u`; \
	for file in $$FILES; do \
	  d=$(srcdir); \
	  if test -d $$d/$$file; then \
	    mkdir $(distdir)/$$file; \
	  else \
	    test -f $(distdir)/$$file \
	    || ln $$d/$$file $(distdir)/$$file 2> /dev/null \
	    || cp -p $$d/$$file $(distdir)/$$file || :; \
	  fi; \
	done

# }}}

# vim600: fdm=marker fdc=3

