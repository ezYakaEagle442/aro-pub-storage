# Get Azure subscription

You need an Azure subscription. If you do not have one, to get started quickly go to [https://my.visualstudio.com](https://my.visualstudio.com).

You can also get free or charge subscription from [https://azure.microsoft.com/en-us/pricing/member-offers/credit-for-visual-studio-subscribers](https://azure.microsoft.com/en-us/pricing/member-offers/credit-for-visual-studio-subscribers), no Credit Card needed.

For MS employees, ask help from the proctor to create your own MS internal subscription. 
 
Check your subscription at : [https://account.azure.com/subscriptions](https://account.azure.com/subscriptions) 
then go to [https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade ) --> remove filter "Show only subscriptions selected in the global subscriptions filter" to see it.

# Use your Azure subscription

You can use the Azure Cloud Shell accessible [https://portal.azure.com](https://portal.azure.com) once you login with an Azure subscription. 
The Azure Cloud Shell has the Azure CLI pre-installed and configured to connect to your Azure subscription as well as `kubectl` and `helm`.

```sh
az --version
az account list 
az account show 
```

Please use your username and password to login to <https://portal.azure.com>.

Also please authenticate your Azure CLI by running the command below on your machine and following the instructions.

```sh
# /!\ In CloudShell, the default subscription is not always the one you thought ...
subName="set here the name of your subscription"

subName=$(az account list --query "[?name=='${subName}'].{name:name}"  --output tsv)
echo "subscription Name :" $subName 
subId=$(az account list --query "[?name=='${subName}'].{id:id}"  --output tsv)
echo "subscription ID :" $subId

az account set --subscription $subId
az account show

tenantId=$(az account show --query tenantId -o tsv)

# if you run az cli out of cloudshell (ex: in WSL)
az login --username xxx --tenant $tenantId

```
