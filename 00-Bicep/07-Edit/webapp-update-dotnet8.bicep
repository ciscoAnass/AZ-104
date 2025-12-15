@description('Name of the existing App Service (Linux).')
param siteName string = 'pythonfreewebappdemo123'

@description('Resource group location of the Web App.')
param location string = 'westeurope'

@description('Name of the existing App Service Plan that the site uses.')
param appServicePlanName string = 'py-webapp-12345'

@description('Project tag value to keep.')
param projectTag string = 'python-webapp'

/*
  Reference the existing App Service Plan (Linux).
  Assumes the plan is in the same resource group you deploy to.
*/
resource plan 'Microsoft.Web/serverfarms@2023-12-01' existing = {
  name: appServicePlanName
}

/*
  Upsert the Web App with new tags (drop `environment`, add `cisco`)
  and keep it on Linux.
*/
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: siteName
  location: location
  kind: 'app,linux'
  tags: {
    project: projectTag
    cisco: 'anass'
  }
  properties: {
    // Keep the current plan
    serverFarmId: plan.id

    // Preserve HTTPS-only as in your current site
    httpsOnly: true
  }
}

/*
  Site configuration: set .NET 8 runtime and Startup Command.
  Using the child resource is the cleanest way to manage SiteConfig.
*/
resource webConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  name: '${webApp.name}/web'
  properties: {
    // Switch stack from Python 3.11 -> .NET 8 (Linux)
    // IMPORTANT: use the pipe |, not a colon :
    linuxFxVersion: 'DOTNETCORE|8.0'

    // Startup Command (Linux): runs when the app boots
    appCommandLine: 'dotnet run'

    // (Optional) Free plan: leave AlwaysOn off
    alwaysOn: false
  }
}
