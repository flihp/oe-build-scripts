#!/bin/sh

# Script to generate a manifest describing the current state of the git
# repositories used for this build. This script should be run after the fetch
# script (need to have the git repos to know their state) but before the build
# script. You can think of this script as saving a snapshot of the git repos
# in this build that can be used at a later date to recreate the same build.

if [ -f fetch.conf ]; then
    . ./fetch.conf
fi

# get object hash of wherever HEAD is
head_hash () {
    local dir=$1
    if [ ! -d ${dir} ]; then
        return 1
    fi
    if [ ! -d ${dir}/.git ]; then
        return 2
    fi
    git --git-dir=${dir}/.git show HEAD | head -n 1 | awk '{print $2}'
}
# Get URL of the current remote (the one your current branch tracks).
# Make last parameter 'follow' to indicate you want to follow local file://
# remotes till you hit a network remote.
repo_url () {
    local dir=${1#file://}
    if [ -d "${dir}/.git" ]; then
        dir="${dir}/.git"
    fi
    local remote=$(git --git-dir=${dir} branch -vv| sed -n 's&^\*\(.*\)*\[\(.*\)\/.*\].*$&\2&p')
    local remote_url=$(git --git-dir=${dir} remote -v | grep "^${remote}.*fetch)$" | awk '{print $2}')

    # for local directories strip prefix and append '.git' if necessary
    remote_url=${remote_url#file://}
    if [ ! -d ${remote_url} ] && [ -d ${remote_url}.git ]; then
        remote_url="${remote_url}.git"
    fi

    if [ "follow" = "$2" ] && [ -d ${remote_url} ]; then
        repo_url ${remote_url} follow
    else
        # add prefix back just for consistency
        if [ -d ${remote_url} ]; then
            remote_url="file://${remote_url}"
        fi
        echo ${remote_url}
    fi
}

process_repos () {
    build_obj=$(head_hash ./)
    if [ $? -ne 0 ]; then
        echo "Failed to get HEAD object for build scripts repo"
        exit 1
    fi
    build_url=$(repo_url ./ follow)
    echo "oe-build-scripts ${build_url} ${build_obj}"
    bitbake_obj=$(head_hash ./bitbake)
    if [ $? -ne 0 ]; then
        echo "Failed to get HEAD oject for bitbake repo"
        exit 1
    fi
    bitbake_url=$(repo_url ./bitbake follow)
    echo "bitbake ${bitbake_url} ${bitbake_obj}"
    ls -1 metas | while read DIR; do
        rel_path=metas/${DIR}
        meta_obj=$(head_hash ${rel_path})
        if [ $? -ne 0 ]; then
            echo "Failed to get HEAD hash for meta layer ${rel_path}"
            exit 1
        fi
        meta_url=$(repo_url ${rel_path} follow)
        echo "${DIR} ${meta_url} ${meta_obj}"
    done
}

process_repos
