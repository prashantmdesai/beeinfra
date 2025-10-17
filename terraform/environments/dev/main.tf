# =============================================================================
# MAIN TERRAFORM CONFIGURATION - DEV ENVIRONMENT
# =============================================================================
# Orchestrates all modules to create the BeEux Word Learning Platform infrastructure
# =============================================================================

# -----------------------------------------------------------------------------
# SSH KEY PAIR (Generated once, shared by all VMs)
# -----------------------------------------------------------------------------

module "ssh_key" {
  source = "../../modules/ssh-key-pair"

  key_name     = "${var.org_name}-${var.platform_name}-${var.vm1_name}"
  save_locally = true
  output_path  = "${path.root}/ssh-keys"
}

# -----------------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------------

module "resource_group" {
  source = "../../modules/resource-group"

  org_name      = var.org_name
  platform_name = var.platform_name
  env_name      = var.env_name
  location      = var.location

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  org_name            = var.org_name
  platform_name       = var.platform_name
  env_name            = var.env_name
  location            = var.location
  resource_group_name = module.resource_group.rg_name

  vnet_address_space    = var.vnet_address_space
  subnet_address_prefix = var.subnet_address_prefix
  laptop_ip             = var.laptop_ip
  wifi_cidr             = var.wifi_cidr

  tags = var.common_tags

  depends_on = [module.resource_group]
}

# -----------------------------------------------------------------------------
# STORAGE
# -----------------------------------------------------------------------------

module "storage" {
  source = "../../modules/storage"

  org_name            = var.org_name
  platform_name       = var.platform_name
  env_name            = var.env_name
  location            = var.location
  resource_group_name = module.resource_group.rg_name

  storage_account_name = var.storage_account_name
  file_share_name      = var.file_share_name
  file_share_quota_gb  = var.file_share_quota_gb
  blob_container_name  = var.blob_container_name

  subnet_ids = [module.networking.subnet_id]
  allowed_ip_ranges = [
    replace(var.laptop_ip, "/32", ""),  # Remove /32 for IP rules
    replace(var.wifi_cidr, "/24", "")   # Remove /24 for IP rules
  ]

  tags = var.common_tags

  depends_on = [module.networking]
}

# -----------------------------------------------------------------------------
# VIRTUAL MACHINES
# -----------------------------------------------------------------------------

# VM1 - Master Node (Infrastructure)
module "vm1_infr1" {
  source = "../../modules/virtual-machine"

  org_name            = var.org_name
  platform_name       = var.platform_name
  env_name            = var.env_name
  location            = var.location
  resource_group_name = module.resource_group.rg_name

  vm_name         = var.vm1_name
  vm_size         = var.vm1_size
  vm_disk_size_gb = var.vm1_disk_size_gb
  vm_disk_sku     = var.vm1_disk_sku
  vm_private_ip   = var.vm1_private_ip
  vm_zone         = var.vm1_zone
  vm_role         = var.vm1_role
  vm_components   = var.vm1_components

  subnet_id = module.networking.subnet_id
  nsg_id    = module.networking.nsg_id

  admin_username = var.admin_username
  ssh_public_key = module.ssh_key.public_key_openssh

  cloud_init_data = templatefile("${path.module}/../../cloud-init/master-node.yaml", {
    # VM specific
    vm_name              = var.vm1_name
    vm_role              = var.vm1_role
    vm_components        = var.vm1_components
    vm_private_ip        = var.vm1_private_ip
    admin_username       = var.admin_username
    ssh_public_key       = module.ssh_key.public_key_openssh
    # Storage
    storage_account_name = module.storage.storage_account_name
    file_share_name      = module.storage.file_share_name
    storage_access_key   = module.storage.primary_access_key
    mount_path           = "/mnt/${var.file_share_name}"
    # GitHub
    github_pat             = var.github_pat
    github_infra_repo      = var.github_infra_repo
    github_infra_path      = var.github_infra_path
    github_infra_cnf_repo  = var.github_infra_cnf_repo
    github_beecommons_repo = var.github_beecommons_repo
    github_shaf_data_path  = var.github_shaf_data_path
    # Kubernetes
    k8s_version          = var.k8s_version
    k8s_pod_cidr         = var.k8s_pod_cidr
    k8s_cni              = var.k8s_cni
    # Organization
    org_name             = var.org_name
    platform_name        = var.platform_name
    env_name             = var.env_name
  })

