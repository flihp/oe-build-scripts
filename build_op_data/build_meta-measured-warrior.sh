#!/bin/bash
    
. ./environment.sh
{
    time bitbake core-image-tpm;
} 2>&1 | tee build.log
exit ${PIPESTATUS[0]}

