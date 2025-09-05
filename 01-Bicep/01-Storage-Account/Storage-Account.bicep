resource storageaccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'storageanas1651545165'
  location: 'westeurope'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
  }
}
