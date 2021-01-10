See also :

- [https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage](https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage)
- [https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-azure.html#storage-create-azure-storage-class_persistent-storage-azure](https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-azure.html#storage-create-azure-storage-class_persistent-storage-azure)
- [https://github.com/container-storage-interface/spec](https://github.com/container-storage-interface/spec)
- [https://github.com/kubernetes-sigs/azuredisk-csi-driver](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
- [https://kubernetes-csi.github.io/docs/topology.html](https://kubernetes-csi.github.io/docs/topology.html)
- [https://kubernetes-csi.github.io/docs/drivers.html](https://kubernetes-csi.github.io/docs/drivers.html)

# Pre-req

See :
- [install guide](https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/docs/install-azuredisk-csi-driver.md)
- Available [sku](https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/docs/driver-parameters.md) are : Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS
- [Pre-req](https://github.com/kubernetes-sigs/azuredisk-csi-driver#prerequisite)
- [https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/charts/v0.7.0/azuredisk-csi-driver/templates/csi-azuredisk-node.yaml#L93](https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/charts/v0.7.0/azuredisk-csi-driver/templates/csi-azuredisk-node.yaml#L93)

The driver initialization depends on a Cloud provider config file, usually it's /etc/kubernetes/azure.json on all kubernetes nodes deployed by AKS or aks-engine, here is azure.json example. This driver also supports read cloud config from kuberenetes secret.

<span style="color:red">**/!\ IMPORTANT**</span> : In openshift the creds file is located in **“/etc/kubernetes/cloud.conf”**, so you would need to replace the path in the deployment for the driver from “/etc/kubernetes/azure.json” to “/etc/kubernetes/cloud.conf”, issue #[398](https://github.com/kubernetes-sigs/azuredisk-csi-driver/issues/398) logged.

**To specify a different cloud provider config file, create azure-cred-file configmap before driver installation, e.g. for OpenShift, it's /etc/kubernetes/cloud.conf**

```sh

# https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/docs/read-from-secret.md
mkdir deploy
tenantId=$(az account show --query tenantId -o tsv)

# https://kubernetes.io/docs/concepts/configuration/secret/#decoding-a-secret
oc get secrets -n kube-system
oc describe secret azure-cloud-provider -n kube-system
azure_cnf_secret=$(oc get secret azure-cloud-provider -n kube-system -o jsonpath="{.data.cloud-config}" | base64 --decode)
echo "Azure Cloud Provider config secret " $azure_cnf_secret

azure_cnf_secret_length=$(echo -n $azure_cnf_secret | wc -c)
echo "Azure Cloud Provider config secret length " $azure_cnf_secret_length

# This is quick & dirty, should be improved with a Regexp
aadClientId="${azure_cnf_secret:13:36}"
echo "aadClientId " $aadClientId

aadClientSecret="${azure_cnf_secret:67:$azure_cnf_secret_length}"
echo "aadClientSecret" $aadClientSecret

# See https://github.com/kubernetes-sigs/cloud-provider-azure/blob/master/docs/cloud-provider-config.md#auth-configs
# https://kubernetes-sigs.github.io/cloud-provider-azure/install/configs/#setting-azure-cloud-provider-from-kubernetes-secrets
cat <<EOF >> deploy/cloud.conf
{
"tenantId": "$tenantId",
"subscriptionId": $subId,
"resourceGroup": "$managed_rg_name",
"location": "$location",
"useManagedIdentityExtension": false,
"aadClientId": "$aadClientId",
"aadClientSecret": "$aadClientSecret"
}
EOF

cat deploy/cloud.conf
export AZURE_CLOUD_SECRET=`cat deploy/cloud.conf | base64 | awk '{printf $0}'; echo`
envsubst < ./cnf/azure-cloud-provider.yaml > deploy/azure-cloud-provider.yaml

cat deploy/azure-cloud-provider.yaml
oc apply -f ./deploy/azure-cloud-provider.yaml
# azure_cnf_secret=$(oc get secret azure-cloud-provider -n kube-system -o jsonpath="{.data.cloud-config}" | base64 --decode)


# https://v1-16.docs.kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-configmaps-from-files
oc create configmap azure-cred-file --from-literal=path="/etc/kubernetes/cloud.conf" -n kube-system
oc get cm -n kube-system
oc describe cm azure-cred-file -n kube-system
oc get cm  azure-cred-file -n kube-system -o yaml

oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:csi-azuredisk-node-sa
oc describe scc privileged

oc describe role csi-azuredisk-controller-secret-role -n kube-system
oc describe role azure-creds-secret-reader -n kube-system
oc describe rolebinding aro-cloud-provider-secret-read -n kube-system
oc describe role aro-cloud-provider-secret-reader -n kube-system

oc describe clusterrole azure-cloud-provider-secret-getter
oc describe sa azure-cloud-provider -n kube-system
oc describe sa node-bootstrapper -n openshift-machine-config-operator


# Must allow SA node-bootstrapper from Namespace openshift-machine-config-operator to get secrets in "kube-system",
# saw error : "system:serviceaccount:openshift-machine-config-operator:node-bootstrapper" cannot get resource "secrets" in API group "" in the namespace "kube-system", skip initializing from secret
oc apply -f ./cnf/node-bootstrapper-role.yaml
oc describe role node-bootstrapper-secret -n kube-system
oc describe rolebinding node-bootstrapper-secret-reader-binding -n kube-system


#oc describe role azure-creds-secret-reader -n kube-system
# oc describe rolebinding aro-cloud-provider-secret-read -n kube-system
# oc describe clusterrole azure-cloud-provider-secret-getter
# oc describe sa azure-cloud-provider -n kube-system
# oc describe sa node-bootstrapper -nopenshift-machine-config-operator
# oc describe clusterrolebinding azure-cloud-provider-secret-getter-controller
# oc describe clusterrolebinding azure-cloud-provider-secret-getter-node


```

# Install the Azure Disk CSI Driver

[ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#restrictions) :
- You must create the ConfigMap before referencing it in a Pod specification
- ConfigMaps reside in a specific Namespace. A ConfigMap can only be referenced by pods residing in the same namespace.

```sh

oc apply -f ./cnf/cloud-cfg-test-pod.yaml
oc describe pvc test-host-pvc
oc describe pv test-host-pv
oc describe pod test-pod
oc get po
oc exec -it test-pod -- bash
ls -al /mnt/k8s
cat /mnt/k8s/cloud.conf # /etc/kubernetes/azurestackcloud.json
```

<span style="color:red">**/!\ IMPORTANT** </span> :  HOTFIX to workaround [issues #658](https://github.com/kubernetes-sigs/azuredisk-csi-driver/issues/658), to apply on ARO & OpenShift :

You need to copy /etc/pki/tls/certs/ca-bundle.crt /etc/pki/tls/certs/ca-certificate.crt

See [https://www.openshift.com/blog/managing-sccs-in-openshift](https://www.openshift.com/blog/managing-sccs-in-openshift)
```sh
oc get scc --as system:admin
oc describe scc hostaccess

oc whoami
oc get ClusterRoleBinding | grep -i "admin"
oc describe ClusterRoleBinding cluster-admin
oc describe ClusterRole cluster-admin

oc create serviceaccount pki-sa -n default
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:default:pki-sa
oc adm policy add-scc-to-user hostaccess -z pki-sa
#oc adm policy add-scc-to-user hostaccess system:serviceaccount:default:pki-sa
# oc adm policy add-scc-to-user privileged system:serviceaccount:default:pki-sa

oc adm policy add-scc-to-user hostaccess system:admin -n default
# oc adm policy add-scc-to-user hostaccess kube:admin -n default
# oc adm policy add-scc-to-user hostaccess root -n default
oc describe scc hostaccess | grep -i "Users:"

oc apply -f ./cnf/pki-tls-ca-cnf-pod.yaml
oc describe pvc pki-tls-ca-cnf-pvc
oc describe pv pki-tls-ca-cnf-pv
oc describe pod pki-tls-ca-cnf-pod
oc get po

# Patch the Pod to run with the SA
# oc patch po/pki-tls-ca-cnf-pod -p '{"spec":{"serviceAccountName": "pki-sa"}}'
# oc describe pod pki-tls-ca-cnf-pod

# oc rsh pki-tls-ca-cnf-pod
oc exec -it pki-tls-ca-cnf-pod -- bash
id
ls -al /mnt/pki/tls/certs/ca-bundle.crt
# cp /mnt/pki/tls/certs/ca-bundle.crt /mnt/pki/tls/certs/ca-certificate.crt
cp /mnt/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /mnt/pki/tls/certs/ca-certificate.crt
ls -al /mnt/pki/tls/certs

# quick & dirty hotfix as ARO has 3 Worker Nodes by default, this is not enough for more than 3 Nodes, does not support Autosclaing neither.
# a DaemonSet might be considered instead
oc get nodes -l topology.kubernetes.io/zone=westeurope-1
oc get nodes -l topology.kubernetes.io/zone=westeurope-2
oc get nodes -l topology.kubernetes.io/zone=westeurope-3
oc apply -f ./cnf/pki-tls-ca-cnf-spread-pods-to-zones.yaml
oc get po -o wide
oc describe pod pki-tls-ca-zone-1
oc describe pod pki-tls-ca-zone-2
oc describe pod pki-tls-ca-zone-3

oc exec -it pod pki-tls-ca-zone-1 -- cp /mnt/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /mnt/pki/tls/certs/ca-certificate.crt
oc exec -it pod pki-tls-ca-zone-2 -- cp /mnt/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /mnt/pki/tls/certs/ca-certificate.crt
oc exec -it pod pki-tls-ca-zone-3 -- cp /mnt/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /mnt/pki/tls/certs/ca-certificate.crt


# DaemonSet
oc apply -f ./cnf/pki-tls-ca-cnf-ds.yaml
oc get ds -o wide
oc get po -l name=pki-tls-ca -o wide

for pod in $(oc get po -l name=pki-tls-ca -o custom-columns=:metadata.name)
do
    node=$(oc get po $pod -o custom-columns=:spec.nodeName)
    echo "Checking pod on node " $node
    echo ""
    # oc exec -it $pod -- cp /mnt/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /mnt/pki/tls/certs/ca-certificate.crt
    oc exec -it $pod -- ls -al /mnt/pki/tls/certs
    echo ""
done

#  it looks like the Driver still look for the CA certs. at /etc/ssl/certs , in fact the issue there is that the Intermediate CA "DigiCert SHA2 Secure Server CA" is missing at at/etc/ssl/certs : the X509 error is about the certificate "login.microsoftonline-int.com" delivered on 06 Oct. 2020 by "DigiCert SHA2 Secure Server CA" which parent is "DigiCert Global Root CA"
# Hotfix 2 : manually import that missing CA Certificate to all Hosts

# Check the Certificate with https://www.sslshopper.com/certificate-decoder.html
# openssl x509 -in certificate.crt -text -noout

for pod in $(oc get po -l name=root-storage-pod -o custom-columns=:metadata.name)
do
    node=$(oc get po $pod -o custom-columns=:spec.nodeName)
    echo "About to apply CA Certificate Hotfix from pod on Node " $node
    echo ""
    oc exec -it $pod -- wget https://raw.githubusercontent.com/ezYakaEagle442/aro-pub-storage/master/cnf/DigiCert_SHA2_Secure_Server_CA.cer
    oc exec -it $pod -- cp DigiCert_SHA2_Secure_Server_CA.cer /mnt/root/etc/ssl/certs
    oc exec -it $pod -- ls -al /mnt/root/etc/ssl/certs
    echo ""
done



# https://unix.stackexchange.com/questions/203606/is-there-any-way-to-install-nano-on-coreos
# /bin/toolbox
# dnf install nano -y
apt-get update
apt-get upgrade
apt search nano 
apt-get install nano -y
# apt-get install nano-tiny -y
nano /mnt/k8s/cloud.conf

wget https://raw.githubusercontent.com/mohatb/kubectl-wls/master/kubectl-wls
chmod +x ./kubectl-wls
sudo mv ./kubectl-wls /usr/local/bin/kubectl-wls
kubectl-wls

# test
systemctl status kubelet


# https://docs.openshift.com/container-platform/4.3/architecture/infrastructure_components/kubernetes_infrastructure.html
oc apply -f ./cnf/kube-cfg-test-pod.yaml
oc describe pvc test-kube-cfg-pvc
oc describe pv test-kube-cfg-pv
oc describe pod test-kube-cnf-pod
oc get po -o wide
oc exec -it test-kube-cnf-pod -- bash
ls -al /mnt/origin
cat /mnt/origin/kubeconfig

oc apply -f ./cnf/root-storage-test-pod.yaml
oc describe pvc root-storage-pvc
oc describe pv root-storage-pv
oc describe pod root-storage-pod
oc get po -o wide
oc exec -it root-storage-pod -- bash
ls -al /mnt/root
cat /mnt/root/etc/kubernetes/kubeconfig

# oc apply -f ./cnf/csi-azuredisk-controller.yaml

driver_version=master #v0.10.0
echo "Driver version " $driver_version
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/$driver_version/deploy/install-driver.sh | bash -s $driver_version --

oc get rolebinding -n kube-system | grep -i "azuredisk"
oc get role -n kube-system | grep -i "azuredisk"
oc get ClusterRoleBinding | grep -i "azuredisk"
oc get ClusterRole | grep -i "azuredisk"
oc get cm -n kube-system  | grep -i "azuredisk"
oc get sa -n kube-system | grep -i "azuredisk"
oc get svc -n kube-system
oc get psp | grep -i "azuredisk"
oc get ds -n kube-system | grep -i "azuredisk"
oc get deploy -n kube-system | grep -i "azuredisk"
oc get rs -n kube-system | grep -i "azuredisk"
oc get po -n kube-system | grep -i "azuredisk"
oc get sc -A

oc describe clusterrole csi-azuredisk-controller-secret-role
oc describe clusterrolebinding csi-azuredisk-controller-secret-binding


# Enable snapshot support ==> Note: only available from v1.17.0
# curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/$driver_version/deploy/install-driver.sh | bash -s $driver_version snapshot --

oc -n kube-system get pod -l app=csi-azuredisk-controller -o wide  --watch
oc -n kube-system get pod -l app=csi-azuredisk-node -o wide  --watch

oc get events -n kube-system | grep -i "Error" 
for pod in $(oc get pods -l app=csi-azuredisk-controller -n kube-system -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n kube-system | grep -i "Error"
	oc logs $pod -c csi-provisioner -n kube-system | grep -i "Error"
    oc logs $pod -c csi-attacher -n kube-system | grep -i "Error"
    oc logs $pod -c csi-snapshotter -n kube-system | grep -i "Error"
    oc logs $pod -c csi-resizer -n kube-system | grep -i "Error"
    oc logs $pod -c liveness-probe -n kube-system | grep -i "Error"
    oc logs $pod -c azuredisk -n kube-system | grep -i "Error"
done

for pod in $(oc get pods -l app=csi-azuredisk-node -n kube-system -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n kube-system | grep -i "Error"
    oc logs $pod -c liveness-probe -n kube-system #| grep -i "Error"
    oc logs $pod -c node-driver-registrar -n kube-system # | grep -i "Error"
    oc logs $pod -c azuredisk -n kube-system # | grep -i "Error"
done
```

### [Troubleshoot](https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/docs/csi-debug.md)

If the logs show failed to get Azure Cloud Provider, ***error: Failed to load config from file: /etc/kubernetes/azure.json***, cloud not get azure cloud provider
it means that you have the cloud provider config file is not correctly set at /etc/kubernetes/cloud.conf in ARO or /etc/kubernetes/azure.json in AKS, or not correctly paramtered in the driver yaml file as explained in the [pre-req](#Pre-req)



## Test Azure Disk CSI Driver

See doc examples :
- [basic usage](https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/deploy/example/e2e_usage.md)

```sh
# Option 1: Azuredisk Dynamic Provisioning
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/example/storageclass-azuredisk-csi.yaml
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/example/pvc-azuredisk-csi.yaml

# oc delete StorageClass managed-csi
# oc delete pvc pvc-azuredisk

# Option 2: Azuredisk Static Provisioning(use an existing azure disk)
# wget https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/example/pv-azuredisk-csi.yaml > ./cnf/pv-static-azuredisk-csi.yaml

# Create a disk
# https://docs.microsoft.com/en-us/cli/azure/disk?view=azure-cli-latest
disk_name="dsk-aro"
az disk create --name $disk_name --sku Premium_LRS --size-gb 5 --zone 1 --location $location -g $rg_name 
az disk list -g $rg_name
disk_id=$(az disk show --name $disk_name -g $rg_name --query id)

export SUBSCRIPTION_ID=$subId
export RESOURCE_GROUP=$rg_name
export TENANT_ID=$tenantId
export DISK_ID=$disk_id
export DISK_NAME=$disk_name

envsubst < ./cnf/pv-static-azuredisk-csi.yaml > deploy/pv-static-azuredisk-csi.yaml
cat deploy/pv-static-azuredisk-csi.yaml
oc create -f ./cnf/pv-static-azuredisk-csi.yaml

# make sure pvc is created and in Bound status finally
watch oc describe pvc pvc-azuredisk

# create a pod with azuredisk CSI PVC
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/example/nginx-pod-azuredisk.yaml

# enter the pod container to do validation: watch the status of pod until its Status changed from Pending to Running and then enter the pod container
watch oc describe po nginx-azuredisk
oc exec -it nginx-azuredisk -- bash

# /mnt/azuredisk directory should mounted as disk filesystem
```

## Snapshot

To be tested !
```sh
oc get pvc azure-managed-disk
NAME                 STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
azure-managed-disk   Bound     pvc-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX      5Gi        RWO            managed-premium   3m

$pv1=`az disk list --query '[].id | [?contains(@,`pvc-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX`)]' -o tsv`
/subscriptions/<guid>/resourceGroups/MC_MYRESOURCEGROUP_MYAKSCLUSTER_EASTUS/providers/MicrosoftCompute/disks/kubernetes-dynamic-pvc-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX

# https://docs.microsoft.com/en-us/cli/azure/snapshot?view=azure-cli-latest
az snapshot create --name PV1Snapsho --source $pv1 -g $rg_name

#Get the snapshot Id 
snapshotId=$(az snapshot show --name $snapshotName --resource-group $rg_name --query [id] -o tsv)

# Create a new Managed Disks using the snapshot Id
# https://docs.microsoft.com/en-us/previous-versions/azure/virtual-machines/scripts/virtual-machines-cli-sample-create-managed-disk-from-snapshot
az disk create --name $osDiskName --sku $storageType --size-gb $diskSize --source $snapshotId --resource-group $resourceGroupName

# https://docs.microsoft.com/en-us/azure/backup/tutorial-restore-disk?toc=/azure/virtual-machines/windows/toc.json&bc=/azure/virtual-machines/windows/breadcrumb/toc.json
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/snapshot-copy-managed-disk

#Create VM by attaching created managed disks as OS
# az vm create --name $virtualMachineName --attach-os-disk $osDiskName --os-type $osType --resource-group $rg_name 

```

# Clean-Up

```sh

oc delete pvc pvc-azuredisk
oc delete pv pv-azuredisk
oc delete pods nginx-azuredisk

az disk delete --name aro-dsk -g $rg_name -y

# Topology(Availability Zone) : https://github.com/kubernetes-sigs/azuredisk-csi-driver/tree/master/deploy/example/topology
# Check node topology after driver installation
oc get no --show-labels | grep topo

# Uninstall Driver : 
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/$driver_version/deploy/uninstall-driver.sh | bash -s $driver_version --
oc delete StorageClass disk.csi.azure.com
oc delete pvc pvc-azuredisk

oc adm policy remove-scc-from-user privileged system:serviceaccount:kube-system:csi-azuredisk-node-sa 


# Shared disk(Multi-node ReadWrite) , still in Alpha : https://github.com/kubernetes-sigs/azuredisk-csi-driver/tree/master/deploy/example/sharedisk

```
