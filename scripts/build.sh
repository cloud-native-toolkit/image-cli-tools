#!/usr/bin/env bash

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

echo "Building ${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}"

docker build -t ${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH} .
