#!/usr/bin/env bash

NAMESPACE="$1"

if [[ -n $(kubectl get namespaces -o jsonpath='{ range .items[*] }{ .metadata.name }{ "\n" }{ end }' | grep "${NAMESPACE}") ]]; then
    echo "*** Deleting namespace and contained resources: ${NAMESPACE}"
    kubectl delete daemonsets,replicasets,services,deployments,pods,rc,ing,statefulsets,crds --all -n "${NAMESPACE}"
    kubectl delete namespace "${NAMESPACE}"
fi
