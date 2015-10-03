from __future__ import print_function

import sys
import os

from repo import Repo

class BBLayerSerializer:
    """ Class to serialize a collection of Repo objects into bblayer form.
    """
    def __init__(self, base, repos=[]):
        """ Initialize class.

        base: Directory component relative to TOPDIR where repos live.
              For repos in ${TOPDIR}/repos the base would be 'repos'.
        repos: An optional list of Repo objects. These objects hold all the
               interesting data that's written to the bblayers.conf file.
        """
        self._base = base
        self._repos = []
        for repo in repos:
            if type(repo) is Repo:
                self._repos.append(repo)
            else:
                raise TypeError
    def add_repo(self, repo):
        """ Add Repo object to be written to the bblayers.conf file.

        repo: The Repo object that's being added to the BBLayerSerializer.
        """
        self._repos.append(repo)
    def write(self, fd=sys.stdout):
        """ Write the bblayers.conf file to the specified file object.

        fd: A file object where the bblayer.conf file will be written.
            The default is sys.stdout.
        """
        fd.write("LCONF_VERSION ?= \"5\"\n")
        fd.write("BBPATH ?= \"${TOPDIR}\"\n")
        fd.write("BBLAYERS ?= \" \\\n")
        for repo in self._repos:
            if repo._layers is not None:
                for layer in repo._layers:
                    tmp_path = os.path.normpath("{0}/{1}/{2}".format(self._base, repo._name, layer))
                    fd.write("    ${{TOPDIR}}/{0} \\\n".format(tmp_path))
        fd.write("\"\n")
