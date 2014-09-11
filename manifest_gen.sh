#!/bin/sh

# Script to generate a manifest describing the current state of the git
# repositories used for this build. This script should be run after the fetch
# script (need to have the git repos to know their state) but before the build
# script. You can think of this script as saving a snapshot of the git repos
# in this build that can be used at a later date to recreate the same build.

if [ -f fetch.conf ]; then
    . ./fetch.conf
fi

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
    local first_remote=$(git --git-dir=${dir}/.git remote -v | grep ${remote} | head -n 1 | awk '{print $2}')

    # If git dir origin remote is from the GIT_MIRROR we use the remote
    # from the mirror presumably to get the 'upstream'. If your mirroring
    # scheme is 2 levels deep or something crazy like that you're on your own.
    if echo "${first_remote}" | grep -q -i "${GIT_MIRROR}" && echo "${GIT_MIRROR}" | grep -q '^file://'; then
        local mirror_dir=$(echo "${first_remote}" | sed -n 's&^file://\(.*\)$&\1&p')
        if [ -d ${mirror_dir}/.git ]; then
            mirror_dir="${mirror_dir}/.git"
        fi
        git --git-dir=${mirror_dir} remote -v | grep ${remote} | head -n 1 | awk '{print $2}'
    else
        echo "${first_remote}"
    fi
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
