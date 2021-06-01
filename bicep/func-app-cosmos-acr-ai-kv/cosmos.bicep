resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2020-06-01-preview' = {
  kind: 'GlobalDocumentDB'
  location: resourceGroup().location
  name: resourceGroup().name
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    createMode: 'Default'
    locations: [
      {
        locationName: resourceGroup().location
      }
    ]
    databaseAccountOfferType: 'Standard'
  }
}

output connectionString string = listConnectionStrings(databaseAccount.id, databaseAccount.apiVersion).connectionStrings[0].connectionString