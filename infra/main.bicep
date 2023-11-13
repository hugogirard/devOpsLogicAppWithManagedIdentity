targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param resourceGroupName string

@secure()
param publisherEmail string
@secure()
param publisherName string

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${resourceGroupName}'
  location: location
}

module storage 'core/storage/storage.bicep' = {
  name: 'storage${resourceToken}'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    resourceToken: resourceToken
  }
}

module monitoring 'core/monitor/monitoring.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'monitoring'
  params: {
    location: location 
    resourceToken: resourceToken
  }
}

module apim 'core/apim/apim.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'apim'
  params: {
    appInsightsName: monitoring.outputs.appInsightName
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
    resourceToken: resourceToken
  }
}

module logicApp 'core/logicapp/logicapp.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'logicapp'
  params: {
    appInsightName: monitoring.outputs.appInsightName
    fileShareName: 'logic'
    location: location
    storageName: storage.outputs.storageAccountName
    resourceToken: resourceToken    
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
