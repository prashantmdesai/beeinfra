# Azure Infrastructure Architecture

## Overview

This document describes the architecture of the Azure-based Kubernetes platform infrastructure. The platform is designed for development and testing of containerized applications with a focus on scalability, security, and maintainability.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Azure Subscription                                   │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    Resource Group: dats-beeux-dev-rg                     ││
│  │                                                                           ││
│  │  ┌────────────────────────────────────────────────────────────────────┐ ││
│  │  │         Virtual Network: dats-beeux-dev-vnet (10.0.0.0/16)         │ ││
│  │  │                                                                      │ ││
│  │  │  ┌─────────────────────────────────────────────────────────────┐   │ ││
│  │  │  │    Subnet: dats-beeux-dev-subnet (10.0.1.0/24)              │   │ ││
│  │  │  │                                                               │   │ ││
│  │  │  │  ┌──────────────────────────────────────────────────────┐   │   │ ││
│  │  │  │  │  Master Node (vm1-infr1-dev)                         │   │   │ ││
│  │  │  │  │  - IP: 10.0.1.4                                      │   │   │ ││
│  │  │  │  │  - Size: Standard_D2s_v3                             │   │   │ ││
│  │  │  │  │  - OS: Ubuntu 22.04 LTS                              │   │   │ ││
│  │  │  │  │  - Kubernetes Master                                 │   │   │ ││
│  │  │  │  │  - Public IP: Dynamic                                │   │   │ ││
│  │  │  │  └──────────────────────────────────────────────────────┘   │   │ ││
│  │  │  │                                                               │   │ ││
│  │  │  │  ┌──────────────────────────────────────────────────────┐   │   │ ││
│  │  │  │  │  Worker Node 1 (vm2-secu1-dev)                       │   │   │ ││
│  │  │  │  │  - IP: 10.0.1.5                                      │   │   │ ││
│  │  │  │  │  - Size: Standard_D2s_v3                             │   │   │ ││
│  │  │  │  │  - OS: Ubuntu 22.04 LTS                              │   │   │ ││
│  │  │  │  │  - Kubernetes Worker                                 │   │   │ ││
│  │  │  │  │  - Public IP: Dynamic                                │   │   │ ││
│  │  │  │  └──────────────────────────────────────────────────────┘   │   │ ││
│  │  │  │                                                               │   │ ││
│  │  │  │  ┌──────────────────────────────────────────────────────┐   │   │ ││
│  │  │  │  │  Worker Node 2 (vm3-apps1-dev)                       │   │   │ ││
│  │  │  │  │  - IP: 10.0.1.6                                      │   │   │ ││
│  │  │  │  │  - Size: Standard_D2s_v3                             │   │   │ ││
│  │  │  │  │  - OS: Ubuntu 22.04 LTS                              │   │   │ ││
│  │  │  │  │  - Kubernetes Worker                                 │   │   │ ││
│  │  │  │  │  - Public IP: Dynamic                                │   │   │ ││
│  │  │  │  └──────────────────────────────────────────────────────┘   │   │ ││
│  │  │  │                                                               │   │ ││
│  │  │  │  ┌──────────────────────────────────────────────────────┐   │   │ ││
│  │  │  │  │  Worker Node 3 (vm4-apps2-dev)                       │   │   │ ││
│  │  │  │  │  - IP: 10.0.1.7                                      │   │   │ ││
│  │  │  │  │  - Size: Standard_D2s_v3                             │   │   │ ││
│  │  │  │  │  - OS: Ubuntu 22.04 LTS                              │   │   │ ││
│  │  │  │  │  - Kubernetes Worker                                 │   │   │ ││
│  │  │  │  │  - Public IP: Dynamic                                │   │   │ ││
│  │  │  │  └──────────────────────────────────────────────────────┘   │   │ ││
│  │  │  │                                                               │   │ ││
│  │  │  │  ┌──────────────────────────────────────────────────────┐   │   │ ││
│  │  │  │  │  Worker Node 4 (vm5-data1-dev)                       │   │   │ ││
│  │  │  │  │  - IP: 10.0.1.8                                      │   │   │ ││
│  │  │  │  │  - Size: Standard_D2s_v3                             │   │   │ ││
│  │  │  │  │  - OS: Ubuntu 22.04 LTS                              │   │   │ ││
│  │  │  │  │  - Kubernetes Worker                                 │   │   │ ││
│  │  │  │  │  - Public IP: Dynamic                                │   │   │ ││
│  │  │  │  └──────────────────────────────────────────────────────┘   │   │ ││
│  │  │  │                                                               │   │ ││
│  │  │  └───────────────────────────────────────────────────────────────┘   │ ││
│  │  │                                                                      │ ││
│  │  │  Network Security Group (NSG): dats-beeux-dev-nsg                  │ ││
│  │  │  - 32 security rules (all ports accessible from laptop + WiFi)     │ ││
│  │  └────────────────────────────────────────────────────────────────────┘ ││
│  │                                                                           ││
│  │  ┌────────────────────────────────────────────────────────────────────┐ ││
│  │  │  Storage Account: datsbeeuxdevstacct                               │ ││
│  │  │  - Type: Standard LRS                                              │ ││
│  │  │  - File Share: dats-beeux-dev-shaf-afs (100GB)                    │ ││
│  │  │  - Purpose: Shared storage for K8s join tokens and logs           │ ││
│  │  └────────────────────────────────────────────────────────────────────┘ ││
│  │                                                                           ││
│  └───────────────────────────────────────────────────────────────────────────┘│
│                                                                               │
│  Internet Access:                                                             │
│  - Your Laptop IP: Full access to all ports on all VMs                       │
│  - Your WiFi Network: Full access to all ports on all VMs                    │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Resource Group

