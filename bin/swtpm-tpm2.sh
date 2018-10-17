#!/usr/bin/env sh

TMPDIR="${1:-/tmp/swtpm2}"
mkdir -p ${TMPDIR}
swtpm socket --tpm2 --tpmstate dir=${TMPDIR} --ctrl type=unixio,path=${TMPDIR}/tpm-sock --log level=20 2>&1 | tee ${TMPDIR}/swtpm.log
