output "resource_group_name" {
  description = "Name of the resource group holding all blueprint resources."
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name (use with `az aks get-credentials`)."
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "Full resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.id
}

output "acr_login_server" {
  description = "ACR login server, e.g. acrblueprintdev.azurecr.io — used as the image registry prefix."
  value       = azurerm_container_registry.main.login_server
}

output "acr_name" {
  description = "ACR registry name (short)."
  value       = azurerm_container_registry.main.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID wired to AKS monitoring."
  value       = azurerm_log_analytics_workspace.main.id
}

output "kube_config" {
  description = "Raw kubeconfig for the cluster. Marked sensitive — never log it."
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}
