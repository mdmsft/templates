resource workspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: resourceGroup().name
  location: resourceGroup().location
  properties: {
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Enabled'
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
  name: resourceGroup().name
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    IngestionMode: 'LogAnalytics'
    WorkspaceResourceId: workspace.id
  }
}

output instrumentationKey string = insights.properties.InstrumentationKey
output connectionString string = insights.properties.ConnectionString