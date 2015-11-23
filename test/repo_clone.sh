#!/bin/sh

# setup
# create empty repo
REPO_DIR=repo_clone.git
REPO_TMP=repo_clone_tmp
mkdir ${REPO_DIR}
git init --bare ${REPO_DIR}
git clone ${REPO_DIR} ${REPO_TMP}
# add a test file & commit
touch ${REPO_TMP}/tmp
git --git-dir=${REPO_TMP}/.git --work-tree=${REPO_TMP} add tmp
git --git-dir=${REPO_TMP}/.git --work-tree=${REPO_TMP} commit --all --message "test commit for checkout"
git --git-dir=${REPO_TMP}/.git --work-tree=${REPO_TMP} push origin master
rm -rf ${REPO_TMP}

# test
PYTHONPATH+=../ python ./repo_clone.py
if [ $? -ne 0 ]; then
    exit $?
fi

# tear down
rm -rf ./repo_clone_test
rm -rf ${REPO_DIR}
