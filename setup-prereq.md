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


```sh


```

# Generates your SSH keys

<span style="color:red">/!\ IMPORTANT </span> :  check & save your ssh_passphrase !!!

Generate & save nodes SSH keys to Azure Key-Vault is a Best-practice. If you want to save your keys to keyVault, [KV must be created first](setup-kv.md)


```sh
ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"

# https://www.ssh.com/ssh/keygen/
# -y Read a private OpenSSH format file and print an OpenSSH public key to stdout.
# ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub
# ssh-keygen -l -f ~/.ssh/id_rsa
# az keyvault key create --name $ssh_key --vault-name $vault_name --size 2048 --kty RSA
az keyvault key import --name $ssh_key --vault-name $vault_name --pem-file ~/.ssh/$ssh_key --pem-password $ssh_passphrase
az keyvault key list --vault-name $vault_name
az keyvault key show --name $ssh_key --vault-name $vault_name
az keyvault key download --name $ssh_key --vault-name $vault_name --encoding PEM --file key2
cat key1
ls -al key1
file key1
stat key1
ls -lApst key1
chmod go-rw key1
ssh-keygen -y -f key1.pem > key1.pub

```