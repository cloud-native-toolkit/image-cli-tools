FROM golang:alpine3.11

ENV TERRAFORM_VERSION 0.12.20
ENV TERRAFORM_IBMCLOUD_VERSION 1.2.1
ENV TERRAFORM_KUBERNETES_VERSION 1.10.0
ENV TERRAFORM_HELM_VERSION 1.0.0
ENV SUPPORTED_CALICO 3.12.0
ENV NVM_VERSION 0.35.2
ENV NODE_VERSION 12.16.1
ENV SOLSA_VERSION 0.3.5
ENV KUBECTL_VERSION 1.15.5

RUN apk add sudo && \
    apk add unzip && \
    apk add openssl && \
    apk add curl

##################################
# Calico CLI
##################################

RUN curl -O -L https://github.com/projectcalico/calicoctl/releases/download/v${SUPPORTED_CALICO}/calicoctl && \
    mv ./calicoctl /usr/local/bin/calicoctl && \
    chmod +x /usr/local/bin/calicoctl

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

# Install Terraform
RUN curl -O -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    chmod +x terraform && \
    rm -rf terraform_${TERRAFORM_VERSION}_linux_amd64.zip

COPY src/bin/* /usr/local/bin/

##################################
# User setup
##################################

# Configure sudoers so that sudo can be used without a password
RUN chmod u+w /etc/sudoers && echo "%sudo   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV HOME /home/devops

RUN apk add shadow

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

RUN sudo apk add bash

# Install the ibmcloud cli
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh && \
    ibmcloud config --check-version=false && \
    ibmcloud plugin install cloud-databases

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash

RUN echo 'echo "Initializing environment..."' > ${HOME}/.bashrc-ni && \
    echo 'export NVM_DIR="${HOME}/.nvm"' >> ${HOME}/.bashrc-ni && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"' >> ${HOME}/.bashrc-ni

# Set the BASH_ENV to /home/devops/.bashrc-ni so that it is executed in a
# non-interactive shell
#ENV BASH_ENV ${HOME}/.bashrc-ni

#RUN bash -c echo ${PWD} && . ./.bashrc-ni && nvm install "v${NODE_VERSION}" && nvm use "v${NODE_VERSION}"
RUN sudo apk add nodejs npm

RUN mkdir -p ${HOME}/.terraform.d/plugins
WORKDIR ${HOME}/.terraform.d/plugins

# Install IBM Cloud Terraform Provider
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

RUN node -v && npm -v
RUN mkdir ${HOME}/.npm && npm config set prefix ${HOME}/.npm

RUN npm i -g yo

RUN npm i -g @garage-catalyst/ibm-garage-cloud-cli

# Install solsa
RUN npm i -g solsa@${SOLSA_VERSION}

COPY src/image-message ./image-message
RUN cat ./image-message >> ./.bashrc-ni

#RUN sudo apk add python py-pip
#RUN /usr/bin/python -m pip install --user ansible && \
#    echo "export PATH=\"${PATH}:${HOME}/.local/bin\"" >> ./.bashrc-ni

RUN curl -L https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz --output oc-client.tar.gz && \
    tar xzf oc-client.tar.gz && \
    sudo cp openshift-origin-client-tools*/oc /usr/local/bin && \
    sudo chmod +x /usr/local/bin/oc && \
    rm -rf openshift-origin-client-tools* && \
    rm oc-client.tar.gz
#    sudo cp openshift-origin-client-tools*/kubectl /usr/local/bin && \
#    sudo chmod +x /usr/local/bin/kubectl && \

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /usr/local/bin

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash && \
    sudo mv /usr/local/bin/helm /usr/local/bin/helm2

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash && \
    sudo mv /usr/local/bin/helm /usr/local/bin/helm3

RUN sudo ln -s /usr/local/bin/helm2 /usr/local/bin/helm

RUN sudo chown -R devops ${HOME} && sudo chgrp -R 0 ${HOME} && sudo chmod -R g=u ${HOME}

ENTRYPOINT ["/bin/bash", "--init-file", "/home/devops/.bashrc-ni"]
