param site object
param network string

resource registry 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: resourceGroup().name
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
    networkRuleBypassOptions: 'AzureServices'
    dataEndpointEnabled: false
    publicNetworkAccess: 'Disabled'
    zoneRedundancy: 'Disabled'
    networkRuleSet: {
      defaultAction:'Deny'
      virtualNetworkRules: [
        {
          id: network
          action: 'Allow'
        }
      ]
      ipRules: [
        {
          value: '95.91.239.197'
          action: 'Allow'
        }
      ]
    }
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      retentionPolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        status: 'disabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
  }
}

resource rbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(registry.name, site.name)
  properties: {
    principalId: site.oid
    principalType: 'ServicePrincipal'
    roleDefinitionId: '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
  }
}

resource webhooks 'Microsoft.ContainerRegistry/registries/webhooks@2020-11-01-preview' = {
  location: resourceGroup().location
  name: '${registry.name}/${site.name}'
  properties: {
    actions: [
      'push'
    ]
    scope: site.image
    serviceUri: site.webhook
    status: 'enabled'
  }
}

output username string = listCredentials(registry.id, registry.apiVersion).username
output password string = listCredentials(registry.id, registry.apiVersion).passwords[0].value
output id string = registry.id