using './main.bicep'

param location = 'eastus'
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

param gptModelName = 'gpt-4.1'
param gptModelVersion = '2025-04-14'
param modelCapacity = 10

param publisherEmail = 'admin@example.com' // IMPORTANT: Replace with a valid email address
param publisherName = 'AI Foundry Publisher'

param useUniqueApimName = true
