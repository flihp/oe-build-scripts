#!/bin/sh

# clean env and add OE stuff
. /etc/profile
METAS=$(readlink -f `dirname ./`)/metas
export PATH=${METAS}/openembedded-core/scripts:${METAS}/bitbake/bin:$PATH
