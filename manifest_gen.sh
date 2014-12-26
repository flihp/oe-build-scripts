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
head_rev () {
    local dir=$1
    if [ ! -d ${dir} ]; then
        return 1
    fi
    if [ ! -d ${dir}/.git ]; then
        return 2
    fi
    git --git-dir=${dir}/.git show HEAD | head -n 1 | awk '{print $2}'
}

repo_branch () {
    local dir=${1}
    if [ ! -d ${dir} ]; then
        return 1
    fi
    if [ ! -d ${dir}/.git ]; then
        return 2
    fi
    git --git-dir=${dir}/.git branch | grep '^\*' | awk '{ print $2 }'
}
# Get URL of the current remote (the one your current branch tracks).
# Make second parameter 'follow' to indicate you want to follow local file://
# remotes till you hit a network remote.
repo_url () {
    local dir=${1#file://}

    # we get something that isn't a local file path we're done
    if echo ${dir} | grep -q '^[^:]\+:\/\/'; then
        echo "${dir}"
        exit 0
    fi
    # find the git dir
    if git --git-dir="${dir}" remote > /dev/null 2>&1; then
        # noop
        dir="${dir}"
    elif git --git-dir="${dir}/.git" remote > /dev/null 2>&1; then
        dir="${dir}/.git"
    elif git --git-dir="${dir}.git" remote > /dev/null 2>&1; then
        dir="${dir}.git"
    else
        return 1
    fi

    # get URL for remote
    local remote=$(git --git-dir=${dir} branch -vv| sed -n 's&^\*\(.*\)*\[\(.*\)\/.*\].*$&\2&p')
    local remote_url=$(git --git-dir=${dir} remote -v | grep "^${remote}.*fetch)$" | awk '{print $2}')

    if [ "follow" = "$2" ]; then
        repo_url ${remote_url} follow
    else
        echo ${remote_url}
    fi
    return $?
}

process_repo () {
    local dir=${1}
    local name=${2}

    if [ -z ${dir} ]; then
        echo "No directory specified"
        return 1
    fi
    if [ -z ${name} ]; then
        name=$(basename $(realpath ${dir}))
    fi

    url=$(repo_url ${dir} follow)
    if [ $? -ne 0 ]; then
        echo "Failed to get URL for: ${name}"
        return 1
    fi
    branch=$(repo_branch ${dir})
    if [ $? -ne 0 ]; then
        echo "Failed to get branch name for: ${name}"
        return 1
    fi
    rev=$(head_rev ${dir})
    if [ $? -ne 0 ]; then
        echo "Failed to get HEAD rev for: ${name}"
        return 1
    fi
    echo "${name} ${url} ${branch} ${rev}"
}

process_repos () {
    ls -1 metas | while read DIR; do
        process_repo metas/${DIR}
    done
}

process_repos
