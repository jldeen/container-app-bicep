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

@secure()
param mysqlRootPassword string
param mysqlPassword string 

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

module mysql 'modules/createContainerApp.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'mysql'
  params: {
    name: 'mysql'
    containerImage: 'mysql:5.7'
    containerAppEnvironmentId: containerAppEnv.outputs.id
    containerPort: 3306
    useExternalIngress: false
    environmentVariables: [
      {
        name: 'MYSQL_ROOT_PASSWORD'
        value: mysqlRootPassword
      }
      {
        name: 'MYSQL_DATABASE'
        value: 'ghost'
      }
      {
        name: 'MYSQL_USER'
        value: 'ghost'
      }
      {
        name: 'MYSQL_PASSWORD'
        value: mysqlPassword
      }
    ]
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
        name: 'database__client'
        value: 'mysql'
      }
      {
        name: 'database__connection__host'
        value: 'mysql'
      }
      {
        name: 'database__connection__user'
        value: 'ghost'
      }
      {
        name: 'database__connection__password'
        value: mysqlPassword
      }
      {
        name: 'database__connection__database'
        value: 'ghost'
      }
    ]
  }
}
