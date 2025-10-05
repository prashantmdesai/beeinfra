# VM3 - dats-beeux-infr-dev (Kubernetes Master)

## Quick Info
- **Role**: Kubernetes Master Node
- **Size**: Standard_B2ms (2 vCPU, 8GB RAM)
- **Zone**: 1 (co-located with VM1 & VM2)
- **Private IP**: 10.0.1.6 (static)

## Files
```
vm3/
├── main-template.bicep                              # Deployment template
├── parameters.json                                  # Configuration
├── modules/
│   ├── networking.bicep                            # Network setup
│   └── vm.bicep                                    # VM configuration
└── scripts/
    ├── vm3-infr-deploy-azurecli-comprehensive.sh   # Deploy VM3
    ├── vm3-infr-setup-software-comprehensive.sh    # Software setup
    └── vm3-infr-setup-kubernetes-master.sh         # Kubernetes setup
```

## Deploy
```bash
cd scripts
./vm3-infr-deploy-azurecli-comprehensive.sh -k "ssh-rsa AAAAB3NzaC1yc2E..."
```

## Features
- Identical software stack to VM1 & VM2  
- Azure File Share auto-mounted at `/mnt/shared-data`
- Kubernetes 1.28.3 ready for cluster initialization
- Inter-VM communication configured