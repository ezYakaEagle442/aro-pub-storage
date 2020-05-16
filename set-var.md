# Set-up environment variables

<span style="color:red">/!\ IMPORTANT </span> : your **appName** & **cluster_name** values MUST BE UNIQUE

## Core variables
```sh

# az account list-locations : francecentral | northeurope | westeurope | eastus2
location=westeurope 
echo "location is : " $location 

appName="arostr" 
echo "appName is : " $appName 

# Storage account name must be between 3 and 24 characters in length and use numbers and lower-case letters only
storage_name="stwe""${appName,,}"
echo "Storage name:" $storage_name

target_namespace="staging"
echo "Target namespace:" $target_namespace

dns_zone="cloudapp.azure.com"
echo "DNS Zone is : " $dns_zone

app_dns_zone="kissmyapp.${location}.${dns_zone}"
echo "App DNS zone " $app_dns_zone

custom_dns="akshandsonlabs.com"
echo "Custom DNS is : " $custom_dns

version=$(az aro get-versions -l $location --query 'orchestrators[-2].orchestratorVersion' -o tsv) 
echo "version is :" $version 

vault_secret="NoSugarNoStar" 
echo "Vault secret:" $vault_secret 

git_url="https://github.com/your-project/xxx.git"
echo "Project git repo URL : " $git_url 

git_url_springboot="https://github.com/spring-projects/spring-petclinic.git"
echo "Project git repo URL : " $git_url_springboot 

ssh_passphrase="<your secret>"
ssh_key="${appName}-key" # id_rsa

```

## AKS Cluster variables
Note: The here under variables are built based on the varibales defined above, you should not need to modify them, just run this snippet

```sh
vault_secret_name="${appName}-secret"
echo "Vault secret name:" $vault_secret_name 

network_plugin="azure"
echo "Network Plugin is : " $network_plugin 

network_policy="azure"
echo "Network Policy is : " $network_policy 

rg_name="rg-${appName}-${location}" 
echo "AKS RG name:" $rg_name 

rg_acr_name="rg-acr-${appName}-${location}" 
echo "ACR RG name:" $rg_acr_name 

rg_bastion_name="rg-bastion-${appName}-${location}" 
echo "Bastion RG name:" $rg_bastion_name 

rg_fw_name="rg-fw-${appName}-${location}"
echo "Firewall RG name:" $rg_fw_name

rg_kv_name="rg-kv-${appName}-${location}" 
echo "KeyVault RG name:" $rg_kv_name 

cluster_name="aro-${appName}-${target_namespace}-101" #aks-<App Name>-<Environment>-<###>
echo "Cluster name:" $cluster_name


# https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools
# The name of a node pool may only contain lowercase alphanumeric characters and must begin with a lowercase letter. 
# --nodepool-name can contain at most 12 characters. must conform to the following pattern: '^[a-z][a-z0-9]{0,11}$'.
node_pool_name="${appName}aksnp"
echo "Node Pool name:" $node_pool_name

poc_node_pool_name="${appName}pocnp"
echo "PoC Node Pool name:" $poc_node_pool_name

spotpool_name_min="spotmin"
echo "Spot cheap Node Pool name:" $spotpool_name_min

spotpool_name_max="spotmax"
echo "Spot market rate Node Pool name:" $spotpool_name_max

```

## Network

