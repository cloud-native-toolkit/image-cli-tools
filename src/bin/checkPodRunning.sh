#!/usr/bin/env bash

NAME="$1"

if [[ -z "${NAME}" ]]; then
    echo "NAME not provided"
    exit 1
fi

if [[ "${NAME}" == "--help" ]]; then
    echo "Usage: ${0} {POD_NAME}"
    exit 1
fi

if [[ -z "${NAMESPACE}" ]]; then
    NAMESPACE="tools"
fi

if [[ -z "${KUBECONFIG}" ]]; then
    echo "KUBECONFIG not found. Attempting to log in"

    if [[ -z "${TMP_DIR}" ]]; then
        TMP_DIR=".tmp"
        mkdir -p ${TMP_DIR}
    fi

    echo "Logging in: ibmcloud login --apikey xxx -r ${REGION} -g ${RESOURCE_GROUP}"

    ibmcloud login --apikey "${APIKEY}" -r "${REGION}" -g "${RESOURCE_GROUP}"

    ibmcloud config --check-version=false
    ibmcloud ks cluster-config --cluster "${CLUSTER}" --export
    ibmcloud ks cluster-config --cluster "${CLUSTER}" --export > ${TMP_DIR}/.kubeconfig

    source ${TMP_DIR}/.kubeconfig
fi

POD_NAME=$(kubectl get pods -n ${NAMESPACE} | grep -m 1 "${NAME}" | sed -E "s/([a-zA-Z0-9-]+) +.*/\1/g")

STATUS=$(kubectl get pod/${POD_NAME} -n ${NAMESPACE} -o jsonpath="{ .status.phase }")

if [[ "Running" == "${STATUS}" ]]; then
    exit 0
else
    exit 1
fi
