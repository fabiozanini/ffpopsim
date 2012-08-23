# vim: fdm=indent
'''
author:     Richard Neher, Fabio Zanini
date:       23/08/12
content:    Distutils setup script for the Python bindings of FFPopSim.

            *Note*: this file is called by the Makefile with the command
            build_ext to build the C++/Python extension. It can, however,
            also be called directly including with other commands such as
            install, to install the Python bindings of FFPopSim on the
            system.
'''
from distutils.core import setup, Extension
from numpy import distutils as npdis

VERSION = '1.1'
SRCDIR = 'src'
PYBDIR = SRCDIR+'/python'

includes = npdis.misc_util.get_numpy_include_dirs()
libs = ['gsl', 'gslcblas']
setup(name='FFPopSim',
      author='Fabio Zanini, Richard Neher',
      author_email='fabio.zanini@tuebingen.mpg.de, richard.neher@tuebingen.mpg.de',
      version=VERSION,
      package_dir={'': PYBDIR},
      py_modules=['FFPopSim'],
      ext_modules=[Extension('_FFPopSim', [PYBDIR+'/FFPopSim_wrap.cpp',
                                           SRCDIR+'/haploid_highd.cpp', 
                                           SRCDIR+'/haploid_lowd.cpp', 
                                           SRCDIR+'/hivpopulation.cpp',
                                           SRCDIR+'/hivgene.cpp',
                                           SRCDIR+'/hypercube_lowd.cpp', 
                                           SRCDIR+'/hypercube_highd.cpp'], 
                             include_dirs=includes, 
                             libraries=libs,
                            ),
                  ]
      )

