@description('Location for all resources')
param location string

@description('Environment prefix for naming')
param envPrefix string

@description('Tags to apply to all resources')
param tags object

@description('Private endpoint subnet ID')
param privateEndpointSubnetId string

@description('GPT model name to deploy')
param gptModelName string

@description('GPT model version')
param gptModelVersion string

@description('Model deployment capacity')
param modelCapacity int

@description('Private DNS Zone IDs')
param privateDnsZoneIds object

@description('Unique deployment ID to avoid naming conflicts')
param deploymentId string

// Application Insights & Log Analytics
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${envPrefix}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${envPrefix}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${uniqueString(resourceGroup().id, envPrefix, deploymentId)}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

// Storage Account
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: toLower('st${replace(envPrefix, '-', '')}${uniqueString(resourceGroup().id, deploymentId)}')
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

// Azure OpenAI Service (Cognitive Services)
resource openAI 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: toLower('aoai-${envPrefix}-${take(deploymentId, 8)}')
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: toLower('aoai-${envPrefix}-${uniqueString(resourceGroup().id, deploymentId)}')
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

// AI Project (associated with Hub)
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: 'aip-${envPrefix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'Project'
  properties: {
    friendlyName: 'AI Project ${envPrefix}'
    description: 'Azure AI Foundry Project for ${envPrefix}'
    storageAccount: storage.id // Project needs its own storage
    keyVault: keyVault.id // Project needs its own key vault
    applicationInsights: appInsights.id // Project needs its own application insights
    publicNetworkAccess: 'Disabled'
    managedNetwork: { // Project needs managed network settings
      isolationMode: 'AllowInternetOutbound'
    }
  }
  dependsOn: [
    peOpenAI // Ensure OpenAI PE is created before the project
    modelDeployment // Ensure the model is deployed before the project
  ]
}

// GPT Model Deployment
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAI
  name: 'gpt-41-deployment'
  sku: {
    name: 'GlobalStandard'
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gptModelName
      version: gptModelVersion
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

// Private Endpoints
resource peKeyVault 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-${keyVault.name}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${keyVault.name}'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: ['vault']
        }
      }
    ]
  }
}

resource peKeyVaultDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: peKeyVault
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.keyVault
        }
      }
    ]
  }
}

resource peStorageBlob 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-${storage.name}-blob'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${storage.name}-blob'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

resource peStorageBlobDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: peStorageBlob
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.blob
        }
      }
    ]
  }
}

resource peStorageFile 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-${storage.name}-file'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${storage.name}-file'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: ['file']
        }
      }
    ]
  }
}

resource peStorageFileDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: peStorageFile
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.file
        }
      }
    ]
  }
}

resource peOpenAI 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-${openAI.name}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${openAI.name}'
        properties: {
          privateLinkServiceId: openAI.id
          groupIds: ['account']
        }
      }
    ]
  }
}

resource peOpenAIDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: peOpenAI
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-openai-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.openai
        }
      }
      {
        name: 'privatelink-cognitiveservices-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZoneIds.cognitiveServices
        }
      }
    ]
  }
}

// RBAC Assignments for Hub
// Removed AI Hub specific RBAC assignments

// RBAC Assignments for Project
resource aiProjectStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiProject.id, storage.id, 'StorageBlobDataContributor')
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource aiProjectKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiProject.id, keyVault.id, 'KeyVaultSecretsUser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource aiProjectOpenAIRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiProject.id, openAI.id, 'CognitiveServicesOpenAIUser')
  scope: openAI
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output aiProjectId string = aiProject.id
output aiProjectName string = aiProject.name
output openAIId string = openAI.id
output openAIName string = openAI.name
output openAIEndpoint string = openAI.properties.endpoint
output modelDeploymentName string = modelDeployment.name
output storageAccountId string = storage.id
output keyVaultId string = keyVault.id
