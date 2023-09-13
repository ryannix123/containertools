# containertools
Container to run essential cloud-native tools such as Kubectl, OpenShift's CLI, Git, the AWS cli, the Azure CLI, etc

This container is a great way to run essential cloud tools such as `kubectl`, `openshift-cli` (oc), `ansible-playbook`s, `git`, `wget`, AWS's cli (`aws`), Azure's CLI (`az`), `wget`, `rsync`, `tar`, `gzip`, etc. The container is much slimmer than running a full VM, and it's potentially better than running package managers on your local system.

The container is built from CentOS Stream 9 and includes EPEL.

A prebuilt container image can be found [here](https://quay.io/repository/ryan_nix/containertools)
