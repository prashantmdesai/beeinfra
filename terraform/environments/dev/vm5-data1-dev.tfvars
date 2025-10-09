# =============================================================================
# VM5 - WORKER NODE (DATA)
# =============================================================================
# VM Name: dats-beeux-data1-dev
# Role: Kubernetes Worker Node
# Components: WDAT (PostgreSQL), WEDA (RabbitMQ), SCBQ (Batch Queue)
# Private IP: 10.0.1.8
# =============================================================================

vm5_name         = "dats-beeux-data1-dev"
vm5_size         = "Standard_B2s"
vm5_disk_size_gb = 30
vm5_disk_sku     = "StandardSSD_LRS"
vm5_private_ip   = "10.0.1.8"
vm5_zone         = "1"
vm5_role         = "worker"
vm5_components   = "WDAT,WEDA,SCBQ"
