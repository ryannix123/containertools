# Container Tools

[![Build and Push Multi-Arch Container](https://github.com/ryannix123/containertools/actions/workflows/build-container.yml/badge.svg)](https://github.com/ryannix123/containertools/actions/workflows/build-container.yml)
[![Docker Repository on Quay](https://quay.io/repository/ryan_nix/containertools/status "Docker Repository on Quay")](https://quay.io/repository/ryan_nix/containertools)

**Keep your workstation clean. Run your cloud tools in a container.**

No more cluttering your Mac or Linux machine with CLIs, SDKs, and dependencies that conflict with each other or break after OS updates. Container Tools gives you a ready-to-go environment with everything you need for Kubernetes, cloud, and infrastructure work.

## Quick Start

```bash
# Pull and run (auto-selects ARM or x64)
podman run -it --name tools quay.io/ryan_nix/containertools:latest

# Or use the architecture-specific tags
podman run -it --name tools quay.io/ryan_nix/containertools:arm   # Apple Silicon, ARM servers
podman run -it --name tools quay.io/ryan_nix/containertools:x64   # Intel/AMD
```

That's it. You're in a fully-equipped environment.

## What's Inside

| Category | Tools |
|----------|-------|
| **Kubernetes & OpenShift** | `kubectl`, `oc`, `rosa`, `odo`, `helm`, `istioctl`, `tkn` (Tekton) |
| **GitOps & Serverless** | `argocd`, `argocd-autopilot`, `kn` (Knative), `func` |
| **Cloud CLIs** | `aws`, `az` (Azure), `gcloud` (Google Cloud) |
| **Infrastructure as Code** | `terraform`, `ansible` (9+) |
| **Container Tools** | `podman` (5.x), `buildah` (via podman) |
| **Languages** | `python3`, `node.js` (22), `java-21-openjdk`, `maven` |
| **Database Clients** | `mysql`, `psql` |
| **Essentials** | `git`, `vim`, `jq`, `ssh`, `rsync` |
| **Network Load Testing** | `fortio` |

All tools automatically fetch the latest versions at build time.

## Podman-in-Podman Support

This container supports running Podman inside Podman for nested containerization workflows:

```bash
# Run with podman-in-podman support
podman run -it --rm --privileged quay.io/ryan_nix/containertools:latest

# Inside the container, you can now run podman commands
podman run --rm hello-world
podman build -t myimage:latest .
```

Perfect for:
- CI/CD demonstrations
- Building containers in pipelines
- Testing container workflows
- OpenShift Pipelines development

See [PODMAN_IN_PODMAN.md](PODMAN_IN_PODMAN.md) for detailed usage including OpenShift deployment with custom SCCs.

## Persist Your Work

Mount a volume to keep your files, configs, and credentials across sessions:

```bash
# Create a persistent volume
podman volume create tools-data

# Run with the volume mounted
podman run -it --name tools \
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
podman build -t containertools -f ./Containerfile.$(uname -m | sed 's/x86_64/x64/' | sed 's/aarch64/arm/')
```

## Why a Container?

- **Isolation** — Your tools don't interfere with your OS or each other
- **Reproducibility** — Same environment everywhere, every time
- **Clean upgrades** — Pull a new image, done. No dependency hell.
- **Multi-arch** — Works on Apple Silicon Macs, Intel machines, ARM servers
- **Always Current** — Automatically fetches latest tool versions at build time

## Security & Vulnerability Scanning

### Understanding Vulnerability Scan Results

If you scan this container image with security tools like Quay, Trivy, or similar scanners, you may see a significant number of reported vulnerabilities. **This is expected and does not indicate OS-level security issues.**

### Why Are There So Many Vulnerabilities?

The vulnerabilities come from **pre-compiled Go binaries** (ArgoCD, Istio, Knative, Tekton, etc.), not from the CentOS Stream 9 base OS or Red Hat packages:

- **Go binaries are statically linked** — They bundle all their dependencies into a single executable
- **Embedded libraries** — Even if a vulnerability is fixed upstream, pre-built binaries still contain old code until rebuilt
- **Scanner detection** — Security scanners detect vulnerable Go libraries embedded in these CLI tools

Example vulnerabilities you might see:
- `golang.org/x/crypto` in ArgoCD, Istio, Knative binaries
- `github.com/go-git/go-git` in various tools
- Other Go standard library CVEs in statically-linked binaries

### Intended Use Cases

This container is designed for:
- ✅ **Development and testing environments**
- ✅ **Demo and proof-of-concept work**
- ✅ **Interactive CLI usage**
- ✅ **YouTube tutorials and training**
- ✅ **Local workstation tooling**

This container is **NOT intended for**:
- ❌ Production workloads
- ❌ Long-running services
- ❌ Exposed network services
- ❌ Processing untrusted input

### Mitigation Strategy

1. **Regular rebuilds** — The Containerfile fetches latest versions automatically. Rebuild monthly to get updated binaries with security patches.

2. **Scope of use** — Use this container for what it's designed for: running CLI tools interactively, not as a service.

3. **Network isolation** — When using for demos, use in isolated networks or development clusters.

4. **Know your risk** — Most reported vulnerabilities require specific attack vectors (network services, file processing) that don't apply to CLI tool usage.

### For Production Use

If you need a hardened container for production CI/CD:
- Use Red Hat's official tool images (ubi-minimal with specific tools)
- Build tools from source with multi-stage builds
- Use Tekton/OpenShift Pipelines with purpose-built task images
- Implement vulnerability remediation policies

This container prioritizes **convenience and completeness** for development work over minimal attack surface.

---

Built on CentOS Stream 9. Maintained by [Ryan Nix](https://github.com/ryannix123).

[View on Quay.io →](https://quay.io/repository/ryan_nix/containertools) | [Report Issues →](https://github.com/ryannix123/containertools/issues)
