# Ghost Blog Standalone Container App w/ Debug Script

One click [Ghost](https://github.com/TryGhost/Ghost) deployment using Azure Container Apps, Azure Database, Azure Frontdoor, and Azure Keyvault.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjldeen%2Fcontainer-app-bicep%2Fghost%2Fmain.json)

## Objectives 

This repo shows an example of how to run a frontend + database using Azure Container Apps, Azure Front Door, and Azure Database. Once could theoretically use the provided bicep files and deploy scripts and standup their own preferred frontend + database application (python + redis, wordpress  + mariadb, etc.) 

This demo includes bicep files to standup a standalone instance of the popular open source headless CMS system known as [Ghost](https://github.com/TryGhost/Ghost).

To simplify the deployment experience, there are abstracted Azure Bicep files located in the `./modules` folder within this repo.

As an added bonus, this repo supports GitHub Actions with the native `azure/arm-deploy@v1` deploy step to stand up everything needed.

### Requirements

* [Azure CLI v2.30.0](https://docs.microsoft.com/cli/azure/install-azure-cli)
* [Azure Account](https://azure.microsoft.com/free/)
* [Azure Container Apps Extension Enabled](https://docs.microsoft.com/en-us/azure/container-apps/get-started?tabs=bash#setup)

## Run this Ghost Sample Demo

Starting from the root of this folder, please login to Azure 

```bash
  az login
```

Set the desired subscription.

```bash
  az account set --subscription <id or name>
```

Ensure the Azure Container Apps extension is installed for your Azure CLI.

```bash
    az extension add --source https://workerappscliextension.blob.core.windows.net/azure-cli-extension/containerapp-0.2.0-py2.py3-none-any.whl
```

Register the `Microsoft.Web` Namespace
   
```bash
    az provider register --namespace Microsoft.Web
```

Now we can deploy the app, as well as all required resources, by simply running the `deploy.sh` script for bash / zsh. 

This script takes the following optional arguments via the included `env.sh` file:

1. `containerAppName`: This is the name of the containerApp for this demo instance of Ghost. Default value is: `ghost`
2. `Resource Group Name`: The name of your resource group created in Azure. Default value is: `ghostDemo`
3. `location`: This is the location your resources will be deployed. Default value is: `eastus`
4. `name`: This is the name for your Container App resources. Default value is: `ghostDemo`
5. `administratorLogin`: This is the user name for your Azure Database for MySQL user name. Default value is: `ghostadmin`
6. `administratorPassword`: This is the password for the Azure Database for MySQL user account: Default value is: `P@ssw012d!`

If the default values work for you, simply run the following to deploy this demo:

```bash
    ./deploy.sh
```

If you would like to provide your own resource group name and location, run the following to deploy this demo with your preferred arguments supplied:

```bash
    ./deploy.sh myResourceGroupName canadacentral
```

The deploy script will run and will create 6 resources in the resource group name you chose:

* Container App Environment
* Log Analytics Workspace
* Container App (ghost)
* Azure Database for MySQL Server (ghost-mysql-uniquestring)
* Front Door (GhostDemo-fd)
* Front Door WAF policy (GhostDemowaf)

After the script completes, you will see output similar to the following:

```bash
    Your app is accessible from https://ghostDemo-fd.azurefd.net

```

> Note: Azure Front Door will take 1-2 minutes to provision and become available.

Simply click the link provided from the script to access the Ghost instance now running in Azure Container Apps. A successful deployment will provide the following in your browser:

![ACA Successful Ghost Example]()

If you navigate to your Azure Portal, and to your created resource group, you will see resources similar to this:

![Azure Portal Example]()

## Debugging Info | Accessing the Azure Container App Logs via Log Analytics

Both the `./deploy.sh` and the `./debug.sh` script source the same `.env.sh` environment variables file. To easily access the container app logs, you can use the debug script in the following ways:

1. With default value for container named `ghost`
```bash
    ./debug.sh
```
2. With alternate container name provided. I.E. `mySpecialGhostContainer`
```bash
    ./debug.sh mySpecialGhostContainer
```

## TO-DO Items / Nice to haves
- [ ] GitHub Actions PR workflow to demonstrate Container App revision support
- [ ] Support for Azure KeyVault; currently only supported via connection string in code itself. This is on the roadmap for Container Apps.
- [ ] Due to current Container App limitations, one cannot run a database (mysql, redis, mariadb, etc.) in a container app and connect to the database from another frontend container app (ghost in this case). This has to do with transport methods support `http/1` and `http/2`, but not `TCP` communcation at this time.


## Bicep Templates Module Info

| Module | Details |
|--------|--------|
| createContainerApp.bicep | Creates Azure Container App Resource |
| createContainerAppEnv.bicep | Creates Azure Container App Environment Resource |
| createLogAnalytics.bicep | Creates Log Analytics Resource |

To deploy the 3 modules with the sample code from Jeff's repo, you will use the `main.bicep` file with the following parameters:

### Required Parameters
| Main Bicep | Required Parameters |
|--------|--------|
| rgName | Resource Group Name |
| location | Location of Azure Resources and Resource Group |
| name | Container App Name |
| administratorLogin | Azure Database Adminsitrator Username |
| administratorPassword | Azure Database Administrator Password |

### Optional Parameters
| Main Bicep | Optional Parameters |
|--------|--------|
| containerImage | Container Image for Azure Container App |
| containerPort | The port your container listens to for incoming requests. Your application ingress endpoint is always exposed on port 443  |
| mySQLServerSku | Skue for MySQL Server. Options include `B_Gen5_1` or `B_Gen5_2` |
| useExternalIngress | Set whether you want your ingress visible externally, or internally within a VNET |
| transportMethod | Transport type for Ingress. Options include `auto` `http` or `http2` |
| environmentVariables | Environment Variables needed for your container apps |