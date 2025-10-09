# =============================================================================
# VM4 - WORKER NODE (APPLICATIONS 2)
# =============================================================================
# VM Name: dats-beeux-apps2-dev
# Role: Kubernetes Worker Node
# Components: SCGC (Gateway), SCSD (Redis), WAPI (API), PFIX (Postfix)
# Private IP: 10.0.1.7
# =============================================================================

vm4_name         = "dats-beeux-apps2-dev"
vm4_size         = "Standard_B2s"
vm4_disk_size_gb = 30
vm4_disk_sku     = "StandardSSD_LRS"
vm4_private_ip   = "10.0.1.7"
vm4_zone         = "1"
vm4_role         = "worker"
vm4_components   = "SCGC,SCSD,WAPI,PFIX"
