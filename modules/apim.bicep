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

@description('Publisher email for APIM')
param publisherEmail string

@description('Publisher name for APIM')
param publisherName string

// Azure API Management
resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: 'apim-${envPrefix}'
  location: location
  tags: tags
  sku: {
    name: 'Developer' // Use Developer for testing, Premium for production VNet integration
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

// Outputs
output apimId string = apim.id
output apimName string = apim.name
output apimGatewayUrl string = apim.properties.gatewayUrl
output apimPrincipalId string = apim.identity.principalId
