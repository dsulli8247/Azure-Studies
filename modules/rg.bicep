targetScope='subscription'

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

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${envPrefix}'
  location: location
  tags: tags
}
