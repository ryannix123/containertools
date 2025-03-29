# Container Tools

[![Docker Repository on Quay](https://quay.io/repository/ryan_nix/containertools/status "Docker Repository on Quay")](https://quay.io/repository/ryan_nix/containertools)

A container is a great way to run essential cloud tools such as `kubectl`, openshift-cli (`oc`), OpenShift Do - for rapid application development against a Kubernetes namespace (`odo`), `ansible-playbook`s, `git`, `wget`, `argocd`, `argocd-autopilot`, AWS's cli (`aws`), Azure's CLI (`az`), `wget`, `rsync`, `tar`, `gzip`, `vim`, `ssh`, and now including `terraform`.

The container is built from CentOS Stream 9 and includes EPEL.

The prebuilt containers are found at my [Quay container repo](https://quay.io/repository/ryan_nix/containertools).
There are tags for x86 and ARM CPUs.

## Building the Container

Build your own on x86 by running:
```bash
podman build -t containertools -f ./Containerfile
```

Build your own on ARM by running:
```bash
podman build -t containertools -f ./Containerfile-ARM
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
podman tag containertools quay.io/your_username/containertools:x86
```
or
```bash
podman tag containertools quay.io/your_username/containertools:arm
```

3. Push the image to Quay.io:
```bash
podman push quay.io/your_username/containertools:x86
```
or
```bash
podman push quay.io/your_username/containertools:arm
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
- git, vim, wget, rsync, tar, gzip, ssh
- Java 17 OpenJDK and Maven
- And more!