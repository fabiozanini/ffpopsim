#############################################################################
#
# Licence:	GPL3
# Author:	Richard Neher, Fabio Zanini
# Date:		2012/05/15
#
# Description:
# ------------
# Makefile for the FFPopSim library.
#
# The first section deals with platform-specific programs, options, and paths.
# Please adapt it to your needs.
#
# The second section of this Makefile, below the clause within !!, is where the
# make recipes are listed and specified. Modify that part of the file only if
# you know what you are doing and want to change some technical detail of the
# dependecy chain.
#
# ---------------------------------------------------------------------------
# The main recipes are the following:
#
# - src: C++ library compilation and (static) linking
# - tests: C++ test cases compilation and linking against the library
# - python: Python bindings
# - python-install: install Python package system-wide (requires root
#   priviledges)
#
# By default, a make call without recipe does the following:
#
# - src tests python: if PYTHON is defined
# - src tests: otherwise
#
# The C++ and Python documentations are built by the following rules:
#
# - doc: C++ documentation
# - python-doc: Python documentation
#
# Moreover, the rule 'all' will call the following:
#
# - src python tests doc python-doc
#
# i.e. will build the whole library and the documentation. Of course, this
# will only work if you have all necessary tools installed.
#
# The compiled library, the C++ include files, the Python bindings, and the
# documentation are put into the pkg folder after building.
#
#############################################################################

############################################################################
#									   #
#			PLATFORM-DEPENDENT OPTIONS			   #
#									   #
############################################################################
# Please select your C++ compiler
CXX := g++

# Please set your Python 2.7 executable if you want to build the Python
# bindings. If you are only interested in the C++ part of the library,
# comment out the following line
PYTHON := python2.7

# Please set your SWIG executable if you wish to regenerate SWIG C++ files
# from the interface files. This is normally not required for compiling the
# Python bindings.
SWIG := swig


# Please set your doxygen executable if you want to rebuild the C++
# documentation.
DOXY := doxygen

# Please set your Sphinx executable (based on Python 2.7) if you want to
# rebuild the Python documentation.
#SPHINX := sphinx-build
SPHINX := sphinx-build2

# Please select the optimization level of the library. Lower this number if
# you prefer to use mildly optimized code only. On Mac OSX, you can use the
# string 'fast' for maximal performance
OPTIMIZATION_LEVEL := O2
#OPTIMIZATION_LEVEL := fast

# Please use the following variable for additional include folders to the
# compiler (e.g. /opt/local/include)
#CXXFLAGS = -I/opt/local/include

# Please look in 'setup.py' if you are trying to compile the Python extension!

############################################################################
#									   #
# 		!! DO NOT EDIT BELOW THIS LINE !!			   #
#									   #
############################################################################
##==========================================================================
# OVERVIEW
##==========================================================================
SRCDIR := src
DOCDIR := doc
TESTSDIR := tests
PYBDIR := $(SRCDIR)/python
PYDOCDIR := $(DOCDIR)/python
PKGDIR := pkg
PFLDIR := profile
DISTUTILS_SETUP := setup.py

# Can we compile Python bindings?
ifdef PYTHON
    python := python
endif

# List all explicit recipes
.PHONY : default all src tests doc python python-doc python-install profile swig clean clean-all clean-src clean-doc clean-tests clean-python clean-python-doc clean-profile clean-swig
default: src tests $(python)
all: src tests python doc python-doc
clean: clean-src clean-tests clean-python clean-profile
clean-all: clean clean-doc clean-python-doc clean-swig

# Profile flag to enable profiling with gprof.
# (Un)Comment the next line to switch off (on) profiling.
#PROFILEFLAGS := -pg
CXXFLAGS := -Wall -$(OPTIMIZATION_LEVEL) -fPIC $(PROFILEFLAGS) $(CXXFLAGS)

##==========================================================================
# C++ SOURCE
##==========================================================================
SRC_CXXFLAGS= $(CXXFLAGS)

LIBRARY := libFFPopSim.a

HEADER_GENERIC := ffpopsim_generic.h
SOURCE_GENERIC := sample.cpp
OBJECT_GENERIC := $(SOURCE_GENERIC:%.cpp=%.o)

