#!/bin/sh
    
BDIR=$(readlink -f `dirname ./`)
export PATH=$BDIR/openembedded-core/scripts:$BDIR/bitbake/bin:$PATH
