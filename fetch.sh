#!/bin/sh

# config file to store variables. Only makes sense to set GIT_MIRROR really
# If GIT_MIRROR is set in conf file it should be a url to the basedir where
#  this script should look for git repos.
# example: if your LAYERS file has a url like git://github.com/foo/repo.git
#  and you set GIT_MIRROR to file:///var/lib/git then this script will fetch
#  from file:///var/lib/git/repo.git
if [ -f fetch.conf ]; then
    . ./fetch.conf
fi

GIT_MIRROR=${GIT_MIRROR:-""}
METAS_DIR=${METAS_DIR:-./metas}

usage () {
    cat <<EOF
usave: $0 [-d] [-h]
EOF
}

help_out () {
    usage
    cat <<EOF
Options
-d: druy run, shows commands being executed but does not 'fetch' anything.
-h: show help text
EOF
}

while getopts "dh" OPTION
do
    case $OPTION in
        d)
            DRYRUN=true
            ;;
        h)
            help_out
            exit 0
            ;;
    esac
done

if [ ! -f ./LAYERS ]; then
    echo "ERROR: Need a LAYERS file to clone."
    exit 1
fi

# if DRYRUN is specified echo the command, don't actually execute it
dryrun_cmd () {
    if [ -z "${DRYRUN}" ]; then
        $@
    else
        echo "dryrun: not executing command"
        echo "    \"$@\""
    fi
    return $?
}

# no output but $? is set to 0 if specified object is a branch name
is_obj_branch () {
    local object=${1}
    local git_dir=${2:-./.git}

    git --git-dir=${git_dir} branch -a | grep -q "^\(\*\)\?[[:space:]]*remotes/origin/${object}[[:space:]]*$"
}

# no output but $? is set to 0 if specified object is a tag
is_obj_tag () {
    local object=${1}
    local git_dir=${2:-./.git}

    git --git-dir=${git_dir} tag -l | grep -q "${object}"
}

# no output but $? is set to 0 if specified object is a hash
is_obj_hash () {
    local object=${1}

    echo ${1} | grep -q '[0-9a-f]\{5,40\}'
}

# returns current branch name on stdout
current_branch () {
    local git_dir=${1:-./.git}

    git --git-dir=${git_dir} branch | sed -n "s&^\(\*\)[[:space:]]*\(.*\)[[:space:]]*$&\2&p"
}

# returns the commit pointed to by a tag on stdout
tag_to_hash () {
    local object=${1}
    local git_dir=${2:-./.git}

    git --git-dir=${git_dir} rev-list ${object} | head -n 1
}

# returns the commit pionted to by HEAD on stdout
get_head_hash () {
    local git_dir=${1:-./.git}

    git --git-dir=${git_dir} show | head -n 1 | awk '{print $2}'
}

# put a single repo into the specified state
# state is determined by 'object':
#  We clone the repo and set 'HEAD' to the specified object.
# If object is a branch and the repo is already cloned we fetch and try to
#  advance the branch to the latest if possible.
# Aim to be conservative: bail if there are local changes, only advance
#  branches if fastforward is possible.
fetch_repo () {
    url="${1}"
    object="${2:-master}"
    repo_name='^.*\/\([A-Za-z_\-]\+\)\(\.git\)\?$'
    name=$(echo "${url}" | sed -n "s&${repo_name}&\1&p")
    # object from user is branch or not
    # assume all branches specified by user are on the origin
    git branch -a | grep -q "^\(\*\)\?[[:space:]]*remotes/origin/${object}[[:space:]]*$"
    is_branch=$?

    # Make sure the repo is in a reasonable state
    # if it doesn't exist just clone it
    if [ ! -d ${name} ]; then
        echo "Cloning from repo: ${name}"
        dryrun_cmd git clone --progress ${url} ${name}
        if [ $? -ne 0 ]; then
            return $?
        fi
    fi

    local thisdir=$(pwd)
    if [ ! -e ${name} ]; then
        mkdir ${name}
    fi
    cd ${name}
    # an extra fetch is redundant for new clones but it doesn't hurt
    dryrun_cmd git fetch --progress
    if [ ${is_branch} -eq 0 ]; then
        # object is a branch: check it out
        dryrun_cmd git checkout ${object}
        if [ $? -ne 0 ]; then
            cd ${thisdir}
            return $?
        fi
        # and pull w/o merge
        dryrun_cmd git pull --ff-only --progress
        if [ $? -ne 0 ]; then
            cd ${thisdir}
            return $?
        fi
    else
        # not a branch: just reset hard to the object
        dryrun_cmd git reset --hard ${object}
        if [ $? -ne 0 ]; then
            cd ${thisdir}
            return $?
        fi
    fi
    cd ${thisdir}
}

