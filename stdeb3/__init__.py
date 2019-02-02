# -*- coding: latin-1 -*-
#
import logging
import sys
# version read by ../setup.py
__version__ = '0.9.0.post1'
if sys.version_info[0] == 2:
    raise RuntimeError("stdeb3 v%s can only be used with python3"%__version__)
elif sys.version_info[1] < 4:
    raise RuntimeError("stdeb3 v%s can only be used with python 3.4+"%__version__)
log = logging.getLogger('stdeb')
log.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(message)s')
handler.setFormatter(formatter)
log.addHandler(handler)
