#!/usr/bin/env bash

helpFunction()
{
   echo ""
   echo "Usage: $0 BM_API_KEY REGION RESOURCE_GROUP CLUSTER_NAME"
   exit 1 # Exit script after printing help
}

if [[ -n "$1" ]]; then
   BM_API_KEY="$1"
fi
if [[ -n "$2" ]]; then
   REGION="$2"
fi
if [[ -n "$3" ]]; then
   RESOURCE_GROUP="$3"
fi
if [[ -n "$4" ]]; then
   CLUSTER_NAME="$4"
fi

# Print helpFunction in case parameters are empty
if [[ -z "${BM_API_KEY}" ]] || [[ -z "${REGION}" ]] || [[ -z "${RESOURCE_GROUP}" ]] || [[ -z "${CLUSTER_NAME}" ]]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# Login to IBM Cloud CLI
ibmcloud login --apikey "${API_KEY}" -r "${REGION}" -g "${RESOURCE_GROUP}" > /dev/null 2>&1

# Use IBM Cloud CLI to get kubectl cluster config (placed in /root/.bluemix/plugins/container-service/clusters/{CLUSTER_NAME})
ibmcloud ks cluster-config --cluster "${CLUSTER_NAME}" > /dev/null 2>&1

# Copy Kube Config YML and Kube Server Cert to /root/.kube directory (where kubectl looks for it)
mkdir -p /root/.kube > /dev/null 2>&1
find /root/.bluemix/plugins/container-service/clusters -name "*.yml" -exec cp {} /root/.kube/config \; > /dev/null 2>&1
find /root/.bluemix/plugins/container-service/clusters -name "*.pem" -exec cp {} /root/.kube \; > /dev/null 2>&1
