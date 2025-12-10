# Azure AI Foundry Infrastructure

This repository contains Infrastructure as Code (IaC) using Azure Bicep to deploy a secure, enterprise-grade Azure AI Foundry environment with network isolation, private endpoints, and API Management.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Infrastructure Components](#infrastructure-components)
- [Security & Networking](#security--networking)
- [Prerequisites](#prerequisites)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Module Structure](#module-structure)
- [CI/CD Pipeline](#cicd-pipeline)
- [Post-Deployment](#post-deployment)
- [Notes & Considerations](#notes--considerations)

## 🎯 Overview

This project deploys a Proof of Concept (POC) environment for Azure AI services with the following key features:

- **Secure Network Architecture**: Full network isolation using VNets, subnets, and private endpoints
- **Azure AI Services**: Azure Cognitive Services with OpenAI model deployments (GPT models)
- **API Management**: Standardized API gateway for AI service access
- **Private Connectivity**: All services communicate over private endpoints with no public internet exposure
- **Hybrid Connectivity**: Support for on-premises network integration via VPN
- **Infrastructure as Code**: Fully automated deployment using Bicep templates
- **CI/CD Ready**: GitHub Actions workflow for automated deployments

## 🏗️ Architecture

### High-Level Architecture

The infrastructure is organized into modular components:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Azure Subscription                              │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    Resource Group (rg-ai-poc-v2)                  │  │
│  │  ┌─────────────────────────────────────────────────────────────┐ │  │
│  │  │              Virtual Network (10.100.0.0/16)                │ │  │
│  │  │  ┌───────────────────────────────────────────────────────┐  │ │  │
│  │  │  │  Subnet: Private Endpoints (10.100.1.0/24)           │  │ │  │
│  │  │  │  - AI Services PE                                     │  │ │  │
│  │  │  │  - Storage Account PE (Blob, File)                    │  │ │  │
│  │  │  │  - Key Vault PE                                       │  │ │  │
│  │  │  │  - APIM Gateway PE                                    │  │ │  │
│  │  │  └───────────────────────────────────────────────────────┘  │ │  │
│  │  │  ┌───────────────────────────────────────────────────────┐  │ │  │
│  │  │  │  Subnet: Web App Integration (10.100.2.0/24)         │  │ │  │
│  │  │  └───────────────────────────────────────────────────────┘  │ │  │
│  │  │  ┌───────────────────────────────────────────────────────┐  │ │  │
│  │  │  │  Subnet: APIM Integration (10.100.3.0/24)            │  │ │  │
│  │  │  │  - API Management Service                             │  │ │  │
│  │  │  └───────────────────────────────────────────────────────┘  │ │  │
│  │  └─────────────────────────────────────────────────────────────┘ │  │
│  │                                                                   │  │
│  │  ┌────────────────┐  ┌──────────────┐  ┌───────────────────┐    │  │
│  │  │ AI Services    │  │ Key Vault    │  │ Storage Account   │    │  │
│  │  │ - GPT Models   │  │ - RBAC       │  │ - Blob, File      │    │  │
│  │  └────────────────┘  └──────────────┘  └───────────────────┘    │  │
│  │                                                                   │  │
│  │  ┌────────────────────────────────────────────────────────────┐  │  │
│  │  │            Private DNS Zones (9 zones)                     │  │  │
│  │  │  - privatelink.openai.azure.com                            │  │  │
│  │  │  - privatelink.cognitiveservices.azure.com                 │  │  │
│  │  │  - privatelink.blob.core.windows.net                       │  │  │
│  │  │  - privatelink.file.core.windows.net                       │  │  │
│  │  │  - privatelink.vaultcore.azure.net                         │  │  │
│  │  │  - privatelink.azure-api.net (APIM)                        │  │  │
│  │  │  - And more...                                             │  │  │
│  │  └────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  On-Premises Networks (VPN Connected)                           │   │
│  │  - Corporate Subnets: 10.62.0.0/16, 10.65.0.0/16, etc.         │   │
│  │  - VPN Subnets: 172.20.24.0/22, 172.20.28.0/22, 172.20.32.0/22 │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Deployment Modes

The infrastructure supports two deployment modes controlled by boolean parameters:

1. **Core Infrastructure** (`core=true`):
   - Resource Group
   - Virtual Network & Subnets
   - Network Security Groups
   - Private DNS Zones

2. **AI Incubator** (`aiincubator=true`):
   - Azure AI Services (Cognitive Services)
   - GPT Model Deployments
   - Storage Account
   - Key Vault
   - API Management
   - Log Analytics & Application Insights

## 🧱 Infrastructure Components

### Core Infrastructure

#### Resource Group (`modules/rg.bicep`)
- **Name Pattern**: `rg-{envPrefix}`
- **Scope**: Subscription-level deployment
- **Default Location**: East US 2

#### Virtual Network (`modules/network.bicep`)
- **Address Space**: 10.100.0.0/16 (configurable)
- **Subnets**:
  - **Private Endpoints**: 10.100.1.0/24
    - For all private endpoint connections
    - Private endpoint network policies disabled
  - **Web App Integration**: 10.100.2.0/24
    - Delegated to `Microsoft.Web/serverFarms`
    - For future app service integration
  - **APIM Integration**: 10.100.3.0/24
    - Dedicated subnet for API Management
    - Delegated for APIM service

#### Network Security Groups
- **NSG for Private Endpoints**: Allows VNet-to-VNet traffic
- **NSG for Web App**: Allows VNet traffic and Azure Load Balancer
- **NSG for APIM**: 
  - Inbound: Client communication (80, 443), Management endpoint (3443) from on-prem subnets
  - Outbound: Azure Storage (443), Azure SQL (1433)

#### Private DNS Zones (`modules/dns.bicep`)
Nine private DNS zones with VNet links:
- `privatelink.openai.azure.com`
- `privatelink.cognitiveservices.azure.com`
- `privatelink.notebooks.azure.net`
- `privatelink.api.azureml.ms`
- `privatelink.blob.core.windows.net`
- `privatelink.file.core.windows.net`
- `privatelink.vaultcore.azure.net`
- `privatelink.azurecr.io`
- `privatelink.azure-api.net`

### AI Incubator Infrastructure

#### Azure AI Services (`modules/ai-foundry.bicep`)
- **Service Type**: Cognitive Services (AIServices kind)
- **SKU**: S0 (Standard)
- **Features**:
  - Custom subdomain for private access
  - Public network access disabled
  - System-assigned managed identity
  - Private endpoint connectivity

#### GPT Model Deployments
- **Model 1** (Configurable):
  - Default: GPT-4.1 (version 2025-04-14)
  - Capacity: 10 units
  - SKU: GlobalStandard
- **Model 2** (Currently commented out):
  - Can deploy additional models as needed

#### Storage Account
- **Naming Pattern**: `st{envPrefix}{uniqueString}`
- **SKU**: Standard_LRS
- **Kind**: StorageV2
- **Features**:
  - Public access disabled
  - Minimum TLS 1.2
  - Hot access tier
  - Private endpoints for Blob and File services

#### Key Vault
- **Naming Pattern**: `kv-{envPrefix}`
- **SKU**: Standard
- **Features**:
  - RBAC authorization enabled
  - Soft delete disabled (for POC/dev environments)
  - Public network access disabled
  - Private endpoint connectivity

#### Azure API Management
- **Naming Pattern**: `apim-{envPrefix}-{timestamp}`
- **SKU**: StandardV2 (capacity: 1)
- **Network Configuration**:
  - Virtual Network Type: External
  - Subnet Integration: Dedicated APIM subnet
  - Private endpoint for Gateway
- **Identity**: System-assigned managed identity
- **Publisher Information**: Configurable via parameters

#### Monitoring
- **Log Analytics Workspace**: 
  - Retention: 30 days
  - SKU: PerGB2018
- **Application Insights**:
  - Type: Web
  - Connected to Log Analytics workspace

## 🔒 Security & Networking

### Network Isolation Strategy

1. **No Public Internet Access**:
   - All services configured with `publicNetworkAccess: 'Disabled'`
   - Traffic flows through private endpoints only

2. **Private Endpoints**:
   - Dedicated private endpoints for each service
   - DNS resolution through private DNS zones
   - All endpoints deployed to the private endpoint subnet

3. **Hybrid Connectivity**:
   - Pre-configured on-premises subnet allowances
   - VPN subnets: 172.20.24.0/22 (EAST), 172.20.28.0/22 (WEST), 172.20.32.0/22 (PGH)
   - Corporate subnets: 10.62.0.0/16, 10.65.0.0/16, 10.72.0.0/16, 10.75.0.0/16, 10.52.0.0/16, 10.55.0.0/16

### RBAC Assignments

The infrastructure implements least-privilege access using role-based access control:

#### AI Services Identity Permissions:
- **Storage Blob Data Contributor** on Storage Account
- **Key Vault Secrets User** on Key Vault

### Network Security Rules

#### APIM NSG Rules:
- **Inbound**:
  - Port 80, 443: Client communication from on-prem subnets
  - Port 3443: Management endpoint from on-prem subnets
- **Outbound**:
  - Port 443: Azure Storage dependency
  - Port 1433: Azure SQL dependency

## 📦 Prerequisites

### Required Tools
- **Azure CLI** (version 2.50.0 or later)
- **Bicep CLI** (version 0.20.0 or later)
- **Git** (for cloning the repository)
- **GitHub Account** (for CI/CD pipeline)

### Required Permissions
- **Subscription Owner** or **Contributor** role on the target Azure subscription
- Permissions to create service principals (for GitHub Actions)

### Azure Subscription Setup
```bash
# Login to Azure
az login

# Set the subscription
az account set --subscription "<your-subscription-id>"

# Verify the subscription
az account show
```

## 🚀 Deployment

### Option 1: Manual Deployment

1. **Clone the Repository**:
```bash
git clone <repository-url>
cd Azure-Studies
```

2. **Review and Update Parameters**:
Edit `main.bicepparam` to customize:
- Environment prefix
- Model configurations
- Publisher information
- On-premises subnet ranges

3. **Deploy the Infrastructure**:
```bash
# Deploy core infrastructure only
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters core=true aiincubator=false

# Deploy complete infrastructure (core + AI)
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters core=true aiincubator=true
```

4. **Monitor Deployment**:
```bash
# View deployment status
az deployment sub list --output table

# View deployment operations
az deployment sub operation list \
  --name <deployment-name> \
  --query "[].{Operation:properties.targetResource.resourceType, State:properties.provisioningState}"
```

### Option 2: GitHub Actions CI/CD

The repository includes a GitHub Actions workflow for automated deployments.

1. **Create Azure Service Principal**:
```bash
az ad sp create-for-rbac \
  --name "github-actions-azure-studies" \
  --role "Contributor" \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

2. **Configure GitHub Secrets**:
Navigate to your GitHub repository → Settings → Secrets and add:
- `AZURE_CLIENT_ID`: Service Principal Client ID
- `AZURE_TENANT_ID`: Azure AD Tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure Subscription ID

3. **Trigger Deployment**:
- Push changes to the `main` branch
- The workflow automatically deploys the infrastructure
- Monitor progress in the Actions tab

## ⚙️ Configuration

### Key Parameters (`main.bicepparam`)

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| `location` | Azure region for deployment | `eastus2` |
| `envPrefix` | Naming prefix for resources | `ai-poc-v2` |
| `core` | Deploy core infrastructure | `true` |
| `aiincubator` | Deploy AI services | `true` |
| `vnetAddressPrefix` | VNet address space | `10.100.0.0/16` |
| `privateEndpointSubnetPrefix` | Private endpoint subnet | `10.100.1.0/24` |
| `webAppSubnetPrefix` | Web app subnet | `10.100.2.0/24` |
| `apimSubnetPrefix` | APIM subnet | `10.100.3.0/24` |
| `gptModelName1` | First GPT model name | `gpt-4.1` |
| `gptModelVersion1` | First GPT model version | `2025-04-14` |
| `modelCapacity1` | Model capacity (TPM) | `10` |
| `publisherEmail` | APIM publisher email | (configurable) |
| `publisherName` | APIM publisher name | (configurable) |
| `useUniqueApimName` | Avoid soft-delete conflicts | `true` |
| `OnPremSubnets` | On-prem subnet ranges | (array of CIDRs) |

### Deployment Modes

Control what gets deployed using boolean flags:

```bicep
// Deploy only networking and DNS (Phase 1)
param core = true
param aiincubator = false

// Deploy complete solution (Phase 2)
param core = true
param aiincubator = true
```

## 📁 Module Structure

### Module Overview

| Module | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| Resource Group | `modules/rg.bicep` | Creates subscription-scoped resource group | None |
| Network | `modules/network.bicep` | VNet, subnets, NSGs | Resource Group |
| DNS | `modules/dns.bicep` | Private DNS zones and VNet links | Network |
| AI Foundry | `modules/ai-foundry.bicep` | AI services, storage, Key Vault | Network, DNS |
| API Management | `modules/apim.bicep` | APIM with VNet integration | Network, DNS |

### Module Inputs and Outputs

#### Network Module Outputs:
- `vnetId`: Virtual Network resource ID
- `vnetName`: Virtual Network name
- `privateEndpointSubnetId`: Private endpoint subnet ID
- `webAppSubnetId`: Web app subnet ID
- `apimSubnetId`: APIM subnet ID

#### DNS Module Outputs:
- `privateDnsZoneIds`: Object containing all DNS zone IDs

#### AI Foundry Module Outputs:
- `aiProjectId`: AI Services resource ID
- `aiProjectName`: AI Services name
- `modelDeploymentName1`: GPT model deployment name
- `storageAccountId`: Storage account ID
- `keyVaultId`: Key Vault ID

#### APIM Module Outputs:
- `apimId`: APIM resource ID
- `apimName`: APIM name
- `apimGatewayUrl`: APIM gateway URL
- `apimPrincipalId`: APIM managed identity principal ID

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow (`.github/workflows/main.yml`)

The pipeline consists of the following stages:

1. **Checkout**: Retrieves the latest code from the repository
2. **Azure Login**: Authenticates using federated identity (OIDC)
3. **Bicep Lint**: Validates Bicep syntax and best practices
4. **Deploy**: Executes subscription-scoped deployment

### Workflow Trigger
- **Push to main branch**: Automatically deploys infrastructure
- **Workflow dispatch**: Manual trigger (currently disabled)

### Required GitHub Secrets
- `AZURE_CLIENT_ID`: Azure AD application (service principal) client ID
- `AZURE_TENANT_ID`: Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID`: Target Azure subscription ID

### Deployment Scope
The workflow deploys at the **subscription scope** to allow resource group creation and management.

## ✅ Post-Deployment

### Validation Steps

1. **Verify Resource Group**:
```bash
az group show --name rg-ai-poc-v2
```

2. **Check Network Resources**:
```bash
# Verify VNet
az network vnet show --resource-group rg-ai-poc-v2 --name vnet-ai-poc-v2

# List subnets
az network vnet subnet list --resource-group rg-ai-poc-v2 --vnet-name vnet-ai-poc-v2 --output table
```

3. **Validate Private Endpoints**:
```bash
# List private endpoints
az network private-endpoint list --resource-group rg-ai-poc-v2 --output table

# Check DNS records
az network private-dns record-set list --resource-group rg-ai-poc-v2 --zone-name privatelink.openai.azure.com
```

4. **Verify AI Services**:
```bash
# List Cognitive Services accounts
az cognitiveservices account list --resource-group rg-ai-poc-v2 --output table

# Check model deployments
az cognitiveservices account deployment list \
  --name <ai-services-name> \
  --resource-group rg-ai-poc-v2 \
  --output table
```

5. **Test APIM**:
```bash
# Get APIM details
az apim show --name <apim-name> --resource-group rg-ai-poc-v2
```

### Accessing Resources

All resources are accessible only through:
- **Private Endpoints**: From within the VNet or via VPN from on-premises networks
- **Azure Portal**: For management and configuration
- **Azure CLI/API**: With appropriate authentication

### Common Issues & Troubleshooting

#### Issue: Deployment fails due to soft-delete conflicts
**Solution**: 
- APIM and AI workspaces use unique names with timestamps
- Set `useUniqueApimName=true` or `useUniqueWorkspaceName=true`
- Alternatively, purge soft-deleted resources:
```bash
# Purge soft-deleted APIM
az apim deletedservice purge --service-name <apim-name> --location eastus2

# Purge soft-deleted Cognitive Services
az cognitiveservices account purge --name <account-name> --resource-group <rg-name> --location eastus2
```

#### Issue: Private endpoint DNS not resolving
**Solution**:
- Verify private DNS zones are linked to the VNet
- Check DNS zone records for the private endpoint
- Ensure you're querying from within the VNet

#### Issue: Cannot access AI services
**Solution**:
- Verify the private endpoint is in a "Succeeded" state
- Check NSG rules allow traffic
- Confirm RBAC assignments are in place
- Test connectivity from a VM within the VNet

## 📝 Notes & Considerations

### Soft-Delete Handling
- **Key Vault**: Soft delete is **disabled** for POC/development environments
- **APIM**: Uses timestamp-based naming to avoid soft-delete conflicts
- **AI Services**: Unique workspace names generated using UTC timestamp

### Cost Considerations
- **API Management StandardV2**: ~$0.66/hour (~$475/month)
- **Cognitive Services S0**: Pay-as-you-go based on usage
- **Storage Standard_LRS**: Low cost, pay for storage used
- **Log Analytics**: Pay-per-GB ingested
- **VNet & Private Endpoints**: Minimal cost

**Estimated Monthly Cost**: $500-800 (depending on usage)

### Scaling Considerations
- **Model Capacity**: Currently set to 10 TPM (Tokens Per Minute)
  - Adjust `modelCapacity1` parameter for higher throughput
- **APIM SKU**: StandardV2 with capacity 1
  - Scale up to higher capacity or Premium SKU for production
- **Storage**: Standard_LRS is suitable for POC
  - Consider GRS or GZRS for production redundancy

### Security Best Practices
✅ **Implemented**:
- Private endpoints for all services
- Public network access disabled
- RBAC-based access control
- Network security groups with explicit allow rules
- Private DNS resolution

🚧 **Consider for Production**:
- Enable Azure Policy for compliance
- Implement Azure Firewall or NVA for egress filtering
- Enable Azure Monitor alerts and diagnostics
- Implement Azure Key Vault with soft delete and purge protection
- Use Azure Private Link for all external dependencies
- Enable Azure DDoS Protection Standard
- Implement certificate management for APIM

### Model Deployment Notes
- The second GPT model deployment is currently commented out
- To deploy additional models, uncomment the relevant sections in `modules/ai-foundry.bicep`
- Ensure sequential deployment using `dependsOn` to avoid conflicts
- Model availability varies by region - check Azure OpenAI model availability

### Network Integration
- On-premises subnets are pre-configured for VPN access
- Ensure VPN or ExpressRoute is established before testing connectivity
- Update `OnPremSubnets` parameter with your actual network ranges

## 📚 Additional Resources

- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure OpenAI Service Documentation](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/)
- [Azure API Management Documentation](https://learn.microsoft.com/en-us/azure/api-management/)
- [Azure Private Link Documentation](https://learn.microsoft.com/en-us/azure/private-link/)
- [Azure Virtual Network Documentation](https://learn.microsoft.com/en-us/azure/virtual-network/)

## 📄 License

This project is provided as-is for educational and POC purposes.

## 👤 Contact

For questions or issues, please contact:
- **Publisher**: David Sullivan
- **Email**: dsulli8247@gmail.com

---

**Last Updated**: December 2025
**Version**: 1.0
