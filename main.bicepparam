using './main.bicep'

param location = 'eastus2'
param envPrefix = 'ai-poc-v2'
param tags = {
  environment: 'poc'
  project: 'ai-foundry'
  managedBy: 'bicep'
}

param vnetAddressPrefix = '10.100.0.0/16'
param privateEndpointSubnetPrefix = '10.100.1.0/24'
param webAppSubnetPrefix = '10.100.2.0/24'
param apimSubnetPrefix = '10.100.3.0/24'

param gptModelName = 'gpt-4o'
param gptModelVersion = '2024-08-06'
param modelCapacity = 10
