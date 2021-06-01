var resourceGroupName = resourceGroup().name
var location = 'germanywestcentral'
var storageAccountName = resourceGroupName
var vnetName = resourceGroupName
var subnetName = resourceGroupName
var insightsName = resourceGroupName
var workspaceName = resourceGroupName
var serverFarmName = resourceGroupName
var siteName = resourceGroupName
var networkConfigName = resourceGroupName
var vnetConnectionName = resourceGroupName
var cosmosName = resourceGroupName

resource vnet 'Microsoft.Network/virtualnetworks@2020-06-01' = {
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
          serviceEndpoints: [
            {
              service: 'Microsoft.AzureCosmosDB'
            }
          ]
        }
      }
    ]
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: workspaceName
  location: location
  properties: {
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: insightsName
  location: location
  kind: ''
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

resource serverFarm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: serverFarmName
  location: location
  kind: 'linux'
  sku: {
    tier: 'ElasticPremium'
    name: 'EP1'
  }
  properties: {
    reserved: true
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Premium_LRS'
    tier: 'Premium'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      // virtualNetworkRules: [
      //   {
      //     action: 'Allow'
      //     id: vnet.properties.subnets[0].id
      //   }
      // ]
    }
  }
}

resource site 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'functionapp,linux'
  properties: {
    httpsOnly: true
    serverFarmId: serverFarm.id
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: insights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: insights.properties.ConnectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '0'
        }
        {
          name: 'WEBSITE_TIME_ZONE'
          value: 'Europe/Berlin'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'AzureWebJobsSecretStorageType'
          value: 'Blob'
        }
      ]
      ftpsState: 'Disabled'
      http20Enabled: true
      linuxFxVersion: 'dotnet|3.1'
      minTlsVersion: '1.2'
      preWarmedInstanceCount: 1
      use32BitWorkerProcess: false
      vnetName: vnet.name
      vnetRouteAllEnabled: true
    }
  }
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2020-06-01-preview' = {
  name: cosmosName
  location: location
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    createMode: 'Default'
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
    backupPolicy: {
      type: 'Continuous'
    }
    isVirtualNetworkFilterEnabled: true
    virtualNetworkRules: [
      {
        id: vnet.properties.subnets[0].id
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    publicNetworkAccess: 'Disabled'
  }
}
