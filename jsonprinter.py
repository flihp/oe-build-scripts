#!/usr/bin/env python

import json
from pprint import pprint

class LayerRepo:
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
                "layers:   {4}".format(self._name, self._url, self._branch,
                                       self._revision,self._layers))

def main():
    json_data = open('LAYERS.json')
    data = json.load(json_data)

    repos = []

    for repo in data:
        repos.append(LayerRepo(repo["name"],
                               repo["url"],
                               repo.get("branch","master"),
                               repo.get("revision", "HEAD"),
                               repo.get("layers", ["./"])))

    for repo in repos:
        print repo

    json_data.close()

if __name__ == '__main__':
    main()

