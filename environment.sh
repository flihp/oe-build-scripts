#!/bin/sh
    
BDIR=$(readlink -f `dirname ./`)
METAS=${BDIR}/metas
export PATH=$METAS/oe-core/scripts:$BDIR/bitbake/bin:$PATH
