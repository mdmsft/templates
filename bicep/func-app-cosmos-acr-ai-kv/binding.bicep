param site string
param host string
param thumbprint string

resource binding 'Microsoft.Web/sites/hostNameBindings@2020-06-01' = {
  name: '${site}/${host}'
  properties: {
    customHostNameDnsRecordType: 'CName'
    azureResourceName: site
    azureResourceType: 'Website'
    hostNameType: 'Managed'
    siteName: site
    sslState: 'SniEnabled'
    thumbprint: thumbprint
  } 
}