**Name**: `dats-beeux-dev-rg`  
**Location**: Canada Central  
**Purpose**: Logical container for all infrastructure resources

### 2. Virtual Network

**Name**: `dats-beeux-dev-vnet`  
**Address Space**: `10.0.0.0/16`  
**Purpose**: Private network for VM communication

#### Subnet

**Name**: `dats-beeux-dev-subnet`  
**Address Range**: `10.0.1.0/24`  
**Available IPs**: 251 addresses  
**Purpose**: Hosts all 5 VMs with static private IPs

### 3. Network Security Group (NSG)

**Name**: `dats-beeux-dev-nsg`  
**Rules**: 32 security rules  
**Purpose**: Control inbound/outbound traffic to VMs

**Key Security Rules** (Inbound):
- SSH (22) - From your laptop + WiFi
- Kubernetes API (6443) - From your laptop + WiFi
- NodePort Range (30000-32767) - From your laptop + WiFi
- All other ports - From your laptop + WiFi

See [Port Mapping](./port-mapping.md) for complete list.

### 4. Virtual Machines

#### Master Node (vm1-infr1-dev)

- **Private IP**: 10.0.1.4 (static)
- **Public IP**: Dynamic (assigned on boot)
- **VM Size**: Standard_D2s_v3 (2 vCPUs, 8GB RAM)
- **OS**: Ubuntu 22.04 LTS
- **OS Disk**: 30GB Premium SSD
- **Role**: Kubernetes Control Plane
- **Components**:
  - kube-apiserver
  - kube-controller-manager
  - kube-scheduler
  - etcd
  - Calico CNI
  - kubectl

#### Worker Nodes

All worker nodes have identical specifications:

**vm2-secu1-dev** (Worker 1)
- **Private IP**: 10.0.1.5
- **Public IP**: Dynamic
- **VM Size**: Standard_D2s_v3
- **OS**: Ubuntu 22.04 LTS
- **OS Disk**: 30GB Premium SSD
- **Role**: Security workloads

**vm3-apps1-dev** (Worker 2)
- **Private IP**: 10.0.1.6
- **Public IP**: Dynamic
- **VM Size**: Standard_D2s_v3
- **OS**: Ubuntu 22.04 LTS
- **OS Disk**: 30GB Premium SSD
- **Role**: Application workloads

**vm4-apps2-dev** (Worker 3)
- **Private IP**: 10.0.1.7
- **Public IP**: Dynamic
- **VM Size**: Standard_D2s_v3
- **OS**: Ubuntu 22.04 LTS
- **OS Disk**: 30GB Premium SSD
- **Role**: Application workloads

**vm5-data1-dev** (Worker 4)
- **Private IP**: 10.0.1.8
- **Public IP**: Dynamic
- **VM Size**: Standard_D2s_v3
- **OS**: Ubuntu 22.04 LTS
- **OS Disk**: 30GB Premium SSD
- **Role**: Data processing workloads

### 5. Storage Account

