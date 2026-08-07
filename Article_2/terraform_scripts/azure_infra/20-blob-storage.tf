
locals {
  dynamic_runner_ip = "${jsondecode(data.http.my_ip.response_body).ip}/30"
  ip_rules = concat(
    [local.dynamic_runner_ip],
    var.allowed_ips
  )
}

# ----------------------------
# Backup storage account
# ----------------------------
resource "azurerm_storage_account" "backup" {
  name                = var.backup_storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.blob_soft_delete_days
    }

    container_delete_retention_policy {
      days = var.container_soft_delete_days
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = local.ip_rules
  }

  tags = local.tags
}

# ----------------------------
# Containers
# ----------------------------
resource "azurerm_storage_container" "longhorn" {
  name                  = "longhorn"
  storage_account_id    = azurerm_storage_account.backup.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "velero" {
  name                  = "velero"
  storage_account_id    = azurerm_storage_account.backup.id
  container_access_type = "private"
}


# ----------------------------
# Lifecycle / retention rules
# ----------------------------
resource "azurerm_storage_management_policy" "backup_retention" {
  storage_account_id = azurerm_storage_account.backup.id

  # ----------------------------
  # Longhorn
  # ----------------------------
  rule {
    name    = "longhorn-retention"
    enabled = true

    filters {
      prefix_match = ["longhorn/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = var.tier_to_cool_after_days_since_modification_greater_than

        delete_after_days_since_modification_greater_than = var.longhorn_retention_days
      }

      snapshot {
        delete_after_days_since_creation_greater_than = var.longhorn_retention_days
      }

      version {
        delete_after_days_since_creation = var.longhorn_retention_days
      }
    }
  }

  # ----------------------------
  # Velero
  # ----------------------------
  rule {
    name    = "velero-retention"
    enabled = true

    filters {
      prefix_match = ["velero/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = var.tier_to_cool_after_days_since_modification_greater_than

        delete_after_days_since_modification_greater_than = var.velero_retention_days
      }

      snapshot {
        delete_after_days_since_creation_greater_than = var.velero_retention_days
      }

      version {
        delete_after_days_since_creation = var.velero_retention_days
      }
    }
  }
  rule {
    name    = "gitlab-retention"
    enabled = true

    filters {
      prefix_match = ["gitlab/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = var.tier_to_cool_after_days_since_modification_greater_than

        delete_after_days_since_modification_greater_than = var.gitlab_retention_days
      }

      snapshot {
        delete_after_days_since_creation_greater_than = var.gitlab_retention_days
      }

      version {
        delete_after_days_since_creation = var.gitlab_retention_days
      }
    }
  }
}

resource "azurerm_storage_container" "gitlab" {
  name                  = "gitlab"
  storage_account_id    = azurerm_storage_account.backup.id
  container_access_type = "private"
}

