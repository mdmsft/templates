param name string
param farm string
param vault string
param secret string

resource certificate 'Microsoft.Web/certificates@2020-06-01' = {
  name: name
  location: resourceGroup().location
  properties: {
    serverFarmId: farm
    keyVaultId: vault
    keyVaultSecretName: secret
  }
}