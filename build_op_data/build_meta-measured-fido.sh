#!/bin/bash
    
. ./environment.sh
{ time bitbake measured-image-bootimg; } 2>&1 | tee build.log
exit ${PIPESTATUS[0]}

