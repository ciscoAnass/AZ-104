param location string = resourceGroup().location

param storageAccountName string = 'sleepybarden2025'

@description('Blob container name')
param containerName string = 'app'

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false         // secure by default
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: '${sa.name}/default'
  properties: {}
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${sa.name}/default/${containerName}'
  properties: {
    publicAccess: 'None'                 // 'None' | 'Blob' | 'Container'
  }
}

output storageAccountId string = sa.id
output containerUrl string = 'https://${storageAccountName}.blob.core.windows.net/${containerName}'
