from __future__ import print_function

from repo import Repo

class RepoFetcher(object):
    """ Class to manage git repo state.
    """
    def __init__(self, base, repos=[]):
        """ Initialize class.

        base: Directory where repos will or currently do reside.
        repos: List of Repo objects for the RepoFetcher to operate on.
        """
        self._base = base
        self._repos = []
        for repo in repos:
            if type(repo) is Repo:
                self._repos.append(repo)
            else:
                raise TypeError
    def add_repo(self, repo):
        """ Add a repo to the RepoFetcher.
        """
        self._repos.append(repo)
    def __str__(self):
        """ Create a string representation of all Repos in the RepoFetcher.
        """
        return ''.join(str(repo) for repo in self._repos)
    def clone(self):
        """ Clone all repos in a RepoFetcher.

        Does nothing more than loop over the list of Repo objects invoking the
        'clone' method on each.
        """
        for repo in self._repos:
            repo.clone(self._base)
            repo.checkout_branch(self._base)
            repo.reset_revision(self._base)
    def fetch(self):
        """ Fetch all respos in the RepoFetcher.
        """
        for repo in self._repos:
            repo.fetch(self._base)
    def reset_state(self):
        """ Set the state of each Repo to the default repo and verision.
        """
        for repo in self._repos:
            repo.checkout_branch(self._base)
            repo.reset_revision(self._base)
    def update(self):
        """ Update repos.
        """
        for repo in self._repos:
            repo.update(self._base)
