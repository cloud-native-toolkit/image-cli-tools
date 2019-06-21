#!/usr/bin/env bash

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

SCRIPT_DIR=$(realpath $(basename $0))

IMAGE_NAME="$1"
IMAGE_VER="$2"
if [[ -n "$3" ]]; then
    IMAGE_BRANCH="-$3"
fi

if [[ -z "${IMAGE_NAME}" ]] || [[ -z "${IMAGE_VER}" ]]; then
   echo "Required input is missing"
   echo "Usage: $0 IMAGE_NAME IMAGE_VER [IMAGE_BRANCH]"
   exit 1
fi

echo "Testing ${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}"

docker run -v ${SCRIPT_DIR}/..:/image -v /var/run:/var/run gcr.io/gcp-runtimes/container-structure-test:latest \
  test --image ${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH} --config /image/config.yaml --save
