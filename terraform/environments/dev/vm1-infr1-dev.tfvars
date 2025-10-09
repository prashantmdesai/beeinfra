# =============================================================================
# VM1 - MASTER NODE (INFRASTRUCTURE)
# =============================================================================
# VM Name: dats-beeux-infr1-dev
# Role: Kubernetes Master Node
# Components: WIOR (Orchestrator), WCID (Identity)
# Private IP: 10.0.1.4 (First usable IP in subnet)
# =============================================================================

vm1_name         = "dats-beeux-infr1-dev"
vm1_size         = "Standard_B2s"
vm1_disk_size_gb = 30
vm1_disk_sku     = "StandardSSD_LRS"
vm1_private_ip   = "10.0.1.4"
vm1_zone         = "1"
vm1_role         = "master"
vm1_components   = "WIOR,WCID"
