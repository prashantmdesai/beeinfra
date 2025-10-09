# BeEux Word Learning Platform - Infrastructure

[![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-623CE4?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)

**Development Environment Infrastructure Automation**

This repository contains the complete infrastructure-as-code for the BeEux Word Learning Platform development environment using Terraform, Kubernetes 1.30, and Azure.

---

## 📋 Quick Start

### Prerequisites

- **Azure CLI** >= 2.50.0 (`az --version`)
- **Terraform** >= 1.5.0 (`terraform version`)
- **Git** >= 2.30.0
- **Azure Subscription** with Contributor + User Access Administrator permissions
- **SSH Client** for VM access

### Deploy Infrastructure

```bash
# 1. Clone repository
git clone https://github.com/prashantmdesai/beeinfra.git
cd beeinfra

# 2. Login to Azure
az login
az account set --subscription <your-subscription-id>

# 3. Navigate to dev environment
cd terraform/environments/dev

# 4. Initialize Terraform
terraform init

# 5. Review plan
terraform plan \
  -var-file="terraform.tfvars" \
  -var-file="vm1-infr1-dev.tfvars" \
  -var-file="vm2-secu1-dev.tfvars" \
  -var-file="vm3-apps1-dev.tfvars" \
  -var-file="vm4-apps2-dev.tfvars" \
  -var-file="vm5-data1-dev.tfvars" \
  -out=tfplan

# 6. Apply infrastructure
terraform apply tfplan
```

---

## 🏗️ Infrastructure Overview

### Resources

- **5 Virtual Machines** (1 K8s master, 4 workers)
- **1 Virtual Network** (10.0.0.0/16)
- **1 Network Security Group** (20+ rules for all services)
- **1 Storage Account** with 100GB File Share
- **5 Public IPs**, **5 NICs**, **5 Managed Disks**

### VMs Configuration

| VM | Name | Role | Components | IP |
|----|------|------|------------|-----|
| VM1 | dats-beeux-infr1-dev | K8s Master | WIOR, WCID | 10.0.1.4 |
| VM2 | dats-beeux-secu1-dev | K8s Worker | KIAM, SCSM, SCCM | 10.0.1.5 |
| VM3 | dats-beeux-apps1-dev | K8s Worker | NGLB, WEUI, WAUI, WCAC, SWAG | 10.0.1.6 |
| VM4 | dats-beeux-apps2-dev | K8s Worker | SCGC, SCSD, WAPI, PFIX | 10.0.1.7 |
| VM5 | dats-beeux-data1-dev | K8s Worker | WDAT, WEDA, SCBQ | 10.0.1.8 |

### Cost Estimate

- **Monthly**: ~$187/month
- **Annual**: ~$2,241/year

---

## 📂 Repository Structure

```
beeinfra/
├── terraform/
│   ├── modules/              # Reusable Terraform modules
│   ├── environments/dev/     # Dev environment configuration
│   ├── cloud-init/           # VM initialization templates
│   ├── scripts/              # Infrastructure automation scripts
│   └── docs/                 # Documentation
├── .github/
│   └── instructions/         # Platform component definitions
├── logs/                     # Script execution logs
└── README.md                 # This file
```

---

## 🔐 Security

### Network Access

All component ports are accessible from:
- **Your Laptop**: 136.56.79.92/32
- **Your WiFi Network**: 136.56.79.0/24

### SSH Access

```bash
# SSH to any VM
ssh beeuser@<vm-public-ip>

# VM public IPs are output after deployment:
terraform output vm_public_ips
```

---

## 📚 Documentation

- **[Provisioning Plan](DATS-BEEUX-DEV-INFRA-PROVISIONING-PLAN.md)** - Complete infrastructure plan
- **[Architecture](terraform/docs/architecture.md)** - Infrastructure diagram
- **[Deployment Guide](terraform/docs/deployment-guide.md)** - Step-by-step deployment
- **[Port Mapping](terraform/docs/port-mapping.md)** - All component ports
- **[Troubleshooting](terraform/docs/troubleshooting.md)** - Common issues
- **[Platform Register](.github/instructions/Platform_Register.md)** - Component definitions

---

## 🛠️ Management

### View Infrastructure

```bash
# List all VMs
az vm list -o table

# Check K8s cluster
ssh beeuser@<vm1-public-ip> "kubectl get nodes"

# View file share mount
ssh beeuser@<vm1-public-ip> "df -h | grep SHAF"
```

### Update Single VM

```bash
# Edit VM-specific config
vim terraform/environments/dev/vm5-data1-dev.tfvars

# Apply changes (only VM5 will be updated)
terraform apply \
  -var-file="terraform.tfvars" \
  -var-file="vm1-infr1-dev.tfvars" \
  -var-file="vm2-secu1-dev.tfvars" \
  -var-file="vm3-apps1-dev.tfvars" \
  -var-file="vm4-apps2-dev.tfvars" \
  -var-file="vm5-data1-dev.tfvars"
```

### Destroy Infrastructure

```bash
cd terraform/environments/dev
terraform destroy
```

---

## 🧪 Component Deployment

Components are deployed via Kubernetes manifests from the [infra repository](https://github.com/prashantmdesai/infra):

```bash
# SSH to master node
ssh beeuser@<vm1-public-ip>

# Navigate to infra repo (cloned during deployment)
cd /home/beeuser/plt

# Deploy all components
kubectl apply -k manifests/dev/

# Check deployment status
kubectl get pods -A
```

---

## 🔍 Monitoring

### Logs

- **Terraform Logs**: `terraform/environments/dev/terraform.log`
- **Script Logs**: `logs/{script-name}-{timestamp}.log`
- **Execution Registry**: `script-execution.registry`
- **VM Cloud-Init**: SSH to VM, check `/var/log/cloud-init-output.log`

### Health Checks

```bash
# Run validation script
./terraform/scripts/deployment/validate-deployment.sh

# Check Kubernetes cluster
ssh beeuser@<vm1-public-ip> "kubectl get nodes -o wide"

# Check component pods
ssh beeuser@<vm1-public-ip> "kubectl get pods -A"
```

---

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and test
3. Commit: `git commit -am 'feat: add new feature'`
4. Push: `git push origin feature/your-feature`
5. Create Pull Request

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/prashantmdesai/beeinfra/issues)
- **Documentation**: See `terraform/docs/` directory
- **Provisioning Plan**: See `DATS-BEEUX-DEV-INFRA-PROVISIONING-PLAN.md`

---

## 📄 License

Copyright © 2025 BeEux Word Learning Platform

---

## 🎯 Environment Variables

```bash
# Used across all scripts and Terraform
export ORGNM="dats"
export PLTNM="beeux"
export ENVNM="dev"
```

---

**Last Updated**: October 8, 2025
**Version**: 1.0.0
**Infrastructure**: Terraform + Kubernetes 1.30 + Azure
