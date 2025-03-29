# Container Tools

[![Docker Repository on Quay](https://quay.io/repository/ryan_nix/containertools/status "Docker Repository on Quay")](https://quay.io/repository/ryan_nix/containertools)

A container is a great way to run essential cloud tools such as `kubectl`, openshift-cli (`oc`), OpenShift Do - for rapid application development against a Kubernetes namespace (`odo`), `ansible-playbook`s, `git`, `wget`, `argocd`, `argocd-autopilot`, AWS's cli (`aws`), Azure's CLI (`az`), `wget`, `rsync`, `tar`, `gzip`, `vim`, `ssh`, `terraform`, and database clients (`mysql`, `psql`).

The container is built from CentOS Stream 9 and includes EPEL.

The prebuilt containers are found at my [Quay container repo](https://quay.io/repository/ryan_nix/containertools).
There are tags for x86 and ARM CPUs.

## Building and Publishing the Container

The container uses a unified Containerfile that detects the architecture at build time and installs the appropriate binaries.

### Building Locally

Build the container for your current architecture:
```bash
# Clone the repository if you haven't already
git clone https://github.com/your-username/containertools.git
cd containertools

# Build the image
podman build -t containertools -f ./Containerfile
```

### Publishing to Quay.io

Complete workflow for building and publishing to Quay.io:

```bash
# 1. Log in to Quay.io
podman login quay.io

# 2. Build the container
podman build -t containertools -f ./Containerfile

# 3. Detect architecture and tag accordingly (improved for Apple Silicon)
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  echo "Tagging as ARM architecture"
  podman tag containertools quay.io/your_username/containertools:arm
else
  echo "Tagging as x86 architecture"
  podman tag containertools quay.io/your_username/containertools:x86
fi

# 4. Push the image to Quay.io
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  podman push quay.io/your_username/containertools:arm
else
  podman push quay.io/your_username/containertools:x86
fi

# 5. Optionally tag as latest for your architecture
podman tag containertools quay.io/your_username/containertools:latest
podman push quay.io/your_username/containertools:latest
```

Replace `your_username` with your actual Quay.io username.

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

## Using a Pre-built Container

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

### Attach to the container
```bash
podman attach tools
```
## Persistent Storage with Podman

If you want to persist data across container restarts, you can create a Podman volume and mount it inside the container.

### Create a Persistent Volume
Run the following command to create a named volume:
```sh
podman volume create tools-data
```

### Run the Container with the Persistent Volume
When starting the container, mount the volume to the desired path:
```sh
podman run -it -v tools-data:/home/tools/local-storage my-container-image
```

### Verify Data Persistence
To test if the data persists after container restarts:
1. Start a container with the volume and create a file:
    ```sh
    podman run -it -v tools-data:/home/tools/local-storage my-container-image bash
    echo "Persistent storage test" > /home/tools/local-storage/testfile.txt
    exit
    ```
2. Start another container with the same volume and check the file:
    ```sh
    podman run -it -v tools-data:/home/tools/local-storage my-container-image bash
    cat /home/tools/local-storage/testfile.txt
    ```
   You should see `Persistent storage test`, confirming that the data is persistent.

### Access the Volume Data from the Host
Podman stores volumes in `/var/lib/containers/storage/volumes/`. To access the stored data from the host:
```sh
ls /var/lib/containers/storage/volumes/tools-data/_data
```

To detach from the container without stopping it, press `Ctrl+P` followed by `Ctrl+Q`.

## Pushing to Quay.io

For additional instructions about publishing to Quay.io, see the "Building and Publishing the Container" section above, which includes a complete workflow.

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