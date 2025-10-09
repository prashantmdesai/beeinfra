# =============================================================================
# VIRTUAL MACHINE MODULE
# =============================================================================
# Creates Azure Virtual Machine with Public IP, NIC, and Managed Disk
# Supports both Kubernetes master and worker node roles
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.vm_zone != null ? [var.vm_zone] : []

  tags = merge(
    var.tags,
    {
      Environment  = var.env_name
      Organization = var.org_name
      Platform     = var.platform_name
      VMName       = var.vm_name
      VMRole       = var.vm_role
      ManagedBy    = "Terraform"
    }
  )
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm_private_ip
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = merge(
    var.tags,
    {
      Environment  = var.env_name
      Organization = var.org_name
      Platform     = var.platform_name
      VMName       = var.vm_name
      VMRole       = var.vm_role
      ManagedBy    = "Terraform"
    }
  )
}

# Associate NIC with NSG
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = var.nsg_id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  zone                = var.vm_zone

  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.vm_disk_sku
    disk_size_gb         = var.vm_disk_size_gb
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  # Cloud-init configuration
  custom_data = var.cloud_init_data != null ? base64encode(var.cloud_init_data) : null

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = null  # Use managed storage
  }

  tags = merge(
    var.tags,
    {
      Environment  = var.env_name
      Organization = var.org_name
      Platform     = var.platform_name
      VMName       = var.vm_name
      VMRole       = var.vm_role
      Components   = var.vm_components
      ManagedBy    = "Terraform"
    }
  )

  lifecycle {
    ignore_changes = [
      custom_data  # Don't recreate VM if cloud-init changes
    ]
  }
}
