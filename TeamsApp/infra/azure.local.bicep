@maxLength(20)
@minLength(4)
@description('Used to generate names for all resources in this file')
param resourceBaseName string

@description('Required when create Azure Bot service')
param botEntraAppClientId string

@maxLength(42)
param botDisplayName string

param botAppDomain string

param modelDeploymentName string
param modelName string
param modelVersion string

param azureContentSafetySku string

module azureBotRegistration './botRegistration/azurebot.bicep' = {
  name: 'Azure-Bot-registration'
  params: {
    resourceBaseName: resourceBaseName
    botEntraAppClientId: botEntraAppClientId
    botAppDomain: botAppDomain
    botDisplayName: botDisplayName
  }
}

// create azure ai service and deployment
module aiServices './aiServices/aiServices.bicep' = {
  name: 'AI-Services'
  params: {
    resourceBaseName: resourceBaseName
    modelDeploymentName: modelDeploymentName
    modelName: modelName
    modelVersion: modelVersion
    azureContentSafetySku: azureContentSafetySku
  }
}

output AZURE_OPENAI_ENDPOINT string = aiServices.outputs.AZURE_OPENAI_ENDPOINT
output AZURE_OPENAI_DEPLOYMENT_NAME string = modelDeploymentName
output AZURE_SEARCH_ENDPOINT string = aiServices.outputs.AZURE_SEARCH_ENDPOINT
output AZURE_CONTENT_SAFETY_ENDPOINT string = aiServices.outputs.AZURE_CONTENT_SAFETY_ENDPOINT

output SECRET_AZURE_SEARCH_KEY string = aiServices.outputs.SECRET_AZURE_SEARCH_KEY
output SECRET_AZURE_OPENAI_API_KEY string = aiServices.outputs.SECRET_AZURE_OPENAI_API_KEY
output SECRET_AZURE_CONTENT_SAFETY_KEY string = aiServices.outputs.SECRET_AZURE_CONTENT_SAFETY_KEY
