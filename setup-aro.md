

```sh

pull_secret=`cat pull-secret.txt`

az provider show -n  Microsoft.RedHatOpenShift --query  "resourceTypes[?resourceType == 'OpenShiftClusters']".locations 

az aro create \
  --name $cluster_name \
  --vnet $vnet_name \
  --master-subnet $master_subnet_id	\
  --worker-subnet $worker_subnet_id \
  --apiserver-visibility $apiserver_visibility \
  --ingress-visibility  $ingress_visibility \
  --location $location \
  --pod-cidr $pod_cidr \
  --service-cidr $svc_cidr \
  --pull-secret @pull-secret.txt \
  --worker-count 3 \
  --resource-group $rg_name 

az aro list -g $rg_name
az aro show -n $cluster_name -g $rg_name

aro_api_server_url=$(az aro show -n $cluster_name -g $rg_name --query 'apiserverProfile.url' -o tsv)
echo "ARO API server URL: " $aro_api_server_url

aro_version=$(az aro show -n $cluster_name -g $rg_name --query 'clusterProfile.version' -o tsv)
echo "ARO version : " $aro_version

aro_console_url=$(az aro show -n $cluster_name -g $rg_name --query 'consoleProfile.url' -o tsv)
echo "ARO console URL: " $aro_console_url

ing_ctl_ip=$(az aro show -n $cluster_name -g $rg_name --query 'ingressProfiles[0].ip' -o tsv)
echo "ARO Ingress Controller IP: " $ing_ctl_ip

aro_spn=$(az aro show -n $cluster_name -g $rg_name --query 'servicePrincipalProfile.clientId' -o tsv)
echo "ARO Service Principal Name: " $aro_spn

managed_rg=$(az aro show -n $cluster_name -g $rg_name --query 'clusterProfile.resourceGroupId' -o tsv)
echo "ARO Managed Resource Group : " $managed_rg

managed_rg_name=`echo -e $managed_rg | cut -d  "/" -f5`
echo "ARO RG Name" $managed_rg_name

cat ~/.azure/accessTokens.json
# You can have a look at the App. Registrations in the portal at https://ms.portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps

```
## Connect to the Cluster

See [https://docs.microsoft.com/en-us/azure/openshift/tutorial-connect-cluster#connect-to-the-cluster](https://docs.microsoft.com/en-us/azure/openshift/tutorial-connect-cluster#connect-to-the-cluster)

```sh
az aro list-credentials -n $cluster_name -g $rg_name
aro_usr=$(az aro list-credentials -n $cluster_name -g $rg_name | jq -r '.kubeadminUsername')
aro_pwd=$(az aro list-credentials -n $cluster_name -g $rg_name | jq -r '.kubeadminPassword')

# Launch the console URL in a browser and login using the kubeadmin credentials.

```

## Install the OpenShift CLI

See [https://docs.microsoft.com/en-us/azure/openshift/tutorial-connect-cluster#install-the-openshift-cli](https://docs.microsoft.com/en-us/azure/openshift/tutorial-connect-cluster#install-the-openshift-cli)
```sh
cd ~
aro_download_url=${aro_console_url/console/downloads}
echo "aro_download_url" $aro_download_url

wget $aro_download_url/amd64/linux/oc.tar

mkdir openshift
tar -xvf oc.tar -C openshift
echo 'export PATH=$PATH:~/openshift' >> ~/.bashrc && source ~/.bashrc
oc version

source <(oc completion bash)
echo "source <(oc completion bash)" >> ~/.bashrc 

oc login $aro_api_server_url -u $aro_usr -p $aro_pwd
oc whoami
oc cluster-info

wget --no-check-certificate  -U 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.67 Safari/537.36 Edg/87.0.664.47' https://www.whatismyip.com

cat index.html |grep "My Public IPv4 is"

```

## Create Namespaces
```sh
oc create namespace development
oc label namespace/development purpose=development

oc create namespace staging
oc label namespace/staging purpose=staging

oc create namespace production
oc label namespace/production purpose=production

oc create namespace sre
oc label namespace/sre purpose=sre

oc get namespaces
oc describe namespace production
oc describe namespace sre
```

## Optionnal Play: what resources are in your cluster

```sh
oc get nodes

# https://docs.microsoft.com/en-us/azure/aks/availability-zones#verify-node-distribution-across-zones
oc describe nodes | grep -e "Name:" -e "failure-domain.beta.kubernetes.io/zone"

oc get pods
oc top node
oc api-resources --namespaced=true
oc api-resources --namespaced=false
oc get crds

oc get serviceaccounts --all-namespaces
oc get roles --all-namespaces
oc get rolebindings --all-namespaces
oc get ingresses  --all-namespaces

oc create serviceaccount api-service-account
oc apply -f ./cnf/clusterRole.yaml

oc create serviceaccount api-service-account
oc get sa api-service-account
oc describe sa api-service-account

sa_secret_name=$(oc get serviceaccount api-service-account  -o json | jq -Mr '.secrets[].name')
echo "SA secret name " $sa_secret_name

token_secret_value=$(oc get secrets  $sa_secret_name -o json | jq -Mr '.items[0].data.token' | base64 -d)
echo "SA secret  " $sa_secret_value

# kube_url=$(oc get endpoints -o jsonpath='{.items[0].subsets[0].addresses[0].ip}')
# echo "Kube URL " $kube_url

curl -k $aro_api_server_url/api/v1/namespaces -H "Authorization: Bearer $token_secret_value" -H 'Accept: application/json'
curl -k $aro_api_server_url/apis/user.openshift.io/v1/users/~ -H "Authorization: Bearer $token_secret_value" -H 'Accept: application/json'

```