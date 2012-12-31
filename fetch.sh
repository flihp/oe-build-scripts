#!/bin/sh

METAS="git://github.com/flihp/meta-measured.git"

# setup submodules
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

# clone meta layers directly from URIs
for meta in ${METAS}; do
    git clone ${meta}
done
