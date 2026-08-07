variable "client_id" {
  description = "Azure Service Principal client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Service Principal client secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Existing Azure resource group"
  type        = string
  default     = "<your_domain>-k8s-cluster_RG"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "<your_domain>-prd"
}

variable "key_vault_name" {
  description = "Azure Key Vault name"
  type        = string
  default     = "<your_domain>kvprod"
}

variable "backup_storage_account_name" {
  description = "Backup storage account name (globally unique, lowercase letters and numbers only, max 24 chars)"
  type        = string
  default     = "<your_domain>blobbackup"
}

variable "allowed_ips" {
  description = "Additional allowed public IP CIDRs for storage account firewall. Use /30 or larger for Azure Storage ip_rules."
  type        = list(string)
  default     = []
}

variable "blob_soft_delete_days" {
  description = "Soft delete retention for blobs"
  type        = number
  default     = 14
}

variable "container_soft_delete_days" {
  description = "Soft delete retention for containers"
  type        = number
  default     = 7
}

variable "longhorn_retention_days" {
  description = "Delete Longhorn old blobs/versions/snapshots after N days"
  type        = number
  default     = 30
}

variable "velero_retention_days" {
  description = "Delete Velero old blobs/versions/snapshots after N days"
  type        = number
  default     = 30
}


variable "tier_to_cool_after_days_since_modification_greater_than" {
  description = "Move blobs to cool tier after N days"
  type        = number
  default     = 7
}


variable "gitlab_retention_days" {
  type        = number
  default     = 60
  description = "GitLab repository backup retention"
}
