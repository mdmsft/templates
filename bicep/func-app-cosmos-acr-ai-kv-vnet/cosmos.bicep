param network string

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2020-06-01-preview' = {
  kind: 'GlobalDocumentDB'
  location: resourceGroup().location
  name: resourceGroup().name
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    isVirtualNetworkFilterEnabled: true
    virtualNetworkRules: [
      {
        id: network
      }
    ]
    createMode: 'Default'
    locations: [
      {
        locationName: resourceGroup().location
      }
    ]
    databaseAccountOfferType: 'Standard'
  }
}

output id string = databaseAccount.id
output connectionString string = listConnectionStrings(databaseAccount.id, databaseAccount.apiVersion).connectionStrings[0].connectionString