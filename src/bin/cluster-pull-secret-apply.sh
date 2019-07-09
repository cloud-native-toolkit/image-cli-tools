#!/usr/bin/env bash

if [[ -z "${KUBECONFIG}" ]]; then
  if [[ -z "${APIKEY}" ]] || [[ -z "${RESOURCE_GROUP}" ]] || [[ -z "${REGION}" ]]; then
    echo "Either KUBECONFIG or APIKEY, RESOURCE_GROUP, and REGION are required"
    exit 1
  fi

  if [[ -z "${CLUSTER_NAME}" ]]; then
    CLUSTER_NAME="${RESOURCE_GROUP}-cluster"
  fi

  if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR="./.tmp"
  fi

  mkdir -p "${TMP_DIR}"

  ibmcloud config --check-version=false

  ibmcloud login --apikey ${APIKEY} -g ${RESOURCE_GROUP} -r ${REGION}
  ibmcloud ks cluster-config --cluster ${CLUSTER_NAME} --export > ${TMP_DIR}/.kubeconfig

  source ${TMP_DIR}/.kubeconfig
else
  if [[ -z "${CLUSTER_NAME}" ]]; then
    if [[ -z "${RESOURCE_GROUP}" ]]; then
      RESOURCE_GROUP=$(ibmcloud target | grep "Resource group" | sed -E "s/Resource group: +([^ ]+) +/\1/g")
    fi

    CLUSTER_NAME="${RESOURCE_GROUP}-cluster"
  fi
fi

echo "Applying pull secrets to cluster: ${CLUSTER_NAME}"

ibmcloud ks cluster-pull-secret-apply --cluster "${CLUSTER_NAME}"
