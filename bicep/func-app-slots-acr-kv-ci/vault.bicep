param name string
param sid string
param sites array
param secrets array

resource vault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: sid
        permissions: {
          certificates: [
            'backup'
            'create'
            'delete'
            'deleteissuers'
            'get'
            'getissuers'
            'import'
            'list'
            'listissuers'
            'managecontacts'
            'manageissuers'
            'purge'
            'recover'
            'restore'
            'setissuers'
            'update'
          ]
          keys: [
            'backup'
            'create'
            'decrypt'
            'delete'
            'encrypt'
            'get'
            'import'
            'list'
            'purge'
            'recover'
            'restore'
            'sign'
            'unwrapKey'
            'update'
            'verify'
            'wrapKey'
          ]
          secrets: [
            'backup'
            'delete'
            'get'
            'list'
            'purge'
            'recover'
            'restore'
            'set'
          ]
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    softDeleteRetentionInDays: 7
  }
}

resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: any('${vault.name}/add')
  properties: {
    accessPolicies: [for site in sites: {
      tenantId: subscription().tenantId
      objectId: site.oid
      permissions: {
        secrets: [
          'get'
        ]
      }
    }]
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = [for secret in secrets: {
  name: '${vault.name}/${secret.name}'
  properties: {
    value: secret.value
  }
}]