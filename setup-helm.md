# Install applications with [Helm in ARO](https://docs.openshift.com/aro/4/cli_reference/helm_cli/getting-started-with-helm-on-openshift-container-platform.html)

Helm version 3 does not come with any repositories predefined, so you’ll need [initialize the stable chart repository](https://v3.helm.sh/docs/intro/quickstart/#initialize-a-helm-chart-repository)

```sh
helm version
helm get -h
# https://helm.sh/docs/intro/using_helm/
# You can see which repositories are configured using helm repo list
helm repo list

# Init default repo: https://hub.helm.sh/charts
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo list
helm search repo
helm search hub
helm search repo mongodb

helm repo update

# https://github.com/ceph/ceph-csi/blob/master/charts/ceph-csi-cephfs/README.md
# https://hub.helm.sh/charts/ceph-csi/ceph-csi-cephfs
helm repo add ceph-csi https://ceph.github.io/csi-charts
# helm repo add ceph-csi-cephfs https://github.com/ceph/ceph-csi/tree/master/charts/ceph-csi-cephfs

# https://rook.io/docs/rook/v1.3/helm-operator.html
# https://github.com/rook/rook/tree/release-1.3/cluster/charts/rook-ceph
helm repo add rook-release https://charts.rook.io/release

# https://vmware-tanzu.github.io/helm-charts/
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts

# https://docs.kasten.io/install/requirements.html#install-prereqs
helm repo add kasten https://charts.kasten.io/

# https://github.com/Azure/aad-pod-identity/tree/master/charts/aad-pod-identity
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts

# https://github.com/Azure/secrets-store-csi-driver-provider-azure/blob/master/charts/csi-secrets-store-provider-azure/README.md
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts

```