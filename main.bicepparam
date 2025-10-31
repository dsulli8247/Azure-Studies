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

param gptModelName1 = 'gpt-4.1'
param gptModelVersion1 = '2025-04-14'
param modelCapacity1 = 10

param gptModelName2 = 'gpt-5'
param gptModelVersion2 = '2025-08-07'
param modelCapacity2 = 10

param publisherEmail = 'dsulli8247@gmail.com' // IMPORTANT: Replace with a valid email address
param publisherName = 'David Sullivan'

param useUniqueApimName = true



