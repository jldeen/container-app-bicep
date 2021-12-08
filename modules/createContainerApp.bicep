@description('Container app location; default is Resource Group location')
param location string = resourceGroup().location

param name string
param containerAppEnvironmentId string

@description('Set image for your container app to use')
param containerImage string

// ACA etworking
@description('Set whether you want your ingress visible externally, or internally within a VNET')
param useExternalIngress bool = false

@description('The port your container listens to for incoming requests. Your application ingress endpoint is always exposed on port 443')
param containerPort int

// For more information on HTTPS ingress in Azure Container Apps Preview, checkout the docs here: https://docs.microsoft.com/en-us/azure/container-apps/ingress?tabs=bash
@description('Transport type for Ingress')
@allowed([
  'auto'
  'http'
  'http2'
])
param transportMethod string = 'auto'

// param registry string 
// param registryUsername string
// @secure()
// param registryPassword string

param environmentVariables array = []

resource containerApp 'Microsoft.Web/containerApps@2021-03-01' = {
  name: name
  kind: 'containerapp'
  location: location
  properties: {
    kubeEnvironmentId: containerAppEnvironmentId
    configuration: {
      secrets: [
      ]    
      registries: [
      ]
      ingress: {
        external: useExternalIngress
        targetPort: containerPort
        transport: transportMethod
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: name
          env: environmentVariables
        }
      ]
      scale: {
        minReplicas: 0
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
