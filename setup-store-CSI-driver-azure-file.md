See also :

- [https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage](https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage)
- [https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-azure-file.html](https://docs.openshift.com/aro/4/storage/persistent_storage/persistent-storage-azure-file.htmle)
- [https://github.com/container-storage-interface/spec](https://github.com/container-storage-interface/spec)
- [https://github.com/kubernetes-sigs/azurefile-csi-driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)
- [https://kubernetes-csi.github.io/docs/topology.html](https://kubernetes-csi.github.io/docs/topology.html)
- [https://kubernetes-csi.github.io/docs/drivers.html](https://kubernetes-csi.github.io/docs/drivers.html)

# Pre-req

See :
- [install guide](https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/docs/install-azurefile-csi-driver.md)
- Available [sku](https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/docs/driver-parameters.md) are : Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS
- [Pre-req](https://github.com/kubernetes-sigs/azurefile-csi-driver#prerequisite) : The driver initialization depends on a Cloud provider config file.

The driver initialization depends on a Cloud provider config file, usually it's /etc/kubernetes/azure.json on all kubernetes nodes deployed by AKS or aks-engine, here is azure.json example. This driver also supports read cloud config from kuberenetes secret.

<span style="color:red">/!\ IMPORTANT </span> : in OpenShift the creds file is located in **“/etc/kubernetes/cloud.conf”**, so you would need to replace the path in the deployment for the driver from “/etc/kubernetes/azure.json” to “/etc/kubernetes/cloud.conf”, issue #[xxx](xxxxx) logged.

```sh

# https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/docs/read-from-secret.md
mkdir deploy
tenantId=$(az account show --query tenantId -o tsv)

# https://kubernetes.io/docs/concepts/configuration/secret/#decoding-a-secret
oc get secrets -n kube-system
oc describe secret azure-cloud-provider -n kube-system
azure_cnf_secret=$(oc get secret azure-cloud-provider -n kube-system -o jsonpath="{.data.cloud-config}" | base64 --decode)
echo "Azure Cloud Provider config secret " $azure_cnf_secret

azure_cnf_secret_length=$(echo -n $azure_cnf_secret | wc -c)
echo "Azure Cloud Provider config secret length " $azure_cnf_secret_length

aadClientId="${azure_cnf_secret:14:35}"
echo "aadClientId " $aadClientId

aadClientSecret="${azure_cnf_secret:53:$azure_cnf_secret_length}"
echo "aadClientSecret" $aadClientSecret

echo -e "{\n"\
"\""tenantId\"": \""$tenantId\"",\n"\
"\""subscriptionId\"": \""$subId\"",\n"\
"\""resourceGroup\"": \""$rg_name\"",\n"\
"\""useManagedIdentityExtension\"": false,\n"\
"\""aadClientId\"": \""$aadClientId\"",\n"\
"\""aadClientSecret\"": \""$aadClientSecret\""\n"\
"}\n"\
> deploy/azure.json

cat deploy/azure.json


# https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/deploy/csi-azurefile-node.yaml#L17
oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:csi-azurefile-node-sa
oc describe scc privileged
```


# Install the Azure File CSI Driver

```sh
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/v0.6.0/deploy/install-driver.sh | bash -s v0.6.0 --

oc get rolebinding -n kube-system | grep -i "azurefile"
oc get role -n kube-system | grep -i "azurefile"
oc get ClusterRoleBinding | grep -i "azurefile"
oc get ClusterRole | grep -i "azurefile"
oc get cm -n kube-system  | grep -i "azurefile"
oc get sa -n kube-system | grep -i "azurefile"
oc get svc -n kube-system
oc get psp | grep -i "azurefile"
oc get ds -n kube-system | grep -i "azurefile"
oc get deploy -n kube-system | grep -i "azurefile"
oc get rs -n kube-system | grep -i "azurefile"
oc get po -n kube-system | grep -i "azurefile"
oc get sc -A

# oc get pod -n kube-system -l app=csi-azurefile-controller -o wide --watch 
# oc get pod -n kube-system -l app=csi-azurefile-node -o wide --watch 

oc get events -n kube-system | grep -i "Error" 

for pod in $(oc get pods -l app=csi-azurefile-controller -n kube-system -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n kube-system | grep -i "Error"
	oc logs $pod csi-provisioner -n kube-system | grep -i "Error"
    oc logs $pod csi-attacher -n kube-system | grep -i "Error"
    oc logs $pod csi-snapshotter -n kube-system | grep -i "Error"
    oc logs $pod csi-resizer -n kube-system | grep -i "Error"
    oc logs $pod liveness-probe -n kube-system | grep -i "Error"
    oc logs $pod azurefile -n kube-system | grep -i "Error"
done

for pod in $(oc get pods -l app=csi-azurefile-node -n kube-system -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n kube-system | grep -i "Error"
    oc logs $pod -c liveness-probe -n kube-system #| grep -i "Error"
    oc logs $pod -c node-driver-registrar # | grep -i "Error"
    oc logs $pod -c azurefile -n kube-system # | grep -i "Error"
done


```
### [Troubleshoot](https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/docs/csi-debug.md)

If the logs show failed to get Azure Cloud Provider, ***error: Failed to load config from file: /etc/kubernetes/azure.json***, cloud not get azure cloud provider
it means that you have the cloud provider config file is not correctly set at /etc/kubernetes/cloud.conf in ARO or /etc/kubernetes/azure.json in AKS, or not correctly paramtered in the driver yaml file as explained in the [pre-req](#Pre-req)


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

curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/v0.6.0/deploy/uninstall-driver.sh | bash -s --

```
