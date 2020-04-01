FROM docker.io/hashicorp/terraform:0.12.24

ENV TERRAFORM_VERSION 0.12.24
ENV TERRAFORM_IBMCLOUD_VERSION 1.2.6
ENV TERRAFORM_KUBERNETES_VERSION 1.10.0
ENV TERRAFORM_HELM_VERSION 1.0.0
ENV SUPPORTED_CALICO 3.12.0
ENV NVM_VERSION 0.35.2
ENV NODE_VERSION 12
ENV SOLSA_VERSION 0.3.5
ENV KUBECTL_VERSION 1.15.5

RUN apk add --update-cache \
  curl \
  unzip \
  sudo \
  shadow \
  bash \
  openssl \
  ca-certificates \
  && rm -rf /var/cache/apk/*

##################################
# Calico CLI
##################################

# Kustomize
RUN opsys=linux && \
    curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases |\
      grep browser_download |\
      grep $opsys |\
      cut -d '"' -f 4 |\
      grep /kustomize/v |\
      sort | tail -n 1 |\
      xargs curl -O -L && \
    tar xzf ./kustomize_v*_${opsys}_amd64.tar.gz && \
    mv kustomize /usr/local/bin/kustomize && \
    chmod +x /usr/local/bin/kustomize

##################################
# Terraform
##################################

WORKDIR $GOPATH/bin

COPY src/bin/* /usr/local/bin/

##################################
# User setup
##################################

# Configure sudoers so that sudo can be used without a password
RUN chmod u+w /etc/sudoers && echo "%sudo   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV HOME /home/devops

# Create devops user
RUN groupadd --force sudo && \
    groupadd -g 10000 devops && \
    useradd -u 10000 -g 10000 -G sudo,root -d ${HOME} -m devops && \
    usermod --password $(echo password | openssl passwd -1 -stdin) devops

USER devops
WORKDIR ${HOME}

COPY --chown=devops:devops src/etc/* ${HOME}/etc/

##################################
# IBM Cloud CLI
##################################

# Install the ibmcloud cli
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh && \
    ibmcloud plugin install container-service && \
    ibmcloud plugin install container-registry && \
    ibmcloud config --check-version=false

RUN mkdir -p ${HOME}/.terraform.d/plugins
WORKDIR ${HOME}/.terraform.d/plugins

# Install IBM Cloud Terraform Provider
RUN curl -O -L https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v1.2.1/linux_amd64.zip &&\
    unzip linux_amd64.zip && \
    chmod +x terraform-provider-ibm_* &&\
    rm -rf linux_amd64.zip
RUN curl -O -L https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v1.2.2/linux_amd64.zip &&\
    unzip linux_amd64.zip && \
    chmod +x terraform-provider-ibm_* &&\
    rm -rf linux_amd64.zip
RUN curl -O -L https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v${TERRAFORM_IBMCLOUD_VERSION}/linux_amd64.zip &&\
    unzip linux_amd64.zip && \
    chmod +x terraform-provider-ibm_* &&\
    rm -rf linux_amd64.zip

# Install Kubernetes Terraform Provider
RUN curl -L https://releases.hashicorp.com/terraform-provider-kubernetes/${TERRAFORM_KUBERNETES_VERSION}/terraform-provider-kubernetes_${TERRAFORM_KUBERNETES_VERSION}_linux_amd64.zip --output kube_linux_amd64.zip && \
    unzip kube_linux_amd64.zip && \
    chmod +x terraform-provider-kubernetes_* && \
    rm -rf kube_linux_amd64.zip

# Install Helm Terraform Provider
RUN curl -L https://releases.hashicorp.com/terraform-provider-helm/${TERRAFORM_HELM_VERSION}/terraform-provider-helm_${TERRAFORM_HELM_VERSION}_linux_amd64.zip --output helm_linux_amd64.zip &&\
    unzip helm_linux_amd64.zip &&\
    chmod +x terraform-provider-helm_* &&\
    rm -rf helm_linux_amd64.zip

WORKDIR ${HOME}

COPY src/image-message ./image-message
RUN cat ./image-message >> ./.bashrc-ni

RUN curl -L https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz --output oc-client.tar.gz && \
    tar xzf oc-client.tar.gz && \
    sudo mkdir -p /usr/local/fix && \
    sudo chmod a+rwx /usr/local/fix && \
    sudo cp openshift-origin-client-tools*/oc /usr/local/fix && \
    sudo chmod +x /usr/local/fix/oc && \
    rm -rf openshift-origin-client-tools* && \
    rm oc-client.tar.gz && \
    echo '/lib/ld-musl-x86_64.so.1 --library-path /lib /usr/local/fix/oc $@' > ./oc && \
    sudo mv ./oc /usr/local/bin && \
    sudo chmod +x /usr/local/bin/oc
#    echo "alias oc='/lib/ld-musl-x86_64.so.1 --library-path /lib /usr/local/bin/oc'" >> ./.bashrc-ni


RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /usr/local/bin

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash && \
    sudo cp /usr/local/bin/helm /usr/local/bin/helm3

RUN sudo chown -R devops ${HOME} && sudo chgrp -R 0 ${HOME} && sudo chmod -R g=u ${HOME}

RUN curl -LO https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod a+x jq-linux64 && \
    sudo mv jq-linux64 /usr/local/bin/jq

ENTRYPOINT ["/bin/bash", "--init-file", "/home/devops/.bashrc-ni"]
