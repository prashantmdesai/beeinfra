# =============================================================================
# VM2 - WORKER NODE (SECURITY)
# =============================================================================
# VM Name: dats-beeux-secu1-dev
# Role: Kubernetes Worker Node
# Components: KIAM (Keycloak), SCSM (Vault), SCCM (Config Server)
# Private IP: 10.0.1.5
# =============================================================================

vm2_name         = "dats-beeux-secu1-dev"
vm2_size         = "Standard_B2s"
vm2_disk_size_gb = 30
vm2_disk_sku     = "StandardSSD_LRS"
vm2_private_ip   = "10.0.1.5"
vm2_zone         = "1"
vm2_role         = "worker"
vm2_components   = "KIAM,SCSM,SCCM"
