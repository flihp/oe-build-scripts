#!/bin/sh

for dir in meta-selinux openembedded-core bitbake; do
    if [ ! -d $dir/.git ]; then
        git submodule init $dir
        git submodule update $dir
    fi

    if [ "$1" = "update" ]; then
        (cd $dir && git checkout master && git pull origin master)
    fi
done
