# =============================================================================
# VARIABLES - DEV ENVIRONMENT
# =============================================================================

# -----------------------------------------------------------------------------
# COMMON VARIABLES
# -----------------------------------------------------------------------------

variable "org_name" {
  description = "Organization name"
  type        = string
  default     = "dats"
}

variable "platform_name" {
  description = "Platform name"
  type        = string
  default     = "beeux"
}

variable "env_name" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralus"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# NETWORKING VARIABLES
# -----------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "VNet address space"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "laptop_ip" {
  description = "Laptop IP address (CIDR format)"
  type        = string
}

variable "wifi_cidr" {
  description = "WiFi network CIDR"
  type        = string
}

# -----------------------------------------------------------------------------
# STORAGE VARIABLES
# -----------------------------------------------------------------------------

variable "storage_account_name" {
  description = "Storage account name (globally unique)"
  type        = string
}

variable "file_share_name" {
  description = "Azure Files share name"
  type        = string
}

variable "file_share_quota_gb" {
  description = "File share quota in GB"
  type        = number
  default     = 100
}

variable "blob_container_name" {
  description = "Blob container name for media files (BLBS component)"
  type        = string
}

# -----------------------------------------------------------------------------
# VM COMMON VARIABLES
# -----------------------------------------------------------------------------

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "beeuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VMs (null to auto-generate)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# KUBERNETES VARIABLES
# -----------------------------------------------------------------------------

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "k8s_pod_cidr" {
  description = "Kubernetes pod network CIDR"
  type        = string
  default     = "192.168.0.0/16"
}

variable "k8s_cni" {
  description = "Kubernetes CNI plugin"
  type        = string
  default     = "calico"
}

# -----------------------------------------------------------------------------
# GITHUB VARIABLES
# -----------------------------------------------------------------------------

variable "github_pat" {
  description = "GitHub Personal Access Token for cloning infra repo"
  type        = string
  sensitive   = true
}

variable "github_infra_repo" {
  description = "GitHub infrastructure repository URL"
  type        = string
  default     = "https://github.com/prashantmdesai/infra"
}

variable "github_infra_path" {
  description = "Local path to clone infra repo"
  type        = string
  default     = "/home/beeuser/plt"
}

variable "github_infra_cnf_repo" {
  description = "GitHub infrastructure configuration repository URL"
  type        = string
  default     = "https://github.com/prashantmdesai/infra-cnf"
}

variable "github_beecommons_repo" {
  description = "GitHub beecommons repository URL"
  type        = string
  default     = "https://github.com/prashantmdesai/beecommons"
}

variable "github_shaf_data_path" {
  description = "Path to SHAF data directory where additional repos will be cloned"
  type        = string
  default     = "/mnt/dats-beeux-dev-shaf-afs/data"
}

# -----------------------------------------------------------------------------
# VM1 - MASTER NODE (INFRASTRUCTURE)
# -----------------------------------------------------------------------------

variable "vm1_name" {
  description = "VM1 name"
  type        = string
}

variable "vm1_size" {
  description = "VM1 size"
  type        = string
  default     = "Standard_B2s"
}

variable "vm1_disk_size_gb" {
  description = "VM1 disk size in GB"
  type        = number
  default     = 20
}

variable "vm1_disk_sku" {
  description = "VM1 disk SKU"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "vm1_private_ip" {
  description = "VM1 private IP"
  type        = string
}

variable "vm1_zone" {
  description = "VM1 availability zone"
  type        = string
  default     = "1"
}

variable "vm1_role" {
  description = "VM1 role (master/worker)"
  type        = string
  default     = "master"
}

variable "vm1_components" {
  description = "Components deployed on VM1"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# VM2 - WORKER NODE (SECURITY)
# -----------------------------------------------------------------------------

variable "vm2_name" {
  description = "VM2 name"
  type        = string
}

variable "vm2_size" {
  description = "VM2 size"
  type        = string
  default     = "Standard_B2s"
}

variable "vm2_disk_size_gb" {
  description = "VM2 disk size in GB"
  type        = number
  default     = 20
}

variable "vm2_disk_sku" {
  description = "VM2 disk SKU"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "vm2_private_ip" {
  description = "VM2 private IP"
  type        = string
}

variable "vm2_zone" {
  description = "VM2 availability zone"
  type        = string
  default     = "1"
}

variable "vm2_role" {
  description = "VM2 role (master/worker)"
  type        = string
  default     = "worker"
}

variable "vm2_components" {
  description = "Components deployed on VM2"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# VM3 - WORKER NODE (APPLICATIONS 1)
# -----------------------------------------------------------------------------

variable "vm3_name" {
  description = "VM3 name"
  type        = string
}

variable "vm3_size" {
  description = "VM3 size"
  type        = string
  default     = "Standard_B2s"
}

variable "vm3_disk_size_gb" {
  description = "VM3 disk size in GB"
  type        = number
  default     = 20
}

variable "vm3_disk_sku" {
  description = "VM3 disk SKU"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "vm3_private_ip" {
  description = "VM3 private IP"
  type        = string
}

variable "vm3_zone" {
  description = "VM3 availability zone"
  type        = string
  default     = "1"
}

variable "vm3_role" {
  description = "VM3 role (master/worker)"
  type        = string
  default     = "worker"
}

variable "vm3_components" {
  description = "Components deployed on VM3"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# VM4 - WORKER NODE (APPLICATIONS 2)
# -----------------------------------------------------------------------------

variable "vm4_name" {
  description = "VM4 name"
  type        = string
}

variable "vm4_size" {
  description = "VM4 size"
  type        = string
  default     = "Standard_B2s"
}

variable "vm4_disk_size_gb" {
  description = "VM4 disk size in GB"
  type        = number
  default     = 20
}

variable "vm4_disk_sku" {
  description = "VM4 disk SKU"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "vm4_private_ip" {
  description = "VM4 private IP"
  type        = string
}

variable "vm4_zone" {
  description = "VM4 availability zone"
  type        = string
  default     = "1"
}

variable "vm4_role" {
  description = "VM4 role (master/worker)"
  type        = string
  default     = "worker"
}

variable "vm4_components" {
  description = "Components deployed on VM4"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# VM5 - WORKER NODE (DATA)
# -----------------------------------------------------------------------------

variable "vm5_name" {
  description = "VM5 name"
  type        = string
}

variable "vm5_size" {
  description = "VM5 size"
  type        = string
  default     = "Standard_B2s"
}

variable "vm5_disk_size_gb" {
  description = "VM5 disk size in GB"
  type        = number
  default     = 20
}

variable "vm5_disk_sku" {
  description = "VM5 disk SKU"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "vm5_private_ip" {
  description = "VM5 private IP"
  type        = string
}

variable "vm5_zone" {
  description = "VM5 availability zone"
  type        = string
  default     = "1"
}

variable "vm5_role" {
  description = "VM5 role (master/worker)"
  type        = string
  default     = "worker"
}

variable "vm5_components" {
  description = "Components deployed on VM5"
  type        = string
  default     = ""
}