HEADER_LOWD := $(HEADER_GENERIC) ffpopsim_lowd.h
SOURCE_LOWD := hypercube_lowd.cpp haploid_lowd.cpp
OBJECT_LOWD := $(SOURCE_LOWD:%.cpp=%.o)

HEADER_HIGHD := $(HEADER_GENERIC) ffpopsim_highd.h
SOURCE_HIGHD := hypercube_highd.cpp haploid_highd.cpp
OBJECT_HIGHD := $(SOURCE_HIGHD:%.cpp=%.o)

HEADER_HIV := hivpopulation.h
SOURCE_HIV := $(HEADER_HIV:%.h=%.cpp)
OBJECT_HIV := $(SOURCE_HIV:%.cpp=%.o)

SOURCE_HIVGENE := hivgene.cpp
OBJECT_HIVGENE := $(SOURCE_HIVGENE:%.cpp=%.o)

SOURCES := $(HEADER_GENERIC) $(HEADER_LOWD) $(HEADER_HIGHD) $(HEADER_HIV) $(SOURCE_GENERIC) $(SOURCE_LOWD) $(SOURCE_HIGHD) $(SOURCE_HIV) $(SOURCE_HIVGENE)
OBJECTS := $(OBJECT_GENERIC) $(OBJECT_LOWD) $(OBJECT_HIGHD) $(OBJECT_HIV) $(OBJECT_HIVGENE)

# Recipes
src: $(SRCDIR)/$(LIBRARY)

$(SRCDIR)/$(LIBRARY): $(OBJECTS:%=$(SRCDIR)/%)
	ar rcs $@ $^
	mkdir -p $(PKGDIR)/lib
	cp $@ $(PKGDIR)/lib/
	mkdir -p $(PKGDIR)/include
	cp $(HEADER_GENERIC:%=$(SRCDIR)/%) $(PKGDIR)/include/
	cp $(HEADER_LOWD:%=$(SRCDIR)/%) $(PKGDIR)/include/
	cp $(HEADER_HIGHD:%=$(SRCDIR)/%) $(PKGDIR)/include/
	cp $(HEADER_HIV:%=$(SRCDIR)/%) $(PKGDIR)/include/

$(OBJECT_GENERIC:%=$(SRCDIR)/%): $(SOURCE_GENERIC:%=$(SRCDIR)/%)
	$(CXX) $(SRC_CXXFLAGS) -c -o $@ $(@:.o=.cpp)

$(OBJECT_LOWD:%=$(SRCDIR)/%): $(SOURCE_LOWD:%=$(SRCDIR)/%) $(HEADER_LOWD:%=$(SRCDIR)/%)
	$(CXX) $(SRC_CXXFLAGS) -c -o $@ $(@:.o=.cpp)

$(OBJECT_HIGHD:%=$(SRCDIR)/%): $(SOURCE_HIGHD:%=$(SRCDIR)/%) $(HEADER_HIGHD:%=$(SRCDIR)/%)
	$(CXX) $(SRC_CXXFLAGS) -c -o $@ $(@:.o=.cpp)

$(OBJECT_HIV:%=$(SRCDIR)/%): $(SOURCE_HIV:%=$(SRCDIR)/%) $(HEADER_HIV:%=$(SRCDIR)/%)
	$(CXX) $(SRC_CXXFLAGS) -c -o $@ $(@:.o=.cpp)

$(OBJECT_HIVGENE:%=$(SRCDIR)/%): $(SOURCE_HIVGENE:%=$(SRCDIR)/%) $(HEADER_HIV:%=$(SRCDIR)/%)
	$(CXX) $(SRC_CXXFLAGS) -c -o $@ $(@:.o=.cpp)

clean-src:
	cd $(SRCDIR); rm -rf $(LIBRARY) *.o *.h.gch
	cd $(PKGDIR); rm -rf lib include

##==========================================================================
# C++ DOCUMENTATION
##==========================================================================
DOXYFILE   = $(DOCDIR)/cpp/Doxyfile

