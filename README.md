# Container Tools

[![Build and Push Multi-Arch Container](https://github.com/ryannix123/containertools/actions/workflows/build-container.yml/badge.svg)](https://github.com/ryannix123/containertools/actions/workflows/build-container.yml)
[![Docker Repository on Quay](https://quay.io/repository/ryan_nix/containertools/status "Docker Repository on Quay")](https://quay.io/repository/ryan_nix/containertools)

**Keep your workstation clean. Run your cloud tools in a container.**

No more cluttering your Mac or Linux machine with CLIs, SDKs, and dependencies that conflict with each other or break after OS updates. Container Tools gives you a ready-to-go environment with everything you need for Kubernetes, cloud, and infrastructure work.

## Quick Start

```bash
# Pull and run (auto-selects ARM or x86)
podman run -it --name tools quay.io/ryan_nix/containertools:latest

# Or use the architecture-specific tags
podman run -it --name tools quay.io/ryan_nix/containertools:arm   # Apple Silicon, ARM servers
podman run -it --name tools quay.io/ryan_nix/containertools:x86   # Intel/AMD
```

That's it. You're in a fully-equipped environment.

## What's Inside

| Category | Tools |
|----------|-------|
| **Kubernetes & OpenShift** | `kubectl`, `oc`, `odo`, `helm`, `istioctl`, `tkn` |
| **GitOps & Serverless** | `argocd`, `argocd-autopilot`, `kn`, `func` |
| **Cloud CLIs** | `aws`, `az` |
| **Infrastructure as Code** | `terraform`, `ansible` |
| **Languages** | `python3`, `nodejs`, `java-21-openjdk`, `maven` |
| **Database Clients** | `mysql`, `psql` |
| **Essentials** | `git`, `vim`, `podman`, `jq`, `ssh`, `rsync` |
| **Testing** | `fortio` |
| **TLS / Certificates** | `certbot`, `certbot-dns-route53`, `certbot-dns-cloudflare` |

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
podman build -t containertools -f ./Containerfile.$(uname -m | sed 's/x86_64/x86/' | sed 's/aarch64/arm/')
```

## Using SSH Keys Securely

> **Never bake a private key into an image layer.** Even if you delete it in a later `RUN` step, it remains permanently accessible in the layer history. Use one of the patterns below instead.

### Option 1 — Runtime volume mount (recommended for interactive use)

Mount your key at run time. Nothing sensitive ever touches the image. The `.ssh` directory is pre-created in the image with `700` permissions so the mount lands correctly.

```bash
podman run -it --rm \
  -v $HOME/.ssh/id_rsa:/home/tools/.ssh/id_rsa:ro,Z \
  quay.io/ryan_nix/containertools:latest
```

> The `:Z` flag applies the correct SELinux label on RHEL/Fedora hosts. Use `:z` (lowercase) for shared mounts across multiple containers.

### Option 2 — Build-time secret mount (for keys only needed during the build)

Use Podman's `--secret` flag. The key is available inside the `RUN` step but is **never written to any image layer**.

```dockerfile
# In your Containerfile
RUN --mount=type=secret,id=ssh_key,uid=1001 \
    cp /run/secrets/ssh_key /home/tools/.ssh/id_rsa && \
    chmod 600 /home/tools/.ssh/id_rsa
```

```bash
podman build \
  --secret id=ssh_key,src=$HOME/.ssh/id_rsa \
  -f Containerfile.x64 \
  -t containertools:x64 .
```

This is ideal for cloning private repositories during a build step, after which the key is no longer needed in the final image.

### Option 3 — Kubernetes / OpenShift Secret (for platform deployments)

```bash
oc create secret generic ssh-private-key \
  --from-file=ssh-privatekey=$HOME/.ssh/id_rsa \
  --type=kubernetes.io/ssh-auth
```

Reference it in your Pod or Deployment spec:

```yaml
spec:
  volumes:
    - name: ssh-key
      secret:
        secretName: ssh-private-key
        defaultMode: 0600
  containers:
    - name: containertools
      image: quay.io/ryan_nix/containertools:latest
      volumeMounts:
        - name: ssh-key
          mountPath: /home/tools/.ssh
          readOnly: true
```

### Option 4 — SSH agent forwarding

Forward your local SSH agent into the container so no key file is ever present inside it at all:

```bash
podman run -it --rm \
  -v $SSH_AUTH_SOCK:/tmp/ssh_auth.sock:Z \
  -e SSH_AUTH_SOCK=/tmp/ssh_auth.sock \
  quay.io/ryan_nix/containertools:latest
```

---

## Working with Certbot

The image ships with `certbot`, `certbot-dns-route53`, and `certbot-dns-cloudflare` installed. Because the container runs as the non-root `tools` user, certbot's working directories are pre-created under `~/letsencrypt` so you don't need root or extra flags for the default system paths.

| Purpose | Path |
|---|---|
| Config / certificates | `~/letsencrypt/config` |
| Working directory | `~/letsencrypt/work` |
| Logs | `~/letsencrypt/logs` |

### Route 53 DNS challenge (AWS)

Credentials are sourced from environment variables or an AWS profile — no config file needed.

```bash
podman run -it --rm \
  -e AWS_ACCESS_KEY_ID=<your-key-id> \
  -e AWS_SECRET_ACCESS_KEY=<your-secret> \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -v $HOME/letsencrypt:/home/tools/letsencrypt:Z \
  quay.io/ryan_nix/containertools:latest \
  certbot certonly \
    --dns-route53 \
    --config-dir  /home/tools/letsencrypt/config \
    --work-dir    /home/tools/letsencrypt/work \
    --logs-dir    /home/tools/letsencrypt/logs \
    -d your.domain.com
```

Mount `~/letsencrypt` from your host so issued certificates persist between container runs.

### Cloudflare DNS challenge

Create a credentials file on your host:

```ini
# ~/cloudflare.ini
dns_cloudflare_api_token = <your-cloudflare-api-token>
```

```bash
podman run -it --rm \
  -v $HOME/cloudflare.ini:/home/tools/cloudflare.ini:ro,Z \
  -v $HOME/letsencrypt:/home/tools/letsencrypt:Z \
  quay.io/ryan_nix/containertools:latest \
  certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /home/tools/cloudflare.ini \
    --config-dir  /home/tools/letsencrypt/config \
    --work-dir    /home/tools/letsencrypt/work \
    --logs-dir    /home/tools/letsencrypt/logs \
    -d your.domain.com
```

### Renewing certificates

```bash
podman run -it --rm \
  -v $HOME/letsencrypt:/home/tools/letsencrypt:Z \
  quay.io/ryan_nix/containertools:latest \
  certbot renew \
    --config-dir  /home/tools/letsencrypt/config \
    --work-dir    /home/tools/letsencrypt/work \
    --logs-dir    /home/tools/letsencrypt/logs
```

### Loading a certificate into OpenShift

After a certificate is issued, load it directly into an OpenShift TLS secret:

```bash
oc create secret tls my-tls-secret \
  --cert=$HOME/letsencrypt/config/live/your.domain.com/fullchain.pem \
  --key=$HOME/letsencrypt/config/live/your.domain.com/privkey.pem
```

### Installing additional certbot plugins

If you need a plugin not included in the image (e.g. `certbot-dns-google`), install it at runtime:

```bash
pip3 install --user certbot-dns-google
```

Or add it to the `pip3 install --user` block in the Containerfile before building.

---

## Why a Container?

- **Isolation** — Your tools don't interfere with your OS or each other
- **Reproducibility** — Same environment everywhere, every time
- **Clean upgrades** — Pull a new image, done. No dependency hell.
- **Multi-arch** — Works on Apple Silicon Macs, Intel machines, ARM servers

---

Built on CentOS Stream 9 (ARM) / CentOS Stream 10 (x86_64). [View on Quay.io →](https://quay.io/repository/ryan_nix/containertools)