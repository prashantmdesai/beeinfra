# DATS-BEEUX Development Infrastructure

## Current Infrastructure Status

### 3-VM Architecture (Zone 1, Central US)
```
VM1: dats-beeux-data-dev    | 52.182.154.41 (10.0.1.4) | Standard_B2ms | Data Services
VM2: dats-beeux-apps-dev    | 52.230.252.48 (10.0.1.5) | Standard_B4ms | Applications
VM3: dats-beeux-infr-dev    | [Deploy needed]  (10.0.1.6) | Standard_B2ms | Kubernetes Master
```

### Software Stack (Identical across all VMs)
- **OS**: Ubuntu 22.04 LTS
- **Container**: Docker (latest stable)
- **Orchestration**: Kubernetes 1.28.3
- **Runtime**: Node.js 18.19.1, Python 3.12
- **Storage**: Azure File Share mounted at `/mnt/shared-data`

### Network Configuration
- **VNet**: `vnet-dev-centralus` (10.0.1.0/24)
- **NSG**: `nsg-dev-ubuntu-vm` (allows your IP + WiFi network)
- **Storage**: `stdatsbeeuxdevcus5309` Azure File Share
- **Region**: Central US, Zone 1 (all VMs co-located for minimum latency)

### Access Information
```bash
# SSH Access
ssh beeuser@52.182.154.41  # VM1 (data)
ssh beeuser@52.230.252.48  # VM2 (apps)
ssh beeuser@[VM3_IP]       # VM3 (master) - after deployment

# Inter-VM Communication (via private IPs)
VM1: ssh beeuser@10.0.1.4
VM2: ssh beeuser@10.0.1.5  
VM3: ssh beeuser@10.0.1.6
```

### Storage Configuration
- **Azure File Share**: `//stdatsbeeuxdevcus5309.file.core.windows.net/shared-data`
- **Mount Point**: `/mnt/shared-data` (all VMs)
- **Credentials**: `/etc/smbcredentials/stdatsbeeuxdevcus5309.cred`
- **Access**: Shared across all VMs for data exchange

### Current Issues to Address
1. **VM3 Deployment**: Infrastructure master node needs deployment
2. **VM Naming**: Consider renaming for consistency (optional)
3. **Kubernetes Cluster**: Need to initialize across the 3 VMs

### Cost Overview (Monthly, if running 24/7)
- VM1 (B2ms): ~$61
- VM2 (B4ms): ~$122  
- VM3 (B2ms): ~$61
- **Total**: ~$244/month

*Note: Auto-shutdown configured for 5:00 AM UTC reduces costs significantly*