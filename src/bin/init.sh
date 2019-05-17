#!/usr/bin/env bash

helpFunction()
{
   echo ""
   echo -e "\033[1;31mUsage:\033[0m $0 BM_API_KEY REGION RESOURCE_GROUP CLUSTER_NAME"
   echo -e "  where \033[1;32mBM_API_KEY\033[0m is the IBM Cloud api key"
   echo -e "        \033[1;32mREGION\033[0m is the IBM Cloud region (e.g. us-south)"
   echo -e "        \033[1;32mRESOURCE_GROUP\033[0m is the IBM Cloud resource group"
   echo -e "        \033[1;32mCLUSTER_NAME\033[0m is the name of the kubernetes cluster in IBM Cloud"
   echo ""
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
ibmcloud login --apikey "${BM_API_KEY}" -r "${REGION}" -g "${RESOURCE_GROUP}" > /dev/null 2>&1

# Use IBM Cloud CLI to get kubectl cluster config (placed in /root/.bluemix/plugins/container-service/clusters/{CLUSTER_NAME})
ibmcloud ks cluster-config --cluster "${CLUSTER_NAME}" > /dev/null 2>&1

# Copy Kube Config YML and Kube Server Cert to /root/.kube directory (where kubectl looks for it)
mkdir -p ~/.kube > /dev/null 2>&1
find ~/.bluemix/plugins/container-service/clusters -name "*.yml" -exec cp {} ~/.kube/config \; > /dev/null 2>&1
find ~/.bluemix/plugins/container-service/clusters -name "*.pem" -exec cp {} ~/.kube \; > /dev/null 2>&1
