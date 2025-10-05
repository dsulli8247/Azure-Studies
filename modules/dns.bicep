@description('Tags to apply to all resources')
param tags object

@description('VNet ID for DNS zone link')
param vnetId string

// Private DNS Zones for Azure AI Services
resource dnsZoneOpenAI 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.openai.azure.com'
  location: 'global'
  tags: tags
}

resource dnsZoneCognitiveServices 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.cognitiveservices.azure.com'
  location: 'global'
  tags: tags
}

resource dnsZoneNotebooks 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.notebooks.azure.net'
  location: 'global'
  tags: tags
}

resource dnsZoneApiAzureML 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.api.azureml.ms'
  location: 'global'
  tags: tags
}

resource dnsZoneBlobStorage 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  tags: tags
}

resource dnsZoneFileStorage 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.file.core.windows.net'
  location: 'global'
  tags: tags
}

resource dnsZoneKeyVault 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags
}

resource dnsZoneContainerRegistry 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  tags: tags
}

// VNet Links for all DNS Zones
resource vnetLinkOpenAI 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneOpenAI
  name: 'vnetlink-openai'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource vnetLinkCognitiveServices 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneCognitiveServices
  name: 'vnetlink-cognitiveservices'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource vnetLinkNotebooks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneNotebooks
  name: 'vnetlink-notebooks'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource vnetLinkApiAzureML 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneApiAzureML
  name: 'vnetlink-api-azureml'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource vnetLinkBlobStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneBlobStorage
  name: 'vnetlink-blob'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource vnetLinkFileStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneFileStorage
  name: 'vnetlink-file'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource vnetLinkKeyVault 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneKeyVault
  name: 'vnetlink-keyvault'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource vnetLinkContainerRegistry 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneContainerRegistry
  name: 'vnetlink-acr'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Output DNS Zone IDs for private endpoint creation
output privateDnsZoneIds object = {
  openai: dnsZoneOpenAI.id
  cognitiveServices: dnsZoneCognitiveServices.id
  notebooks: dnsZoneNotebooks.id
  apiAzureML: dnsZoneApiAzureML.id
  blob: dnsZoneBlobStorage.id
  file: dnsZoneFileStorage.id
  keyVault: dnsZoneKeyVault.id
  containerRegistry: dnsZoneContainerRegistry.id
}
