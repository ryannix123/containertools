# Build on top of base CentOS 9 Stream image with multi-arch support
FROM quay.io/centos/centos:stream9

# Create a non-root user
RUN useradd -ms /bin/bash tools

# Update container libraries and install tools available from the repos
RUN dnf -y update && \
    dnf install -y epel-release vim tar wget java-17-openjdk maven sudo gzip git rsync podman bash unzip openssh-clients ansible-core \
    # Add database clients
    mysql postgresql && \
    dnf clean all

# Install the latest ArgoCD (architecture-specific)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
      curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64 && \
      sudo install -m 555 argocd-linux-arm64 /usr/local/bin/argocd && \
      rm argocd-linux-arm64; \
    else \
      curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
      sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd && \
      rm argocd-linux-amd64; \
    fi

# Install the latest ArgoCD Autopilot (architecture-specific)
RUN VERSION=$(curl --silent "https://api.github.com/repos/argoproj-labs/argocd-autopilot/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
      curl -L --output - https://github.com/argoproj-labs/argocd-autopilot/releases/download/"$VERSION"/argocd-autopilot-linux-arm64.tar.gz | tar zx; \
    else \
      curl -L --output - https://github.com/argoproj-labs/argocd-autopilot/releases/download/"$VERSION"/argocd-autopilot-linux-amd64.tar.gz | tar zx; \
    fi && \
    chmod 555 argocd-autopilot-* && \
    mv ./argocd-autopilot-* /usr/local/bin/argocd-autopilot

# Install the latest Kubectl and OpenShift CLI tools (architecture-specific)
RUN mkdir /ocp-tools && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
      wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-arm64.tar.gz -P /ocp-tools; \
    else \
      wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz -P /ocp-tools; \
    fi && \
    cd /ocp-tools && \
    tar xvzf openshift-client-linux*.tar.gz oc kubectl && \
    chmod 777 * && \
    mv oc kubectl /usr/local/bin

# Install the latest version of odo for development (architecture-specific)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
      curl -L https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/odo/v3.15.0/odo-linux-arm64 -o odo; \
    else \
      curl -L https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/odo/v3.15.0/odo-linux-amd64.tar.gz -o odo.tar.gz && \
      tar -xzf odo.tar.gz && \
      rm odo.tar.gz; \
    fi && \
    sudo install -o root -g root -m 0755 odo /usr/local/bin/odo

# Install the main hyperscaler CLIs
# Install the Azure CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm && \
    dnf install -y azure-cli

# Install the AWS CLI (architecture-specific)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
      curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    else \
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    fi && \
    unzip -u awscliv2.zip && \
    sudo ./aws/install && \
    rm awscliv2.zip

# Install Terraform (architecture-specific)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
      curl -O https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_arm64.zip && \
      unzip terraform_1.7.5_linux_arm64.zip; \
    else \
      curl -O https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip && \
      unzip terraform_1.7.5_linux_amd64.zip; \
    fi && \
    sudo install -o root -g root -m 0755 terraform /usr/local/bin/terraform && \
    rm terraform_*.zip

# Create directory for optional local storage mount
RUN mkdir -p /home/tools/local-storage && \
    chown -R tools:tools /home/tools/local-storage

# Switch to non-root user
USER tools

# Set WORKDIR to the location where the local storage will be mounted
WORKDIR /home/tools

CMD /bin/bash