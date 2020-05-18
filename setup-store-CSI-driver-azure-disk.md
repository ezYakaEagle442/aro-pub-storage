See also :

- [https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage](https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage)
- [https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-azure.html#storage-create-azure-storage-class_persistent-storage-azure](https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-azure.html#storage-create-azure-storage-class_persistent-storage-azure)
- [https://github.com/container-storage-interface/spec](https://github.com/container-storage-interface/spec)
- [https://github.com/kubernetes-sigs/azuredisk-csi-driver](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
- [https://github.com/kubernetes-sigs/azurefile-csi-driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)
- [https://kubernetes-csi.github.io/docs/topology.html](https://kubernetes-csi.github.io/docs/topology.html)
- [https://kubernetes-csi.github.io/docs/drivers.html](https://kubernetes-csi.github.io/docs/drivers.html)

# Install the Azure Disk CSI Driver


See :
- [install guide](https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/docs/install-azuredisk-csi-driver.md)
- Available [sku](https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/docs/driver-parameters.md) are : Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS
- [Pre-req](https://github.com/kubernetes-sigs/azuredisk-csi-driver#prerequisite) : The driver initialization depends on a Cloud provider config file, usually it's /etc/kubernetes/azure.json 

```sh

# https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/docs/read-from-secret.md
mkdir deploy
tenantId=$(az account show --query tenantId -o tsv)
pull_secret=`cat pull-secret.txt`

echo -e "{\n"\
"\""tenantId\"": \""$tenantId\"",\n"\
"\""subscriptionId\"": \""$subId\"",\n"\
"\""resourceGroup\"": \""$rg_name\"",\n"\
"\""useManagedIdentityExtension\"": false,\n"\
"\""aadClientId\"": \""$aro_spn\"",\n"\
"\""aadClientSecret\"": \""$pull_secret\""\n"\
"}\n"\
> deploy/azure.json

cat deploy/azure.json

# IMPORTANT : The secret should be put in kube-system namespace and its name should be azure-cloud-provider
oc create secret generic azure-cnf --from-file=deploy/azure.json -n kube-system
oc get secrets -n kube-system
oc describe secret azure-cnf -n kube-system

curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/v0.7.0/deploy/install-driver.sh | bash -s v0.7.0 --

# Enable snapshot support ==> Note: only available from v1.17.0
# curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/v0.7.0/deploy/install-driver.sh | bash -s v0.7.0 snapshot --

oc -n kube-system get pod -l app=csi-azuredisk-controller -o wide  --watch
oc -n kube-system get pod -l app=csi-azuredisk-node -o wide  --watch

oc get events -n kube-system | grep -i "Error" 
for pod in $(oc get pods -l app=csi-azuredisk-controller -n kube-system -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n kube-system | grep -i "Error"
	oc logs $pod csi-provisioner -n kube-system | grep -i "Error"
    oc logs $pod csi-attacher -n kube-system | grep -i "Error"
    oc logs $pod csi-snapshotter -n kube-system | grep -i "Error"
    oc logs $pod csi-resizer -n kube-system | grep -i "Error"
    oc logs $pod liveness-probe -n kube-system | grep -i "Error"
    oc logs $pod azuredisk -n kube-system | grep -i "Error"
done

for pod in $(oc get pods -l app=csi-azuredisk-node -n kube-system -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n kube-system | grep -i "Error"
    oc logs $pod -c liveness-probe -n kube-system #| grep -i "Error"
    oc logs $pod -c azuredisk -n kube-system # | grep -i "Error"
    oc logs $pod -c node-driver-registrar # | grep -i "Error"
done

# Troubleshoot: https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/docs/csi-debug.md
# if the logs show failed to get Azure Cloud Provider, error: Failed to load config from file: /etc/kubernetes/azure.json, cloud not get azure cloud provider
# it means that you have forgotten to install the file /etc/kubernetes/azure.json

```

## Test Azure Disk CSI Driver

See doc examples :
- [basic usage](https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/deploy/example/e2e_usage.md)

```sh
# Option 1: Azuredisk Dynamic Provisioning
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/example/storageclass-azuredisk-csi.yaml
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/example/pvc-azuredisk-csi.yaml

# oc delete StorageClass disk.csi.azure.com
# oc delete pvc pvc-azuredisk

# Option 2: Azuredisk Static Provisioning(use an existing azure disk)
# wget https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/example/pv-azuredisk-csi.yaml > ./cnf/pv-static-azuredisk-csi.yaml

# Create a disk
az disk create --name aro-dsk --sku Premium_LRS --size-gb 5 --zone 1 --location $location -g $rg_name 
az disk list -g $rg_name
disk_id=$(az disk show --name aro-dsk -g $rg_name --query id)

export SUBSCRIPTION_ID=$subId
export RESOURCE_GROUP=$rg_name
export TENANT_ID=$tenantId
export DISK_ID=$disk_id

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
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/v0.7.0/deploy/uninstall-driver.sh | bash -s v0.7.0 --
oc delete StorageClass disk.csi.azure.com
oc delete pvc pvc-azuredisk


# Shared disk(Multi-node ReadWrite) , still in Alpha : https://github.com/kubernetes-sigs/azuredisk-csi-driver/tree/master/deploy/example/sharedisk

```
