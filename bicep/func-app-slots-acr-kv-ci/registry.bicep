param name string
param sites array

resource registry 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: name
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    networkRuleBypassOptions: 'AzureServices'
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
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

resource auth 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for site in sites: {
  name: guid(site.name)
  dependsOn: [
    registry
  ]
  properties: {
    principalId: site.oid
    principalType: 'ServicePrincipal'
    roleDefinitionId: '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
  }
}]

resource webhooks 'Microsoft.ContainerRegistry/registries/webhooks@2020-11-01-preview' = [for site in sites: {
  location: resourceGroup().location
  name: '${registry.name}/${site.name}'
  properties: {
    actions: [
      'push'
    ]
    scope: '${site.image}'
    serviceUri: site.webhook
    status: 'enabled'
  }
}]

output username string = listCredentials(registry.id, registry.apiVersion).username
output password string = listCredentials(registry.id, registry.apiVersion).passwords[0].value