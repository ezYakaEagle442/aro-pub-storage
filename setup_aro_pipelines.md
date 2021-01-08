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


```sh
oc create -f ./cnf/arm_deploy_task.yaml
tkn task ls
tkn task describe arm-db-deploy

oc apply -f ./cnf/arm_deploy_pipeline.yaml
tkn pipeline list
tkn pipeline describe arm-deploy
 
tkn pipeline start arm-deploy \
    -w name=arm-wip,volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/01_pipeline/03_persistent_volume_claim.yaml \
    -p ARM_TEMPLATE=101-managed-postgresql-with-vnet \
    -p ARM_RG_NAME=rg-arm-paas-db \
    -p DEPLOYMENT_GRP=pgsql \
    -p DB_SERVER_NAME=pgsql_flyingblue \
    -p ADM_LOGIN=sky_adm \
    -p ADM_PWD=SkyIsTheLimit200! \
    -p ARM_RG_LOCATION=francecentral

tkn pipelinerun ls

```