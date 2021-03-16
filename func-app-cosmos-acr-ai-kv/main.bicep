param oid string = ''
param sid string = ''

var acr = '${resourceGroup().name}${environment().suffixes.acrLoginServer}'

var acrUsernameKey = 'acr-username'
var acrPasswordKey = 'acr-password'
var aiInstrumentationKey = 'ai-instrumentation-key'
var cosmosConnectionStringKey = 'cosmos-connection-string'
var storageConnectionStringKey = 'storage-connection-string'

module storage 'storage.bicep' = {
  name: '${deployment().name}-storage'
}

module cosmos 'cosmos.bicep' = {
  name: '${deployment().name}-sql'
}

module insights 'insights.bicep' = {
  name: '${deployment().name}-insights'
}

module web 'web.bicep' = {
  name: '${deployment().name}-web'
}

module registry 'registry.bicep' = {
  name: '${deployment().name}-registry'
  dependsOn: [
    web
  ]
  params: {
    site: web.outputs.site
  }
}

module vault 'vault.bicep' = {
  name: '${deployment().name}-vault'
  dependsOn: [
    web
    storage
    insights
    registry
  ]
  params: {
    sid: sid
    policies: [
      {
        oid: web.outputs.site.oid
        permissions: [
          'get'
        ]
      }
    ]
    secrets: [
      {
        name: cosmosConnectionStringKey
        value: cosmos.outputs.connectionString
      }
      {
        name: storageConnectionStringKey
        value: storage.outputs.connectionString
      }
      {
        name: aiInstrumentationKey
        value: insights.outputs.instrumentationKey
      }
      {
        name: acrUsernameKey
        value: registry.outputs.username
      }
      {
        name: acrPasswordKey
        value: registry.outputs.password
      }
    ]
  }
}

module config 'config.bicep' = {
  name: '${deployment().name}-config'
  dependsOn: [
    registry
    vault
  ]
  params: {
    acr: acr
    vault: vault.outputs.name
    site: web.outputs.site.name
    image: web.outputs.site.image
    acrUsernameKey: acrUsernameKey
    acrPasswordKey: acrPasswordKey
    aiInstrumentationKey: aiInstrumentationKey
    cosmosConnectionStringKey: cosmosConnectionStringKey
    storageConnectionStringKey: storageConnectionStringKey
  }
}

output acr string = acr
output image string = '${acr}/${web.outputs.site.image}'
output token string = web.outputs.site.verification
output farm string = web.outputs.site.farm
output site string = web.outputs.site.name