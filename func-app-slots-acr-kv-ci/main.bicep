param globalPrefix string = uniqueString('contoso')
param storageAccountName string = globalPrefix
param objectId string
param containerRegistryName string = globalPrefix
param serverFarmName string = globalPrefix
param siteName string = globalPrefix
param keyVaultName string = globalPrefix

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'contoso'
  location: deployment().location
}

module storage './storage.bicep' = {
  scope: rg
  name: '${deployment().name}-storage'
  params: {
    name: storageAccountName
  }
}

module web './web.bicep' = {
  scope: rg
  name: '${deployment().name}-web'
  params: {
    farmName: serverFarmName
    siteName: siteName
  }
}

module registry './registry.bicep' = {
  scope: rg
  dependsOn: [
    web
  ]
  name: '${deployment().name}-registry'
  params: {
    name: containerRegistryName
    sites: web.outputs.sites
  }
}

module vault './vault.bicep' = {
  scope: rg
  name: '${deployment().name}-vault'
  dependsOn: [
    web
    registry
    storage
  ]
  params: {
    name: keyVaultName
    sid: objectId
    sites: web.outputs.sites
    secrets: [
      {
        name: '${siteName}-AzureWebJobsStorage'
        value: storage.outputs.connectionString
      }
      {
        name: '${siteName}-DockerRegistryServerPassword'
        value: registry.outputs.password
      }
    ]
  }
}

module config './config.bicep' = {
  scope: rg
  dependsOn: [
    web
    vault
  ]
  name: '${deployment().name}-config'
  params: {
    siteName: siteName
    vaultName: keyVaultName
    registryName: containerRegistryName
  }
}