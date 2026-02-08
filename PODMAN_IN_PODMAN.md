# Podman-in-Podman Guide

This container ships with Podman and Buildah pre-configured for nested containerization. You can log in to registries, build images, and run containers from inside the container.

## Quick Start

### Without `--privileged` (registry login and builds)

The container is pre-configured so that `podman login` and `podman build` work without any special flags:

```bash
podman run -it --rm quay.io/ryan_nix/containertools:latest
```

Inside the container:

```bash
# Authenticate to a registry
podman login quay.io

# Build an image
podman build -t myimage:latest .

# Push to a registry
podman push myimage:latest quay.io/myuser/myimage:latest
```

This works because the image is configured with the VFS storage driver and `BUILDAH_ISOLATION=chroot`, which avoids the `newuidmap` permission errors that normally block rootless Podman-in-Podman.

### With `--privileged` (full nested container support)

If you need to **run** containers inside the container (not just build/push), use `--privileged`:

```bash
podman run -it --rm --privileged quay.io/ryan_nix/containertools:latest
```

Inside the container:

```bash
# All of the above, plus:
podman run --rm docker.io/library/alpine echo "Hello from nested container"
```

## How It Works

The image includes three configuration pieces that make this possible:

**`~/.config/containers/storage.conf`** — Uses the VFS storage driver instead of overlay. VFS is slower (it copies layers) but requires no kernel support or special privileges.

```ini
[storage]
driver = "vfs"
```

**`~/.config/containers/containers.conf`** — Shares namespaces with the host and uses cgroupfs instead of systemd.

```ini
[containers]
netns="host"
ipcns="host"
utsns="host"
cgroupns="host"

[engine]
cgroup_manager="cgroupfs"
events_logger="file"
```

**Environment variables** — `_CONTAINERS_USERNS_CONFIGURED` tells Podman to skip calling `newuidmap`/`newgidmap`, and `BUILDAH_ISOLATION=chroot` uses chroot isolation for builds instead of requiring a user namespace.

## Persisting Registry Credentials

To keep your `podman login` credentials across container restarts, mount a volume for the auth directory:

```bash
podman run -it --rm \
  -v tools-auth:/home/tools/.config/containers/auth.json:z \
  quay.io/ryan_nix/containertools:latest
```

Or mount the entire home directory as described in the main [README](README.md#persist-your-work).

## OpenShift Deployment

To use Podman-in-Podman on OpenShift, you need a custom SecurityContextConstraints (SCC) that allows privileged containers. This is typical for CI/CD pipeline agents.

### Create a Custom SCC

```yaml
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: containertools-scc
allowPrivilegedContainer: true
allowPrivilegeEscalation: true
allowedCapabilities:
  - SYS_ADMIN
  - MKNOD
  - SETUID
  - SETGID
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
fsGroup:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
volumes:
  - '*'
```

### Deploy

```bash
# Create the SCC
oc apply -f containertools-scc.yaml

# Create a service account and bind the SCC
oc create sa containertools-sa
oc adm policy add-scc-to-user containertools-scc -z containertools-sa

# Deploy with the service account
oc run containertools --image=quay.io/ryan_nix/containertools:latest \
  --overrides='{"spec":{"serviceAccountName":"containertools-sa","containers":[{"name":"containertools","image":"quay.io/ryan_nix/containertools:latest","stdin":true,"tty":true,"securityContext":{"privileged":true}}]}}' \
  -it --rm
```

## Troubleshooting

### `newuidmap: write to uid_map failed: Operation not permitted`

This means the outer container doesn't allow user namespace remapping. Either:
- Run with `--privileged`, or
- Make sure you're using the latest image (which includes the `_CONTAINERS_USERNS_CONFIGURED` fix)

If you're on an older image, reset Podman storage and it should pick up the VFS config:

```bash
podman system reset --force
```

### `database graph driver "overlay" does not match our graph driver "vfs"`

Podman previously initialized with the overlay driver. Reset it:

```bash
podman system reset --force
```

### Builds are slow

The VFS driver copies entire layers instead of using overlayfs. This is the trade-off for not requiring `--privileged`. For frequent builds, consider running with `--privileged` and switching to fuse-overlayfs:

```bash
# Inside the container, after running with --privileged:
mkdir -p ~/.config/containers
cat > ~/.config/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF
podman system reset --force
```
