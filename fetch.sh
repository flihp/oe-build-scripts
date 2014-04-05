#!/bin/sh

METAS_DIR=${METAS_DIR:-./metas}

# setup submodules
fetch_submodules() {
    [ ! -f ./.gitmodules ] && return 0
    grep 'submodule[[:space:]]*\".*\"]' ./.gitmodules \
	| sed -e 's&\[submodule\s\+\"\(.*\)\"\]&\1&' \
	| while read dir; do
	echo "submodule: ${dir}"
	if [ ! -d $dir/.git ]; then
            git submodule init $dir
            git submodule update $dir
	fi
	
	if [ "$1" = "update" ]; then
            (cd $dir && git checkout master && git pull origin master)
	fi
    done
}

fetch_repo () {
    url="${1}"
    branch="${2:-master}"
    repo_name='^.*\/\([A-Za-z_\-]\+\)\(\.git\)\?$'
    branch_name='^[[:space:]]\?\(\*\)[[:space:]]\+\([A-Za-z0-9_\-\.]\+\)[[:space:]]*$'
    name=$(echo "${url}" | sed -n "s&${repo_name}&\1&p")
    ret=0

    # fresh clone
    if [ ! -d ${name} ]; then
        echo "Cloning ${branch} from repo: ${name}"
        git clone --branch ${branch} ${url} ${name}
        return $?
    fi

    # pull existing
    thisdir=$(pwd)
    cd ${name}
    if git status | grep -q 'nothing to commit (working directory clean)'; then
        tmp_name=$(git branch | sed -n "s&${branch_name}&\2&p")
        if [ "${tmp_name}" = "${branch}" ]; then
            echo "${name}: Pulling branch ${branch} --ff-only ..."
            git pull --ff-only
            ret=$?
        else
            echo "Git repo ${name} is on ${tmp_name} branch, this disagrees with LAYERS file. Not pulling."
            ret=1
        fi
    else
        echo "Working dir for meta layer ${name} is dirty: not pulling."
        ret=1
    fi
    cd ${thisdir}

    return ${ret}
}

# clone meta layers directly from URIs
fetch_repos () {
    [ ! -f ./LAYERS ] && return 0
    . ./LAYERS
    echo "${BITBAKE}" | while read -r url branch; do
        if [ -z ${url} ]; then
            echo "ERROR: BITBAKE must be set in LAYERS."
            exit 1
        fi
        fetch_repo "${url}" "${branch}"
    done
    if [ ! -d ${METAS_DIR} ]; then mkdir ${METAS_DIR}; fi
    thisdir=$(pwd)
    cd ${METAS_DIR}
    echo "${METAS}" | while read -r url branch; do
        if [ ! -z ${url} ]; then
            fetch_repo "${url}" "${branch}"
        fi
    done
    cd ${thisdir}
}

if [ ! -f ./.gitmodules ] && [ ! -f ./LAYERS ]; then
    echo "ERROR: Need some gitmodules or layers to clone."
    exit 1
fi

fetch_submodules
fetch_repos
