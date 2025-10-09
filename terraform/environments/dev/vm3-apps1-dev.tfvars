# =============================================================================
# VM3 - WORKER NODE (APPLICATIONS 1)
# =============================================================================
# VM Name: dats-beeux-apps1-dev
# Role: Kubernetes Worker Node
# Components: NGLB (NGINX), WEUI (Web UI), WAUI (Admin UI), WCAC (Cache), SWAG (Swagger)
# Private IP: 10.0.1.6
# =============================================================================

vm3_name         = "dats-beeux-apps1-dev"
vm3_size         = "Standard_B2s"
vm3_disk_size_gb = 30
vm3_disk_sku     = "StandardSSD_LRS"
vm3_private_ip   = "10.0.1.6"
vm3_zone         = "1"
vm3_role         = "worker"
vm3_components   = "NGLB,WEUI,WAUI,WCAC,SWAG"
