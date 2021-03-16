param name string
param zone string
param token string
param site string

resource cname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: '${zone}/${name}'
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: '${site}.azurewebsites.net'
    }
  }
}

resource txtR 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  name: '${zone}/asuid.${name}'
  properties: {
    TTL: 3600
    TXTRecords: [
      {
        value: [
          token
        ]
      }
    ]
  }
}