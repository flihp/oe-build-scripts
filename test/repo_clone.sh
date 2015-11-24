#!/bin/sh

if [ -f ./functions.sh ]; then
    . ./functions.sh
else
    echo "missing function library"
    exit 1
fi

# setup
# create empty repo
BASE=$(echo "$0" | sed 's&^\(.*\)\.sh&\1&')
REPO_DIR=${BASE}.git
REPO_TMP=${BASE}_tmp
REPO_NAME=${BASE}_test

repo_init ${REPO_DIR} ${REPO_TMP}
# add a test file & commit
echo "test" | { repo_commit ${REPO_TMP} test_file; }
rm -rf ${REPO_TMP}

# test
PYTHONPATH+=../ python ./repo_clone.py --name="${REPO_NAME}" \
    --url="${REPO_DIR}" --branch="master" --revision="head"
if [ $? -ne 0 ]; then
    exit $?
fi

# tear down
rm -rf ${REPO_NAME} ${REPO_DIR}
