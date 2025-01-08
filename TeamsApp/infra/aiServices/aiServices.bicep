@maxLength(20)
@minLength(4)
@description('Used to generate names for all resources in this file')
param resourceBaseName string

param location string = resourceGroup().location
param modelName string
param modelVersion string
param modelDeploymentName string

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
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

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
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

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: resourceBaseName
  location: location
  sku: {
    name: 'basic'
  }
  properties: {
    hostingMode: 'default'
    partitionCount: 1
    replicaCount: 1
    publicNetworkAccess: 'enabled'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: resourceBaseName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: resourceBaseName
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
  }
}

resource contentSafetyAccount 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: resourceBaseName
  location: location
  kind: 'ContentSafety'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: resourceBaseName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'F0'
  }
}

resource raiPolicy 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-06-01-preview' = {
  parent: contentSafetyAccount
  name: 'ContentSafety.Default'
  properties: {
    mode: 'Blocking'
    contentFilters: []
  }
}

output AZURE_OPENAI_ENDPOINT string = account.properties.endpoint
output AZURE_SEARCH_ENDPOINT string = 'https://${searchService.name}.search.windows.net'
output AZURE_CONTENT_SAFETY_ENDPOINT string = contentSafetyAccount.properties.endpoint

output SECRET_AZURE_OPENAI_API_KEY string = listKeys(account.id, '2022-12-01').key1
output SECRET_AZURE_SEARCH_KEY string = listKeys(searchService.id, '2024-06-01-preview').primaryKey
output SECRET_AZURE_CONTENT_SAFETY_KEY string = listKeys(contentSafetyAccount.id, '2024-06-01-preview').key1
