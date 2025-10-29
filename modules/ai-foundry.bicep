@description('Location for all resources')
param location string

@description('Environment prefix for naming')
param envPrefix string

@description('Tags to apply to all resources')
param tags object

@description('Private endpoint subnet ID')
param privateEndpointSubnetId string

@description('GPT model name to deploy')
param gptModelName1 string

@description('GPT model version')
param gptModelVersion1 string

@description('Model deployment capacity')
param modelCapacity1 int

@description('GPT model name to deploy')
param gptModelName2 string

@description('GPT model version')
param gptModelVersion2 string

@description('Model deployment capacity')
param modelCapacity2 int

@description('Private DNS Zone IDs')
param privateDnsZoneIds object

@description('Unique deployment ID to avoid naming conflicts')
param deploymentId string

@description('If true, appends a unique string to the AI workspace name to avoid soft-delete conflicts.')
param useUniqueWorkspaceName bool = false

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
  name: 'kv-${envPrefix}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: false
    //softDeleteRetentionInDays: 7
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
// resource openAI 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
//   name: toLower('aoai-${envPrefix}-${take(deploymentId, 8)}')
//   location: location
//   tags: tags
//   kind: 'OpenAI'
//   sku: {
//     name: 'S0'
//   }
//   properties: {
//     customSubDomainName: toLower('aoai-${envPrefix}-${uniqueString(resourceGroup().id, deploymentId)}')
//     publicNetworkAccess: 'Disabled'
//     networkAcls: {
//       defaultAction: 'Deny'
//     }
//   }
// }

// AI Project (associated with Hub)
resource aiProject 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: 'aip-${envPrefix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'AIServices' // Changed to a general Cognitive Services resource
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: toLower('aip-${envPrefix}-${uniqueString(resourceGroup().id, deploymentId)}')
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

//GPT Model Deployment
resource modelDeployment1 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiProject
  name: '${gptModelName1}-deployment'
  sku: {
    name: 'GlobalStandard'
    capacity: modelCapacity1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gptModelName1
      version: gptModelVersion1
    }
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [
    peaiProject // Explicitly wait for the Private Endpoint to be created before deploying the model.
  ]
}

resource modelDeployment2 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiProject
  name: '${gptModelName2}-deployment'
  sku: {
    name: 'GlobalStandard'
    capacity: modelCapacity2
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gptModelName2
      version: gptModelVersion2
    }
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [
    modelDeployment1 // Explicitly wait for the Private Endpoint to be created before deploying the model.
  ]
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

resource peaiProject 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-${aiProject.name}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${aiProject.name}'
        properties: {
          privateLinkServiceId: aiProject.id
          groupIds: ['account']
        }
      }
    ]
  }
}

resource peOpenAIDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: peaiProject
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

//RBAC Assignments for Project
resource aiProjectStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiProject.id, 'StorageBlobDataContributor')
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource aiProjectKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiProject.id, 'KeyVaultSecretsUser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// resource aiProjectOpenAIRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(aiProject.id, 'CognitiveServicesOpenAIUser')
//   scope: openAI
//   properties: {
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
//     principalId: aiProject.identity.principalId
//     principalType: 'ServicePrincipal'
//   }
// }

// Outputs
output aiProjectId string = aiProject.id
output aiProjectName string = aiProject.name
// output openAIId string = openAI.id
// output openAIName string = openAI.name
// output openAIEndpoint string = openAI.properties.endpoint
output modelDeploymentName1 string = modelDeployment1.name
output modelDeploymentName2 string = modelDeployment2.name
output storageAccountId string = storage.id
output keyVaultId string = keyVault.id
