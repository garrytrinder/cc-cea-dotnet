@maxLength(20)
@minLength(4)
@description('Used to generate names for all resources in this file')
param resourceBaseName string

param location string = resourceGroup().location
param modelName string
param modelVersion string
param modelDeploymentName string

param azureContentSafetySku string

resource account 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: resourceBaseName
  location: location
  kind: 'OpenAI'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: resourceBaseName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    disableLocalAuth: false
  }
  sku: {
    name: 'S0'
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: account
  name: modelDeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
  sku: {
    name: 'Standard'
    capacity: 10
  }
}

resource search 'Microsoft.Search/searchServices@2020-08-01' = {
  name: resourceBaseName
  location: location
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: toLower(replace(resourceBaseName, '-', ''))
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'OPTIONS']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 200
        }
      ]
    }
  }
}

resource contentSafetyAccount 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: '${resourceBaseName}-cs'
  location: location
  kind: 'ContentSafety'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: azureContentSafetySku
  }
}

output AZURE_OPENAI_ENDPOINT string = account.properties.endpoint
output AZURE_SEARCH_ENDPOINT string = 'https://${search.name}.search.windows.net'
output AZURE_CONTENT_SAFETY_ENDPOINT string = contentSafetyAccount.properties.endpoint

output SECRET_AZURE_OPENAI_API_KEY string = account.listKeys().key1
output SECRET_AZURE_SEARCH_KEY string = search.listAdminKeys().primaryKey
output SECRET_AZURE_CONTENT_SAFETY_KEY string = contentSafetyAccount.listKeys().key1
