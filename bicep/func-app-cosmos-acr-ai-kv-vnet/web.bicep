param network string

resource farm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: resourceGroup().name
  location: resourceGroup().location
  kind: 'linux'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    size: 'BP1'
    family: 'EP'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource site 'Microsoft.Web/sites@2020-06-01' = {
  name: resourceGroup().name
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'functionapp,linux,container,elastic'
  properties: {
    enabled: true
    serverFarmId: farm.id
    httpsOnly: true
    reserved: true
    siteConfig: {
      ftpsState: 'Disabled'
      healthCheckPath: '/'
      http20Enabled: true
      linuxFxVersion: ''
      minTlsVersion: '1.2'
      numberOfWorkers: 1
      windowsFxVersion: ''
      use32BitWorkerProcess: false
      webSocketsEnabled: false
    }
  }
}

var scmUri = list(resourceId('Microsoft.Web/sites/config', site.name, 'publishingcredentials'), site.apiVersion).properties.scmUri

output site object = {
  name: site.name
  webhook: '${scmUri}/docker/hook'
  oid: site.identity.principalId
  image: '${site.name}:latest'
  verification: site.properties.customDomainVerificationId
  farm: farm.id
}

resource vnet 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  name: '${site.name}/virtualNetwork'
  properties: {
    subnetResourceId: network
    swiftSupported: true
  }
}

output id string = site.id