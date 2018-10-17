#!/usr/bin/env sh

TMPDIR="${1:-/tmp/swtpm1.2}"
mkdir -p ${TMPDIR}
swtpm socket --tpmstate dir=${TMPDIR} --ctrl type=unixio,path=${TMPDIR}/tpm-sock --log level=20 2>&1 | tee ${TMPDIR}/swtmp.log
