# Create RG
```sh
az group create --name $rg_name --location $location
# az group create --name rg-cloudshell-$location --location $location

```

# Create Storage

This is not mandatory, you can create a storage account to play with CloudShell

```sh
# https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create
# https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction#types-of-storage-accounts
az storage account create --name stcloudshellwe --kind StorageV2 --sku Standard_LRS -g rg-cloudshell-$location --location $location --https-only true
# az storage account create --name $storage_name --kind StorageV2 --sku Standard_LRS --resource-group $rg_name --location $location --https-only true

```

# Get a Red Hat pull secret

See [Azure docs](https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster#get-a-red-hat-pull-secret-optional)
to connect to [Red Hat OpenShift cluster manager portal](https://cloud.redhat.com/openshift/install/azure/aro-provisioned)

Click Download pull secret from [https://cloud.redhat.com/openshift/install/azure/aro-provisioned/pull-secret](https://cloud.redhat.com/openshift/install/azure/aro-provisioned/pull-secret)
Keep the saved pull-secret.txt file somewhere safe - it will be used in each cluster creation.
When running the az aro create command, you can reference your pull secret using the --pull-secret @pull-secret.txt parameter. Execute az aro create from the directory where you stored your pull-secret.txt file. Otherwise, replace @pull-secret.txt with @<path-to-my-pull-secret-file>.

See also [https://github.com/stuartatmicrosoft/azure-aro#aro4-replace-pull-secretsh](https://github.com/stuartatmicrosoft/azure-aro#aro4-replace-pull-secretsh)


## Ensure you have the appropriate Roles to be allowed to create a Service Principal

[az ad group create CLI](https://docs.microsoft.com/en-us/cli/azure/ad/group?view=azure-cli-latest#az_ad_group_create)
[az ad user create CLI](https://docs.microsoft.com/en-us/cli/azure/ad/user?view=azure-cli-latest#az_ad_user_create)
[az ad group member add CLI](https://docs.microsoft.com/en-us/cli/azure/ad/group/member?view=azure-cli-latest#az_ad_group_member_add)
[az role assignment create CLI](https://docs.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az_role_assignment_create)


Too much: [Application Administrator permission](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#application-administrator-permissions)
[Application Developer permission is enough to create a Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#application-developer-permissions)
- microsoft.directory/servicePrincipals/create
- microsoft.directory/applications/create
- microsoft.directory/appRoleAssignments/create

You could add roles to a Group, this is in PREVIEW in the [Portal](https://docs.microsoft.com/en-us/azure/active-directory/roles/groups-concept#required-license-plan) but this feature requires you to have an available Azure AD Premium P1 license in your Azure AD organization.