#!/usr/bin/env python3
# -*- coding: latin-1 -*-
import sys
if sys.version_info[0] == 2:
    raise RuntimeError("stdeb3 setup.py can only be used with python3")
elif sys.version_info[1] < 4:
    raise RuntimeError("stdeb3 setup.py can only be used with python 3.4+")
import os
import io
import re
setuptools_min = [5,5,1]  # Oldest one from Debian Jessie
try:
    from setuptools import __version__ as setuptools_version
except ImportError as e:
    raise RuntimeError("stdeb3 requires setuptools to be installed before running.")
setuptools_v = [int(x) for x in str(setuptools_version).split('.')]
if setuptools_v < setuptools_min:
    raise RuntimeError("setuptools minimum version 5.5.1 must be installed.")

from setuptools import setup


def open_local(paths, mode='r', encoding='utf8'):
    if isinstance(paths, str):
        paths = [paths]
    path = os.path.join(
        os.path.abspath(os.path.dirname(__file__)),
        *paths
    )
    return io.open(path, mode, encoding=encoding)


with open_local(['stdeb3', '__init__.py'], encoding='latin-1') as fp:
    try:
        version = re.findall(r"^__version__ = '([^']+)'\r?$",
                             fp.read(), re.M)[0]
    except IndexError:
        raise RuntimeError('Unable to determine version.')

with open_local('README.rst') as file:
    long_description = file.read()

setup(name='stdeb3',
      version=version,
      author='Ashley Sommer',
      author_email='Ashley.Sommer@csiro.au',
      description='Python to Debian source package conversion utility, forked from stdeb',
      long_description=long_description,
      license='MIT',
      url='http://github.com/ashleysommer/stdeb3',
      packages=['stdeb3','stdeb3.command'],
      scripts=['scripts/py2dsc',
               'scripts/py2dsc-deb',
               'scripts/pypi-download',
               'scripts/pypi-install',
               ],
      classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: MIT License',
        'Operating System :: POSIX :: Linux',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3 :: Only',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
    ],
)
