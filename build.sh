#!/bin/sh
    
. ./environment.sh
{ time bitbake core-image-minimal; } 2>&1 | tee build.log
