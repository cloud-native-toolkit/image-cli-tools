FROM golang:alpine

ENV TERRAFORM_VERSION=0.11.13
ENV TERRAFORM_IBMCLOUD_VERSION 0.16.0
ENV TERRAFORM_KUBERNETES_VERSION 1.5.2
ENV TERRAFORM_HELM_VERSION 0.9.0
ENV SUPPORTED_CALICO 3.3.1

RUN apk add --update bash

WORKDIR $GOPATH/bin

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip &&\
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip &&\
    chmod +x terraform &&\
    rm -rf terraform_${TERRAFORM_VERSION}_linux_amd64.zip

WORKDIR /root/.terraform.d/plugins

# Install IBM Cloud Terraform Provider
RUN wget https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v${TERRAFORM_IBMCLOUD_VERSION}/linux_amd64.zip &&\
    unzip linux_amd64.zip &&\
    chmod +x terraform-provider-ibm_* &&\
    rm -rf linux_amd64.zip

# Install Kubernetes Terraform Provider
RUN wget https://releases.hashicorp.com/terraform-provider-kubernetes/${TERRAFORM_KUBERNETES_VERSION}/terraform-provider-kubernetes_${TERRAFORM_KUBERNETES_VERSION}_linux_amd64.zip -O kube_linux_amd64.zip &&\
    unzip kube_linux_amd64.zip &&\
    chmod +x terraform-provider-kubernetes_* &&\
    rm -rf kube_linux_amd64.zip

# Install Helm Terraform Provider
RUN wget https://releases.hashicorp.com/terraform-provider-helm/${TERRAFORM_HELM_VERSION}/terraform-provider-helm_${TERRAFORM_HELM_VERSION}_linux_amd64.zip -O helm_linux_amd64.zip &&\
    unzip helm_linux_amd64.zip &&\
    chmod +x terraform-provider-helm_* &&\
    rm -rf helm_linux_amd64.zip

WORKDIR /root

# Install IBM Cloud CLI, IBM Cloud Kubernetes Service plugin, IBM Cloud Container Registry plugin, Kubernetes CLI, Calico CLI, and Helm CLI
RUN apk add --no-cache \

    ##################################
    # Curl && Vim
    ##################################

    # Install Curl
    curl \

    # Install VIM
    vim &&\


    ##################################
    # IBM Cloud CLI
    ##################################

    # Install the Linux version of the IBM Cloud CLI
    curl -fsSL https://clis.ng.bluemix.net/install/linux | sh &&\

    # Install the IBM Cloud Kubernetes Service CLI
    ibmcloud plugin install container-service &&\

    # Install the IBM Cloud Container Registry CLI
    ibmcloud plugin install container-registry &&\

    # Install the IBM Cloud Databases CLI
    ibmcloud plugin install cloud-databases &&\


    ##################################
    # Kubernetes CLI
    ##################################

    # Download the latest version of Kubernetes
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl &&\

    # Update the permissions for and the location of the Kubernetes CLI executable file
    chmod +x ./kubectl &&\
    mv ./kubectl /usr/local/bin/kubectl &&\


    ##################################
    # Calico CLI
    ##################################

    # Download the latest supported version of the Calico CLI
    curl -O -L https://github.com/projectcalico/calicoctl/releases/download/v${SUPPORTED_CALICO}/calicoctl &&\

    # Update the permissions for and the location of the Calico CLI executable file
    mv ./calicoctl /usr/local/bin/calicoctl &&\
    chmod +x /usr/local/bin/calicoctl &&\


    ##################################
    # Helm CLI
    ##################################

    # Download the latest version of the Helm CLI and unpack
    curl -LO https://storage.googleapis.com/kubernetes-helm/helm-$(wget -qO- https://github.com/kubernetes/helm/releases | sed -n '/Latest release<\/a>/,$p' | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' |head -1)-linux-amd64.tar.gz &&\
    tar -xvzf helm-$(wget -qO- https://github.com/kubernetes/helm/releases | sed -n '/Latest release<\/a>/,$p' | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' |head -1)-linux-amd64.tar.gz &&\

    # Update the permissions for and the location of the Helm CLI executable file
    chmod +x linux-amd64/helm &&\
    mv linux-amd64/helm /usr/local/bin/helm &&\
    rm -rf linux-amd64 &&\
    rm helm-*.tar.gz

COPY src/bashrc /root/.bashrc
