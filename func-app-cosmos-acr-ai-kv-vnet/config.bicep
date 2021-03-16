param site string
param vault string
param image string
param acr string
param acrUsernameKey string
param acrPasswordKey string
param aiInstrumentationKey string
param storageConnectionStringKey string
param cosmosConnectionStringKey string

resource appSettings 'Microsoft.Web/sites/config@2020-09-01' = {
  name: '${site}/appsettings'
  properties: {
      AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${vault};SecretName=${storageConnectionStringKey})'
      CosmosConnectionString: '@Microsoft.KeyVault(VaultName=${vault};SecretName=${cosmosConnectionStringKey})'
      FUNCTIONS_EXTENSION_VERSION: '~3'
      DOCKER_ENABLE_CI: 'true'
      DOCKER_REGISTRY_SERVER_URL: 'https://${acr}'
      DOCKER_REGISTRY_SERVER_USERNAME: '@Microsoft.KeyVault(VaultName=${vault};SecretName=${acrUsernameKey})'
      DOCKER_REGISTRY_SERVER_PASSWORD: '@Microsoft.KeyVault(VaultName=${vault};SecretName=${acrPasswordKey})'
      APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(VaultName=${vault};SecretName=${aiInstrumentationKey})'
      WEBSITE_VNET_ROUTE_ALL: '1'
      WEBSITE_CONTENTSHARE: site
      WEBSITE_CONTENTOVERVNET: '1'
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${vault};SecretName=${storageConnectionStringKey})'
      WEBSITE_TIME_ZONE: 'Europe/Berlin'
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
  }
}

resource web 'Microsoft.Web/sites/config@2020-09-01' = {
  name: '${site}/web'
  properties: {
    linuxFxVersion: 'DOCKER|${acr}/${image}'
  }
}