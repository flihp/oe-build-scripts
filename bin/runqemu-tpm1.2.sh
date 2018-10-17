#!/usr/bin/env sh

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path/to/rootfs"
fi
ROOTFS="$1"
TMPDIR="${2:-/tmp/swtpm1.2}"
runqemu nographic slirp \
    qemuparams="-chardev 'socket,id=chrtpm0,path=${TMPDIR}/tpm-sock' -tpmdev 'emulator,id=tpm0,chardev=chrtpm0' -device 'tpm-tis,tpmdev=tpm0'" \
    ${ROOTFS}
