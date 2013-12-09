#!/bin/sh
    
BDIR=$(readlink -f `dirname ./`)/src
export PATH=$BDIR/oe-core/scripts:$BDIR/bitbake/bin:$PATH
