#!/usr/bin/env python

from argparse import ArgumentParser
import json
from json import JSONDecoder
from twobit.oebuild import Repo, RepoFetcher, FetcherEncoder

def main():
    description="Test program to deserialize Repo objects from JSON file."
    parser = ArgumentParser(prog=__file__, description=description)
    parser.add_argument("-i", "--json-in",
                        default="LAYERS_in.json",
                        help="input file containing Repo object as JSON")
    parser.add_argument("-o", "--json-out",
                        default="LAYERS_out.json",
                        help="output file to dump Repo object as JSON")
    args = parser.parse_args()
    # Parse JSON file with repo data
    with open(args.json_in, 'r') as repos_fd:
        repos = JSONDecoder(object_hook=Repo.repo_decode).decode(repos_fd.read())
    # Dump it back out (should be functionally equivalent), I wonder if 'diff' will think so ...
    fetcher = RepoFetcher(base="foo", repos=repos)
    with open(args.json_out, 'w') as repos_fd:
        json.dump(fetcher, repos_fd, indent=4, cls=FetcherEncoder)

if __name__ == '__main__':
    main()
