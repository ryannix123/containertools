# Container Tools

[![Docker Repository on Quay](https://quay.io/repository/ryan_nix/containertools/status "Docker Repository on Quay")](https://quay.io/repository/ryan_nix/containertools)

A container is a great way to run essential cloud tools such as `kubectl`, openshift-cli (`oc`), OpenShift Do - for rapid application development against a Kubernetes namespace (`odo`), `ansible-playbook`s, `git`, `wget`, `argocd`, `argocd-autopilot`, AWS's cli (`aws`), Azure's CLI (`az`), `wget`, `rsync`, `tar`, `gzip`, `vim`, `ssh`, `terraform`, and database clients (`mysql`, `psql`).

The container is built from CentOS Stream 9 and includes EPEL.

The prebuilt containers are found at my [Quay container repo](https://quay.io/repository/ryan_nix/containertools).
There are tags for x86 and ARM CPUs.

## Building the Container

The container now uses a unified Containerfile that detects the architecture at build time and installs the appropriate binaries.

Build the container for your current architecture:
```bash
podman build -t containertools -f ./Containerfile
```

## Using the Container

### Pull the appropriate image for your system's architecture
```bash
podman pull quay.io/ryan_nix/containertools:x86
```
or
```bash
podman pull quay.io/ryan_nix/containertools:arm
```

### List images
```bash
podman images
```

### Run the container
Basic run:
```bash
podman run -d -it --name tools quay.io/ryan_nix/containertools:x86
```
or
```bash
podman run -d -it --name tools quay.io/ryan_nix/containertools:arm
```

### Run with local storage mounted
First, create a local directory to store files (if it doesn't exist):
```bash
mkdir -p ~/container-storage
```

Then run the container with this directory mounted:
```bash
podman run -d -it --name tools -v ~/container-storage:/home/tools/local-storage quay.io/ryan_nix/containertools:x86
```
or
```bash
podman run -d -it --name tools -v ~/container-storage:/home/tools/local-storage quay.io/ryan_nix/containertools:arm
```

Any files placed in `~/container-storage` on your host system will be accessible inside the container at `/home/tools/local-storage`.

### Attach to the container
```bash
podman attach tools
```

To detach from the container without stopping it, press `Ctrl+P` followed by `Ctrl+Q`.

## Pushing to Quay.io

If you've made changes and want to push your own version to Quay.io:

1. First, log in to Quay.io:
```bash
podman login quay.io
```

2. Tag your local image with your Quay.io repository:
```bash
# Detect architecture and tag accordingly
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
  podman tag containertools quay.io/your_username/containertools:arm
else
  podman tag containertools quay.io/your_username/containertools:x86
fi
```

3. Push the image to Quay.io:
```bash
# Push based on detected architecture
if [ "$ARCH" = "aarch64" ]; then
  podman push quay.io/your_username/containertools:arm
else
  podman push quay.io/your_username/containertools:x86
fi
```

### Building Multi-Architecture Images (Advanced)

For more advanced users, you can create a multi-architecture manifest that includes both x86 and ARM versions:

```bash
# Build on x86 system
podman build -t quay.io/your_username/containertools:x86 .
podman push quay.io/your_username/containertools:x86

# Build on ARM system 
podman build -t quay.io/your_username/containertools:arm .
podman push quay.io/your_username/containertools:arm

# Create and push the manifest
podman manifest create quay.io/your_username/containertools:latest \
  quay.io/your_username/containertools:x86 \
  quay.io/your_username/containertools:arm

podman manifest push quay.io/your_username/containertools:latest
```

## Available Tools

This container includes:
- kubectl and oc (OpenShift CLI)
- odo (OpenShift Do for developers)
- argocd and argocd-autopilot
- AWS CLI (aws)
- Azure CLI (az)
- terraform
- ansible-core
- Database clients (mysql and psql for PostgreSQL)
- git, vim, wget, rsync, tar, gzip, ssh
- Java 17 OpenJDK and Maven
- And more!

## Connecting to Databases

The container includes client tools for connecting to MySQL and PostgreSQL databases:

### MySQL
```bash
mysql -h hostname -u username -p database_name
```

### PostgreSQL
```bash
psql -h hostname -U username -d database_name
```

You can also use these clients with connection strings stored in your mounted local storage for better security.
