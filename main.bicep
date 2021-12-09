targetScope = 'subscription'

// Resource Group Name
@description('Resource Group Name')
@minLength(4)
@maxLength(64)
param rgName string

// Location
@description('Location of Azure Resources')
@allowed([
  'eastus'
  'westus'
  'centralus'
])
param location string

// Container App Name
@description('Container App Name')
@minLength(4)
@maxLength(64)
param name string

@description('Azure Database Admin login')
param administratorLogin string

@secure()
param administratorPassword string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module logAnalytics 'modules/createLogAnalytics.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'logAnalyticsWorkspace'
  params: {
    name: name
  }
}

module containerAppEnv 'modules/createContainerAppEnv.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'containerAppEnv'
  dependsOn:[
    logAnalytics
  ]
  params: {
    name: name
    workspaceClientId: logAnalytics.outputs.clientId
    workspaceClientSecret: logAnalytics.outputs.clientSecret
  }
}

module database 'modules/createAzureDatabase.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'database'
  params: {
    workspaceId: logAnalytics.outputs.workspaceId
    mySQLServerSku: 'B_Gen5_1'
    administratorLogin: administratorLogin
    administratorPassword: administratorPassword
    mySQLServerName: 'ghost-sql-server'
  }
}

module ghost 'modules/createContainerApp.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'ghost'
  dependsOn: [
    database
    containerAppEnv
  ]
  params: {
    name: 'ghost'
    containerImage: 'jldeen/ghost:latest'
    containerAppEnvironmentId: containerAppEnv.outputs.id
    containerPort: 2368
    useExternalIngress: true
    transportMethod: 'http'
    environmentVariables: [
      {
        name: 'database__client'
        value: 'mysql'
      }
      {
        name: 'database__connection__host'
        value: database.outputs.fqdn
      }
      {
        name: 'database__connection__user'
        value: '${administratorLogin}@${database.outputs.name}'
      }
      {
        name: 'database__connection__password'
        value: administratorPassword
      }
      {
        name: 'database__connection__database'
        value: 'ghost'
      }
      {
        name: 'url'
        value: 'http://${name}-fd.azurefd.net'
      }
      {
        name: 'database__connection__ssl'
        value: 'true'
      }
      {
        name: 'database__connection__ssl_minVersion'
        value: 'TLSv1.2'
      }
    ]
  }
}

module frontdoor 'modules/createFrontdoor.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'frontdoor' 
  params: {
    containerAppName: ghost.outputs.name
    fdName: '${name}-fd'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    wafPolicyName: '${name}waf'
  }
}

output frontdoorFQDN string = frontdoor.outputs.hostname
output ghostFQDN string = ghost.outputs.fqdn
