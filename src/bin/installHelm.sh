#!/usr/bin/env bash
# Installation script per IBM Cloud Documentation
# https://console.bluemix.net/docs/containers/cs_integrations.html#helm

# Install Helm into the cluster (kube-system namespace)
kubectl apply -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/rbac/serviceaccount-tiller.yaml
helm init --service-account tiller

# Setup IBM Cloud Repositories
helm repo add ibm https://registry.bluemix.net/helm/ibm
helm repo add ibm-charts https://registry.bluemix.net/helm/ibm-charts

# Setup Helm Incubator Repository
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/

# Refresh Repository Cache
helm repo update
