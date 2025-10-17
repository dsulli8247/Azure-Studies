targetScope = 'subscription'
//this is a change in the "Updates" branch
@description('Location for all resources')
param location string = 'eastus2'

@description('Environment prefix for naming')
param envPrefix string = 'ai-poc-v2'

@description('Tags to apply to all resources')
param tags object = {
  environment: 'poc'
  project: 'ai-foundry'
  managedBy: 'bicep'
}

@description('VNet address prefix')
param vnetAddressPrefix string = '10.100.0.0/16'

@description('Private endpoint subnet prefix')
param privateEndpointSubnetPrefix string = '10.100.1.0/24'

@description('Web app VNet integration subnet prefix')
param webAppSubnetPrefix string = '10.100.2.0/24'

@description('APIM integration subnet prefix')
param apimSubnetPrefix string = '10.100.3.0/24'

@description('GPT model name to deploy')
param gptModelName string = 'gpt-4.1'

@description('GPT model version')
param gptModelVersion string = '2025-04-14'

@description('Model deployment capacity')
param modelCapacity int = 10

@description('Publisher email for APIM')
param publisherEmail string

@description('Publisher name for APIM')
param publisherName string

@description('Unique deployment ID to avoid naming conflicts with soft-deleted resources')
param deploymentId string = newGuid() // Changed to newGuid() to ensure unique names for resources prone to soft-delete conflicts

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${envPrefix}'
  location: location
  tags: tags
}

// Network Infrastructure
module network 'modules/network.bicep' = {
  scope: rg
  name: 'network-deployment'
  params: {
    location: location
    envPrefix: envPrefix
    tags: tags
    vnetAddressPrefix: vnetAddressPrefix
    privateEndpointSubnetPrefix: privateEndpointSubnetPrefix
    webAppSubnetPrefix: webAppSubnetPrefix
    apimSubnetPrefix: apimSubnetPrefix
  }
}

// Private DNS Zones
module dns 'modules/dns.bicep' = {
  scope: rg
  name: 'dns-deployment'
  params: {
    tags: tags
    vnetId: network.outputs.vnetId
  }
}

// Azure AI Foundry Infrastructure
module aiFoundry 'modules/ai-foundry.bicep' = {
  scope: rg
  name: 'ai-foundry-deployment'
  params: {
    location: location
    envPrefix: envPrefix
    tags: tags
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    gptModelName: gptModelName
    gptModelVersion: gptModelVersion
    modelCapacity: modelCapacity
    privateDnsZoneIds: dns.outputs.privateDnsZoneIds
    deploymentId: deploymentId
    useUniqueWorkspaceName: true // Set to true to avoid soft-delete issues during development
  }
}

// Azure API Management
module apim 'modules/apim.bicep' = {
  scope: rg
  name: 'apim-deployment'
  params: {
    location: location
    envPrefix: envPrefix
    tags: tags
    vnetId: network.outputs.vnetId
    apimSubnetId: network.outputs.apimSubnetId
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

// RBAC Assignments for APIM to access Key Vault
resource apimKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(apim.outputs.apimId, aiFoundry.outputs.keyVaultId, 'KeyVaultSecretsUser')
  scope: resource(aiFoundry.outputs.keyVaultId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-08a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: apim.outputs.apimPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC Assignments for APIM to access aiProject (Cognitive Services)
resource apimAiProjectRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(apim.outputs.apimId, aiFoundry.outputs.aiProjectId, 'CognitiveServicesUser')
  scope: resource(aiFoundry.outputs.aiProjectId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a00ae02ab2e1447d9f891636572bb4e4') // Cognitive Services User
    principalId: apim.outputs.apimPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC Assignments for APIM to access openAI (Cognitive Services OpenAI)
resource apimOpenAIRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(apim.outputs.apimId, aiFoundry.outputs.openAIId, 'CognitiveServicesOpenAIUser')
  scope: resource(aiFoundry.outputs.openAIId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
    principalId: apim.outputs.apimPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output resourceGroupName string = rg.name
output vnetId string = network.outputs.vnetId
output aiProjectId string = aiFoundry.outputs.aiProjectId
output modelDeploymentName string = aiFoundry.outputs.modelDeploymentName
output apimId string = apim.outputs.apimId
output apimName string = apim.outputs.apimName
output apimGatewayUrl string = apim.outputs.apimGatewayUrl
