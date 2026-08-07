
key_vault_name = "k8s<your_domain>vault"
allowed_ips = [
  "on-prem-cluster-public-ip/30"
  ]

resource_group_name = "<your_domain>-k8s-cluster_RG"
environment         = "<your_domain>-prd"

backup_storage_account_name = "<your_domain>backup"

