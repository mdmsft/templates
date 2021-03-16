targetScope = 'subscription'

param sid string
param oid string = ''

var name = deployment().name
var domain = 'mdmsft.net'
var hostname = '${name}.${domain}'
var dnsResourceGroupName = 'mdmsft'
var pfxResourceGroupName = 'mdmsft'
var resourceGroupName = 'az${uniqueString(subscription().id, name)}'

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupName
  location: deployment().location
  tags: {
    name: name
  }
}

module main 'main.bicep' = {
  scope: rg
  name: '${deployment().name}-main'
  params: {
    oid: oid
    sid: sid
  }
}

module dns 'dns.bicep' = {
  name: '${deployment().name}-dns'
  dependsOn: [
    main
  ]
  scope: resourceGroup(dnsResourceGroupName)
  params: {
    name: name
    zone: domain
    site: main.outputs.site
    token: main.outputs.token
  }
}

resource certificateOrder 'Microsoft.CertificateRegistration/certificateOrders@2020-06-01' existing = {
  scope: resourceGroup(pfxResourceGroupName)
  name: 'mdmsft'
}

var certificate = certificateOrder.properties.certificates.mdmsft

module tls 'tls.bicep' = {
  name: '${deployment().name}-tls'
  scope: rg
  params: {
    name: certificateOrder.properties.distinguishedName
    farm: main.outputs.farm
    vault: certificate.keyVaultId
    secret: certificate.keyVaultSecretName
  }
}

module binding 'binding.bicep' = {
  name: '${deployment().name}-binding'
  dependsOn: [
    tls
  ]
  scope: rg
  params: {
    site: main.outputs.site
    host: hostname
    thumbprint: certificateOrder.properties.signedCertificate.thumbprint
  }
}