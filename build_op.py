#!/usr/bin/env python

from __future__ import print_function

import argparse
import fileinput
import json
from json import JSONEncoder,JSONDecoder
import os
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile

from twobit.oebuild import BBLayerSerializer, FetcherEncoder, LayerSerializer, PathSanity, Repo, RepoEncoder, RepoFetcher

def layers_from_bblayers(top_dir, bblayers_fd):
    """ Parse the layers from the bblayers.conf file

    top_dir: The absolute path to replace occurrences of TOPDIR in the
             bblayers.conf file.
    bblayers_fd: A file object attached to the bblayers.conf file
    """
    front = ""
    while True:
        cur = bblayers_fd.read(1)
        if not front.endswith("BBLAYERS"):
            front += cur
        else:
            break
    # Gobble till first quote
    while True:
        cur = bblayers_fd.read(1)
        if cur == '\"':
            break
    # collect all characters till the next quote
    layers = ""
    while True:
        cur = bblayers_fd.read(1)
        if cur == '\"' and not layers.endswith('\\'):
            break
        else:
            if cur == '\n':
                layers += ' '
            else:
                layers += cur

    # strip newlines and extra whitespace
    tmp =  " ".join(layers.replace("${TOPDIR}", top_dir).split())
    return tmp

def repo_state(git_dir):
    """ Collect the url, branch and revision of the parameter git repo

    git_dir: The file path to a local git clone.
    returns a tripple (url, branch, rev)
    """
    rev = subprocess.check_output(
        ["git", "--git-dir", git_dir, "rev-parse", "HEAD"]
    ).rstrip()
    branch = subprocess.check_output(
        ["git", "--git-dir", git_dir, "rev-parse", "--abbrev-ref", "HEAD"]
    ).rstrip()
    remote = subprocess.check_output(
        ["git", "--git-dir", git_dir, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"]
    ).split("/")[0].rstrip()
    url = subprocess.check_output(
        ["git", "--git-dir", git_dir, "config", "--get", "remote." + remote + ".url"]
    ).rstrip()
    return url, branch, rev

def json_gen(args):
    """ Parse bblayers.conf and collect data from repos in src_dir to generate
        a json file representing their state.
    """
    paths = PathSanity(args.top_dir)
    paths["conf_dir"] = "conf"
    paths["bblayers_file"] = os.path.join(paths["conf_dir"], "bblayers.conf")
    paths["src_dir"] = args.src_dir
    paths["json_out"] = args.json_out

    # build a list of Repo objects and create a fetcher for them
    repos = Repo.repos_from_state(paths["bblayers_file"],
                                  top_dir=paths._top_dir,
                                  src_dir=paths["src_dir"])
    fetcher = RepoFetcher(paths["src_dir"], repos=repos)
    # Serialize Repo objects to JSON manifest
    with open(paths["json_out"], 'w') as repo_json_fd:
        json.dump(fetcher, repo_json_fd, indent=4, cls=FetcherEncoder)

def layers_gen(args):
    """ Collect data from repos in src_dir to generate the LAYERS file.
    """
    paths = PathSanity(args.top_dir)
    paths["src_dir"] = args.src_dir
    paths["bblayers_file"] = args.bblayers_file
    paths["layers_file"] = args.layers_file

    # create list of Repo objects
    repos = Repo.repos_from_state(paths["bblayers_file"],
                                  top_dir=paths._top_dir,
                                  src_dir=paths["src_dir"])

    # create LAYERS file
    layers = LayerSerializer(repos)
    with open(paths["layers_file"], 'w') as layers_fd:
        layers.write(fd=layers_fd)

def manifest(args):
    """ Create manifest describing current state of repos in src_dir.

    top_dir: The root directory of the build.
    """
    # need sanity tests for paths / names
    paths = PathSanity(args.top_dir)
    paths.setitem_strict("conf_dir", "conf", exist=True)
    paths.setitem_strict("bblayers_file",
                         os.path.join(paths["conf_dir"], "bblayers.conf"),
                         exist=True)
    paths.setitem_strict("localconf_file",
                         os.path.join(paths["conf_dir"], "local.conf"),
                         exist=True)
    paths.setitem_strict("env_file", "environment.sh", exist=True)
    paths.setitem_strict("build_file", "build.sh", exist=True)
    paths.setitem_strict("build_op_file", "build_op.py", exist=True)
    paths.setitem_strict("layers_file", "LAYERS.json", exist=True)
    archive_prefix = args.archive
    paths["archive_file"] = archive_prefix + ".tar.bz2"

    # collect build config files and tar it all up
    # make temporary directory
    tmp_paths = PathSanity(tempfile.mkdtemp())
    tmp_paths.setitem_strict("conf_dir", "conf", exist=False)
    # mk conf dir
    os.mkdir(tmp_paths["conf_dir"])
    # copy local.conf to tmp/conf/local.conf
    shutil.copy(paths["bblayers_file"], tmp_paths["conf_dir"])
    shutil.copy(paths["localconf_file"], tmp_paths["conf_dir"])
    # copy environment.sh to tmp/
    shutil.copy(paths["env_file"], tmp_paths._top_dir)
    # copy build.sh to tmp/
    shutil.copy(paths["build_file"], tmp_paths._top_dir)
    # copy fetch.sh to tmp/
    shutil.copy(paths["build_op_file"], tmp_paths._top_dir)
    # copy LAYERS to tmp
    shutil.copy(paths["layers_file"], tmp_paths._top_dir)

    # tar it all up
    with tarfile.open(paths["archive_file"], "w:bz2") as tar:
        tar.add(tmp_paths._top_dir, arcname=archive_prefix, recursive=True)

    return

def setup(args):
    """ Setup build structure.
    """
    # Setup paths to source and destination files. Test for existence.
    try:
        paths = PathSanity(args.top_dir)
        paths["src_dir"] = args.src_dir
        paths["conf_dir"] = "conf"

        build_type = args.build_type
        paths.setitem_strict("build_op_data", args.build_op_data)
        paths.setitem_strict("build_src",
                             os.path.join(paths["build_op_data"],
                                          "build_" + build_type + ".sh"))
        paths.setitem_strict("build_dst", "build.sh", exist=False)
        paths.setitem_strict("json_dst", "LAYERS.json", exist=False)
        paths.setitem_strict("json_src",
                             os.path.join(paths["build_op_data"],
                                          "LAYERS_" + build_type + ".json"))
        paths.setitem_strict("local_conf_src",
                             os.path.join(paths["build_op_data"],
                                          "local_" + build_type + ".conf"))
        paths.setitem_strict("local_conf_dst",
                             os.path.join(paths["conf_dir"], "local.conf"),
                             exist=False)
        paths.setitem_strict("env_src",
                             os.path.join(paths["build_op_data"],
                                          "environment.sh.template"))
        paths.setitem_strict("env_dst", "environment.sh", exist=False)
        paths.setitem_strict("bblayers_dst",
                             os.path.join(paths["conf_dir"], "bblayers.conf"),
                             exist=False)
    except ValueError as e:
        print(e)
        sys.exit(1)

    # Parse JSON file with repo data
    with open(paths["json_src"], 'r') as repos_fd:
        while True:
            try:
                repos = JSONDecoder(object_hook=Repo.repo_decode).decode(repos_fd.read())
                fetcher = RepoFetcher(paths["src_dir"], repos=repos)
            except ValueError:
                break;
    # create bblayers.conf file
    if not os.path.isdir(paths["conf_dir"]):
        os.mkdir(paths["conf_dir"])
    bblayers = BBLayerSerializer(paths.getitem_rel("src_dir"),
                                 repos=fetcher._repos)
    with open(paths["bblayers_dst"], 'w') as test_file:
        bblayers.write(fd=test_file)

    # create LAYERS.json in root of build to make it obvious which layers are
    # currently in use.
    shutil.copy(paths["json_src"], paths["json_dst"])

    # copy local_type.conf -> local.conf
    shutil.copy(paths["local_conf_src"], paths["local_conf_dst"])

    # generate environment.sh
    shutil.copy(paths["env_src"], paths["env_dst"])
    os.chmod(paths["env_dst"],
             stat.S_IRWXU | stat.S_IRWXG | stat.S_IROTH | stat.S_IWOTH)
    for line in fileinput.input(paths["env_dst"], inplace=1):
        line = re.sub("@sources@", paths.getitem_rel("src_dir"), line.rstrip())
        print(line)

    # copy build script
    shutil.copy(paths["build_src"], paths["build_dst"])
    os.chmod(paths["build_dst"],
             stat.S_IRWXU | stat.S_IRWXG | stat.S_IROTH | stat.S_IWOTH)

    return

def fetch_repos(args):
    """ Clone repos and set them to the state described by the LAYERS.json file
    """
    update = args.update
    try:
        paths = PathSanity(args.top_dir)
        paths["src_dir"] = args.src_dir
        paths.setitem_strict("json_in", args.json_in)
    except ValueError as e:
        print(e)
        sys.exit(1)

    # Parse JSON file with repo data
    with open(paths["json_in"], 'r') as repos_fd:
        while True:
            try:
                repos = JSONDecoder(object_hook=Repo.repo_decode).decode(repos_fd.read())
                fetcher = RepoFetcher(paths["src_dir"], repos=repos)
            except ValueError:
                break;

    if not os.path.exists(paths["src_dir"]):
        os.mkdir(paths["src_dir"])

    try:
        if not update:
            fetcher.clone()
        else:
            fetcher.update()
    except EnvironmentError as e:
        print(e)
        sys.exit(1)

def main():
    description = "Manage OE build infrastructure."
    repos_json_help = "A JSON file describing the state of the repos."
    action_help = "An action to perform on the build directory."
    bblayers_help = "Path to the bblayer.conf file."
    conf_dir_help = "Directory where all local bitbake configs live."
    manifest_help = "Generate tarball for reproducing build."
    setup_help = "Setup the OE build directory. This includes cloning the " \
            "repos from the JSON file and creating the bblayers.conf " \
            "file."
    source_dir_help = "Checkout git repos into this directory."
    top_dir_help = "Root of build directory. This is TOPDIR in OE. Defaults " \
            "to the current working directory."
    build_type_help = "The type of the build to setup."
    json_gen_help = "Parse bblayers.conf and git repos in source dir to generate JSON file describing the build."
    json_out_help = "File to write JSON representation of the build state to."
    archive_file_help = "Prefix for build archive file name."
    layers_file_help = "File it write LAYERS representation of the build state to."
    layers_gen_help = "Parse git repos in source dir to generate LAYERS file describing the build."
    build_op_data_help = "Path to directory containing data for use by " + __file__

    parser = argparse.ArgumentParser(prog=__file__, description=description)
    actionparser = parser.add_subparsers(help=action_help)
    # parser for 'setup' action
    setup_parser = actionparser.add_parser("setup", help=setup_help)
    setup_parser.add_argument("-b", "--build-type", default="oe-core", help=build_type_help)
    setup_parser.add_argument("-t", "--top-dir", default=os.getcwd(), help=top_dir_help)
    setup_parser.add_argument("-s", "--src-dir", default="sources", help=source_dir_help)
    setup_parser.add_argument("-d", "--build-op-data", default="build_op_data", help=build_op_data_help)
    setup_parser.set_defaults(func=setup)
    # parser for 'manifest' action
    manifest_parser = actionparser.add_parser("manifest", help=manifest_help)
    manifest_parser.add_argument("-s", "--src-dir", default="sources", help=source_dir_help)
    manifest_parser.add_argument("-t", "--top-dir", default=os.getcwd(), help=top_dir_help)
    manifest_parser.add_argument("-a", "--archive", default="archive.tar.bz2", help=archive_file_help)
    manifest_parser.set_defaults(func=manifest)
    # parser for 'json-refresh' action
    jsongen_parser = actionparser.add_parser("json-gen", help=json_gen_help)
    jsongen_parser.add_argument("-s", "--src-dir", default="sources", help=source_dir_help)
    jsongen_parser.add_argument("-t", "--top-dir", default=os.getcwd(), help=top_dir_help)
    jsongen_parser.add_argument("-j", "--json-out", default="LAYERS.json", help=json_out_help)
    jsongen_parser.set_defaults(func=json_gen)
    # generate LAYERS file from current state
    layersgen_parser = actionparser.add_parser("layers-gen", help=layers_gen_help)
    layersgen_parser.add_argument("-s", "--src-dir", default="sources", help=source_dir_help)
    layersgen_parser.add_argument("-t", "--top-dir", default=os.getcwd(), help=top_dir_help)
    layersgen_parser.add_argument("-l", "--layers-file", default="LAYERS", help=layers_file_help)
    layersgen_parser.add_argument("-b", "--bblayers-file", default="conf/bblayers.conf", help=bblayers_help)
    layersgen_parser.set_defaults(func=layers_gen)
    # Fetch repos and set their state to match the specification in the JSON
    # file
    fetch_help = "Fetch repos and set them to the state defined in JSON file."
    fetch_update_help = "Update existing repos if necessary. Use carefully."
    fetch_parser = actionparser.add_parser("fetch", help=fetch_help)
    fetch_parser.add_argument("-s", "--src-dir", default="sources", help=source_dir_help)
    fetch_parser.add_argument("-t", "--top-dir", default=os.getcwd(), help=top_dir_help)
    fetch_parser.add_argument("-j", "--json-in", default="LAYERS.json", help=repos_json_help)
    fetch_parser.add_argument("-u", "--update", action="store_true", default=False, help=fetch_update_help)
    fetch_parser.set_defaults(func=fetch_repos)

    args = parser.parse_args()
    args.func(args)

    return 

if __name__ == '__main__':
    main()

