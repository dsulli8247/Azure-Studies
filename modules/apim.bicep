@description('Location for all resources')
param location string

@description('Environment prefix for naming')
param envPrefix string

@description('Tags to apply to all resources')
param tags object

@description('Virtual Network ID for APIM integration')
param vnetId string

@description('Subnet ID for APIM integration')
param apimSubnetId string

@description('Subnet ID for the private endpoint')
param privateEndpointSubnetId string

@description('Private DNS Zone IDs for private endpoint integration')
param privateDnsZoneIds object

@description('Unique deployment ID to avoid naming conflicts')
param deploymentId string

@description('If true, appends a unique string to the APIM name to avoid soft-delete conflicts.')
param useUniqueName bool = false

@description('Publisher email for APIM')
param publisherEmail string

@description('Publisher name for APIM')
param publisherName string

// Azure API Management
resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: useUniqueName ? 'apim-${envPrefix}-${take(deploymentId, 5)}' : 'apim-${envPrefix}'
  location: location
  tags: tags
  sku: {
    name: 'Developer' // Switched back to Developer SKU to support VNet integration for network isolation.
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'Internal' // Internal VNet mode for network isolation
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnetId
    }
  }
}

// // RBAC Assignments for APIM to access Key Vault
// resource apimKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(apim.outputs.apimId, aiFoundry.outputs.keyVaultId, 'KeyVaultSecretsUser')
//   scope: resource(aiFoundry.outputs.keyVaultId)
//   properties: {
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-08a-b874-0445c86b69e6') // Key Vault Secrets User
//     principalId: apim.outputs.apimPrincipalId
//     principalType: 'ServicePrincipal'
//   }
// }

// // RBAC Assignments for APIM to access aiProject (Cognitive Services)
// resource apimAiProjectRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(apim.outputs.apimId, aiFoundry.outputs.aiProjectId, 'CognitiveServicesUser')
//   scope: resource(aiFoundry.outputs.aiProjectId)
//   properties: {
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a00ae02ab2e1447d9f891636572bb4e4') // Cognitive Services User
//     principalId: apim.outputs.apimPrincipalId
//     principalType: 'ServicePrincipal'
//   }
// }
// Private Endpoint for APIM Gateway
resource peApimGateway 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-${apim.name}-gateway'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${apim.name}-gateway'
        properties: {
          privateLinkServiceId: apim.id
          groupIds: ['Gateway'] // The specific group ID for the APIM Gateway
        }
      }
    ]
  }
}

// // RBAC Assignments for APIM to access openAI (Cognitive Services OpenAI)
// resource apimOpenAIRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(apim.outputs.apimId, aiFoundry.outputs.openAIId, 'CognitiveServicesOpenAIUser')
//   scope: resource(aiFoundry.outputs.openAIId)
//   properties: {
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
//     principalId: apim.outputs.apimPrincipalId
//     principalType: 'ServicePrincipal'
//   }
// }

// Outputs
output apimId string = apim.id
output apimName string = apim.name
output apimGatewayUrl string = apim.properties.gatewayUrl
output apimPrincipalId string = apim.identity.principalId
