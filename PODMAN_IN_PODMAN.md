# Podman-in-Podman Usage Guide

Your containertools image is now configured for podman-in-podman support!

## Running on Your Workstation

### Rootless Mode (Recommended)
```bash
podman run -it --rm \
  --security-opt label=disable \
  --device /dev/fuse \
  quay.io/your-repo/containertools:latest
```

### Privileged Mode (Most Compatible)
```bash
podman run -it --rm \
  --privileged \
  quay.io/your-repo/containertools:latest
```

## Testing Podman-in-Podman

Once inside the container:

```bash
# Test basic functionality
podman run --rm hello-world

# Run a simple container
podman run --rm registry.access.redhat.com/ubi9/ubi:latest cat /etc/os-release

# Build an image
cat > Containerfile << EOF
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
RUN microdnf install -y httpd && microdnf clean all
CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
EOF

podman build -t mytest:latest .
```

## Running on OpenShift

For OpenShift, you'll need a custom Security Context Constraint (SCC):

```yaml
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: podman-in-podman
allowPrivilegedContainer: true
allowHostDirVolumePlugin: true
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
fsGroup:
  type: RunAsAny
volumes:
  - configMap
  - downwardAPI
  - emptyDir
  - persistentVolumeClaim
  - projected
  - secret
users:
  - system:serviceaccount:your-namespace:your-serviceaccount
```

Apply the SCC:
```bash
oc apply -f podman-scc.yaml
oc adm policy add-scc-to-user podman-in-podman -z your-serviceaccount
```

Then deploy your pod with the service account:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: containertools
spec:
  serviceAccountName: your-serviceaccount
  containers:
  - name: tools
    image: quay.io/your-repo/containertools:latest
    command: ["/bin/bash"]
    stdin: true
    tty: true
```

## What's Configured

The Containerfile includes:

- ✅ **VFS Storage Driver** - Most compatible for nested containers
- ✅ **fuse-overlayfs** - Better performance option
- ✅ **subuid/subgid mappings** - Proper user namespace support
- ✅ **SUID newuidmap/newgidmap** - Required for rootless
- ✅ **Host namespace sharing** - Reduces isolation overhead
- ✅ **cgroupfs manager** - Works better in nested scenarios

## Storage Drivers

The container uses the **vfs** driver by default, which is slower but most compatible. If you want to try **overlay** or **fuse-overlayfs** for better performance:

```bash
# Inside the container, edit ~/.config/containers/storage.conf
vim ~/.config/containers/storage.conf

# Change driver = "vfs" to:
driver = "overlay"
# or
driver = "fuse-overlayfs"

# Then reset storage
podman system reset
```

## Troubleshooting

**Issue**: `ERRO[0000] cannot find UID/GID for user tools`
**Solution**: The container needs `--userns=keep-id` or privileged mode

**Issue**: `Error: cannot set up namespace using newuidmap`
**Solution**: Run with `--security-opt label=disable` and `--device /dev/fuse`

**Issue**: `Error: OCI runtime error: crun: mount`
**Solution**: Use privileged mode or ensure fuse device is available

## Performance Considerations

- **VFS**: Slowest but most compatible
- **overlay**: Fastest but may not work in all nested scenarios
- **fuse-overlayfs**: Good balance, requires `/dev/fuse`

For OpenShift demos and testing, the preconfigured settings work out of the box with the appropriate SCC.
