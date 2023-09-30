A container is a great way to run essential cloud tools such as `kubectl`, openshift-cli (`oc`), OpenShift Do - for rapid application development against a Kubernetes namespace (`odo`)`ansible-playbook`s, `git`, `wget`, `argocd`, `argocd-autopilot`, AWS's cli (`aws`), Azure's CLI (`az`), `wget`, `rsync`, `tar`, `gzip`, `vim`, and `ssh`.

The container is built from CentOS Stream 9 and includes EPEL.

The prebuilt containers are found at my [Quay container repo](https://quay.io/repository/ryan_nix/containertools).
There are tags for x86 and ARM CPUs.

Build your own on x86 by running `podman build -t containertools -f ./Containerfile`

Build your own on ARM by running `podman build -t containertools -f ./Containerfile-ARM`

Instructions:

Pull the appropriate image for your system's architecture
`podman pull quay.io/ryan_nix/containertools:x86` or `podman pull quay.io/ryan_nix/containertools:arm`

List images
`podman images`

Run the container
`podman run -d -it --name tools quay.io/ryan_nix/containertools:x86` or `podman run -d -it --name tools quay.io/ryan_nix/containertools:arm`

Attach the container
`podman attach tools`

