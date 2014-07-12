#!/bin/sh

# clean env and add OE stuff
. /etc/profile
BDIR=$(readlink -f `dirname ./`)
METAS=${BDIR}/metas
export PATH=$METAS/oe-core/scripts:$BDIR/bitbake/bin:$PATH
