param siteName string
param vaultName string
param registryName string

var slot = 'canary'

resource siteSettings 'Microsoft.Web/sites/config@2020-09-01' = {
  name: '${siteName}/appsettings'
  properties: {
      AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${vaultName};SecretName=${siteName}-AzureWebJobsStorage)'
      FUNCTIONS_EXTENSION_VERSION: '~3'
      DOCKER_ENABLE_CI: 'true'
      DOCKER_REGISTRY_SERVER_URL: 'https://${registryName}${environment().suffixes.acrLoginServer}'
      DOCKER_REGISTRY_SERVER_USERNAME: registryName
      DOCKER_REGISTRY_SERVER_PASSWORD: '@Microsoft.KeyVault(VaultName=${vaultName};SecretName=${siteName}-DockerRegistryServerPassword)'
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
  }
}

resource siteConfig 'Microsoft.Web/sites/config@2020-09-01' = {
  name: '${siteName}/web'
  properties: {
    linuxFxVersion: 'DOCKER|${registryName}${environment().suffixes.acrLoginServer}/${siteName}:latest'
  }
}

resource slotSettings 'Microsoft.Web/sites/slots/config@2020-09-01' = {
  name: '${siteName}/${slot}/appsettings'
  properties: {
      AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${vaultName};SecretName=${siteName}-AzureWebJobsStorage)'
      FUNCTIONS_EXTENSION_VERSION: '~3'
      DOCKER_ENABLE_CI: 'true'
      DOCKER_REGISTRY_SERVER_URL: 'https://${registryName}${environment().suffixes.acrLoginServer}'
      DOCKER_REGISTRY_SERVER_USERNAME: registryName
      DOCKER_REGISTRY_SERVER_PASSWORD: '@Microsoft.KeyVault(VaultName=${vaultName};SecretName=${siteName}-DockerRegistryServerPassword)'
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
  }
}

resource slotConfig 'Microsoft.Web/sites/slots/config@2020-09-01' = {
  name: '${siteName}/${slot}/web'
  properties: {
    linuxFxVersion: 'DOCKER|${registryName}${environment().suffixes.acrLoginServer}/${siteName}:canary'
  }
}