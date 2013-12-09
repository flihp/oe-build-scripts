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

# clone meta layers directly from URIs
fetch_repos () {
    [ ! -f ./LAYERS ] && return 0
    . ./LAYERS
    echo "${BITBAKE}" | while read -r url branch; do
        if [ -z ${url} ]; then
            echo "ERROR: BITBAKE must be set in LAYERS."
            exit 1
        fi
        git clone --branch ${branch:-master} ${url}
    done
    echo "${METAS}" | while read -r url branch; do
        if [ ! -z ${url} ]; then
            [ ! -d ${METAS_DIR} ] && mkdir ${METAS_DIR}
            cd ${METAS_DIR}
            git clone --branch ${branch:-master} ${url}
            cd - > /dev/null
        fi
    done
}

if [ ! -f ./.gitmodules ] && [ ! -f ./LAYERS ]; then
    echo "ERROR: Need some gitmodules or layers to clone."
    exit 1
fi

fetch_submodules
fetch_repos