```sh

# ARO VNet & Subnet
vnet_name="vnet-${appName}"
echo "VNet Name :" $vnet_name

subnet_name="snet-${appName}"
echo "Subnet Name :" $subnet_name

new_node_pool_subnet_name="snet-new-np-${appName}"
echo "New Node-Pool Subnet Name :" $new_node_pool_subnet_name

# Internal Load Balancer (ILB)
ilb_subnet_name="snet-ilb_${appName}"
echo "Internal Load Balancer Subnet Name :" $ilb_subnet_name

vnet_peering_name_aks_fw="vnetp-${appName}-AKSVNet-To-FW-VNet"
echo "VNet Peering Name :" $vnet_peering_name_aks_fw

firewall_vnet_name="vnet-${appName}-fw"
echo "Azure Firewall VNet Name :" $firewall_vnet_name
 # DO NOT CHANGE $firewall_subnet_name - This is currently a requirement for Azure Firewall.
firewall_subnet_name="AzureFirewallSubnet"
echo "Azure Firewall Subnet Name :" $firewall_subnet_name

firewall_public_IP_name="pip-fw-pub-IP-${appName}"
echo "Firewall IP :" $firewall_public_IP_name

firewall_name="fw-${appName}"
echo "Firewall Name :" $firewall_name

firewall_ip_config_name="fw-cnf-${appName}"
echo "Azure Firewall IP-Config Name :" $firewall_ip_config_name

fw_route_table_name="route-table-${appName}"
echo "Azure Firewall Route Table Name :" $fw_route_table_name

fw_route="rte${appName}"
echo "Azure Firewall Route Name :" $fw_route

fw_network_collection_name="fw-net-coll-${appName}"
echo "Azure Firewall Network Collection Name :" $fw_network_collection_name

fw_app_collection_name="fw-app-coll-${appName}"
echo "Azure Firewall Application Collection Name :" $fw_app_collection_name

fw_app_rule_name="fw-app-rule-${appName}"
echo "Azure Firewall application rule Name :" $fw_app_rule_name

# Bastion

bastion_name="${appName}-bastion"
echo "Bastion name :" $bastion_name

bastion_admin_username="${appName}-admin"
echo "Bastion admin user-name :" $bastion_admin_username

aks_admin_username="${appName}-admin"
echo "AKS admin user-name :" $aks_admin_username

vnet_bastion_name="vnet-bastion-${appName}"
echo "Bastion VNet Name :" $vnet_bastion_name

vnet_peering_name_bastion_aks="vnetp-BastionVNet-To-AKS-${appName}-VNet"
echo "VNet Peering Name Bastion VNet To AKS:" $vnet_peering_name_bastion_aks

vnet_peering_name_bastion_kv="vnetp-BastionVNet-To-KV-${appName}-VNet"
echo "VNet Peering Name Bastion VNet To KV :" $vnet_peering_name_bastion_kv

vnet_peering_name_bastion_acr="vnetp-BastionVNet-To-ACR-${appName}-VNet"
echo "VNet Peering Name Bastion VNet To ACR :" $vnet_peering_name_bastion_acr

appgw_vnet_peering_name="vnetp-AppGwVNet-To-AKS-${appName}-VNet"
echo "VNet Peering Name App. Gateway VNet To AKS :" $appgw_vnet_peering_name

# https://docs.microsoft.com/en-us/cli/azure/network/bastion?view=azure-cli-latest#az-network-bastion-create
# must have a subnet called AzureBastionSubnet
subnet_bastion_name="AzureBastionSubnet" #"snet-${appName}-AzureBastion"
echo "Bastion Subnet Name :" $subnet_bastion_name

bastion_IP="pip-bastionIP-${appName}"
echo "Bastion IP :" $bastion_IP

bastion_DNS_name="${appName}-bastion"
echo "Bastion DNS name :" $bastion_DNS_name

# App. Gateway (not the one for AGIC)
vnet_appgw="vnet-appgw-${appName}"
echo "App. Gateway VNet Name :" $vnet_appgw

appgw_subnet_name="snet-agw-${appName}"
echo "App. Gateway Subnet Name :" $appgw_subnet_name

acr_vnet_name="vnet-acr-${appName}"
echo "ACR VNet Name :" $acr_vnet_name

acr_subnet_name="snet-acr-${appName}"
echo "ACR Subnet Name :" $acr_subnet_name

acr_vnet_peering_name="vnetp-AKS-${appName}-VNet-To-ACRVNet"
echo "ACR VNet Peering Name :" $acr_vnet_peering_name

kv_vnet_name="vnet-kv-${appName}"
echo "KeyVault VNet Name :" $kv_vnet_name

kv_subnet_name="snet-kv-${appName}"
echo "KeyVault Subnet Name :" $kv_subnet_name

kv_vnet_peering_name="vnetp-AKS-${appName}-VNet-To-KeyVaultVNet"
echo "KeyVault VNet Peering Name :" $kv_vnet_peering_name

```


## Application gateway

```sh
# Classical App Gateway without AGIC
appgw_name="agw-${appName}"
echo "App Gateway name:" $appgw_name

appgw_IP="pip-appgwIP-${appName}"
echo "App Gateway  IP :" $appgw_IP

appgw_DNS_name="${appName}-appgw"
echo "App Gateway  DNS name :" $appgw_DNS_name


# AGIC
appgw_agic_name="agw-agic-${appName}"
echo "App Gateway Ingress Controller name:" $appgw_agic_name

agic_subnet_name="snet-agic-${appName}"
echo "App. Gateway Ingress Controller Subnet Name :" $agic_subnet_name

appgw_agic_IP="pip-appgw-agic-IP-${appName}"
echo "App Gateway Ingress Controller IP :" $appgw_IP

appgw_agic_DNS_name="${appName}-agic"
echo "App Gateway Ingress Controller DNS name :" $appgw_agic_DNS_name

```


```sh

vault_name="kv-${appName}"
echo "Vault name :" $vault_name

analytics_workspace_name="log-${appName}-analytics-wks"
echo "Analytics Workspace Name :" $analytics_workspace_name

analytics_workspace_template="deployworkspacetemplate.json"
echo "Analytics Workspace template file name :" $analytics_workspace_template

acr_registry_name="acr${appName,,}"
echo "ACR registry Name :" $acr_registry_name

acr_analytics_workspace="acr-wrk-${appName,,}"
echo "ACR Log Analytics Workspace Name:" $acr_analytics_workspace

app_insights_name="appi-${appName}"
echo "Application Insights Name :" $app_insights_name

```