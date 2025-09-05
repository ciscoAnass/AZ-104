param location string = resourceGroup().location
param sqlServerName string = 'DB-CiscoAnass'
param adminLogin string = 'sqladmin'
@secure()
param adminPassword string      // supply via your pipeline secret Var
param databaseName string = 'appdb'

@description('Allow Azure services to connect (firewall 0.0.0.0).')
param allowAzureServices bool = true

@description('OPTIONAL: your public IPv4 to allow, e.g. 203.0.113.5 (leave blank to skip).')
param clientIp string = '89.154.12.34' // Your public IP

// SQL logical server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Single database (Standard S0 — easy + inexpensive to start; change as needed)
resource db 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: '${sqlServer.name}/${databaseName}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {}
}

// Firewall: allow Azure services (0.0.0.0)
resource fwAzure 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = if (allowAzureServices) {
  name: '${sqlServer.name}/AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Firewall: allow a single client IP (optional)
resource fwClient 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = if (clientIp != '') {
  name: '${sqlServer.name}/ClientIp'
  properties: {
    startIpAddress: clientIp
    endIpAddress: clientIp
  }
}

output sqlFqdn string = sqlServer.properties.fullyQualifiedDomainName
output connectionStringTemplate string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${databaseName};User ID=${adminLogin};Password=<yourSecret>;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;'
