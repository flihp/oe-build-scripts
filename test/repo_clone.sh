#!/bin/sh

if [ -f ./functions.sh ]; then
    . ./functions.sh
else
    echo "missing function library"
    exit 1
fi

# setup
# create empty repo
REPO_DIR=repo_clone.git
REPO_TMP=repo_clone_tmp
repo_init ${REPO_DIR} ${REPO_TMP}
# add a test file & commit
echo "test" | { repo_commit ${REPO_TMP} test_file; }
rm -rf ${REPO_TMP}

# test
PYTHONPATH+=../ python ./repo_clone.py --name="repo_clone_test" \
    --url="${REPO_DIR}" --branch="master" --revision="head"
if [ $? -ne 0 ]; then
    exit $?
fi

# tear down
rm -rf ./repo_clone_test
rm -rf ${REPO_DIR}
