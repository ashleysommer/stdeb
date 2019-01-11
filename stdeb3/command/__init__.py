# -*- coding: utf-8 -*-
#
import sys

if sys.version_info[0] == 2:
    raise RuntimeError("stdeb3.command can only be used with python3")
elif sys.version_info[1] < 4:
    raise RuntimeError("stdeb3.command can only be used with python 3.4+")

from stdeb3.command import sdist_dsc
from stdeb3.command import bdist_deb
from stdeb3.command import install_deb
from stdeb3.command import debianize

__all__ = ['sdist_dsc','bdist_deb','install_deb','debianize']
