# vim: fdm=indent
'''
author:     Richard Neher, Fabio Zanini
date:       23/08/12
license:    GPL3
content:    Distutils setup script for the Python bindings of FFPopSim.

            If your compiler has problems finding GSL and/or BOOST and you are
            sure they are installed on your system, check the section
            PLATFORM-DEPENDENT OPTIONS below.

            *Note*: this file is called by the Makefile with the command

                python setup.py build_ext
            
            to build the C++/Python extension. It can, however, also be called
            directly including with other commands such as

                python setup.py install

            to install the Python bindings of FFPopSim on the system. Note that
            calling this file directly does not clean the 'build' folder.

Static building: copy your GSL includes and static lib files into

    static/<architechture>/

following the directory structure (i.e. include/gsl and /lib). Then, set the
'platform' variable here below accordingly and build.
'''
from distutils.core import setup, Extension
from numpy import distutils as npdis
import sys
import platform as pfm

############################################################################
#									   #
#			PLATFORM-DEPENDENT OPTIONS			   #
#									   #
############################################################################
# Please add your include folders to the following list, where the compiler
# can find GSL, BOOST, and Python 2.7 headers.
includes = ['/usr/include', '/usr/local/include', '/opt/local/include']

# Please add your shared library folders to the following list, where the linker
# can find Python 2.x (GLS is static in this branch)
library_dirs = ['/ebio/ag-neher/share/programs/lib']

############################################################################
#                !!  DO NOT EDIT BELOW THIS LINE  !!                       #
############################################################################
VERSION = '2.0'
SRCDIR = 'src'
PYBDIR = SRCDIR+'/python'

# Find the current platform and Python interpreter 64-bitness
# Mac OSX
if pfm.system().lower() == 'darwin':
    if sys.maxsize > 2**32:
        platform = 'mac_64'
    else:
        platform = 'mac_32'
# Linux
else:
    if pfm.architecture()[0][:2] == '64':
        platform = 'linux_64'
    else:
        platform = 'linux_32'
print 'The current platform is recognized as: '+platform+''
print 'If this is not correct, please modify setup.py manually.'

# Include local static copies of GSL (headers and library object file)
includes =  ['static/'+platform+'/include'] + includes + npdis.misc_util.get_numpy_include_dirs()
library_dirs = ['static/'+platform+'/lib'] + library_dirs
libs = ['gsl', 'gslcblas']


# Setup
setup(name='FFPopSim',
      author='Fabio Zanini, Richard Neher',
      author_email='fabio.zanini@tuebingen.mpg.de, richard.neher@tuebingen.mpg.de',
      description='C++/Python library for population genetics.',
      license='GPL3',
      url='http://webdav.tuebingen.mpg.de/ffpopsim/',

      version=VERSION,
      package_dir={'': PYBDIR},

      # This is the pure Python file
      py_modules=['FFPopSim'],

      # This is the C++ extension
      ext_modules=[Extension('_FFPopSim',
                             sources=[PYBDIR+'/FFPopSim_wrap.cpp',
                                      SRCDIR+'/haploid_highd.cpp', 
                                      SRCDIR+'/haploid_lowd.cpp', 
                                      SRCDIR+'/hivpopulation.cpp',
                                      SRCDIR+'/hivgene.cpp',
                                      SRCDIR+'/rootedTree.cpp',
                                      SRCDIR+'/multiLocusGenealogy.cpp',
                                      SRCDIR+'/hypercube_lowd.cpp', 
                                      SRCDIR+'/hypercube_highd.cpp'],
                             include_dirs=includes, 
                             library_dirs=library_dirs,
                             libraries=libs,
                             extra_compile_args=[''],
                             extra_objects=[''],
                            ),
                  ]
      )

