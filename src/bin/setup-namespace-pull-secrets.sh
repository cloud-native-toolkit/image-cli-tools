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

if [[ -z "$1" ]]; then
   echo "CLUSTER_NAMESPACE should be provided as first argument"
   exit 1
else
   CLUSTER_NAMESPACE="$1"
fi

echo "*** Copying pull secrets from default namespace to ${CLUSTER_NAMESPACE} namespace"

kubectl get secrets -n default | grep icr | sed "s/\([A-Za-z-]*\) *.*/\1/g" | while read default_secret; do
    kubectl get secret ${default_secret} -o yaml | sed "s/default/${CLUSTER_NAMESPACE}/g" | kubectl -n ${CLUSTER_NAMESPACE} create -f -
done

echo "*** Adding secrets to serviceaccount/default in ${CLUSTER_NAMESPACE} namespace"

EXISTING_SECRETS=$(kubectl describe serviceaccount/default -n "${CLUSTER_NAMESPACE}" | grep "Image pull secrets:" | sed -E "s/Image pull secrets: +([^ ]+) */\1/g")

if [[ "${EXISTING_SECRETS}" == "<none>" ]]; then
    PULL_SECRETS=$(kubectl get secrets -n "${CLUSTER_NAMESPACE}" -o jsonpath='{ range .items[*] }{ "{\"name\": \""}{ .metadata.name }{ "\"}\n" }{ end }' | grep icr | paste -sd "," - | sed -E "s/(.*)/[\1]/g")
    kubectl patch -n "${CLUSTER_NAMESPACE}" serviceaccount/default -p "{\"imagePullSecrets\": ${PULL_SECRETS}}"
else
    kubectl get secrets -n "${CLUSTER_NAMESPACE}" -o jsonpath='{ range .items[*] }{ "{\"name\": \""}{ .metadata.name }{ "\"}\n" }{ end }' | grep icr | while read secret; do
        kubectl patch -n "${CLUSTER_NAMESPACE}" serviceaccount/default --type='json' -p="[{\"op\":\"add\",\"path\":\"/imagePullSecrets/-\",\"value\":${secret}]"
    done
fi
