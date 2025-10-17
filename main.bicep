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

// Outputs
output resourceGroupName string = rg.name
output vnetId string = network.outputs.vnetId
output aiProjectId string = aiFoundry.outputs.aiProjectId
output modelDeploymentName string = aiFoundry.outputs.modelDeploymentName
