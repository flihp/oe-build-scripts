from __future__ import print_function

import os
import subprocess

class Repo(object):
    """ Data required to clone a git repo in a specific state.
    """
    def __init__(self, name, url, branch="master", revision="head", layers=["./"]):
        """ Initialize Repo object.

        name: Sting name of the repo.
        url: URL where git repo lives.
        brance: Branch that will be checked out. Default is 'master'.
        revision: Revision where HEAD should point. Default is 'HEAD'.
        layers: A list of the OE meta-layers in the repo that we care about.
                By default we assume the base of the repo is the root of the
                meta layer but in some cases the repo may contain many, or none
                at all. In this last case layers should be set to None.
        """
        self._name = name
        self._url = url
        self._branch = branch
        self._revision = revision
        self._layers = layers
    def set_branch(self, branch):
        """ Set branch for Repo object.
        """
        self._branch = branch
    def set_revision(self, revision):
        """ Set revision for Repo object.
        """
        self._revision = revision
    def set_layers(self, layers):
        """ Set the list of layers for the Repo ojbect.
        """
        self._layers = layers
    def __str__(self):
        """ Create a human readable string representation of the Repo object.
        """
        return ("name:     {0}\n"
                "url:      {1}\n"
                "branch:   {2}\n"
                "revision: {3}\n"
                "layers:   {4}\n".format(self._name, self._url, self._branch,
                                         self._revision,self._layers))
    def clone(self, path):
        """ Clone the Repo.

        path: Path where Repo will be cloned. If renative it will be relative
              to $(pwd).
        """
        work_dir = os.path.join(path, self._name)
        try:
            if not os.path.exists(work_dir):
                print("cloning {0} into {1}".format (self._name, path))
                return subprocess.call(
                    ['git', 'clone', '--progress', self._url, work_dir], shell=False
                )
            else:
                raise EnvironmentError("Cannot clone {0} to {1}: directory exists".format(self._name, work_dir))
        except subprocess.CalledProcessError, e:
            print(e)

    def fetch(self, path):
        """ Fetch the Repo.
        """
        work_tree = os.path.join(path, self._name)
        if work_tree is None or not os.path.exists(work_tree):
            raise EnvironmentError("{0} doesn't exist, cannot fetch".format(work_tree))
        git_dir = os.path.join(work_tree, ".git")
        try:
            print("fetching {0} ...".format(self._name))
            return subprocess.call(
                [
                    'git',
                    '--git-dir={0}'.format(git_dir),
                    '--work-tree={0}'.format(work_tree),
                    'fetch'
                ],
                shell=False
            )
        except subprocess.CalledProcessError as e:
            print(e)

    def checkout_branch(self, path):
        """ Checkout the branch specified. Fall back to using the branch
            specified in the constructor.
        """
        work_tree = os.path.join(path, self._name)
        if work_tree is None or not os.path.exists(work_tree):
            raise EnvironmentError("Cannot reset repo state: {0} doesn't exist".format(work_tree))
        git_dir = os.path.join(work_tree, ".git")
        try:
            print("checking out branch: {0}".format(self._branch))
            return subprocess.call(
                [
                    'git',
                    '--git-dir={0}'.format(git_dir),
                    '--work-tree={0}'.format(work_tree),
                    'checkout',
                    self._branch
                ],
                shell=False
            )
        except subprocess.CalledProcessError as e:
            print(e)

    def reset_revision(self, path):
        """ Reset the repo to the specified revision.

        Use this method with care. You may lose data.
        """
        work_tree = os.path.join(path, self._name)
        if work_tree is None or not os.path.exists(work_tree):
            raise EnvironmentError("Cannot reset repo state: {0} doesn't exist".format(work_tree))
        git_dir = os.path.join(work_tree, ".git")
        try:
            print("resetting repo revision {0}".format(self._revision))
            return subprocess.call(
                [
                    'git',
                    '--git-dir={0}'.format(git_dir),
                    '--work-tree={0}'.format(work_tree),
                    'reset',
                    '--hard',
                    self._revision
                ],
                shell=False
            )
        except subprocess.CalledProcessError as e:
            print(e)
    def update(self, path):
        """ Update the repo.

        Check it out if necessary. Otherwise fetch it and reset state.
        """
        work_tree = os.path.join(path, self._name)
        if work_tree is None:
            raise EnvironmentError("Cannot update repo. Invalid path: {0}".format(work_tree))
        if not os.path.exists(work_tree):
            self.clone(path)
        else:
            self.fetch(path)
            self.checkout_branch(path)
            self.reset_revision(path)
    @staticmethod
    def repo_decode(json_obj):
        """ Create a repository object from a dictionary.

        Intended for use in JSON deserialization.
        json_obj: A dictionary object that contains a serialized Repo object.
        """
        if type(json_obj) is not dict:
            raise TypeError
        return Repo(json_obj["name"],
                    json_obj["url"],
                    json_obj.get("branch", "master"),
                    json_obj.get("revision", "HEAD"),
                    json_obj.get("layers", None))
