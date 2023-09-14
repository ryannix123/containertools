# Build on top of base CentOS 9 Stream image
FROM quay.io/centos/centos:stream9

RUN dnf -y update && \
dnf install -y epel-release vim tar wget sudo gzip git rsync podman bash unzip openssh-clients ansible-core && \
dnf clean all

RUN mkdir /ocp-tools

RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz -P /ocp-tools && \
cd /ocp-tools && \
tar xvzf openshift-client-linux.tar.gz oc kubectl && \
chmod 777 * && \
mv oc kubectl /usr/local/bin

#Install cloud tools
#Install the Azure cli
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm  
RUN dnf install -y azure-cli

#Install the AWS cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
unzip -u awscliv2.zip && \
sudo ./aws/install

CMD /bin/bash