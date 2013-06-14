#!/bin/sh
    
BDIR=$(readlink -f `dirname ./`)
export PATH=$BDIR/oe-core/scripts:$BDIR/bitbake/bin:$PATH
