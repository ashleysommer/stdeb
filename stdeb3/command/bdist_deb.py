# -*- coding: utf-8 -*-
#
import os
import stdeb3.util as util

from distutils.core import Command

class bdist_deb(Command):
    description = 'distutils command to create debian binary package'

    user_options = [
        ('sign-results',None,
         'Use gpg to sign the resulting .dsc and .changes file'),
        ('sign-key=',None,
         'Override the signing key to use to sign the package.'),
        ('gpg-proxy=', None,
         'Use this gpg proxy rather than gpg to sign the package.'),
    ]
    boolean_options = [
        'sign-results',
        ]

    def initialize_options (self):
        self.sign_results = False
        self.sign_key = None
        self.gpg_proxy = None

    def finalize_options (self):
        self.sign_results = bool(self.sign_results)

    def run(self):
        # generate .dsc source pkg
        self.run_command('sdist_dsc')

        # get relevant options passed to sdist_dsc
        sdist_dsc = self.get_finalized_command('sdist_dsc')
        dsc_tree = sdist_dsc.dist_dir

        # execute system command and read output (execute and read output of find cmd)
        target_dirs = []
        for entry in os.listdir(dsc_tree):
            fulldir = os.path.join(dsc_tree,entry)
            if os.path.isdir(fulldir):
                if entry == 'tmp_py2dsc':
                    continue
                target_dirs.append( fulldir )

        if len(target_dirs)>1:
            raise ValueError('More than one directory in deb_dist. '
                             'Unsure which is source directory. All: %r'%(
                target_dirs,))

        if len(target_dirs)==0:
            raise ValueError('could not find debian source directory')

        # define system command to execute (gen .deb binary pkg)
        syscmd = ['dpkg-buildpackage','-rfakeroot','-b']

        if not self.sign_results:
            syscmd.append('-uc')
        else:
            if self.sign_key:
                syscmd.append('--sign-key=' + self.sign_key)
            if self.gpg_proxy:
                syscmd.append('--sign-command=' + str(self.gpg_proxy))
        util.process_command(syscmd,cwd=target_dirs[0])

__all__ = ['bdist_deb']