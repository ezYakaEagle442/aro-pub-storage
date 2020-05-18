# CEPH CSI driver for CEPH
See also :

- [https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage](https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage)
-[https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-ocs.html](https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-ocs.html)
- [https://www.openshift.com/blog/openshift-container-storage-4-introduction-to-ceph](https://www.openshift.com/blog/openshift-container-storage-4-introduction-to-ceph)
- [https://ceph.io](https://ceph.io)
- [https://github.com/container-storage-interface/spec](https://github.com/container-storage-interface/spec)
- [https://github.com/kubernetes-sigs/azuredisk-csi-driver](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
- [https://github.com/kubernetes-sigs/azurefile-csi-driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)
- [https://kubernetes-csi.github.io/docs/topology.html](https://kubernetes-csi.github.io/docs/topology.html)
- [https://kubernetes-csi.github.io/docs/drivers.html](https://kubernetes-csi.github.io/docs/drivers.html)
- [https://github.com/ceph/ceph-csi](https://github.com/ceph/ceph-csi)
- [https://www.redhat.com/en/technologies/storage/ceph](https://www.redhat.com/en/technologies/storage/ceph)



## Install a CEPH Cluster with Rook

Rook deploys and manages Ceph clusters running in Kubernetes, while also enabling management of storage resources and provisioning via Kubernetes APIs. We recommend Rook as the way to run Ceph in Kubernetes or to connect an existing Ceph storage cluster to Kubernetes.

See :
- [https://github.com/ceph/ceph/blob/master/doc/install/index.rst#recommended-methods](https://github.com/ceph/ceph/blob/master/doc/install/index.rst#recommended-methods)
- [Rook CEPH examples](https://github.com/rook/rook/tree/release-1.3/cluster/examples/kubernetes/ceph)
- [https://rook.io/docs/rook/v1.3/flexvolume.html#openshift](https://rook.io/docs/rook/v1.3/flexvolume.html#openshift)

The settings for Rook in OpenShift are described below, and are also included in the example yaml files:

operator-openshift.yaml: Creates the security context constraints and starts the operator deployment
object-openshift.yaml: Creates an object store with rgw listening on a valid port number for OpenShift

```sh

# HELM Install https://rook.io/docs/rook/v1.3/helm-operator.html
# https://github.com/rook/rook/tree/release-1.3/cluster/charts/rook-ceph
rook_namespace="rook-ceph"
helm show chart rook-release/rook-ceph
helm inspect chart rook-release/rook-ceph
oc create ns $rook_namespace
helm install rook-ceph rook-release/rook-ceph --namespace $rook_namespace \
    --set csi.enableCephfsDriver=false \
    --set csi.logLevel=5

helm ls -n $rook_namespace
helm status rook-ceph -n $rook_namespace

oc get crds -n $rook_namespace | grep -i "ceph"
oc get rolebinding -n $rook_namespace | grep -i "ceph"
oc get role -n $rook_namespace | grep -i "ceph"
oc get ClusterRoleBinding | grep -i "ceph"
oc get ClusterRole | grep -i "ceph"
oc get cm -n $rook_namespace | grep -i "ceph"
oc get sa -n $rook_namespace | grep -i "ceph"
oc get svc -n $rook_namespace | grep -i "ceph"
oc get psp 
oc get ds -n $rook_namespace | grep -i "ceph"
oc get deploy -n $rook_namespace | grep -i "ceph"E
oc get rs -n $rook_namespace | grep -i "ceph"
oc get po -n $rook_namespace | grep -i "ceph"
oc get sc -A

oc get events -n $rook_namespace | grep -i "Error" 

```

## Install CEPH Driver

See :
- [https://github.com/ceph/ceph-csi/blob/master/docs/deploy-cephfs.md#deployment-with-kubernetes](https://github.com/ceph/ceph-csi/blob/master/docs/deploy-cephfs.md#deployment-with-kubernetes)
- [https://github.com/ceph/ceph-csi/blob/master/charts/ceph-csi-cephfs/README.md](https://github.com/ceph/ceph-csi/blob/master/charts/ceph-csi-cephfs/README.md)
- Your ARO [cluster must allow privileged pods](https://github.com/ceph/ceph-csi/blob/master/docs/deploy-cephfs.md#deployment-with-kubernetes) i.e. --allow-privileged flag must be set to true for both the API server and the kubelet. Moreover, as stated in the mount propagation docs, the Docker daemon of the cluster nodes must allow shared mounts.
- [https://github.com/ceph/ceph-csi/issues/1077](https://github.com/ceph/ceph-csi/issues/1077)
- [Managing Security Context Constraints / Volumes in ARO](https://docs.openshift.com/container-platform/4.3/authentication/managing-security-context-constraints.html#authorization-controlling-volumes_configuring-internal-oauth)
```sh

# https://docs.openshift.com/aro/4/authentication/managing-security-context-constraints.html
# https://docs.openshift.com/aro/4/rest_api/index.html#securitycontext-v1core
# https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/

export CSI_NAMESPACE="ceph-csi-cephfs"
oc create namespace $CSI_NAMESPACE

envsubst < ./cnf/ceph/csi-provisioner-rbac.yaml > deploy/csi-provisioner-rbac.yaml
cat deploy/csi-provisioner-rbac.yaml
oc create -f deploy/csi-provisioner-rbac.yaml -n $CSI_NAMESPACE

envsubst < ./cnf/ceph/csi-nodeplugin-rbac.yaml > deploy/csi-nodeplugin-rbac.yaml
cat deploy/csi-nodeplugin-rbac.yaml
oc create -f deploy/csi-nodeplugin-rbac.yaml -n $CSI_NAMESPACE

oc get clusterrolebindings | grep -i "ceph"
oc get clusterroles | grep -i "ceph"
oc get sa -n $CSI_NAMESPACE | grep -i "ceph"

envsubst < ./cnf/ceph/csi-provisioner-psp.yaml > deploy/csi-provisioner-psp.yaml
cat deploy/csi-provisioner-psp.yaml
oc create -f deploy/csi-provisioner-psp.yaml -n $CSI_NAMESPACE

envsubst < ./cnf/ceph/csi-nodeplugin-psp.yaml > deploy/csi-nodeplugin-psp.yaml
cat deploy/csi-nodeplugin-psp.yaml
oc create -f deploy/csi-nodeplugin-psp.yaml -n $CSI_NAMESPACE

oc get rolebindings -n $CSI_NAMESPACE | grep -i "ceph"
oc get roles -n $CSI_NAMESPACE | grep -i "ceph"
oc get sa -n $CSI_NAMESPACE | grep -i "ceph"

oc get psp

oc create -f ./cnf/ceph/csi-config-map.yaml -n $CSI_NAMESPACE

# envsubst < ./cnf/ceph/csi-aro-scc.yaml > deploy/csi-aro-scc.yaml
# cat deploy/csi-aro-scc.yaml
# oc create -f deploy/csi-aro-scc.yaml
# oc describe scc cephfs-csi-provisioner-scc
oc adm policy add-scc-to-user privileged system:serviceaccount:$CSI_NAMESPACE:cephfs-csi-nodeplugin
oc get scc -o wide
oc describe scc privileged

oc create -f ./cnf/ceph/csi-cephfsplugin-provisioner.yaml -n $CSI_NAMESPACE
oc create -f ./cnf/ceph/csi-cephfsplugin.yaml -n $CSI_NAMESPACE

oc get rolebinding -n $CSI_NAMESPACE | grep -i "ceph"
oc get role -n $CSI_NAMESPACE | grep -i "ceph"
oc get ClusterRoleBinding | grep -i "ceph"
oc get ClusterRole | grep -i "ceph"
oc get cm -n $CSI_NAMESPACE
oc get sa -n $CSI_NAMESPACE
oc get svc -n $CSI_NAMESPACE
oc get psp | grep -i "ceph"
oc get ds -n $CSI_NAMESPACE
oc get deploy -n $CSI_NAMESPACE
oc get rs -n $CSI_NAMESPACE
oc get sc -A
oc get po -n $CSI_NAMESPACE

oc get events -n $CSI_NAMESPACE | grep -i "Error" 

for pod in $(oc get pods -l app=csi-cephfsplugin -n $CSI_NAMESPACE -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n $CSI_NAMESPACE | grep -i "Error"
    oc logs $pod -c driver-registrar -n $CSI_NAMESPACE #| grep -i "Error"
    oc logs $pod -c csi-cephfsplugin -n $CSI_NAMESPACE #| grep -i "Error"
    oc logs $pod -c liveness-prometheus -n $CSI_NAMESPACE #| grep -i "Error"
done


oc login $aro_api_server_url -u $aro_usr -p $aro_pwd
# token_secret_value=$(oc get secrets default-token-rmslp -o json | jq -Mr '.data.token' | base64 -d)
# token_secret_value=`cat ~/.azure/accessTokens.json`

token_secret_value=$(oc whoami -t)
# ENDPOINT=$(oc config current-context | cut -d/ -f2 | tr - .)
# NAMESPACE=$(oc config current-context | cut -d/ -f1)
# curl -k $aro_api_server_url/apis/v1/core/privileged=true -H "Authorization: Bearer $token_secret_value"

curl -k \
    -X POST \
    -d @- \
    -H "Authorization: Bearer $token_secret_value" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    $aro_api_server_url/apis/v1/core <<'EOF'
{
  "privileged=" : "true"
}
EOF

curl -k $aro_api_server_url/apis/v1/namespaces -H "Authorization: Bearer $token_secret_value" -H 'Accept: application/json'


oc adm policy --help


helm install --namespace "ceph-csi-cephfs" "ceph-csi-cephfs" ceph-csi/ceph-csi-cephfs
    #--set ceph-csi-cephfs.serviceAccountName.nodeplugin="" \
    #--set ceph-csi-cephfs.serviceAccountName.provisioner="" 

helm ls -n "ceph-csi-cephfs" 
helm status "ceph-csi-cephfs" -n "ceph-csi-cephfs"

```

## Test CEPH

See :
- [https://github.com/ceph/ceph-csi/blob/master/examples/README.md#deploying-the-storage-class](https://github.com/ceph/ceph-csi/blob/master/examples/README.md#deploying-the-storage-class)
- Samples from [https://github.com/ceph/ceph-csi/tree/master/examples/cephfs](https://github.com/ceph/ceph-csi/tree/master/examples/cephfs)

```sh

# bash ./cnf/ceph/cephfs/logs.sh

for pod in $(oc get pods -l app=csi-cephfsplugin -n $CSI_NAMESPACE -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n $CSI_NAMESPACE | grep -i "Error"
    oc logs $pod -c driver-registrar -n $CSI_NAMESPACE #| grep -i "Error"
    oc logs $pod -c csi-cephfsplugin -n $CSI_NAMESPACE #| grep -i "Error"
    oc logs $pod -c liveness-prometheus -n $CSI_NAMESPACE #| grep -i "Error"
done

mkdir deploy/cephfs
# Required for statically provisioned volumes
export CEPH_USR_ID="???": #<plaintext ID>
export CEPH_USR_KYE="???" # <Ceph auth key corresponding to ID above>

# Required for dynamically provisioned volumes
export CEPH_ADM_ID="???" # <plaintext ID>
export CEPH_ADM_KEY="??? " # <Ceph auth key corresponding to ID above>

envsubst < ./cnf/ceph/cephfs/secret.yaml > deploy/cephfs/secret.yaml
cat deploy/cephfs/secret.yaml
oc create -f deploy/cephfs/secret.yaml -n $CSI_NAMESPACE

export CLUSTER_ID=$cluster_name
envsubst < ./cnf/ceph/cephfs/storageclass.yaml > deploy/cephfs/storageclass.yaml
cat deploy/cephfs/storageclass.yaml

oc create -f ./cnf/ceph/cephfs/storageclass.yaml
oc create -f ./cnf/ceph/cephfs/pvc.yaml
oc create -f ./cnf/ceph/cephfs/pod.yaml

```

## Clean-Up
```sh

helm uninstall "ceph-csi-cephfs" -n "ceph-csi-cephfs"

oc adm policy remove-scc-from-user privileged system:serviceaccount:$CSI_NAMESPACE:cephfs-csi-nodeplugin

oc delete ClusterRoleBinding cephfs-csi-nodeplugin
oc delete ClusterRoleBinding cephfs-csi-provisioner-role

oc delete ClusterRole cephfs-csi-nodeplugin
oc delete ClusterRole cephfs-csi-nodeplugin-rules
oc delete ClusterRole cephfs-external-provisioner-runner
oc delete ClusterRole cephfs-external-provisioner-runner-rules

oc delete psp cephfs-csi-nodeplugin-psp
oc delete psp cephfs-csi-provisioner-psp -n  $CSI_NAMESPACE
oc delete namespace $CSI_NAMESPACE

oc delete scc cephfs-csi-provisioner-scc

helm uninstall rook-ceph -n $rook_namespace
oc delete ns rook-ceph


```