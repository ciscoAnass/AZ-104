param location string = resourceGroup().location
param name string = 'storage${uniqueString(resourceGroup().id)}'
param environmentType string = 'dev'

var storageAccountSkuName = environmentType == 'prod' ? 'Standard_GRS' : 'Standard_LRS'

resource storageaccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountSkuName
  }
  properties: {
    accessTier: 'Hot'
  }
}