# error checking for buildscript repo
# we change nothing about the state of this repo, only fail if it disagrees
#  with the manifest
handle_buildscripts () {
    local name=${1}
    local url=${2}
    local object=${3:-master}

    # if object is a hash make sure HEAD points to that hash, else fail
    if is_obj_hash ${object}; then
        if [ "$(get_head_hash)" != "${object}" ]; then
            echo "Manifest wants oe-build-scripts HEAD to be on ${object} but it's currently on $(get_head_hash). Please sort this out before running this script."
            exit 1
        fi
        return 0
    fi
    # if object is a tag make sure HEAD points to the same commit
    if is_obj_tag ${object}; then
        if [ "$(get_head_hash)" != "$(tag_to_hash ${object})" ]; then
            echo "Manifest wants oe-build-scripts HEAD to be on ${object} but it's currently on $(get_head_hash). Please sort this out before running this script."
            exit 1
        fi
        return 0
    fi
    # if buildscripts should be on a branch fail if it's not
    if is_obj_branch ${object}; then
        if [ "${object}" != "$(current_branch)" ]; then
            echo "oe-build-scripts: Current branch is $(current_branch) but manifest wants us on ${object}. Please sort this out before running this script."
            exit 1
        fi
        return 0
    fi
    # fallthrough: if we get here the object is invalid
    echo "oe-build-scripts: Object from manifest: \"${object}\" isn't a branch, tag or commit hash? Check to be sure the manifest isn't corrupt."
    exit 1
}
# Iterate over LAYERS file processing each line.
# We treat 'bitbake' special and process it from the build root. All other
#  repos are assumed to be meta layers and we process those in the METAS_DIR.
fetch_repos () {
    [ ! -f ./LAYERS ] && return 0
    local thisdir=$(pwd)
    cat ./LAYERS | \
        grep -v '^\([[:space:]]*$\|[[:space:]]*#\)' | \
        while read name url branch;
    do
        if [ -z ${url} ] | [ -z ${name} ]; then
            echo "ERROR: format error in LAYERS file."
            exit 1
        fi
        # Build scripts repo is where this script lives so it must alredy be
        # checked out. We handle this repo separately because we don't change
        # it.
        if [ ${name} = "oe-build-scripts" ]; then
            handle_buildscripts ${name} ${url} ${branch}
        fi
        # we put bitbake in the top level dir
        # we put all other repos (meta-layers) in METAS_DIR
        if [ ${name} != "bitbake" ]; then
            if [ ! -d ${METAS_DIR} ]; then
                mkdir -p ${METAS_DIR}
            fi
            cd ${METAS_DIR}
        fi
        if [ ! -z "${GIT_MIRROR}" ]; then
            url=$(echo ${url} | sed -n "s&^.*/\([0-9A-Za-z_-]\+\(\.git\)\?\)$&${GIT_MIRROR}/\1&p")
        fi
        if ! fetch_repo "${url}" "${branch}"; then
            echo "ERROR: Failed to fetch repo from ${url}"
            exit 1
        fi
        cd ${thisdir}
    done
}

fetch_repos
