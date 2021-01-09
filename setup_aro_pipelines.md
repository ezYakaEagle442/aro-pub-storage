# Tekton Pipelines

- [Tekton overview](https://tekton.dev/docs/overview)
- [TektonCD Pipelines](https://github.com/tektoncd/pipeline/blob/master/docs/pipelines.md)
- [Guide to OpenShift pipelines part 2](https://www.openshift.com/blog/guide-to-openshift-pipelines-part-2-using-source-2-image-build-in-tekton)
- [Guide to OpenShift pipelines part4](https://www.openshift.com/blog/guide-to-openshift-pipelines-part-4-application-deployment-and-pipeline-orchestration-1)

## pre-req
Check [tkn cli is installed](./tools.md#how-to-install-tekton-cli)

```sh
tkn help
tkn version
```

Install the Red Hat OpenShift Pipelines Operator based on Tekton from the OperatorHub
```sh
echo "Please Install the Red Hat OpenShift Pipelines Operator based on Tekton from the OperatorHub, go to :"
echo "$aro_console_url/operatorhub/ns/openshift-machine-api?category=Developer+Tools&keyword=Tekton"
```

## Create a dummy App. Pipeline

```sh
projectname=pipelines-tutorial
oc new-project $projectname

oc config current-context
oc status
oc projects
oc project $projectname

oc create serviceaccount pipeline
oc get sa pipeline
oc describe sa pipeline

sa_secret_name=$(kubectl get serviceaccount pipeline -o json | jq -Mr '.secrets[].name')
echo "SA secret name " $sa_secret_name

# Openshift Cheatsheet: https://gist.github.com/rafaeltuelho/111850b0db31106a4d12a186e1fbc53e
sa_secret_value=$(oc get secrets  $sa_secret_name -o json | jq -Mr '.items[1].data.token' | base64 -d)
echo "SA secret  " $sa_secret_value

kube_url=$(oc get endpoints -n default -o jsonpath='{.items[0].subsets[0].addresses[0].ip}')
echo "Kube URL " $kube_url

curl -k $aro_api_server_url/api/v1/namespaces -H "Authorization: Bearer $sa_secret_value" -H 'Accept: application/json'
curl -k $aro_api_server_url/apis/user.openshift.io/v1/users/~ -H "Authorization: Bearer $sa_secret_value" -H 'Accept: application/json'

oc adm policy add-scc-to-user privileged -z pipeline # system:serviceaccount:$projectname:pipeline
# oc policy add-role-to-user registry-editor -z pipeline

oc adm policy add-role-to-user edit -z pipeline
oc describe scc privileged

for tkncrd in $(oc get crds -l app.kubernetes.io/part-of=tekton-pipelines -o=custom-columns=:.metadata.name)
do
  if [[ "$tkncrd"="*.tekton.dev.*" ]]
    then
      echo "Verifying CRD $tkncrd"
      oc describe crd $tkncrd | grep -i "Short Names"
  fi
done

oc create -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/01_pipeline/01_apply_manifest_task.yaml
oc create -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/01_pipeline/02_update_deployment_task.yaml
oc create -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/01_pipeline/03_persistent_volume_claim.yaml

tkn task ls
tkn clustertask ls

oc apply -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/01_pipeline/04_pipeline.yaml
tkn pipeline list

# Lets start a pipeline to build and deploy backend application using tkn:
tkn pipeline start build-and-deploy \
    -w name=shared-workspace,volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/01_pipeline/03_persistent_volume_claim.yaml \
    -p deployment-name=vote-api \
    -p git-url=https://github.com/openshift-pipelines/vote-api.git \
    -p IMAGE=image-registry.openshift-image-registry.svc:5000/$projectname/vote-api

# Similarly, start a pipeline to build and deploy frontend application:
tkn pipeline start build-and-deploy \
    -w name=shared-workspace,volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/01_pipeline/03_persistent_volume_claim.yaml \
    -p deployment-name=vote-ui \
    -p git-url=https://github.com/openshift-pipelines/vote-ui.git \
    -p IMAGE=image-registry.openshift-image-registry.svc:5000/$projectname/vote-ui

tkn pipeline list
tkn pipelinerun ls
tkn pipeline logs -f

# to re-run the pipeline again, use the following short-hand command to rerun the last pipelinerun again that uses the same workspaces, params and sa used in the previous pipeline run:
tkn pipeline start build-and-deploy --last

#  get the route of the application by executing the following command and access the application
oc get route vote-ui --template='http://{{.spec.host}}'

```

## Create a Pipeline to deploy Azure PaaS services

# Pre-req : create a Service Principal to Signin to az CLI
```sh
azcli_sp_password=$(az ad sp create-for-rbac --name tkn-pipeline --role contributor --query password -o tsv)
echo $azcli_sp_password > azcli_tkn_sp_password.txt
echo "Service Principal Password saved to ./tkn_azcli_sp_password.txt IMPORTANT Keep your password ..." 
# azcli_sp_password=`cat azcli_tkn_sp_password.txt`
azcli_sp_id=$(az ad sp show --id http://tkn-pipeline --query appId -o tsv)
#azcli_sp_id=$(az ad sp list --all --query "[?appDisplayName=='tkn-pipeline'].{appId:appId}" --output tsv)
#azcli_sp_id=$(az ad sp list --show-mine --query "[?appDisplayName=='tkn-pipeline'].{appId:appId}" -o tsv)
echo "Tekton Service Principal ID:" $azcli_sp_id 
echo $azcli_sp_id > azcli_tkn_sp_id.txt
# azcli_sp_id=`cat azcli_tkn_sp_id.txt`
az ad sp show --id $azcli_sp_id

tenantId=$(az account show --query tenantId -o tsv)
```


```sh

# https://github.com/tektoncd/pipeline/blob/master/docs/pipelines.md#tekton-bundles : This is only allowed if enable-tekton-oci-bundles is set to "true"
oc get cm feature-flags -n openshift-pipelines
oc describe cm feature-flags -n openshift-pipelines

oc create -f ./cnf/arm_deploy_task.yaml
tkn task ls
tkn task describe arm-db-deploy

oc apply -f ./cnf/arm_deploy_pipeline.yaml
tkn pipeline list
tkn pipeline describe arm-deploy
 
# MariaDB
tkn pipeline start arm-deploy \
    -w name=arm-wip,volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/01_pipeline/03_persistent_volume_claim.yaml \
    -p ARM_TEMPLATE=101-managed-mariadb-with-vnet \
    -p ARM_RG_NAME=rg-arm-paas-db \
    -p DEPLOYMENT_GRP=mariadb \
    -p DB_SERVER_NAME=mariadb-flyingblue \
    -p ADM_LOGIN=sky_adm \
    -p ADM_PWD=MariaMariaFlyToTheMoon777! \
    -p ARM_RG_LOCATION=francecentral \
    -p AZ_CLI_SP_NAME=$azcli_sp_id \
    -p AZ_CLI_SP_PWD=$azcli_sp_password \
    -p AZ_TENANT=$tenantId

# PostgreSQL

# Admin login name cannot be 'azure_superuser', 'azure_pg_admin', 'admin', 'administrator', 'root', 'guest', 'public' or start with 'pg_'.
# Your password must be at least 8 characters and at most 128 characters.
# Your password must contain characters from three of the following categories – English uppercase letters, English lowercase letters, numbers (0-9), and non-alphanumeric characters (!, $, #, %, etc.).
# /!\ Your password cannot contain all or part of the login name. Part of a login name is defined as three or more consecutive alphanumeric characters.
tkn pipeline start arm-deploy \
    -w name=arm-wip,volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/01_pipeline/03_persistent_volume_claim.yaml \
    -p ARM_TEMPLATE=101-managed-postgresql-with-vnet \
    -p ARM_RG_NAME=rg-arm-paas-db \
    -p DEPLOYMENT_GRP=pgsql \
    -p DB_SERVER_NAME=pgsql-flyingblue \
    -p ADM_LOGIN=azure_pg_adm \
    -p ADM_PWD=GrowthMindSet-SKY-IsTheLimit200! \
    -p ARM_RG_LOCATION=francecentral \
    -p AZ_CLI_SP_NAME=$azcli_sp_id \
    -p AZ_CLI_SP_PWD=$azcli_sp_password \
    -p AZ_TENANT=$tenantId

tkn pipelinerun ls

# To Test AZ CLI image : 
# oc run az --image=mcr.microsoft.com/azure-cli:latest --restart=Never -- sleep 3600
# oc exec -it azclipod -- /bin/bash
# az version

# To Test bash:latest image : 
# oc run bashpod --image=bash:latest --restart=Never -- sleep 3600
# oc exec -it bashpod -- bash

```