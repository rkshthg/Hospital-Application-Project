# 1. Define the Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.57.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "d008c7cc-9795-4292-bf79-74ae52cda63d"
}

# 2. Resource Group
data "azurerm_resource_group" "rg" {
  name = "LabsKraft360"
}

# 3. Create a Virtual Network and Subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "rkshth-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus2"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "rkshth-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 3. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "acrhospitalprod01"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Standard" 
  admin_enabled       = false
}

# 4. AKS Cluster & Node Pools
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-hospital-prod-01"
  location            = "east us2"
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "hospital-aks"

default_node_pool {
    name                = "agentpool"
    vm_size             = "Standard_D2s_v3"
    zones               = ["1", "2"]
    auto_scaling_enabled = true
    min_count           = 2
    max_count           = 5
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.100.0.0/16" 
    dns_service_ip    = "10.100.0.10"
  }

  # Enables monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  }
}

# 5. Role Assignment (AKS -> ACR)
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Supporting Resource: Log Analytics
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "law-hospital-prod-01"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Outputs
output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}