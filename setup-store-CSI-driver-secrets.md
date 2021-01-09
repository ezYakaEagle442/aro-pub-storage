
See also :
- [Limit credential exposure](https://docs.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security#limit-credential-exposure)
- [Use Azure Key Vault with Secrets Store CSI Driver](https://docs.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security#use-azure-key-vault-with-secrets-store-csi-driver)
- [https://github.com/Azure/secrets-store-csi-driver-provider-azure](https://github.com/Azure/secrets-store-csi-driver-provider-azure)
- [Pre-req](https://github.com/Azure/secrets-store-csi-driver-provider-azure#install-the-secrets-store-csi-driver-and-the-azure-keyvault-provider) : AKS 1.16+
CSI driver provides the ability to [sync with Kubernetes secrets, which can then be referenced by an environment variable.](https://github.com/kubernetes-sigs/secrets-store-csi-driver#optional-sync-with-kubernetes-secrets)



# Install the Secrets Store CSI Driver and the Azure Keyvault Provider

[Installing the Chart](https://github.com/Azure/secrets-store-csi-driver-provider-azure/blob/master/charts/csi-secrets-store-provider-azure/README.md)
```sh
helm install csi-secrets-store-provider-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure -n $target_namespace
helm ls -n $target_namespace -o yaml
helm status csi-secrets-store-provider-azure -n $target_namespace
```

# Create key-Vault & Secret
```sh

az provider register -n Microsoft.KeyVault
# https://docs.microsoft.com/en-us/azure/key-vault/key-vault-soft-delete-cli
# az keyvault list-deleted
# az keyvault purge --name $vault_name --location $location

az keyvault create --name $vault_name --enable-soft-delete true --location $location -g $rg_name
az keyvault show --name $vault_name 
az keyvault update --name $vault_name --default-action deny -g $rg_name 

kv_id=$(az keyvault show --name $vault_name -g $rg_name --query "id" --output tsv)
echo "KeyVault ID :" $kv_id

# https://docs.microsoft.com/en-us/cli/azure/keyvault/secret?view=azure-cli-latest#az-keyvault-secret-set
az keyvault secret set --name $vault_secret_name --value $vault_secret --description "CSI secret store driver - ${appName} Secret" --vault-name $vault_name
az keyvault secret list --vault-name $vault_name
az keyvault secret show --vault-name $vault_name --name $vault_secret_name --output tsv

aro_client_id=$(az aro show -n $cluster_name -g $rg_name --query 'servicePrincipalProfile.clientId' -o tsv)
echo "ARO Cluster Client ID : " $aro_client_id

```

## Perform role assignments

See [https://github.com/Azure/aad-pod-identity/blob/master/docs/readmes/README.role-assignment.md#performing-role-assignments](https://github.com/Azure/aad-pod-identity/blob/master/docs/readmes/README.role-assignment.md#performing-role-assignments)

```sh
# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#managed-identity-operator
# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#virtual-machine-contributor
# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader
# https://github.com/Azure/secrets-store-csi-driver-provider-azure/blob/master/docs/service-principal-mode.md


# Assign Reader Role to the service principal for your keyvault
az role assignment create --role Reader --assignee $aro_client_id --scope /subscriptions/$subId/resourcegroups/$rg_name/providers/Microsoft.KeyVault/vaults/$vault_name # $kv_id

az keyvault set-policy -n $vault_name --key-permissions get --spn $aro_client_id
az keyvault set-policy -n $vault_name --secret-permissions get --spn $aro_client_id
az keyvault set-policy -n $vault_name --certificate-permissions get --spn $aro_client_id
# az role assignment create --role "Managed Identity Operator" --assignee $aks_client_id --scope /subscriptions/$subId/resourcegroups/$managed_rg
# az role assignment create --role "Virtual Machine Contributor" --assignee $aks_client_id --scope /subscriptions/$subId/resourcegroups/$managed_rg
```


# Configure & Deploy secretproviderclasses


```sh
tenantId=$(az account show --query tenantId -o tsv)

export SUBSCRIPTION_ID=$subId
export RESOURCE_GROUP=$rg_name
export TENANT_ID=$tenantId
export KV_NAME=$vault_name
export SECRET_NAME=$vault_secret_name

oc create secret generic secrets-store-creds --from-literal clientid=$aro_client_id --from-literal clientsecret=$aro_client_secret -n $target_namespace

envsubst < ./cnf/secrets-store-csi-provider-class.yaml > deploy/secrets-store-csi-provider-class.yaml
cat deploy/secrets-store-csi-provider-class.yaml
oc apply -f deploy/secrets-store-csi-provider-class.yaml -n $target_namespace
oc get secretproviderclasses -n $target_namespace
oc describe secretproviderclasses azure-$KV_NAME -n $target_namespace

envsubst < ./cnf/csi-demo-pod-sp.yaml > deploy/csi-demo-pod-sp.yaml
cat deploy/csi-demo-pod-sp.yaml
oc apply -f deploy/csi-demo-pod-sp.yaml -n $target_namespace

oc get po -n $target_namespace -o wide
oc get events -n $target_namespace | grep -i "Error" 
oc describe pod nginx-secrets-store-inline -n $target_namespace
oc logs nginx-secrets-store-inline -n $target_namespace


```

# Test

```sh
k exec -it nginx-secrets-store-inline -n $target_namespace -- ls /mnt/secrets-store/ 
k exec -it nginx-secrets-store-inline -n $target_namespace -- cat /mnt/secrets-store/key1
k exec -it nginx-secrets-store-inline -n $target_namespace -- cat /mnt/secrets-store/$vault_secret_name

```