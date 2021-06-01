param farmName string
param siteName string

var slot = 'canary'
var slotName = '${siteName}/${slot}'

resource farm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: farmName
  location: resourceGroup().location
  kind: 'linux'
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource site 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    environment: 'production'
  }
  kind: 'functionapp,linux,container'
  properties: {
    enabled: true
    serverFarmId: farm.id
    httpsOnly: true
    reserved: true
    siteConfig: {
      alwaysOn: true
      ftpsState: 'Disabled'
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

resource canary 'Microsoft.Web/sites/slots@2020-06-01' = {
  name: slotName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    environment: 'canary'
  }
  kind: 'functionapp,linux,container'
  properties: {
    enabled: true
    serverFarmId: farm.id
    httpsOnly: true
    reserved: true
    siteConfig: {
      alwaysOn: true
      ftpsState: 'Disabled'
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

var siteScmUri = list(resourceId('Microsoft.Web/sites/config', siteName, 'publishingcredentials'), site.apiVersion).properties.scmUri
var slotScmUri = list(resourceId('Microsoft.Web/sites/slots/config', siteName, slot, 'publishingcredentials'), site.apiVersion).properties.scmUri

output sites array = [
  {
    name: siteName
    oid: site.identity.principalId
    image: '${siteName}:latest'
    webhhok: '${siteScmUri}/docker/hook'
  }
  {
    name: slot
    oid: canary.identity.principalId
    image: '${siteName}:canary'
    webhhok: '${slotScmUri}/docker/hook'
  }
]