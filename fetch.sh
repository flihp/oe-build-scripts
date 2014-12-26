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

# put a single repo into the specified state
# state is determined by 'object':
#  We clone the repo and set 'HEAD' to the specified object.
# If object is a branch and the repo is already cloned we fetch and try to
#  advance the branch to the latest if possible.
# Aim to be conservative: bail if there are local changes, only advance
#  branches if fastforward is possible.
fetch_repo () {
    local name="${1}"
    local url="${2}"
    local branch="${3:-master}"
    local rev="${4:-HEAD}"
    local worktree=${name}
    local gitdir=${name}/.git

    if [ -z "${url}" ]; then
        echo "fetch_repo: no URL provided"
        return 1
    fi
    if [ ! -d ${name} ]; then
        echo "Cloning from repo: ${name}"
        if ! dryrun_cmd git clone --progress ${url} ${name}; then
            return 1
        fi
    else
        echo "Fetching repo: ${name}"
        if ! dryrun_cmd git --git-dir=${gitdir} --work-tree=${worktree} fetch --progress; then
            return 2
        fi
    fi

    if ! dryrun_cmd git --git-dir=${gitdir} --work-tree=${worktree} checkout ${branch}; then
        return 3
    fi
    if ! dryrun_cmd git --git-dir=${gitdir} --work-tree=${worktree} reset --hard ${rev}; then
        return 4
    fi
}

# Iterate over LAYERS file processing each line.
# We treat 'bitbake' special and process it from the build root. All other
#  repos are assumed to be meta layers and we process those in the METAS_DIR.
fetch_repos () {
    [ ! -f ./LAYERS ] && return 0
    local thisdir=$(pwd)
    cat ./LAYERS | \
        grep -v '^\([[:space:]]*$\|[[:space:]]*#\)' | \
        while read name url branch rev;
    do
        if [ -z ${url} ] | [ -z ${name} ]; then
            echo "ERROR: format error in LAYERS file."
            exit 1
        fi
        if [ ! -d ${METAS_DIR} ]; then
            mkdir -p ${METAS_DIR}
        fi
        cd ${METAS_DIR}
        if [ ! -z "${GIT_MIRROR}" ]; then
            url=$(echo ${url} | sed -n "s&^.*/\([0-9A-Za-z_-]\+\(\.git\)\?\)$&${GIT_MIRROR}/\1&p")
        fi
        if ! fetch_repo "${name}" "${url}" "${branch}" "${rev}"; then
            echo "ERROR: Failed to fetch repo from ${url}"
            exit 1
        fi
        cd ${thisdir}
    done
}

fetch_repos
