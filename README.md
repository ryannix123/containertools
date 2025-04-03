# Container Tools

[![Docker Repository on Quay](https://quay.io/repository/ryan_nix/containertools/status "Docker Repository on Quay")](https://quay.io/repository/ryan_nix/containertools)

A container is a great way to run essential cloud tools such as `kubectl`, openshift-cli (`oc`), OpenShift Do - for rapid application development against a Kubernetes namespace (`odo`), `ansible-playbook`s, `git`, `wget`, `argocd`, `knative & fortio`, `argocd-autopilot`, `python3`, AWS's cli (`aws`), Azure's CLI (`az`), `wget`, `rsync`, `tar`, `gzip`, `vim`, `ssh`, `terraform`, and database clients (`mysql`, `psql`).

The container is built from CentOS Stream 9 and includes EPEL.

The prebuilt containers are found at my [Quay container repo](https://quay.io/repository/ryan_nix/containertools).
There are tags for x86 and ARM CPUs.

## Building and Publishing the Container

The container now uses separate Containerfiles for each architecture to simplify maintenance and troubleshooting.

### Building Locally

Build the container for your architecture:

```bash
# Clone the repository if you haven't already
git clone https://github.com/your-username/containertools.git
cd containertools

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Build the appropriate image based on architecture
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm" ]; then
  echo "Building ARM image"
  podman build -t containertools:arm -f ./Containerfile.arm
else
  echo "Building x86 image"
  podman build -t containertools:x86 -f ./Containerfile.x86
fi
```

### Publishing to Quay.io

Complete workflow for building and publishing to Quay.io:

```bash
# 1. Log in to Quay.io
podman login quay.io

# 2. Detect architecture and build appropriate image
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm" ]; then
  echo "Building ARM architecture image"
  podman build -t containertools:arm -f ./Containerfile.arm
  # Tag with the Quay.io repository name
  podman tag containertools:arm quay.io/your_username/containertools:arm
  # Push the image to Quay.io
  podman push quay.io/your_username/containertools:arm
else
  echo "Building x86 architecture image"
  podman build -t containertools:x86 -f ./Containerfile.x86
  # Tag with the Quay.io repository name
  podman tag containertools:x86 quay.io/your_username/containertools:x86
  # Push the image to Quay.io
  podman push quay.io/your_username/containertools:x86
fi
```

Replace `your_username` with your actual Quay.io username.

### Building Multi-Architecture Images (Advanced)

For those who need to build multi-architecture images on a single system, you'll need to use a build environment with QEMU support:

```bash
# 1. Install QEMU support (if not already installed)
# For RHEL/CentOS/Fedora:
sudo dnf install qemu-user-static

# 2. Build and push images separately
# For x86_64 (native or emulated)
podman build -t containertools:x86 -f ./Containerfile.x86
podman tag containertools:x86 quay.io/your_username/containertools:x86
podman push quay.io/your_username/containertools:x86

# For ARM64 (native or emulated)
podman build -t containertools:arm -f ./Containerfile.arm
podman tag containertools:arm quay.io/your_username/containertools:arm
podman push quay.io/your_username/containertools:arm

# 3. Create a manifest list
podman manifest create quay.io/your_username/containertools:latest

# 4. Add the images to the manifest
podman manifest add quay.io/your_username/containertools:latest quay.io/your_username/containertools:x86
podman manifest add quay.io/your_username/containertools:latest quay.io/your_username/containertools:arm

# 5. Push the manifest
podman manifest push quay.io/your_username/containertools:latest
```

For macOS users with Podman Desktop or Podman Machine:
```bash
# The QEMU emulator should be included with Podman Machine by default
# Verify it's working with:
podman machine ssh
ls -la /usr/bin/qemu-*
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
# Run interactively (you'll immediately enter the container)
podman run -it --name tools -v tools-data:/home/tools/local-storage quay.io/ryan_nix/containertools:arm

# OR run in the background (detached mode)
podman run -d -it --name tools -v tools-data:/home/tools/local-storage quay.io/ryan_nix/containertools:arm
```

If you run the container in detached mode, you can later connect to it using:
```sh
podman attach name-of-your-running-container
```

### Verify Data Persistence
To test if the data persists after container restarts:
1. Start a container with the volume and create a file:
    ```sh
    # Interactive mode for testing
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

### Copying Data to the Container
To copy files from your host machine to the container:

```sh
# Copy a single file to the container's volume
podman cp ~/path/to/yourfile tools:/home/tools/local-storage/

# Copy the directory including its name (recursive copy)
podman cp ~/path/to/your/directory tools:/home/tools/local-storage/
```

This works for both Linux and macOS users, and is the simplest way to transfer files to your container.

### Access the Volume Data from the Host

#### **Linux Users**
Podman stores volumes in `/var/lib/containers/storage/volumes/`. To access the stored data from the host:
```sh
ls /var/lib/containers/storage/volumes/tools-data/_data
```

#### **macOS Users**
Since Podman runs inside a virtual machine (VM) on macOS, volumes are not directly accessible from the host filesystem. To access the volume data:

1. Find the volume mount location inside the Podman VM:
    ```sh
    podman volume inspect tools-data
    ```
2. SSH into the Podman VM:
    ```sh
    podman machine ssh
    ```
3. Navigate to the volume's storage path inside the VM, which will be under `/var/lib/containers/storage/volumes/`:
    ```sh
    ls /var/lib/containers/storage/volumes/tools-data/_data
    ```
    
## Pushing to Quay.io

For additional instructions about publishing to Quay.io, see the "Building and Publishing the Container" section above, which includes a complete workflow.

## Available Tools

This container includes the latest builds of:
- kubectl and oc (OpenShift CLI)
- odo (OpenShift Do for developers)
- argocd and argocd-autopilot
- AWS CLI (aws)
- Azure CLI (az)
- terraform
- ansible-core with amazon.aws collection
- Python 3 with boto3 and botocore packages
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
