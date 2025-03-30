# Build on top of base CentOS 9 Stream image with multi-arch support
FROM quay.io/centos/centos:stream9

# Create a non-root user
RUN useradd -ms /bin/bash tools

# Update container libraries and install tools available from the repos
RUN dnf install -y epel-release && \
    dnf update -y && \
    dnf install -y \
      vim tar wget java-17-openjdk maven sudo gzip git rsync podman bash unzip openssh-clients ansible-core \
      mysql postgresql \
      python3 python3-pip python3-devel && \
    dnf clean all

# Install Python packages
RUN pip3 install --upgrade pip && \
    pip3 install boto3 botocore && \
    ansible-galaxy collection install amazon.aws

# Detect architecture and set environment variable
ARG ARCH
RUN ARCH=$(uname -m) && echo "Detected architecture: $ARCH" && \
    case "$ARCH" in \
        "arm64" | "aarch64") echo "arm64" > /tmp/arch ;; \
        "x86_64") echo "amd64" > /tmp/arch ;; \
    esac

# Install latest ArgoCD (architecture-specific)
RUN ARCH=$(cat /tmp/arch) && \
    curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-$ARCH && \
    install -m 555 argocd /usr/local/bin/argocd && rm argocd

# Install latest ArgoCD Autopilot
RUN VERSION=$(curl -s https://api.github.com/repos/argoproj-labs/argocd-autopilot/releases/latest | \
    grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') && \
    ARCH=$(cat /tmp/arch) && \
    curl -L https://github.com/argoproj-labs/argocd-autopilot/releases/download/"$VERSION"/argocd-autopilot-linux-$ARCH.tar.gz | tar zx && \
    chmod 555 argocd-autopilot-* && mv argocd-autopilot-* /usr/local/bin/argocd-autopilot

# Install latest OpenShift CLI (oc) and kubectl
RUN mkdir /ocp-tools && \
    ARCH=$(cat /tmp/arch) && \
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-$ARCH.tar.gz -P /ocp-tools && \
    tar xvzf /ocp-tools/openshift-client-linux-*.tar.gz -C /ocp-tools oc kubectl && \
    install -m 755 /ocp-tools/oc /usr/local/bin/oc && \
    install -m 755 /ocp-tools/kubectl /usr/local/bin/kubectl && \
    rm -rf /ocp-tools

# Install latest odo CLI
RUN ARCH=$(cat /tmp/arch) && \
    curl -L https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/odo/v3.15.0/odo-linux-$ARCH -o odo && \
    install -m 0755 odo /usr/local/bin/odo && rm odo

# Install Azure CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm && \
    dnf install -y azure-cli && \
    dnf clean all

# Install AWS CLI (architecture-specific)
RUN ARCH=$(cat /tmp/arch) && \
    echo "Downloading AWS CLI for architecture: $ARCH" && \
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then \
        AWS_ARCH="aarch64"; \
    else \
        AWS_ARCH="x86_64"; \
    fi && \
    curl -fsSL -o awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-$AWS_ARCH.zip" && \
    echo "Checking AWS CLI archive integrity..." && \
    unzip -t awscliv2.zip && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Install Terraform from the official HashiCorp RPM repository
RUN dnf install -y yum-utils && \
    yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    dnf install -y terraform && \
    dnf clean all

# Create directory for optional local storage mount
RUN mkdir -p /home/tools/local-storage && chown -R tools:tools /home/tools/local-storage

# Switch to non-root user
USER tools

# Set WORKDIR
WORKDIR /home/tools

CMD ["/bin/bash"]