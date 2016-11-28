#!/usr/bin/env python
"""A Python module for working with OpenPGP messages

PyGPGME is a Python module that lets you sign, verify, encrypt and
decrypt messages using the OpenPGP format.

It is built on top of the GNU Privacy Guard and the GPGME library.
"""

from distutils.core import setup, Extension

gpgme = Extension(
    'gpgme._gpgme',
    ['src/gpgme.c',
     'src/pygpgme-error.c',
     'src/pygpgme-data.c',
     'src/pygpgme-context.c',
     'src/pygpgme-key.c',
     'src/pygpgme-signature.c',
     'src/pygpgme-import.c',
     'src/pygpgme-keyiter.c',
     'src/pygpgme-constants.c',
     'src/pygpgme-genkey.c',
     ],
    libraries=['gpgme'])

description, long_description = __doc__.split("\n\n", 1)

setup(name='pygpgme',
      version='0.3',
      author='James Henstridge',
      author_email='james@jamesh.id.au',
      description=description,
      long_description=long_description,
      license='LGPL',
      classifiers=[
          'Intended Audience :: Developers',
          'License :: OSI Approved :: GNU Library or Lesser General Public License (LGPL)',
          'Operating System :: POSIX',
          'Programming Language :: C',
          'Programming Language :: Python :: 2',
          'Programming Language :: Python :: 3',
          'Topic :: Security :: Cryptography',
          'Topic :: Software Development :: Libraries :: Python Modules'
      ],
      url='https://launchpad.net/pygpgme',
      ext_modules=[gpgme],
      packages=['gpgme'])
