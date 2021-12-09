@minLength(5)
@maxLength(64)
param fdName string

@minLength(1)
@maxLength(128)
param wafPolicyName string

@description('Log Analytics workspace id to use for diagnostics settings')
param logAnalyticsWorkspaceId string

@description('Container App Name')
param containerAppName string

var backendPool1Name = '${fdName}-backendPool1'
var healthProbe1Name = '${fdName}-healthProbe1'
var frontendEndpoint1Name = '${fdName}-frontendEndpoint1'
var loadBalancing1Name = '${fdName}-loadBalancing1'
var routingRule1Name = '${fdName}-routingRule1'
var frontendEndpoint1hostName = '${fdName}.azurefd.net'

resource existingContainerApp 'Microsoft.Web/containerApps@2021-03-01' existing = {
  name: containerAppName
}

resource frontDoor 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: fdName
  location: 'global'
  properties: {
    routingRules: [
      {
        name: routingRule1Name
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', fdName, frontendEndpoint1Name)
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', fdName, backendPool1Name)
            }
            cacheConfiguration: {
              queryParameterStripDirective: 'StripNone'
              dynamicCompression: 'Enabled'
            }
          }
          enabledState: 'Enabled'
        }
      }
    ]
    healthProbeSettings: [
      {
        name: healthProbe1Name
        properties: {
          path: '/'
          protocol: 'Https'
          intervalInSeconds: 120
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: loadBalancing1Name
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]
    backendPools: [
      {
        name: backendPool1Name
        properties: {
          backends: [
            {
              address: existingContainerApp.properties.configuration.ingress.fqdn
              backendHostHeader: existingContainerApp.properties.configuration.ingress.fqdn
              httpPort: 80
              httpsPort: 443
              weight: 50
              priority: 1
              enabledState: 'Enabled'
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', fdName, loadBalancing1Name)
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', fdName, healthProbe1Name)
          }
        }
      }
    ]
    frontendEndpoints: [
      {
        name: frontendEndpoint1Name
        properties: {
          hostName: frontendEndpoint1hostName
          sessionAffinityEnabledState: 'Disabled'
          webApplicationFirewallPolicyLink: {
            id: wafPolicy.id
          }
        }
      }
    ]
    enabledState: 'Enabled'
  }
}

resource frontDoorDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: frontDoor
  name: 'FrontDoorDiagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'FrontdoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontdoorWebApplicationFirewallLog'
        enabled: true
      }
    ]
  }
}

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-11-01' = {
  name: wafPolicyName
  location: 'global'
  properties: {
    policySettings: {
      mode: 'Prevention'
      enabledState: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '1.1'
        }
      ]
    }
  }
}

output hostname string = frontendEndpoint1hostName
