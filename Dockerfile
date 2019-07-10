FROM golang:stretch

ENV TERRAFORM_VERSION=0.11.13
ENV TERRAFORM_IBMCLOUD_VERSION 0.16.1
ENV TERRAFORM_KUBERNETES_VERSION 1.5.2
ENV TERRAFORM_HELM_VERSION 0.9.0
ENV SUPPORTED_CALICO 3.3.1
ENV NVM_VERSION 0.34.0
ENV NODE_VERSION 11.12.0

RUN apt-get update && \
    apt install -y apt-transport-https ca-certificates curl software-properties-common

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

# Install some core libraries (build-essentials, sudo, python, curl)
RUN apt-get update && \
    apt-get install -y gnupg gnupg2 gnupg1 && \
    apt-get install -y build-essential && \
    apt-get install -y python && \
    apt-get install -y curl && \
    apt-get install -y jq && \
    apt-get install -y vim && \
    apt-get install -y unzip && \
    apt-get install -y sudo && \
    apt-get install -y docker-ce docker-ce-cli

##################################
# Calico CLI
##################################

RUN curl -O -L https://github.com/projectcalico/calicoctl/releases/download/v${SUPPORTED_CALICO}/calicoctl && \
    mv ./calicoctl /usr/local/bin/calicoctl && \
    chmod +x /usr/local/bin/calicoctl

# Kustomize

RUN opsys=linux && \
    curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest |\
      grep browser_download |\
      grep $opsys |\
      cut -d '"' -f 4 |\
      xargs curl -O -L &&\
    mv kustomize_*_${opsys}_amd64 /usr/local/bin/kustomize && \
    chmod +x /usr/local/bin/kustomize

##################################
# Terraform
##################################

WORKDIR $GOPATH/bin

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
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

# Create devops user
RUN groupadd -g 10000 devops && \
    useradd -u 10000 -g 10000 -G sudo -d ${HOME} -m devops && \
    usermod --password $(echo password | openssl passwd -1 -stdin) devops

USER devops
WORKDIR ${HOME}

COPY src/etc/* ${HOME}/etc/*

##################################
# IBM Cloud CLI
##################################

# Install the ibmcloud cli
RUN curl -sL https://ibm.biz/idt-installer | bash && \
    ibmcloud config --check-version=false && \
    ibmcloud plugin install cloud-databases

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash

RUN echo 'echo "Initializing environment..."' > ${HOME}/.bashrc-ni && \
    echo 'export NVM_DIR="${HOME}/.nvm"' >> ${HOME}/.bashrc-ni && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ${HOME}/.bashrc-ni

# Set the BASH_ENV to /home/devops/.bashrc-ni so that it is executed in a
# non-interactive shell
#ENV BASH_ENV ${HOME}/.bashrc-ni

# Pre-install node v11.12.0
RUN echo ${PWD} && . ./.bashrc-ni && nvm install "v${NODE_VERSION}" && nvm use "v${NODE_VERSION}"

RUN mkdir -p ${HOME}/.terraform.d/plugins
WORKDIR ${HOME}/.terraform.d/plugins

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

WORKDIR ${HOME}

# Install yo
RUN . ./.bashrc-ni && npm i -g yo
RUN . ./.bashrc-ni && npm i -g @garage-catalyst/ibm-garage-cloud-cli@0.0.25

COPY src/image-message ./image-message
RUN cat ./image-message >> ./.bashrc-ni

RUN sudo apt-get install -y postgresql-client

RUN sudo apt-get autoremove && sudo apt-get clean

ENTRYPOINT ["/bin/bash", "--init-file", "/home/devops/.bashrc-ni"]
