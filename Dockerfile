FROM registry.access.redhat.com/ubi8/ubi:8.0-208

ENV TERRAFORM_VERSION=0.11.14
ENV TERRAFORM_IBMCLOUD_VERSION 0.20.0
ENV TERRAFORM_KUBERNETES_VERSION 1.9.0
ENV TERRAFORM_HELM_VERSION 0.10.2
ENV SUPPORTED_CALICO 3.9.1
ENV NVM_VERSION 0.35.0
ENV NODE_VERSION 11.12.0

RUN dnf install -y dnf-plugins-core --disableplugin=subscription-manager && \
    dnf install -y golang --disableplugin=subscription-manager && \
    dnf install -y sudo --disableplugin=subscription-manager && \
    dnf install -y unzip --disableplugin=subscription-manager && \
    dnf install -y openssl --disableplugin=subscription-manager

##################################
# Calico CLI
##################################

RUN curl -O -L https://github.com/projectcalico/calicoctl/releases/download/v${SUPPORTED_CALICO}/calicoctl && \
    mv ./calicoctl /usr/local/bin/calicoctl && \
    chmod +x /usr/local/bin/calicoctl

# Kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && \
    mv kustomize /usr/local/bin

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

# Create devops user
RUN groupadd --force sudo && \
    groupadd -g 10000 devops && \
    useradd -u 10000 -g 10000 -G sudo -d ${HOME} -m devops && \
    usermod --password $(echo password | openssl passwd -1 -stdin) devops

USER devops
WORKDIR ${HOME}

COPY --chown=devops:devops src/etc/* ${HOME}/etc/

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

# Install yo
RUN . ./.bashrc-ni && npm i -g yo
RUN . ./.bashrc-ni && npm i -g @garage-catalyst/ibm-garage-cloud-cli

COPY src/image-message ./image-message
RUN cat ./image-message >> ./.bashrc-ni

RUN sudo dnf install python3-pip -y --disableplugin=subscription-manager && \
    sudo ln -s /usr/bin/python3 /usr/bin/python && \
    sudo ln -s /usr/bin/pip3 /usr/bin/pip
RUN pip install --user ansible && \
    echo "export PATH=\"${PATH}:${HOME}/.local/bin\"" >> ./.bashrc-ni

RUN sudo dnf clean all

RUN curl -L https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz --output oc-client.tar.gz && \
    tar xzf oc-client.tar.gz && \
    sudo cp openshift-origin-client-tools*/oc /usr/local/bin && \
    sudo cp openshift-origin-client-tools*/kubectl /usr/local/bin && \
    sudo chmod +x /usr/local/bin/oc && \
    sudo chmod +x /usr/local/bin/kubectl && \
    rm -rf openshift-origin-client-tools*

ENTRYPOINT ["/bin/bash", "--init-file", "/home/devops/.bashrc-ni"]
