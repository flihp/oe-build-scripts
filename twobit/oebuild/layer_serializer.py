from __future__ import print_function

import sys

class LayerSerializer:
    """ Class to serialize a collection of Repo objects into LAYERS form.
    """
    def __init__(self, repos):
        self._repos = []
        for repo in repos:
            if type(repo) is Repo:
                self._repos.append(repo)
            else:
                raise TypeError
    def write(self, fd=sys.stdout):
        """ Write the LAYERS file to the specified file object.
        """
        for repo in self._repos:
            fd.write("{0} {1} {2} {3}\n".format(repo._name, repo._url, repo._branch, repo._revision))