**Name**: `datsbeeuxdevstacct`  
**Type**: Standard LRS (Locally Redundant Storage)  
**Location**: Canada Central  
**Purpose**: Shared storage for cluster

#### File Share

**Name**: `dats-beeux-dev-shaf-afs`  
**Quota**: 100GB  
**Protocol**: SMB 3.0  
**Mount Point**: `/mnt/dats-beeux-dev-shaf-afs`  
**Purpose**: 
- Kubernetes join token sharing
- Centralized logging
- Configuration management
- Backup storage

**Directory Structure**:
```
/mnt/dats-beeux-dev-shaf-afs/
├── k8s-join-token/     # Kubernetes join tokens
├── logs/               # Application logs
├── configs/            # Configuration files
├── data/               # Application data
├── backups/            # Backup files
└── scripts/            # Automation scripts
```

### 6. Network Interfaces

Each VM has one network interface:
- **vm1-infr1-dev-nic**: 10.0.1.4
- **vm2-secu1-dev-nic**: 10.0.1.5
- **vm3-apps1-dev-nic**: 10.0.1.6
- **vm4-apps2-dev-nic**: 10.0.1.7
- **vm5-data1-dev-nic**: 10.0.1.8

### 7. Public IP Addresses

Each VM has one dynamic public IP:
- **vm1-infr1-dev-pip**: For master node external access
- **vm2-secu1-dev-pip**: For worker 1 external access
- **vm3-apps1-dev-pip**: For worker 2 external access
- **vm4-apps2-dev-pip**: For worker 3 external access
- **vm5-data1-dev-pip**: For worker 4 external access

## Kubernetes Cluster Architecture

### Cluster Configuration

**Cluster Name**: dats-beeux-dev-cluster  
**Kubernetes Version**: 1.30.x  
**Container Runtime**: containerd  
**CNI Plugin**: Calico v3.27  
**Pod CIDR**: 192.168.0.0/16  
**Service CIDR**: 10.96.0.0/12

### Node Roles

```
Master Node (vm1-infr1-dev):
  - Control plane components
  - etcd datastore
  - API server endpoint
  - Scheduling decisions
  - Cluster state management

Worker Nodes (vm2-5):
  - Pod execution
  - Container runtime
  - kubelet agent
  - kube-proxy networking
  - Application workloads
```

### Networking Model

**Pod-to-Pod Communication**:
- All pods can communicate with each other
- Calico CNI provides overlay network
- Pod CIDR: 192.168.0.0/16

**Service Discovery**:
- CoreDNS for cluster DNS
- Service CIDR: 10.96.0.0/12
- ClusterIP for internal services
- NodePort for external access

**External Access**:
- NodePort services: 30000-32767
- LoadBalancer services (future)
- Ingress controller (future)

## Data Flow

### 1. VM Initialization Flow

```
Terraform Apply
    ↓
Azure Resources Created
    ↓
Cloud-Init Executes
    ↓
1. System Updates
2. Package Installation
3. Azure File Share Mount
4. GitHub Repo Clone
5. Kubernetes Installation
    ↓
Master: kubeadm init
    ↓
Workers: kubeadm join
    ↓
Cluster Ready
```

### 2. Application Deployment Flow

```
Developer
    ↓
kubectl apply
    ↓
API Server (Master)
    ↓
Scheduler assigns Pod to Node
    ↓
Kubelet pulls container image
    ↓
Container Runtime creates container
    ↓
Pod Running
```

### 3. Storage Access Flow

```
Application
    ↓
Volume Mount Request
    ↓
Azure File Share
    ↓
SMB/CIFS Protocol
    ↓
File Access
```

## Security Architecture

### Network Security

**Network Segmentation**:
- Single subnet for development simplicity
- Production should use multiple subnets

**Access Control**:
- NSG rules restrict access to your IPs only
- SSH key authentication (no passwords)
- Kubernetes RBAC for pod-level security

**Encryption**:
- SSH encrypted communication
- Kubernetes API TLS encryption
- Azure Storage encryption at rest

### Identity and Access

**VM Access**:
- Username: `beeuser`
- Authentication: SSH keys only
- sudo access: Configured

**Kubernetes Access**:
- kubeconfig on master node
- RBAC policies (default)
- Service accounts for pods

**Azure Resources**:
- Managed Identity (future)
- Service Principal (current)
- RBAC assignments