# Recipes
doc:
	$(DOXY) $(DOXYFILE)
	cd $(PKGDIR)/doc; rm -rf cpp
	mkdir -p $(PKGDIR)/doc/cpp
	mv -f $(DOCDIR)/cpp/html $(PKGDIR)/doc/cpp/

clean-doc:
	cd $(PKGDIR)/doc; rm -rf cpp

##==========================================================================
# C++ TESTS
##==========================================================================
TESTS_CXXFLAGS = $(CXXFLAGS) -Isrc
TESTS_LDFLAGS = -$(OPTIMIZATION_LEVEL) $(PROFILEFLAGS)
TEST_LIBDIRS = -L$(CURDIR)/$(SRCDIR)
TESTS_LIBS = -lFFPopSim -lgsl -lgslcblas

TESTS_LOWD = lowd
TESTS_HIGHD = highd
TESTS_LOWD_REC = recombination_lowd

TESTS_SOURCE_LOWD = $(TESTS_LOWD:%=%.cpp)
TESTS_SOURCE_HIGHD = $(TESTS_HIGHD:%=%.cpp)
TESTS_SOURCE_LOWD_REC = $(TESTS_LOWD_REC:%=%.cpp)

TESTS_OBJECT_LOWD = $(TESTS_LOWD:%=%.o)
TESTS_OBJECT_HIGHD = $(TESTS_HIGHD:%=%.o)
TESTS_OBJECT_LOWD_REC = $(TESTS_LOWD_REC:%=%.o)

# Recipes
tests: $(SRCDIR)/$(LIBRARY) $(TESTSDIR)/$(TESTS_LOWD) $(TESTSDIR)/$(TESTS_HIGHD) $(TESTSDIR)/$(TESTS_LOWD_REC)

$(TESTSDIR)/$(TESTS_LOWD_REC): $(TESTSDIR)/$(TESTS_OBJECT_LOWD_REC) $(SRCDIR)/$(LIBRARY)
	$(CXX) $(TESTS_LDFLAGS) $^ $(TEST_LIBDIRS) $(TESTS_LIBS) -o $@

$(TESTSDIR)/$(TESTS_OBJECT_LOWD_REC): $(TESTSDIR)/$(TESTS_SOURCE_LOWD_REC)
	$(CXX) $(TESTS_CXXFLAGS) -c $(@:.o=.cpp) -o $@

$(TESTSDIR)/$(TESTS_LOWD): $(TESTSDIR)/$(TESTS_OBJECT_LOWD) $(SRCDIR)/$(LIBRARY)
	$(CXX) $(TESTS_LDFLAGS) $^ $(TEST_LIBDIRS) $(TESTS_LIBS) -o $@

$(TESTSDIR)/$(TESTS_OBJECT_LOWD): $(TESTSDIR)/$(TESTS_SOURCE_LOWD)
	$(CXX) $(TESTS_CXXFLAGS) -c $(@:.o=.cpp) -o $@

$(TESTSDIR)/$(TESTS_HIGHD): $(TESTSDIR)/$(TESTS_OBJECT_HIGHD) $(SRCDIR)/$(OBJECT_HIV) $(SRCDIR)/$(LIBRARY)
	$(CXX) $(TESTS_LDFLAGS) $^ $(TEST_LIBDIRS) $(TESTS_LIBS) -o $@

$(TESTSDIR)/$(TESTS_OBJECT_HIGHD): $(TESTSDIR)/$(TESTS_SOURCE_HIGHD)
	$(CXX) $(TESTS_CXXFLAGS) -c $(@:.o=.cpp) -o $@

clean-tests:
	cd $(TESTSDIR); rm -rf *.o $(TESTS_LOWD) $(TESTS_HIGHD)

##==========================================================================
# PYTHON BINDINGS
##==========================================================================
SWIG_MODULE := FFPopSim.i
SWIG_GENERIC := ffpopsim_generic.i
SWIG_LOWD := ffpopsim_lowd.i
SWIG_HIGHD := ffpopsim_highd.i
SWIG_HIV := hivpopulation.i

SWIG_WRAP := $(SWIG_MODULE:%.i=%_wrap.cpp)

