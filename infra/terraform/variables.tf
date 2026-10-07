variable "project" {
  description = "Short project slug used in resource names."
  type        = string
  default     = "blueprint"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "centralus"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Check `az aks get-versions -l <location> -o table` for valid values."
  type        = string
  default     = "1.29"
}

variable "node_count" {
  description = "Number of nodes in the default (system) node pool."
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM SKU for AKS nodes. Standard_B2s keeps dev costs low."
  type        = string
  default     = "Standard_B2s"
}

variable "acr_sku" {
  description = "Container Registry SKU (Basic is fine for dev; use Standard/Premium for prod)."
  type        = string
  default     = "Basic"
}

variable "log_retention_days" {
  description = "Log Analytics data retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    project     = "cloud-native-blueprint"
    environment = "dev"
    managed_by  = "terraform"
  }
}
