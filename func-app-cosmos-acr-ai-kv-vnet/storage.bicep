param network string

resource storage 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: resourceGroup().name
  location: resourceGroup().location
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: network
          action: 'Allow'
        }
      ]
    }
  }
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
}


resource services 'Microsoft.Storage/storageAccounts/fileServices@2020-08-01-preview' = {
  name: '${storage.name}/default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2020-08-01-preview' = {
  name: '${services.name}/${resourceGroup().name}'
  properties: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
    shareQuota: 1024
  }
}

output id string = storage.id
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value}'