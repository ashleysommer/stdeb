# -*- coding: utf-8 -*-
#
from stdeb3.command.common import CommonDebianPackageCommand

from stdeb3.util import build_dsc, stdeb_cmdline_opts, \
     stdeb_cmd_bool_opts, stdeb_cfg_options

class debianize(CommonDebianPackageCommand):
    description = "distutils command to create a debian directory"

    user_options = stdeb_cmdline_opts + stdeb_cfg_options
    boolean_options = stdeb_cmd_bool_opts

    def run(self):
        debinfo = self.get_debinfo()
        if debinfo.patch_file != '':
            raise RuntimeError('Patches cannot be applied in debianize command')

        dist_dir = None
        repackaged_dirname = None

        build_dsc(debinfo,
                  dist_dir,
                  repackaged_dirname,
                  debian_dir_only=True,
                  )

__all__ = ['debianize']