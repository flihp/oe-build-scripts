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
TEST_PY=${BASE}.py
JSON_IN=data/simple.json
JSON_OUT=${BASE}.json

# round trip LAYERS file through Repo serialization
PYTHONPATH+=../ python ./${TEST_PY} --json-in=${JSON_IN} --json-out=${JSON_OUT}
if [ $? -ne 0 ]; then
    exit 1
fi
if ! diff ${JSON_IN} ${JSON_OUT};  then
    exit 2
fi

# tear down
rm -rf ${JSON_OUT}