  tags = var.common_tags

  depends_on = [module.networking, module.storage]
}

# VM2 - Worker Node (Security)
module "vm2_secu1" {
  source = "../../modules/virtual-machine"

  org_name            = var.org_name
  platform_name       = var.platform_name
  env_name            = var.env_name
  location            = var.location
  resource_group_name = module.resource_group.rg_name

  vm_name         = var.vm2_name
  vm_size         = var.vm2_size
  vm_disk_size_gb = var.vm2_disk_size_gb
  vm_disk_sku     = var.vm2_disk_sku
  vm_private_ip   = var.vm2_private_ip
  vm_zone         = var.vm2_zone
  vm_role         = var.vm2_role
  vm_components   = var.vm2_components

  subnet_id = module.networking.subnet_id
  nsg_id    = module.networking.nsg_id

  admin_username = var.admin_username
  ssh_public_key = module.ssh_key.public_key_openssh  # Use same key as master

  cloud_init_data = templatefile("${path.module}/../../cloud-init/worker-node.yaml", {
    # VM specific
    vm_name              = var.vm2_name
    vm_role              = var.vm2_role
    vm_components        = var.vm2_components
    vm_private_ip        = var.vm2_private_ip
    admin_username       = var.admin_username
    ssh_public_key       = module.ssh_key.public_key_openssh
    # Storage
    storage_account_name = module.storage.storage_account_name
    file_share_name      = module.storage.file_share_name
    storage_access_key   = module.storage.primary_access_key
    mount_path           = "/mnt/${var.file_share_name}"
    # Kubernetes
    master_ip            = module.vm1_infr1.private_ip
    k8s_version          = var.k8s_version
    # Organization
    org_name             = var.org_name
    platform_name        = var.platform_name
    env_name             = var.env_name
  })

  tags = var.common_tags

  depends_on = [module.vm1_infr1]
}

# VM3 - Worker Node (Applications 1)
module "vm3_apps1" {
  source = "../../modules/virtual-machine"

  org_name            = var.org_name
  platform_name       = var.platform_name
  env_name            = var.env_name
  location            = var.location
  resource_group_name = module.resource_group.rg_name

  vm_name         = var.vm3_name
  vm_size         = var.vm3_size
  vm_disk_size_gb = var.vm3_disk_size_gb
  vm_disk_sku     = var.vm3_disk_sku
  vm_private_ip   = var.vm3_private_ip
  vm_zone         = var.vm3_zone
  vm_role         = var.vm3_role
  vm_components   = var.vm3_components

  subnet_id = module.networking.subnet_id
  nsg_id    = module.networking.nsg_id

  admin_username = var.admin_username
  ssh_public_key = module.ssh_key.public_key_openssh  # Use same key as master

  cloud_init_data = templatefile("${path.module}/../../cloud-init/worker-node.yaml", {
    # VM specific
    vm_name              = var.vm3_name
    vm_role              = var.vm3_role
    vm_components        = var.vm3_components
    vm_private_ip        = var.vm3_private_ip
    admin_username       = var.admin_username
    ssh_public_key       = module.ssh_key.public_key_openssh
    # Storage
    storage_account_name = module.storage.storage_account_name
    file_share_name      = module.storage.file_share_name
    storage_access_key   = module.storage.primary_access_key
    mount_path           = "/mnt/${var.file_share_name}"
    # Kubernetes
    master_ip            = module.vm1_infr1.private_ip
    k8s_version          = var.k8s_version
    # Organization
    org_name             = var.org_name
    platform_name        = var.platform_name
    env_name             = var.env_name
  })

