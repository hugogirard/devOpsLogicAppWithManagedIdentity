
param location string
param resourceToken string
param appInsightsName string
@secure()
param publisherEmail string
@secure()
param publisherName string

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: 'apim-${resourceToken}'
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}


resource logger 'Microsoft.ApiManagement/service/loggers@2019-01-01' = {
  parent: apim
  name: appInsightsName
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsights.id
    credentials: {
      instrumentationKey: appInsights.properties.InstrumentationKey
    }
  }
}

resource diagnostics 'Microsoft.ApiManagement/service/diagnostics@2019-01-01' = {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: logger.id
    alwaysLog: 'allErrors'
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
  }
}
