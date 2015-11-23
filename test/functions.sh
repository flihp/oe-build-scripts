# initialize an empty repo and check it out into a temp directory
repo_init () {
    local REPO_DIR=$1
    local REPO_TMP=$2

    mkdir ${REPO_DIR}
    git init --bare ${REPO_DIR}
    git clone ${REPO_DIR} ${REPO_TMP}
}

# write a file in a git work-tree 
repo_commit () {
    local REPO_TMP=$1
    local FILE=$2
    local BRANCH=${3:master}

    while read LINE; do
        echo ${LINE}
    done > ${REPO_TMP}/${FILE}

    git --git-dir=${REPO_TMP}/.git --work-tree=${REPO_TMP} add ${FILE}
    git --git-dir=${REPO_TMP}/.git --work-tree=${REPO_TMP} commit --all \
        --message "test commit"
    git --git-dir=${REPO_TMP}/.git --work-tree=${REPO_TMP} push origin ${BRANCH}
}