  tags = var.common_tags

  depends_on = [module.vm1_infr1]
}

# VM4 - Worker Node (Applications 2)
module "vm4_apps2" {
  source = "../../modules/virtual-machine"

  org_name            = var.org_name
  platform_name       = var.platform_name
  env_name            = var.env_name
  location            = var.location
  resource_group_name = module.resource_group.rg_name

  vm_name         = var.vm4_name
  vm_size         = var.vm4_size
  vm_disk_size_gb = var.vm4_disk_size_gb
  vm_disk_sku     = var.vm4_disk_sku
  vm_private_ip   = var.vm4_private_ip
  vm_zone         = var.vm4_zone
  vm_role         = var.vm4_role
  vm_components   = var.vm4_components

  subnet_id = module.networking.subnet_id
  nsg_id    = module.networking.nsg_id

  admin_username = var.admin_username
  ssh_public_key = module.ssh_key.public_key_openssh  # Use same key as master

  cloud_init_data = templatefile("${path.module}/../../cloud-init/worker-node.yaml", {
    # VM specific
    vm_name              = var.vm4_name
    vm_role              = var.vm4_role
    vm_components        = var.vm4_components
    vm_private_ip        = var.vm4_private_ip
    admin_username       = var.admin_username
    ssh_public_key       = module.ssh_key.public_key_openssh
    # Storage
    storage_account_name = module.storage.storage_account_name
    file_share_name      = module.storage.file_share_name
    storage_access_key   = module.storage.primary_access_key
    mount_path           = "/mnt/${var.file_share_name}"
    # Kubernetes
    master_ip            = module.vm1_infr1.private_ip
    k8s_version          = var.k8s_version
    # Organization
    org_name             = var.org_name
    platform_name        = var.platform_name
    env_name             = var.env_name
  })

  tags = var.common_tags

  depends_on = [module.vm1_infr1]
}

# VM5 - Worker Node (Data)
module "vm5_data1" {
  source = "../../modules/virtual-machine"

  org_name            = var.org_name
  platform_name       = var.platform_name
  env_name            = var.env_name
  location            = var.location
  resource_group_name = module.resource_group.rg_name

  vm_name         = var.vm5_name
  vm_size         = var.vm5_size
  vm_disk_size_gb = var.vm5_disk_size_gb
  vm_disk_sku     = var.vm5_disk_sku
  vm_private_ip   = var.vm5_private_ip
  vm_zone         = var.vm5_zone
  vm_role         = var.vm5_role
  vm_components   = var.vm5_components

  subnet_id = module.networking.subnet_id
  nsg_id    = module.networking.nsg_id

  admin_username = var.admin_username
  ssh_public_key = module.ssh_key.public_key_openssh  # Use same key as master

  cloud_init_data = templatefile("${path.module}/../../cloud-init/worker-node.yaml", {
    # VM specific
    vm_name              = var.vm5_name
    vm_role              = var.vm5_role
    vm_components        = var.vm5_components
    vm_private_ip        = var.vm5_private_ip
    admin_username       = var.admin_username
    ssh_public_key       = module.ssh_key.public_key_openssh
    # Storage
    storage_account_name = module.storage.storage_account_name
    file_share_name      = module.storage.file_share_name
    storage_access_key   = module.storage.primary_access_key
    mount_path           = "/mnt/${var.file_share_name}"
    # Kubernetes
    master_ip            = module.vm1_infr1.private_ip
    k8s_version          = var.k8s_version
    # Organization
    org_name             = var.org_name
    platform_name        = var.platform_name
    env_name             = var.env_name
  })

  tags = var.common_tags

  depends_on = [module.vm1_infr1]
}
