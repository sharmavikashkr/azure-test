## Description

A simple application developed in [Nest](https://github.com/nestjs/nest) framework to demonstrate deployment to Azure in 2 ways:
1. By using Azure Cli and [Azure Resource manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview) templates.
2. Though [Github Actions](https://github.com/features/actions) workflows.

## Installation

```bash
$ npm install
```

## Running the app locally

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev
```

## Running the app locally in Docker

```bash
# build docker image
$ docker build -t hello-world:1.0.0 .
# run
$ docker run -p 80:80 hello-world:1.0.0
# verify
$ verify that the application is accessible at http://localhost/hello
```

## Create a service principal (To be done only once)

This is a common step before deploying though either ways discussed below.

1. Download Azure Cli and login to Azure using your tenant
```bash
$ az login --tenant <tenant_id>
```
2. Create a resource group
```bash
$ az group create -l centralindia -n TestGroup
```
3. Create a group scoped service principal. Save the generated JSON output securely.
```bash
$ groupId=$(az group show --name TestGroup --query id --output tsv)
$ MSYS_NO_PATHCONV=1 az ad sp create-for-rbac --name TestApp --role contributor --scope $groupId --sdk-auth
```

### Deploy to Azure using Azure Cli and Azure Resource manager templates

Steps in details [here](https://medium.com/nerd-for-tech/deploy-an-application-in-azure-container-instances-aci-using-azure-resource-manager-arm-f678ee3de06e).

1. Login with service principal
```bash
$ az login — service-principal -u <client_id> -p <client_secret> --tenant <tenant_id>
```
2. Create a container registry
```bash
$ az acr create --resource-group TestGroup --name testgroupregistry --sku Basic
```
3. Build and push image to the registry
```bash
$ docker build . -t hello-world:1.0.0
$ docker tag hello-world:1.0.0 testgroupregistry.azurecr.io/samples/hello-world:1.0.0
$ az acr login --name testgroupregistry
$ docker push testgroupregistry.azurecr.io/samples/hello-world:1.0.0
```
4. Create a container instance
There is template file `infra/aci.bicep` which is a [Azure Resource Manager template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) for creating Azure Container Instance. We will use it to create an ACI and deploy the docker image generated above.
```bash
$ az deployment group create --resource-group TestGroup --template-file infra/aci.bicep --parameters name=helloworlddev image=testgroupregistry.azurecr.io/samples/hello-world:1.0.0 registryServer=testgroupregistry.azurecr.io clientId=<client_id> clientSecret=<client_secret> dnsNameLabel=helloworlddevtest port=80
```

### Deploy to Azure using GitHub Actions

Steps in details [here](https://medium.com/nerd-for-tech/deploy-an-application-in-azure-container-instances-aci-through-github-actions-df7144fcd67f).

1. Store service pricipal credentials in your GitHub repo's secrets:
```bash
  AZURE_CREDENTIALS => <the service principal json generated above>
  AZURE_USERNAME => <clientId of the service principal>
  AZURE_PASSWORD => <clientSecret of the service principal>
```
2. The `.github/workflows/workflow.yml` takes care of creating the ACI and deployment on every push.
