resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: resourceGroup().name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: resourceGroup().name
        properties: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.AzureCosmosDB'
            }
            {
              service: 'Microsoft.ContainerRegistry'
            }
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.Web'
            }
          ]
          networkSecurityGroup: {
            id: nsg.id
          }
          delegations: [
            {
              name: resourceGroup().name
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: resourceGroup().name
  location: resourceGroup().location
}

output subnet string = vnet.properties.subnets[0].id
