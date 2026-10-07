# -----------------------------------------------------------------------------
# Cloud-Native Blueprint — Azure landing zone
#
# Provisions:
#   1. Resource Group
#   2. Log Analytics workspace (AKS monitoring destination)
#   3. Azure Container Registry (private image store for the sample app)
#   4. AKS cluster (SystemAssigned identity, Azure CNI Overlay networking)
#   5. AcrPull role assignment so AKS kubelets can pull from ACR
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# 1. Resource group ------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = var.tags
}

# 2. Log Analytics workspace ---------------------------------------------------
# AKS ships container logs/metrics here via the OMS agent add-on.
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# 3. Azure Container Registry --------------------------------------------------
resource "azurerm_container_registry" "main" {
  name                = replace("acr${var.project}${var.environment}", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false # prefer managed identity / service principal auth
  tags                = var.tags
}

# 4. AKS cluster ----------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dns_prefix          = "aks-${local.name_prefix}"
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  # Single system node pool is enough for a dev blueprint; add user pools
  # for prod workloads.
  default_node_pool {
    name            = "system"
    node_count      = var.node_count
    vm_size         = var.node_vm_size
    os_disk_size_gb = 64
    type            = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Keep the API server private in prod:
  # api_server_access_profile { authorized_ip_ranges = ["<your-ip>/32"] }
}

# 5. Let AKS pull images from ACR ------------------------------------------------
# Without this, pods fail with ImagePullBackOff.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id

  # Avoids a perpetual diff when Azure normalizes the principal id casing.
  skip_service_principal_aad_check = true
}
