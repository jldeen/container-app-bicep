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

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module logAnalytics 'modules/createLogAnalytics.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'logAnalyticsWorkspace'
  params: {
    name: 'aca-logs'
  }
}

module containerAppEnv 'modules/createContainerAppEnv.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'containerAppEnv'
  params: {
    name: 'aca-env'
    workspaceClientId: logAnalytics.outputs.clientId
    workspaceClientSecret: logAnalytics.outputs.clientSecret
  }
}

module grpcBackend 'modules/createContainerApp.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'grpc-backend'
  params: {
    name: 'grpc-backend'
    containerImage: 'ghcr.io/jeffhollan/grpc-sample-python/grpc-backend:main'
    containerAppEnvironmentId: containerAppEnv.outputs.id
    containerPort: 50051
    useExternalIngress: false
    transportMethod: 'http2'
    environmentVariables: []
  }
}

module httpsFrontend 'modules/createContainerApp.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'https-frontend'
  params: {
    name: 'https-frontend'
    containerImage: 'ghcr.io/jeffhollan/grpc-sample-python/https-frontend:main'
    containerAppEnvironmentId: containerAppEnv.outputs.id
    containerPort: 8050
    useExternalIngress: true
    environmentVariables: [
      {
        name: 'GRPC_SERVER_ADDRESS'
        value: '${grpcBackend.outputs.fqdn}:443'
      }
      {
        name: 'GRPC_DNS_RESOLVER'
        value: 'native'
      }
    ]
  }
}

output httpsFrontendFQDN string = httpsFrontend.outputs.fqdn