## High Availability Considerations

### Current Setup (Development)

- **Single master node**: Not HA
- **Multiple workers**: Provides redundancy for workloads
- **Shared storage**: Single point of failure

### Production Recommendations

1. **Multi-Master Setup**:
   - 3 or 5 master nodes
   - External etcd cluster
   - Load balancer for API server

2. **Worker Node Redundancy**:
   - More worker nodes
   - Anti-affinity rules
   - Availability zones

3. **Storage Redundancy**:
   - Zone-redundant storage
   - Regular backups
   - Disaster recovery plan

## Scalability

### Vertical Scaling

Change VM sizes in tfvars:
```hcl
vm_size = "Standard_D4s_v3"  # 4 vCPUs, 16GB RAM
vm_size = "Standard_D8s_v3"  # 8 vCPUs, 32GB RAM
```

### Horizontal Scaling

Add more worker nodes:
1. Create new tfvars file: `vm6-apps3-dev.tfvars`
2. Update `main.tf` to include new VM module
3. Run `terraform apply`
4. Join new node to cluster

### Storage Scaling

Increase file share quota:
```hcl
share_quota = 500  # GB
```

## Monitoring and Logging

### Current Setup

**Logs Location**:
- System logs: `/var/log/`
- Cloud-init: `/var/log/cloud-init-output.log`
- Kubernetes: `kubectl logs`
- Scripts: `/var/log/deployment/`, `/var/log/infrastructure/`, `/var/log/kubernetes/`

### Recommended Additions

1. **Prometheus + Grafana**: Metrics collection and visualization
2. **ELK Stack**: Centralized logging
3. **Azure Monitor**: Cloud-native monitoring
4. **Alerting**: Critical event notifications

## Cost Optimization

### Current Monthly Costs (Estimated)

- **5 VMs** (Standard_D2s_v3): ~$160/month
- **Storage** (100GB LRS): ~$2/month
- **Public IPs** (5 dynamic): ~$15/month
- **Bandwidth**: ~$10/month (estimated)
- **Other resources**: ~$27/month
- **Total**: ~$214/month

### Cost Reduction Strategies

1. **Auto-shutdown**: Stop VMs when not in use
2. **Reserved Instances**: 1-year or 3-year commitments
3. **Spot VMs**: For non-critical workloads
4. **Right-sizing**: Use smaller VMs if sufficient
5. **Storage Optimization**: Clean up unused data

## Disaster Recovery

### Backup Strategy

**What to Backup**:
- Terraform state files
- Kubeconfig files
- Application data
- etcd snapshots
- Configuration files

**Backup Location**:
- Azure File Share: `/mnt/.../backups/`
- Git repository: Configuration as code
- Azure Blob Storage: Long-term backups

### Recovery Procedures

**VM Failure**:
1. Terraform recreates VM with same configuration
2. Cloud-init re-executes initialization
3. Rejoin Kubernetes cluster

**Cluster Failure**:
1. Restore etcd from snapshot
2. Recreate master node
3. Rejoin worker nodes

**Complete Disaster**:
1. Run `terraform apply` to recreate infrastructure
2. Restore etcd snapshot
3. Redeploy applications

## Future Enhancements

### Short Term

1. **Helm Package Manager**: Simplify application deployment
2. **Ingress Controller**: Better external access
3. **Cert-Manager**: Automated TLS certificates
4. **Metrics Server**: Resource utilization tracking

### Medium Term

1. **Service Mesh** (Istio/Linkerd): Advanced traffic management
2. **GitOps** (ArgoCD/Flux): Automated deployments
3. **Container Registry**: Private image repository
4. **CI/CD Pipeline**: Automated testing and deployment

### Long Term

1. **Multi-Region Deployment**: Geographic redundancy
2. **Multi-Cluster Setup**: Workload isolation
3. **Advanced Monitoring**: ML-based anomaly detection
4. **Compliance Automation**: Security and audit controls

## Related Documentation

- [Deployment Guide](./deployment-guide.md) - Step-by-step deployment
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions
- [Port Mapping](./port-mapping.md) - Complete port reference
- [Best Practices](./best-practices.md) - Standards and conventions
- [Environment Setup](./environment-setup.md) - Multi-environment guide

---

**Last Updated**: 2025-10-08  
**Version**: 1.0.0  
**Maintainer**: Infrastructure Team
