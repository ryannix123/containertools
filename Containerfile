# Build on top of base CentOS 9 Stream image for x86
FROM quay.io/centos/centos:stream9

# Update container libraries and install tools available from the repos
RUN dnf -y update && \
dnf install -y epel-release vim tar wget sudo gzip git rsync podman bash unzip openssh-clients ansible-core && \
dnf clean all

# Install the latest version of Source-to-image (s2i)
RUN curl -s https://api.github.com/repos/openshift/source-to-image/releases/latest| grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4  | wget -qi - && \
tar xvf source-to-image*.gz && \
sudo mv s2i /usr/local/bin

# Install the latest ArgoCD from the official Github repo
RUN curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd && \
rm argocd-linux-amd64

# Install the latest ArgoCD Autopilot from the official repo
RUN VERSION=$(curl --silent "https://api.github.com/repos/argoproj-labs/argocd-autopilot/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') && \
curl -L --output - https://github.com/argoproj-labs/argocd-autopilot/releases/download/"$VERSION"/argocd-autopilot-linux-amd64.tar.gz | tar zx && \
chmod 555 argocd-autopilot-* && \
mv ./argocd-autopilot-* /usr/local/bin/argocd-autopilot

# Install the latest Kubectl and OpenShift CLI tools
RUN mkdir /ocp-tools && \
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz -P /ocp-tools && \
cd /ocp-tools && \
tar xvzf openshift-client-linux.tar.gz oc kubectl && \
chmod 777 * && \
mv oc kubectl /usr/local/bin

# Install the main hyperscaler clis
# Install the Azure cli
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm && \
dnf install -y azure-cli

#Install the AWS cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
unzip -u awscliv2.zip && \
sudo ./aws/install

CMD /bin/bash
