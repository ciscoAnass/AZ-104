// containerapp-nginx.bicep — ACA Consumption, nginx:latest, anonymous pull, public HTTP

param location string = resourceGroup().location

@description('Managed environment name')
param environmentName string = 'ca-env-${uniqueString(resourceGroup().id)}'

@description('Container App name')
param containerAppName string = 'ca-nginx-${uniqueString(resourceGroup().id)}'

@description('Container image (Docker Hub public)')
param containerImage string = 'nginx:latest'

@description('CPU as string for old compilers; coerced to number with json()')
param cpu string = '0.25'       // 0.25 vCPU

@description('Memory in Gi (string per ACA schema)')
param memory string = '0.5Gi'   // 0.5 GiB

@description('Ingress target port')
param targetPort int = 80

@description('Scaling bounds')
param minReplicas int = 1
param maxReplicas int = 1

// Managed Environment (Consumption by default; omit sku for older type definitions)
resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {}
}

// Container App
resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'nginx-server'
          image: containerImage
          resources: {
            cpu: json(cpu)       // "0.25" -> 0.25
            memory: memory       // "0.5Gi"
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

// The FQDN is exposed on the resource after deployment; no need for reference()
output containerAppFqdn string = app.properties.configuration.ingress.fqdn
output httpUrl string = 'http://${app.properties.configuration.ingress.fqdn}'
