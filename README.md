# Container Tools

![Podman](https://img.shields.io/badge/Podman-892CA0?style=for-the-badge&logo=podman&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Cloud](https://img.shields.io/badge/Cloud-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)

[![Build and Push Multi-Arch Container](https://github.com/ryannix123/containertools/actions/workflows/build-container.yml/badge.svg)](https://github.com/ryannix123/containertools/actions/workflows/build-container.yml)
[![Docker Repository on Quay](https://quay.io/repository/ryan_nix/containertools/status "Docker Repository on Quay")](https://quay.io/repository/ryan_nix/containertools)

**Keep your workstation clean. Run your cloud tools in a container.**

No more cluttering your Mac or Linux machine with CLIs, SDKs, and dependencies that conflict with each other or break after OS updates. Container Tools gives you a ready-to-go environment with everything you need for Kubernetes, cloud, and infrastructure work.

## Quick Start

### Interactive Mode

Start the container and jump right into a shell:

```bash
# Pull and run (auto-selects ARM or x86)
podman run -it --name tools quay.io/ryan_nix/containertools:latest

# Or use the architecture-specific tags
podman run -it --name tools quay.io/ryan_nix/containertools:arm   # Apple Silicon, ARM servers
podman run -it --name tools quay.io/ryan_nix/containertools:x86   # Intel/AMD
```

### Background Mode

Run the container in the background and attach when needed:

```bash
# Start detached with a name
podman run -d --name tools -it --rm --privileged quay.io/ryan_nix/containertools:latest

# Attach to the running container
podman attach tools

# Or execute commands directly
podman exec -it tools kubectl get nodes
```

That's it. You're in a fully-equipped environment.

## What's Inside

| Category | Tools |
|----------|-------|
| **Kubernetes & OpenShift** | `kubectl`, `oc`, `odo`, `helm`, `istioctl`, `tkn` |
| **GitOps & Serverless** | `argocd`, `argocd-autopilot`, `kn`, `func` |
| **Cloud CLIs** | `aws`, `az` |
| **Infrastructure as Code** | `terraform`, `ansible` |
| **Languages** | `python3`, `nodejs`, `java-17-openjdk`, `maven` |
| **Database Clients** | `mysql`, `psql` |
| **Essentials** | `git`, `vim`, `podman`, `jq`, `ssh`, `rsync` |
| **Testing** | `fortio` |

## Persist Your Work

Mount a volume to keep your files, configs, and credentials across sessions:

```bash
# Create a persistent volume
podman volume create tools-data

# Run with the volume mounted (interactive)
podman run -it --name tools \
  -v tools-data:/home/tools/local-storage \
  quay.io/ryan_nix/containertools:latest

# Or run in background mode with volume
podman run -d --name tools -it --rm --privileged \
  -v tools-data:/home/tools/local-storage \
  quay.io/ryan_nix/containertools:latest
```

Your data lives in `/home/tools/local-storage` inside the container.

## Copy Files In

```bash
# Copy files into the running container
podman cp ~/my-kubeconfig tools:/home/tools/local-storage/
podman cp ~/projects/my-ansible-playbook tools:/home/tools/local-storage/
```

## Reconnect to Your Container

```bash
# If you exit, your container keeps running. Reattach with:
podman attach tools

# Or start it if stopped:
podman start -ai tools
```

## Build It Yourself

```bash
git clone https://github.com/ryannix123/containertools.git
cd containertools

# Build for your architecture
podman build -t containertools -f ./Containerfile.$(uname -m | sed 's/x86_64/x86/' | sed 's/aarch64/arm/')
```

## Why a Container?

- **Isolation** — Your tools don't interfere with your OS or each other
- **Reproducibility** — Same environment everywhere, every time
- **Clean upgrades** — Pull a new image, done. No dependency hell.
- **Multi-arch** — Works on Apple Silicon Macs, Intel machines, ARM servers

---

Built on CentOS Stream 9. [View on Quay.io →](https://quay.io/repository/ryan_nix/containertools)
