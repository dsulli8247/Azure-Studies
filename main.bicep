targetScope = 'subscription'
//this is a change in the "Updates" branch
@description('Location for all resources')
param location string = 'eastus2'

//modify for deployment type core or app
param core bool = true
param aiincubator bool = true

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
param gptModelName1 string = 'gpt-4.1'

@description('GPT model version')
param gptModelVersion1 string = '2025-04-14'

@description('Model deployment capacity')
param modelCapacity1 int = 10

@description('GPT model name to deploy')
param gptModelName2 string = 'gpt-5'

@description('GPT model version')
param gptModelVersion2 string = '2025-08-07'

@description('Model deployment capacity')
param modelCapacity2 int = 10

@description('Publisher email for APIM')
param publisherEmail string

@description('Publisher name for APIM')
param publisherName string

@description('If true, appends a unique string to the APIM name to avoid soft-delete conflicts.')
param useUniqueApimName bool = false

@description('Unique deployment ID to avoid naming conflicts with soft-deleted resources')
param deploymentId string = newGuid() // Changed to newGuid() to ensure unique names for resources prone to soft-delete conflicts

param utc string = utcNow()
//vars

// Resource Group
module rgMain './modules/rg.bicep' = if (core==true){
  name: 'rg-${envPrefix}'
}


// Network Infrastructure
module network 'modules/network.bicep' = if (core==true){
  scope: resourceGroup('rg-${envPrefix}')
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
module dns 'modules/dns.bicep' = if (core==true){
  scope: resourceGroup('rg-${envPrefix}')
  name: 'dns-deployment'
  params: {
    tags: tags
    vnetId: network.outputs.vnetId
  }
}

// Azure AI Foundry Infrastructure
module aiFoundry 'modules/ai-foundry.bicep' = if (aiincubator==true){
  scope: resourceGroup('rg-${envPrefix}')
  name: 'ai-foundry-deployment'
  params: {
    location: location
    envPrefix: envPrefix
    tags: tags
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    gptModelName1: gptModelName1
    gptModelVersion1: gptModelVersion1
    modelCapacity1: modelCapacity1
    gptModelName2: gptModelName2
    gptModelVersion2: gptModelVersion2
    modelCapacity2: modelCapacity2
    privateDnsZoneIds: dns.outputs.privateDnsZoneIds
    deploymentId: deploymentId
    useUniqueWorkspaceName: true // Set to true to avoid soft-delete issues during development
  }
}

// Azure API Management
module apim 'modules/apim.bicep' = if (aiincubator==true){
  scope: resourceGroup('rg-${envPrefix}')
  name: 'apim-deployment'
  params: {
    location: location
    envPrefix: envPrefix
    tags: tags
    vnetId: network.outputs.vnetId
    apimSubnetId: network.outputs.apimSubnetId
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    privateDnsZoneIds: dns.outputs.privateDnsZoneIds
    deploymentId: deploymentId
    useUniqueName: useUniqueApimName
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}



// Outputs
output resourceGroupName string = rgMain.name
output vnetId string = network.outputs.vnetId
output aiProjectId string = aiFoundry.outputs.aiProjectId
output modelDeploymentName1 string = aiFoundry.outputs.modelDeploymentName1
output modelDeploymentName2 string = aiFoundry.outputs.modelDeploymentName2
output apimId string = apim.outputs.apimId
output apimName string = apim.outputs.apimName
output apimGatewayUrl string = apim.outputs.apimGatewayUrl
