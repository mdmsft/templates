var resourceGroup = 'dockerio'
var location = 'germanywestcentral'
var vmName = resourceGroup
var niName = resourceGroup
var ipName = resourceGroup
var nsgName = resourceGroup
var vnetName = resourceGroup
var subnetName = resourceGroup
var osDiskName = resourceGroup

param sshKey string {
  secure: true
}
param customData string

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          destinationAddressPrefix: '*'
          protocol: 'Tcp'
        }
      }
    ]
  }
}
resource ip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: ipName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmName
      fqdn: format('{0}.{1}.cloudapp.azure.com', vmName, location)
    }
  }
}
resource vnet 'Microsoft.Network/virtualnetworks@2015-05-01-preview' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}
resource ni 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: niName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: ipName
        properties: {
          primary: true
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: ip.id
          }
        }
      }
    ]
  }
}
resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  location: location
  name: vmName
  properties: {
    osProfile: {
      customData: base64(customData)
      adminUsername: 'azure'
      computerName: vnetName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azure/.ssh/authorized_keys'
              keyData: sshKey
            }
          ]
        }
      }
    }
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ni.id
        }
      ]
    }
    storageProfile: {
      osDisk:{
        name: osDiskName
        osType: 'Linux'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        offer: '0001-com-ubuntu-server-groovy'
        publisher: 'Canonical'
        version: 'latest'
        sku: '20_10-gen2'
      }
    }
  }
}