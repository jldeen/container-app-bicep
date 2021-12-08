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
  params: {
    name: name
    workspaceClientId: logAnalytics.outputs.clientId
    workspaceClientSecret: logAnalytics.outputs.clientSecret
  }
}

module ghost 'modules/createContainerApp.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'ghost'
  params: {
    name: 'ghost'
    containerImage: 'jldeen/ghost:latest'
    containerAppEnvironmentId: containerAppEnv.outputs.id
    containerPort: 2368
    useExternalIngress: true
    environmentVariables: [
      {
        name: 'url'
        value: 'http://localhost:2368'
      }
    ]
  }
}

output ghostFQDN string = ghost.outputs.fqdn
