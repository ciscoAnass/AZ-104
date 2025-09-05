param location string = resourceGroup().location


@description('Globally unique app name (used in default hostname)')
param appName string = 'py-webapp-12345'

@description('App Service Plan SKU (B1 is the cheapest Linux tier)')
param skuName string = 'F1' // B1, B2, B3, etc.

param pythonVersion string = '3.11' // e.g. 3.10, 3.11, 3.12


resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appName
  location: location
  sku: {
    name: skuName
  }
  kind: 'linux'
  properties: {
    reserved: true   // Linux plan
    perSiteScaling: false
  }
}

resource site 'Microsoft.Web/sites@2023-12-01' = {
  name: 'pythonfreewebappdemo123'   // must be globally unique, lowercase, 2–60 chars
  location: 'westeurope'
  kind: 'app,linux'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|${pythonVersion}'
      minimumTlsVersion: '1.2'
      alwaysOn: false 
      ftpsState: 'FtpsOnly'
    }
  }
  tags: {
    environment: 'development'
    project: 'python-webapp'
  }
}

output defaultHostname string = site.properties.defaultHostName
output url string = 'https://${site.properties.defaultHostName}'
output scmUrl string = 'https://${app.name}.scm.azurewebsites.net'
output planName string = plan.name