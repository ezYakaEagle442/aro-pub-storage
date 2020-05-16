# Install applications with [Helm in AKS](https://docs.microsoft.com/en-us/azure/aks/kubernetes-helm)

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

# https://github.com/Azure/aad-pod-identity/tree/master/charts/aad-pod-identity
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts

# https://github.com/Azure/secrets-store-csi-driver-provider-azure/blob/master/charts/csi-secrets-store-provider-azure/README.md
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts

```