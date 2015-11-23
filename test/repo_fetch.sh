#!/bin/sh

if [ -f ./functions.sh ]; then
    . ./functions.sh
else
    echo "missing function library"
    exit 1
fi

BASE=$(echo "$0" | sed 's&^\(.*\)\.sh&\1&')
REPO_DIR=${BASE}.git
REPO_TMP=${BASE}_tmp
REPO_NAME=${BASE}_test

# setup
# create empty repo
repo_init ${REPO_DIR} ${REPO_TMP}
# add a test file & commit
echo "test" | { repo_commit ${REPO_TMP} test_file; }

# we need to clone the test repo before we can fetch updates
PYTHONPATH+=../ python ./repo_clone.py --name="${REPO_NAME}" \
    --url="${REPO_DIR}" --branch="master" --revision="head"
if [ $? -ne 0 ]; then
    exit $?
fi

echo "test2" | { repo_commit ${REPO_TMP} test_file; }
PYTHONPATH+=../ python ./repo_fetch.py --name="${REPO_NAME}" \
    --url="${REPO_DIR}" --branch="master" --revision="head"
if [ $? -ne 0 ]; then
    exit $?
fi

# test for success
git --git-dir=${REPO_NAME}/${REPO_NAME}/.git --work-tree=${REPO_NAME}/${REPO_NAME} status | grep "^Your branch is behind 'origin/master' by 1 commit, and can be fast-forwarded\.$"
if [ $? -ne 0 ]; then
    exit $?
fi
# tear down
rm -rf ${REPO_TMP} ${REPO_NAME} ${REPO_DIR}
