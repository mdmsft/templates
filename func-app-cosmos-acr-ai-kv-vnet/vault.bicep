param sid string
param secrets array
param policies array
param network string

var initialAccessPolicies = empty(sid) ? [] : [
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

resource vault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: resourceGroup().name
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: initialAccessPolicies
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    softDeleteRetentionInDays: 7
  }
}

resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: any('${vault.name}/add')
  properties: {
    accessPolicies: [for policy in policies: {
      tenantId: subscription().tenantId
      objectId: policy.oid
      permissions: {
        secrets: policy.permissions
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

output id string = vault.id
output name string = vault.name