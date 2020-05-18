# Setup Velero

See :
- [https://github.com/vmware-tanzu/velero/blob/master/site/docs/master/supported-providers.md](https://github.com/vmware-tanzu/velero/blob/master/site/docs/master/supported-providers.md)
- [https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure](https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure)
- [https://velero.io/docs/v1.3.2/supported-providers/](https://velero.io/docs/v1.3.2/supported-providers/)



<span style="color:red">/!\ IMPORTANT </span> :  [Velero/Kasten won’t work for disk snapshots](https://github.com/Azure/OpenShift/issues/186)

## Pre-requisites

```sh

# Create the storage account.

AZURE_STORAGE_ACCOUNT_ID="velero$(uuidgen | cut -d '-' -f5 | tr '[A-Z]' '[a-z]')"
echo "AZURE_STORAGE_ACCOUNT_ID" $AZURE_STORAGE_ACCOUNT_ID

az storage account create \
    --name $AZURE_STORAGE_ACCOUNT_ID \
    --resource-group $rg_name \
    --sku Standard_GRS \
    --encryption-services blob \
    --https-only true \
    --kind BlobStorage \
    --access-tier Hot

BLOB_CONTAINER=velero
az storage container create -n $BLOB_CONTAINER --public-access off --account-name $AZURE_STORAGE_ACCOUNT_ID

velero_sp_password=$(az ad sp create-for-rbac --name velero --role contributor --scopes /subscriptions/$subId --query password -o tsv)
# velero_sp_password=`az ad sp create-for-rbac --name "velero" --role "Contributor" --query 'password' -o tsv \
  --scopes /subscriptions/$subId]`

echo "Velero Service Principal PWD" $velero_sp_password


#velero_sp_id=$(az ad sp list --all --query "[?appDisplayName=='velero'].{appId:appId}" --output tsv)
#velero_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='velero'].{appId:appId}" --output tsv)
velero_sp_id=$(az ad sp list --display-name "velero" --query '[0].appId' -o tsv)
echo "Velero Service Principal ID:" $velero_sp_id 
echo $velero_sp_id > velero_sp_id.txt
# velero_sp_id=`cat velero_sp_id.txt`
az ad sp show --id $velero_sp_id

# az ad sp credential reset -n xxx

# Now you need to create a file that contains all the relevant environment variables. The command looks like the following:

cat << EOF > ./credentials-velero
AZURE_SUBSCRIPTION_ID=${subId}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${velero_sp_password}
AZURE_RESOURCE_GROUP=${rg_name}
AZURE_CLOUD_NAME=AzurePublicCloud
EOF

```

## Download Velero

```sh
# https://velero.io/docs/v1.3.2/basic-install/

wget https://github.com/vmware-tanzu/velero/releases/download/v1.3.2/velero-v1.3.2-linux-amd64.tar.gz
tar -zxvf velero-v1.3.2-linux-amd64.tar.gz

velero install \
    --provider azure \
    --plugins velero/velero-plugin-for-microsoft-azure:v1.0.1 \
    --bucket $BLOB_CONTAINER \
    --secret-file ./credentials-velero \
    --backup-location-config resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,storageAccount=$AZURE_STORAGE_ACCOUNT_ID[,subscriptionId=$AZURE_BACKUP_SUBSCRIPTION_ID] \
    --snapshot-location-config apiTimeout=<YOUR_TIMEOUT>[,resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,subscriptionId=$AZURE_BACKUP_SUBSCRIPTION_ID]

# Install and configure the server components: https://vmware-tanzu.github.io/helm-charts/

# https://github.com/vmware-tanzu/helm-charts/blob/master/charts/velero/README.md
helm install --namespace <YOUR NAMESPACE> \
--set configuration.provider=<PROVIDER NAME> \
--set-file credentials.secretContents.cloud=<FULL PATH TO FILE> \
--set configuration.backupStorageLocation.name=<PROVIDER NAME> \
--set configuration.backupStorageLocation.bucket=<BUCKET NAME> \
--set configuration.backupStorageLocation.config.region=<REGION> \
--set configuration.volumeSnapshotLocation.name=<PROVIDER NAME> \
--set configuration.volumeSnapshotLocation.config.region=<REGION> \
--set image.repository=velero/velero \
--set image.pullPolicy=IfNotPresent \
--set initContainers[0].name=velero-plugin-for-aws \
--set initContainers[0].image=velero/velero-plugin-for-aws:v1.0.0 \
--set initContainers[0].volumeMounts[0].mountPath=/target \
--set initContainers[0].volumeMounts[0].name=plugins \
vmware-tanzu/velero


# Command line Autocompletion : https://velero.io/docs/v1.3.2/customize-installation/#optional-velero-cli-configurations

source <(velero completion bash)
echo "source <(velero completion bash)" >> ~/.bashrc 
echo 'alias v=velero' >>~/.bashrc
echo 'complete -F __start_velero v' >>~/.bashrc

```