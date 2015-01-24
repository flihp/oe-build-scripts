#!/usr/bin/env python

from __future__ import print_function

import argparse
import json
from json import JSONEncoder,JSONDecoder
import os
import subprocess
import sys

""" This is a utility to manage an OE build directory.
"""

class BBLayerSerializer:
    """ Class to serialize a collection of Repo objects into bblayer form.
    """
    def __init__(self, base, repos=[]):
        self._base = base
        self._repos = []
        for repo in repos:
            if type(repo) is Repo:
                self._repos.append(repo)
            else:
                raise TypeError
    def add_repo(self, repo):
        self._repos.append(repo)
    def write(self, fd=sys.stdout):
        fd.write("LCONF_VERSION = \"5\"\n")
        fd.write("BBPATH = \"${TOPDIR}\"\n")
        fd.write("BBLAYERS = \" \\\n")
        for repo in self._repos:
            if repo._layers is not None:
                for layer in repo._layers:
                    fd.write("    ${{TOPDIR}}/{0}/{1}/{2} \\\n".format(self._base, repo._name, layer))
        fd.write("\"\n")

class RepoFetcher(object):
    """ Class to manage git repo state.
    """
    def __init__(self, base, repos=[]):
        self._base = base
        self._repos = []
        for repo in repos:
            if type(repo) is Repo:
                self._repos.append(repo)
            else:
                raise TypeError
    def add_repo(self, repo):
        self._repos.append(repo)
    def __str__(self):
        return ''.join(str(repo) for repo in self._repos)
    def clone(self):
        for repo in self._repos:
            repo.clone(self._base)

class Repo(object):
    """ Data required to clone a git repo in a specific state.
    """
    def __init__(self, name, url, branch="master", revision="head", layers=["./"]):
        self._name = name
        self._url = url
        self._branch = branch
        self._revision = revision
        self._layers = layers
    def set_branch(self, branch):
        self._branch = branch
    def set_revision(self, revision):
        self._revision = revision
    def set_layers(self, layers):
        self._layers = layers
    def __str__(self):
        return ("name:     {0}\n"
                "url:      {1}\n"
                "branch:   {2}\n"
                "revision: {3}\n"
                "layers:   {4}\n".format(self._name, self._url, self._branch,
                                         self._revision,self._layers))
    def clone(self, path):
        dest = path + "/" + self._name
        try:
            if not os.path.exists(dest):
                print("cloning {0} into {1}".format (self._name, path))
                return subprocess.call(
                    ['git', 'clone', '--progress', self._url, dest], shell=False
                )
            else:
                return 1
        except subprocess.CalledProcessError, e:
            print(e)
 
class FetcherEncoder(JSONEncoder):
    """ Encode RepoFetcher object as JSON

    Pass this class to the dumps function from the json module alnog with your
    RepoFetcher object.
    """
    def default(self, obj):
        if type(obj) is not RepoFetcher:
            raise TypeError
        if obj._repos is None:
            raise ValueError
        list_tmp = []
        for repo in obj._repos:
            list_tmp.append(RepoEncoder().default(repo))
        return list_tmp

class RepoEncoder(JSONEncoder): 
    """ Encode a Repo object as JSON

    Pass this class to the dumps function from the json module along with your
    Repo object.
    """
    def default(self, obj):
        if type(obj) is not Repo:
            raise TypeError
        dict_tmp = {}
        dict_tmp["name"] = obj._name
        dict_tmp["url"] = obj._url
        if obj._branch != "master":
            dict_tmp["branch"] = obj._branch
        if obj._layers is None:
            dict_tmp["layers"] = obj._layers
        elif len(obj._layers) > 1 or obj._layers[0] != "./":
            dict_tmp["layers"] = obj._layers
        return dict_tmp

def repo_decode(json_obj):
    """ Create a repository object from a dictionary.

    Intended for use in JSON deserialization.
    """
    if type(json_obj) is not dict:
        raise TypeError
    return Repo(json_obj["name"],
                     json_obj["url"],
                     json_obj.get("branch", "master"),
                     json_obj.get("revision", "HEAD"),
                     json_obj.get("layers", ["./"]))

def setup(repo_file, src_dir="./sources", conf_dir="./conf"):
    """ Setup build structure.
    """
    bblayers_file = conf_dir + "/bblayers.conf"
    # Parse JSON file with repo data
    with open(repo_file, 'r') as repos_fd:
        while True:
            try:
                repos = JSONDecoder(object_hook=repo_decode).decode(repos_fd.read())
                fetcher = RepoFetcher(src_dir, repos=repos)
            except ValueError:
                break;
    # fetch repos
    if not os.path.isdir(src_dir):
        os.mkdir(src_dir)
    fetcher.clone()
    # create bblayers.conf file, don't overwrite
    if not os.path.isdir(conf_dir):
        os.mkdir(conf_dir)
    bblayers = BBLayerSerializer(conf_dir, repos=fetcher._repos)
    if os.path.exists(bblayers_file):
        raise ValueError(bblayers_file + " already exists");
    with open(bblayers_file, 'w') as test_file:
        bblayers.write(fd=test_file)
    return
"""
    print("serializing a single Repo to JSON:")
    print(RepoEncoder().encode(fetcher._repos[0]))
    print("serializing a single Repo to JSON with dumps")
    print(json.dumps(fetcher._repos[0], indent=4, cls=RepoEncoder))
    print("serializing a RepoFetcher to JSON:")
    print(FetcherEncoder().encode(fetcher))
    print("serializing a RepoFetcher to JSON with dumps")
    print(json.dumps(fetcher, indent=4, cls=FetcherEncoder))
"""

""" A sort of function table for the actions this script performs.
"""
actions = {
    "setup": setup
}

def main():
    description = "Manage OE build infrastructure."
    repos_json_help = "A JSON file describing the state of the repos."
    action_help = "An action to perform on the build directory. Possible " \
                  "values are: setup"
    source_dir_help = "Checkout git repos into this directory."

    parser = argparse.ArgumentParser(prog=__file__, description=description)
    parser.add_argument("action", help=action_help)
    parser.add_argument("-r", "--repos-json", help=repos_json_help)
    parser.add_argument("-s", "--source-dir", help=source_dir_help)
    args = parser.parse_args()
    action = args.action
    repo_file = args.repos_json
    source_dir = args.source_dir
    
    try:
        actions[action](repo_file, src_dir=source_dir)
    except KeyError:
        parser.print_help()
    return

if __name__ == '__main__':
    main()

