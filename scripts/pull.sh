#!/usr/bin/env bash

IMAGE_ORG="$1"
IMAGE_NAME="$2"
IMAGE_VER="$3"
if [[ -n "$4" ]]; then
    IMAGE_BRANCH="-$4"
fi

if [[ -z "${IMAGE_ORG}" ]] || [[ -z "${IMAGE_NAME}" ]] || [[ -z "${IMAGE_VER}" ]]; then
   echo "Required input is missing"
   echo "Usage: $0 IMAGE_ORG IMAGE_NAME IMAGE_VER [IMAGE_BRANCH]"
   exit 1
fi

echo "Pulling and tagging ${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}"

docker pull ${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}
docker tag ${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH} ${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}
