See also :

- [https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage](https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage)
- [https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-azure-file.html](https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-azure-file.htmle)
- [https://github.com/container-storage-interface/spec](https://github.com/container-storage-interface/spec)
- [https://github.com/kubernetes-sigs/azuredisk-csi-driver](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
- [https://github.com/kubernetes-sigs/azurefile-csi-driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)
- [https://kubernetes-csi.github.io/docs/topology.html](https://kubernetes-csi.github.io/docs/topology.html)
- [https://kubernetes-csi.github.io/docs/drivers.html](https://kubernetes-csi.github.io/docs/drivers.html)


# Install the Azure File CSI Driver

See :
- [install guide](https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/docs/install-azurefile-csi-driver.md)
- Available [sku](https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/docs/driver-parameters.md) are : Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS
- [Pre-req](https://github.com/kubernetes-sigs/azurefile-csi-driver#prerequisite) : The driver initialization depends on a Cloud provider config file, usually it's /etc/kubernetes/azure.json 

```sh
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/v0.6.0/deploy/install-driver.sh | bash -s v0.6.0 --

oc get pod -n kube-system -l app=csi-azurefile-controller -o wide --watch 
oc get pod -n kube-system -l app=csi-azurefile-node -o wide --watch 

# Clean-Up
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/v0.6.0/deploy/uninstall-driver.sh | bash -s --

```


## Test Azure File CSI Driver
See doc examples :
- [basic usage](https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/deploy/example/e2e_usage.md)


```sh
# Option 1: Dynamic Provisioning
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/deploy/example/storageclass-azurefile-csi.yaml
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/deploy/example/pvc-azurefile-csi.yaml

# Option 2: Static Provisioning(use an existing azure file share)
# oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/deploy/example/storageclass-azurefile-existing-share.yaml

# Create a File
str_name="stwefile""${appName,,}"
az storage account create --name $str_name --kind FileStorage --sku Premium_ZRS --location $location -g $rg_name 
az storage account list -g $rg_name

fs_share_name=arofs
az storage share create --name $fs_share_name --account-name $str_name
az storage share list --account-name $str_name
az storage share show --name $fs_share_name --account-name $str_name

export RESOURCE_GROUP=$rg_name
export STORAGE_ACCOUNT_NAME=$str_name
export SHARE_NAME=$fs_share_name

envsubst < ./cnf/storageclass-azurefile-existing-share.yaml > deploy/storageclass-azurefile-existing-share.yaml
cat deploy/storageclass-azurefile-existing-share.yaml

oc create -f ./cnf/storageclass-azurefile-existing-share.yaml
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/deploy/example/pvc-azurefile-csi.yaml

# validate PVC status and create an nginx pod
oc describe pvc pvc-azurefile -w
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/deploy/example/nginx-pod-azurefile.yaml

# enter the pod container to do validation
oc describe po nginx-azurefile -w
oc exec -it nginx-azurefile -- bash
# /mnt/azurefile directory should be mounted as cifs filesystem

```

## Clean-Up
```sh
az storage share delete --name $fs_share_name --account-name $str_name
az storage account delete --name $str_name -g $rg_name -y

oc delete sc file.csi.azure.com
oc delete pvc pvc-azurefile
oc delete pv pv-azurefile
oc delete pods xxx

```
