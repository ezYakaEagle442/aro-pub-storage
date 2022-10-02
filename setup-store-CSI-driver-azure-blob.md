See also :

- [https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage](https://docs.openshift.com/aro/4/storage/understanding-persistent-storage.html#types-of-persistent-volumes_understanding-persistent-storage)
- [https://github.com/container-storage-interface/spec](https://github.com/container-storage-interface/spec)
- [https://github.com/kubernetes-sigs/blob-csi-driver](https://github.com/kubernetes-sigs/blob-csi-driver)

# Pre-req

See :
- [install guide](https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/install-blob-csi-driver.md)
- Available [sku](https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/driver-parameters.md) are : Standard_LRS, Premium_LRS, Standard_GRS, Standard_RAGRS
- [Pre-req](https://github.com/kubernetes-sigs/blob-csi-driver#prerequisite) : The driver initialization depends on a Cloud provider config file.

The driver initialization depends on a Cloud provider config file, usually it's /etc/kubernetes/azure.json on all kubernetes nodes deployed by AKS or aks-engine, here is azure.json example. This driver also supports read cloud config from kuberenetes secret.

<span style="color:red">/!\ IMPORTANT </span> : in OpenShift the creds file is located in **“/etc/kubernetes/cloud.conf”**, so you would need to replace the path in the deployment for the driver from “/etc/kubernetes/azure.json” to “/etc/kubernetes/cloud.conf”

```sh

# https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/read-from-secret.md
mkdir deploy
tenantId=$(az account show --query tenantId -o tsv)

# https://kubernetes.io/docs/concepts/configuration/secret/#decoding-a-secret
oc get secrets -n kube-system
oc describe secret azure-cloud-provider -n kube-system
azure_cnf_secret=$(oc get secret azure-cloud-provider -n kube-system -o jsonpath="{.data.cloud-config}" | base64 --decode)
echo "Azure Cloud Provider config secret " $azure_cnf_secret

azure_cnf_secret_length=$(echo -n $azure_cnf_secret | wc -c)
echo "Azure Cloud Provider config secret length " $azure_cnf_secret_length

aadClientId="${azure_cnf_secret:13:36}"
echo "aadClientId " $aadClientId

aadClientSecret="${azure_cnf_secret:67:$azure_cnf_secret_length}"
echo "aadClientSecret" $aadClientSecret

subId=$(az account show --query id)
echo "subscription ID :" $subId

tenantId=$(az account show --query tenantId -o tsv)

managed_rg=$(az aro show -n $cluster_name -g $rg_name --query 'clusterProfile.resourceGroupId' -o tsv)
echo "ARO Managed Resource Group : " $managed_rg

managed_rg_name=`echo -e $managed_rg | cut -d  "/" -f5`
echo "ARO RG Name" $managed_rg_name

# /§\ IMPORTANT : the resourceGroup is the ARO Cluster managed RG
# "resourceGroup": "rg-managed-cluster-aropub-francecentral",
# "vnetResourceGroup": "rg-aropub-francecentral",

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


# https://github.com/kubernetes-sigs/azureblob-csi-driver/blob/master/deploy/csi-azureblob-node.yaml#L17
oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:csi-azureblob-node-sa
oc describe scc privileged
```


# Install the Azure BLOB CSI Driver

```sh

oc apply -f ./cnf/cloud-cfg-test-pod.yaml
oc describe pvc test-host-pvc
oc describe pv test-host-pv
oc describe pod test-pod
oc get po
oc exec -it test-pod -- cat /mnt/k8s/cloud.conf

oc create configmap azure-cred-file --from-literal=path="/etc/kubernetes/cloud.conf" -n kube-system
oc get cm -n kube-system
oc describe cm azure-cred-file -n kube-system

driver_version=master #vv0.11.0
echo "Driver version " $driver_version
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/$driver_version/deploy/install-driver.sh | bash -s $driver_version --


oc get rolebinding -n kube-system | grep -i "csi-blob"
oc get role -n kube-system | grep -i "csi-blob"
oc get ClusterRoleBinding | grep -i "csi-blob"
oc get ClusterRole | grep -i "csi-blob"
oc get cm -n kube-system  | grep -i "csi-blob"
oc get sa -n kube-system | grep -i "csi-blob"
oc get svc -n kube-system
oc get psp | grep -i "csi-blob"
oc get ds -n kube-system | grep -i "csi-blob"
oc get deploy -n kube-system | grep -i "csi-blob"
oc get rs -n kube-system | grep -i "csi-blob"
oc get po -n kube-system | grep -i "csi-blob"
oc get sc -A

# oc get pod -n kube-system -l app=csi-blob-controller -o wide --watch 
# oc get pod -n kube-system -l app=app=csi-blob-node -o wide --watch 

oc get events -n kube-system | grep -i "Error" 

for pod in $(oc get pods -l app=csi-blob-controller -n kube-system -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n kube-system | grep -i "Error"
	oc logs $pod -c csi-provisioner -n kube-system | grep -i "Error"
    oc logs $pod -c csi-resizer -n kube-system | grep -i "Error"
    oc logs $pod -c liveness-probe -n kube-system | grep -i "Error"
    oc logs $pod -c blob -n kube-system | grep -i "Error"
done

for pod in $(oc get pods -l app=csi-blob-node -n kube-system -o custom-columns=:metadata.name)
do
	oc describe pod $pod -n kube-system | grep -i "Error"
    oc logs $pod -c liveness-probe -n kube-system #| grep -i "Error"
    oc logs $pod -c node-driver-registrar # | grep -i "Error"
    oc logs $pod -c blob -n kube-system # | grep -i "Error"
done


```
### [Troubleshoot](https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/csi-debug.md)

If the logs show failed to get Azure Cloud Provider, ***error: Failed to load config from file: /etc/kubernetes/azure.json***, cloud not get azure cloud provider
it means that you have the cloud provider config file is not correctly set at /etc/kubernetes/cloud.conf in ARO or /etc/kubernetes/azure.json in AKS, or not correctly paramtered in the driver yaml file as explained in the [pre-req](#Pre-req)


## Test Azure BLOB CSI Driver

[https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/deploy/example/e2e_usage.md](https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/deploy/example/e2e_usage.md)


# Create strorage Class
```sh
# oc create -f https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/deploy/example/storageclass-blobfuse.yaml
# Create a statefulset with volume mount
# oc create -f https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/deploy/example/statefulset.yaml
# oc get sts
# oc exec -it statefulset-blob-0 -- bash

str_name="stweblob""${appName,,}"
export AZURE_STORAGE_ACCOUNT=$str_name

az storage account create --name $str_name --kind StorageV2 --sku Standard_LRS --location $location -g $rg_name 
az storage account list -g $rg_name -o tsv

httpEndpoint=$(az storage account show --name $str_name -g $rg_name --query "primaryEndpoints.blob" | tr -d '"')
echo "httpEndpoint" $httpEndpoint 

export AZURE_STORAGE_ACCESS_KEY=$(az storage account keys list --account-name $str_name -g $rg_name --query "[0].value" | tr -d '"')
echo "storageAccountKey" $AZURE_STORAGE_ACCESS_KEY 

blob_container_name=aroblob
az storage container create --name $blob_container_name
az storage container list --account-name $str_name
az storage container show --name $blob_container_name --account-name $str_name

export RESOURCE_GROUP=$rg_name
export STORAGE_ACCOUNT_NAME=$str_name
export CONTAINER_NAME=$blob_container_name

envsubst < ./cnf/storageclass-blobfuse-existing-container.yaml > deploy/storageclass-blobfuse-existing-container.yaml
cat deploy/storageclass-blobfuse-existing-container.yaml

oc create -f ./deploy/storageclass-blobfuse-existing-container.yaml
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/deploy/example/pvc-blob-csi.yaml
oc create -f https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/deploy/example/nginx-pod-blob.yaml

oc get po
oc exec -it nginx-blob -- sh
df -h
ls -al /mnt/blob/outfile
cat /mnt/blob/outfile
```

## Clean-Up
```sh
az storage account delete --name $str_name -g $rg_name -y

oc delete sc blob.csi.azure.com
oc delete pvc pvc-azureblob
oc delete pv pv-azureblob
oc delete pods xxx

curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/$driver_version/deploy/uninstall-driver.sh | bash -s master --

```