PYMODULE := $(SWIG_MODULE:%.i=%.py)
PYCMODULE := $(SWIG_MODULE:%.i=%.pyc)
SOMODULE := $(SWIG_MODULE:%.i=_%.so)

# Recipes
python: $(PYBDIR)/$(PYMODULE) $(PYBDIR)/$(SOMODULE) $(DISTUTILS_SETUP)

python-install:
	rm -rf build
	$(PYTHON) setup.py install

$(PYBDIR)/$(SOMODULE): $(PYBDIR)/$(SWIG_WRAP) $(PYBDIR)/$(PYMODULE) $(SOURCES:%=$(SRCDIR)/%)
	rm -rf build
	$(PYTHON) setup.py build_ext --inplace
	mkdir -p $(PKGDIR)/python
	cp -f $(PYBDIR)/$(PYMODULE) $(PKGDIR)/python/
	cp -f $(PYBDIR)/$(SOMODULE) $(PKGDIR)/python/

clean-python:
	rm -rf build
	cd $(PYBDIR); rm -rf $(SOMODULE) $(PYCMODULE)
	cd $(PKGDIR)/python; rm -rf $(SOMODULE) $(PYMODULE) $(PYCMODULE)

##==========================================================================
# SWIG (USED FOR PYTHON BINDINGS)
##==========================================================================
SWIGFLAGS := -c++ -python -O -castmode -keyword

swig: $(PYBDIR)/$(SWIG_WRAP) $(PYBDIR)/$(PYMODULE)

$(PYBDIR)/$(SWIG_WRAP) $(PYBDIR)/$(PYMODULE): $(PYBDIR)/$(SWIG_MODULE) $(PYBDIR)/$(SWIG_GENERIC) $(PYBDIR)/$(SWIG_LOWD) $(PYBDIR)/$(SWIG_HIGHD) $(PYBDIR)/$(SWIG_HIV)
	$(SWIG) $(SWIGFLAGS) -o $(PYBDIR)/$(SWIG_WRAP) $(PYBDIR)/$(SWIG_MODULE)

clean-swig:
	cd $(PYBDIR); rm -rf $(SWIG_WRAP) $(PYMODULE)

##==========================================================================
# PYTHON DOCUMENTATION
##==========================================================================
python-doc:
	cd $(PYDOCDIR); $(MAKE) SPHINXBUILD=$(SPHINX) html
	cd $(PKGDIR)/doc; rm -rf python
	mkdir -p $(PKGDIR)/doc/python
	mv -f $(PYDOCDIR)/build/html $(PKGDIR)/doc/python/

clean-python-doc:
	cd $(PYDOCDIR); rm -rf build
	cd $(PKGDIR)/doc; rm -rf python

##==========================================================================
# PROFILE
##==========================================================================
PROFILE_CXXFLAGS = $(CXXFLAGS) -I$(SRCDIR) -Wall -$(OPTIMIZATION_LEVEL) -c -fPIC $(PROFILEFLAGS)
PROFILE_LDFLAGS = -$(OPTIMIZATION_LEVEL) $(PROFILEFLAGS)
PROFILE_LIBDIRS = -L$(CURDIR)/$(SRCDIR)
PROFILE_LIBS = -lFFPopSim -lgsl -lgslcblas

PROFILE = profile
PROFILE_SOURCE = $(PROFILE:%=%.cpp)
PROFILE_OBJECT = $(PROFILE:%=%.o)

# Recipes
profile: $(SRCDIR)/$(LIBRARY) $(PROFILE:%=$(PFLDIR)/%)

$(PROFILE:%=$(PFLDIR)/%): $(PROFILE_OBJECT:%=$(PFLDIR)/%) $(SRCDIR)/$(LIBRARY)
	$(CXX) $(PROFILE_LDFLAGS) $^ $(PROFILE_LIBDIRS) $(PROFILE_LIBS) -o $@

$(PROFILE_OBJECT:%=$(PFLDIR)/%): $(PROFILE_SOURCE:%=$(PFLDIR)/%)
	$(CXX) $(PROFILE_CXXFLAGS) -c $(@:.o=.cpp) -o $@

#############################################################################
