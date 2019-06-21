#!/usr/bin/env bash

IMAGE_ORG="$1"
IMAGE_NAME="$2"
IMAGE_VER="$3"
if [[ -n "$4" ]]; then
    IMAGE_BRANCH="-$4"
fi
NOT_LATEST="$5"

if [[ -z "${IMAGE_ORG}" ]] || [[ -z "${IMAGE_NAME}" ]] || [[ -z "${IMAGE_VER}" ]]; then
   echo "Required input is missing"
   echo "Usage: publish.sh IMAGE_ORG IMAGE_NAME IMAGE_VER [IMAGE_BRANCH] [NOT_LATEST]"
   exit 1
fi

echo "Tagging and pushing ${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}"

docker tag "${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}" "${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}"
docker push "${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}"

if [[ -z "$4" ]]; then
    LATEST="latest"
else
    LATEST="$4"
fi

if [[ -z "${NOT_LATEST}" ]]; then
    echo "Tagging and pushing ${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH} as ${IMAGE_ORG}/${IMAGE_NAME}:${LATEST}"
    docker tag "${IMAGE_NAME}:${IMAGE_VER}${IMAGE_BRANCH}" "${IMAGE_ORG}/${IMAGE_NAME}:${LATEST}"
    docker push "${IMAGE_ORG}/${IMAGE_NAME}:${LATEST}"
fi
