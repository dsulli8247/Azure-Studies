@description('Location for all resources')
param location string

@description('Environment prefix for naming')
param envPrefix string

@description('Tags to apply to all resources')
param tags object

@description('VNet address prefix')
param vnetAddressPrefix string

@description('Private endpoint subnet prefix')
param privateEndpointSubnetPrefix string

@description('Web app VNet integration subnet prefix')
param webAppSubnetPrefix string

@description('APIM integration subnet prefix')
param apimSubnetPrefix string

@description('Array of on-premise subnet address prefixes to allow access from')
param OnPremSubnets array



// Network Security Group for Private Endpoints
resource nsgPrivateEndpoints 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-${envPrefix}-pe'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowVNetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
    ]
  }
}

// Network Security Group for Web App Integration
resource nsgWebApp 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-${envPrefix}-webapp'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowVNetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Network Security Group for APIM
resource nsgApim 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-${envPrefix}-apim'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowClientCommunicationToAPIManagement'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['80', '443']
          sourceAddressPrefixes: OnPremSubnets
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowManagementEndpointForAzurePortal'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefixes: OnPremSubnets
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowDependencyOnAzureStorage'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
        }
      }
      {
        name: 'AllowDependencyOnAzureSQL'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'SQL'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'vnet-${envPrefix}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-privateendpoints'
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          networkSecurityGroup: {
            id: nsgPrivateEndpoints.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'snet-webapp'
        properties: {
          addressPrefix: webAppSubnetPrefix
          networkSecurityGroup: {
            id: nsgWebApp.id
          }
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'snet-apim'
        properties: {
          addressPrefix: apimSubnetPrefix
          delegations: [
            { name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          networkSecurityGroup: {
            id: nsgApim.id
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output privateEndpointSubnetId string = vnet.properties.subnets[0].id
output webAppSubnetId string = vnet.properties.subnets[1].id
output apimSubnetId string = vnet.properties.subnets[2].id
