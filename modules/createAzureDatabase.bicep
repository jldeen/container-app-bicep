@allowed([
  'B_Gen5_1'
  'B_Gen5_2'
])
param mySQLServerSku string

@description('Database administrator login name')
@minLength(1)
param administratorLogin string

@description('Database administrator password')
@minLength(8)
@maxLength(128)
@secure()
param administratorPassword string

@description('Location to deploy the resources')
param location string = resourceGroup().location

@description('Log Analytics workspace id to use for diagnostics settings')
param workspaceId string

var mysqlServerName = 'ghost-mysql-${uniqueString(resourceGroup().id)}'

resource mySQLServer 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: mysqlServerName
  location: location
  sku: {
    name: mySQLServerSku
    tier: 'Basic'
  }
  properties: {
    createMode: 'Default'
    version: '5.7'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    sslEnforcement: 'Enabled'
    minimalTlsVersion: 'TLS1_2'
  }
}

resource firewallRules 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01' = {
  parent: mySQLServer
  name: 'AllowAzureIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource mySQLServerDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: mySQLServer
  name: 'MySQLServerDiagnostics'
  properties: {
    workspaceId: workspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'MySqlSlowLogs'
        enabled: true
      }
      {
        category: 'MySqlAuditLogs'
        enabled: true
      }
    ]
  }
}

output name string = mySQLServer.name
output fqdn string = mySQLServer.properties.fullyQualifiedDomainName
