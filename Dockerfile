FROM docker.io/hashicorp/terraform:0.12.26

ENV TERRAFORM_IBMCLOUD_VERSION 1.7.0
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

WORKDIR $GOPATH/bin

COPY src/bin/* /usr/local/bin/

##################################
# User setup
##################################

# Configure sudoers so that sudo can be used without a password
RUN groupadd --force sudo && \
    chmod u+w /etc/sudoers && \
    echo "%sudo   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV HOME /home/devops

# Create devops user
RUN useradd -u 10000 -g root -G sudo -d ${HOME} -m devops && \
    usermod --password $(echo password | openssl passwd -1 -stdin) devops

USER devops
WORKDIR ${HOME}

COPY --chown=devops:root src/etc/* ${HOME}/etc/

##################################
# IBM Cloud CLI
##################################

# Install the ibmcloud cli
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh && \
    ibmcloud plugin install container-service && \
    ibmcloud plugin install container-registry && \
    ibmcloud config --check-version=false

# Install IBM Cloud Terraform Provider
RUN mkdir -p ${HOME}/.terraform.d/plugins && \
    cd ${HOME}/.terraform.d/plugins && \
    curl -O -L https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v${TERRAFORM_IBMCLOUD_VERSION}/linux_amd64.zip &&\
    unzip linux_amd64.zip && \
    chmod +x terraform-provider-ibm_* &&\
    rm -rf linux_amd64.zip && \
    cd -

WORKDIR ${HOME}

COPY --chown=devops:root src/image-message ./image-message
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

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /usr/local/bin

#RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash && \
#    sudo cp /usr/local/bin/helm /usr/local/bin/helm3

#RUN sudo chown -R devops ${HOME} && sudo chgrp -R 0 ${HOME} && sudo chmod -R g=u ${HOME}

#RUN curl -LO https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
#    chmod a+x jq-linux64 && \
#    sudo mv jq-linux64 /usr/local/bin/jq

ENTRYPOINT ["/bin/bash", "--init-file", "/home/devops/.bashrc-ni"]
