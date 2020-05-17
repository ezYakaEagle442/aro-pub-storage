

```sh
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
wget https://downloads-openshift-console.apps.rptd5b3w.westeurope.aroapp.io/amd64/linux/oc.tar

mkdir openshift
tar -xvf oc.tar -C openshift
echo 'export PATH=$PATH:~/openshift' >> ~/.bashrc && source ~/.bashrc
oc version

source <(oc completion bash)
echo "source <(oc completion bash)" >> ~/.bashrc 

oc login $aro_api_server_url -u $aro_usr -p $aro_pwd

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

oc get roles --all-namespaces
oc get serviceaccounts --all-namespaces
oc get rolebindings --all-namespaces
oc get ingresses  --all-namespaces
```