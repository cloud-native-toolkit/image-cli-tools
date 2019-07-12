#!/usr/bin/env bash

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

SCRIPT_DIR=$(realpath $(dirname $0))

ORG=$(cat ${SCRIPT_DIR}/package.json | grep '"org"' | sed -E "s/.*\"org\": \"(.*)\".*/\1/g")
IMAGE_NAME=$(cat ${SCRIPT_DIR}/package.json | grep '"name"' | sed -E "s/.*\"name\": \"(.*)\".*/\1/g")
IMAGE_VER=$(cat ${SCRIPT_DIR}/package.json | grep '"version"' | sed -E "s/.*\"version\": \"(.*)\".*/\1/g")
BRANCH=$(cat ${SCRIPT_DIR}/package.json | grep '"branch"' | sed -E "s/.*\"version\": \"(.*)\".*/\1/g")

IMAGE="${ORG}/${IMAGE_NAME}:${IMAGE_VER}"
if [[ -z "${BRANCH}" ]]; then
    IMAGE="${IMAGE}-${BRANCH}"
fi

docker run -it ${IMAGE}
