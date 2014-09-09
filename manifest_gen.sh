#!/bin/sh

# Script to generate a manifest describing the current state of the git
# repositories used for this build. This script should be run after the fetch
# script (need to have the git repos to know their state) but before the build
# script. You can think of this script as saving a snapshot of the git repos
# in this build that can be used at a later date to recreate the same build.

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

repo_url () {
    local dir=$1
    local remote="$(git --git-dir=${dir}/.git remote)"

    git --git-dir=${dir}/.git remote -v | grep ${remote} | head -n 1 | awk '{print $2}'
}

process_repos () {
    build_obj=$(head_hash ./)
    if [ $? -ne 0 ]; then
        echo "Failed to get HEAD object for build scripts repo"
        exit 1
    fi
    build_url=$(repo_url ./)
    echo "oe-build-scripts ${build_url} ${build_obj}"
    bitbake_obj=$(head_hash ./bitbake)
    if [ $? -ne 0 ]; then
        echo "Failed to get HEAD oject for bitbake repo"
        exit 1
    fi
    bitbake_url=$(repo_url ./bitbake)
    echo "bitbake ${bitbake_url} ${bitbake_obj}"
    ls -1 metas | while read DIR; do
        rel_path=metas/${DIR}
        meta_obj=$(head_hash ${rel_path})
        if [ $? -ne 0 ]; then
            echo "Failed to get HEAD hash for meta layer ${rel_path}"
            exit 1
        fi
        meta_url=$(repo_url ${rel_path})
        echo "${DIR} ${meta_url} ${meta_obj}"
    done
}

process_repos
