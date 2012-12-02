#!/bin/sh
    
BDIR=`readlink -f \`dirname $0\``
export PATH=$BDIR/openembedded-core/scripts:$BDIR/bitbake/bin:$PATH
