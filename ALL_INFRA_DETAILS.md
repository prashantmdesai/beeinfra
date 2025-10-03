# 🏗️ Complete Infrastructure Documentation

## 📋 Overview
This document contains complete details of all components, services, DNS names, and access points for the DATS-BEEUX development infrastructure running on Azure.

**Last Updated**: October 2, 2025  
**Environment**: Development  
**Region**: Central US  
**Architecture**: Multi-VM Kubernetes + Infrastructure Services

---

## 📍 **VM Infrastructure**

### **Virtual Machines**
| VM Name | Role | Public IP | Private IP | Zone | Size | Status |
|---------|------|-----------|------------|------|------|--------|
| `dats-beeux-dev-data` | Infrastructure Services | `52.182.154.41` | `10.0.1.4` | Zone 1 | Standard_B2ms | ✅ Running |
| `dats-beeux-dev-apps` | Kubernetes Applications | `52.230.252.48` | `10.0.1.5` | Zone 1 | Standard_B4ms | ✅ Running |

### **Network Configuration**
- **Resource Group**: `rg-dev-centralus`
- **Virtual Network**: `vnet-dev-centralus`
- **Subnet**: `subnet-dev-default` (10.0.1.0/24)
- **Private DNS Zone**: `dats-beeux-dev.internal`
- **Shared Storage**: `stdatsbeeuxdevcus5309` (Azure Files)

---

## 🌐 **DNS Configuration**

### **Private DNS Zone Records**
| DNS Name | Type | IP Address | Points To |
|----------|------|------------|-----------|
| `dats-beeux-dev-data.dats-beeux-dev.internal` | A | `10.0.1.4` | Data VM |
| `dats-beeux-dev-apps.dats-beeux-dev.internal` | A | `10.0.1.5` | Apps VM |
| `data.dats-beeux-dev.internal` | A | `10.0.1.4` | Data VM (Alias) |
| `apps.dats-beeux-dev.internal` | A | `10.0.1.5` | Apps VM (Alias) |
| `sccm-config-server.dats-beeux-dev.internal` | A | `10.0.1.4` | Config Server |
| `scsm-vault.dats-beeux-dev.internal` | A | `10.0.1.4` | HashiCorp Vault |
| `wcac-redis.dats-beeux-dev.internal` | A | `10.0.1.4` | Redis Cluster |
| `wdat-postgresql.dats-beeux-dev.internal` | A | `10.0.1.4` | PostgreSQL Cluster |
| `weda-rabbitmq.dats-beeux-dev.internal` | A | `10.0.1.4` | RabbitMQ Cluster |

---

## 🗄️ **DATA VM (dats-beeux-dev-data) - Infrastructure Services**

### **VM Details**
- **Public IP**: `52.182.154.41`
- **Private IP**: `10.0.1.4`
- **Internal FQDN**: `dats-beeux-dev-data.dats-beeux-dev.internal`
- **SSH Access**: `ssh <username>@52.182.154.41`
- **Password**: `<password>`

### **Running Services**

#### **📊 Database Services**
| Service | Internal FQDN | Port(s) | External Access | Purpose |
|---------|---------------|---------|-----------------|---------|
| **PostgreSQL Primary** | `wdat-postgresql.dats-beeux-dev.internal` | `5432` | `psql -h 52.182.154.41 -p 5432 -U <username>` | Main Database |
| **PostgreSQL Replica 1** | `wdat-postgresql.dats-beeux-dev.internal` | `5433` | `psql -h 52.182.154.41 -p 5433 -U <username>` | Read Replica |
| **PostgreSQL Replica 2** | `wdat-postgresql.dats-beeux-dev.internal` | `5434` | `psql -h 52.182.154.41 -p 5434 -U <username>` | Read Replica |

#### **🔴 Cache & Session Services**
| Service | Internal FQDN | Port(s) | External Access | Purpose |
|---------|---------------|---------|-----------------|---------|
| **Redis Primary** | `wcac-redis.dats-beeux-dev.internal` | `6379` | `redis-cli -h 52.182.154.41 -p 6379` | Primary Cache |
| **Redis Replica** | `wcac-redis.dats-beeux-dev.internal` | `6380` | `redis-cli -h 52.182.154.41 -p 6380` | Cache Replica |
| **Redis Cluster Manager** | `wcac-redis.dats-beeux-dev.internal` | `26379-26381` | Internal cluster management | Cluster Coordination |

#### **🐰 Message Broker Services**
| Service | Internal FQDN | Port(s) | External Access | Purpose |
|---------|---------------|---------|-----------------|---------|
| **RabbitMQ AMQP** | `weda-rabbitmq.dats-beeux-dev.internal` | `5672-5674` | AMQP client connection | Message Broker |
| **RabbitMQ Management** | `weda-rabbitmq.dats-beeux-dev.internal` | `15672-15674` | http://52.182.154.41:15672 | Web Management UI |

#### **🔐 Security & Configuration Services**
| Service | Internal FQDN | Port(s) | External Access | Purpose |
|---------|---------------|---------|-----------------|---------|
| **HashiCorp Vault** | `scsm-vault.dats-beeux-dev.internal` | `8200,8201` | https://52.182.154.41:8200 | Secrets Management |
| **Config Server** | `sccm-config-server.dats-beeux-dev.internal` | `8888,8889` | http://52.182.154.41:8888 | Configuration Service |

#### **📈 Monitoring & Admin Services**
| Service | Port | External Access | Purpose |
|---------|------|-----------------|---------|
| **Redis Admin** | `8083` | http://52.182.154.41:8083 | Redis Management UI |
| **HAProxy Stats** | `8404` | http://52.182.154.41:8404 | Load Balancer Statistics |
| **Admin Console** | `8888` | http://52.182.154.41:8888 | Primary Admin Interface |
| **Secondary Admin** | `8889` | http://52.182.154.41:8889 | Secondary Admin Interface |
| **Prometheus** | `9090` | http://52.182.154.41:9090 | Metrics Collection |
| **Monitoring Service** | `9121` | http://52.182.154.41:9121 | System Monitoring |
| **Debug Interface** | `9419` | http://52.182.154.41:9419 | Debug Console |
| **System Monitor** | `9999` | http://52.182.154.41:9999 | System Health Monitor |

---

## 🚀 **APPS VM (dats-beeux-dev-apps) - Kubernetes Platform**

### **VM Details**
- **Public IP**: `52.230.252.48`
- **Private IP**: `10.0.1.5`
- **Internal FQDN**: `dats-beeux-dev-apps.dats-beeux-dev.internal`
- **SSH Access**: `ssh <username>@52.230.252.48`
- **Password**: `<password>`
- **Kubernetes**: Minikube v1.28.3 on `192.168.49.2`

### **🌟 PRODUCTION EXTERNAL ACCESS**

#### **Primary Gateway (NGLB - Nginx Gateway Load Balancer)**
```
✅ **HTTPS Gateway**: https://52.230.252.48:8443
✅ **HTTP Gateway**:  http://52.230.252.48:8080
```

#### **🎯 Application Access Routes (via NGLB)**
| Application | URL | Purpose |
|-------------|-----|---------|
| **WEUI (End User Interface)** | https://52.230.252.48:8443/ | Main User Application |
| **WAUI (Admin Interface)** | https://52.230.252.48:8443/admin/ | Administrative Dashboard |
| **SWAG (API Documentation)** | https://52.230.252.48:8443/docs/ | API Documentation |
| **API Gateway** | https://52.230.252.48:8443/api/ | REST API Endpoints |
| **Security Gateway** | https://52.230.252.48:8443/gateway/ | Security Services |
| **Keycloak Authentication** | https://52.230.252.48:8443/auth/ | User Authentication |

### **🔧 Kubernetes Internal Services**

#### **Application Services (ClusterIP - Internal Only)**
| Service Name | Internal FQDN | Cluster IP | Ports | Purpose |
|--------------|---------------|------------|-------|---------|
| **NGLB Gateway** | `nglb-nginx-service.dats-beeux-dev.svc.cluster.local` | `10.103.102.205` | `80,443,8080` | Production Load Balancer |
| **WEUI** | `weui-end-user-interface-service.dats-beeux-dev.svc.cluster.local` | `10.98.68.113` | `8080,8443,9090` | End User Interface |
| **WAUI** | `waui-admin-interface-service.dats-beeux-dev.svc.cluster.local` | `10.111.241.164` | `8080,8443,9090,9091` | Admin Interface |
| **SWAG** | `swag-api-documentation-service.dats-beeux-dev.svc.cluster.local` | `10.110.101.159` | `8080,8443,9090` | API Documentation |
| **Keycloak** | `kiam-keycloak-service.dats-beeux-dev.svc.cluster.local` | `10.102.156.197` | `8080,8443,9000` | Authentication Service |
| **WAPI** | `wapi-service.dats-beeux-dev.svc.cluster.local` | `10.106.177.13` | `80` | Web API Service |
| **Security Gateway** | `scgc-service.dats-beeux-dev.svc.cluster.local` | `10.97.214.120` | `80,8080` | Security Gateway |
| **Postfix** | `pfix-postfix-service.dats-beeux-dev.svc.cluster.local` | `10.98.47.163` | `25,587` | Email Service |

#### **External Service References (K8s → Data VM)**
| Kubernetes Service | External FQDN Target | Purpose |
|--------------------|---------------------|---------|
| `scsm-vault-external-service` | `scsm-vault.dats-beeux-dev.internal:8200` | Vault Access |
| `sccm-config-server-external-service` | `sccm-config-server.dats-beeux-dev.internal:8888` | Config Server |
| `wcac-redis-cluster-external-service` | `wcac-redis.dats-beeux-dev.internal:6379,6380,6381` | Redis Cluster |
| `wdat-postgres-primary-external-service` | `wdat-postgresql.dats-beeux-dev.internal:5432` | Primary DB |
| `wdat-postgres-secondary-external-service` | `wdat-postgresql.dats-beeux-dev.internal:5433` | Secondary DB |
| `weda-rabbitmq-external-service` | `weda-rabbitmq.dats-beeux-dev.internal:5672,15672` | Message Broker |

#### **Ingress Controllers**
| Service | Type | External Access | Internal IP | Purpose |
|---------|------|-----------------|-------------|---------|
| **Primary Ingress** | NodePort | `http://52.230.252.48:32680`, `https://52.230.252.48:30603` | `10.101.131.5` | Standard Ingress |
| **NGLB External** | NodePort | `http://52.230.252.48:30080`, `https://52.230.252.48:30443` | `10.110.45.232` | NGLB External Access |

---

## 🔒 **Security & Access Configuration**

### **Network Security Groups (NSG)**
- **NSG Name**: `nsg-dev-ubuntu-vm`
- **Applied To**: `subnet-dev-default`

#### **Access Rules**
| Rule Name | Priority | Source | Destination Ports | Purpose |
|-----------|----------|--------|-------------------|---------|
| `AllowLaptopSpecificIP` | 900 | `136.56.79.92/32` | All service ports | Laptop Access |
| `AllowLocalWiFiSubnet` | 901 | `192.168.86.0/24` | All service ports | WiFi Network Access |

#### **Allowed Ports**
```
SSH: 22
HTTP/HTTPS: 80, 443
Applications: 3000, 3001
RabbitMQ: 4369, 5670-5674, 15670-15674, 25672
PostgreSQL: 5432-5434
Redis: 6379-6380, 26379-26381
Services: 8080, 8083, 8200-8201, 8404, 8443, 8888-8889
Monitoring: 9090-9091, 9121, 9419, 9999
NodePorts: 30000-32767
```

### **Authentication**
- **VM User**: `<username>`
- **VM Password**: `<password>`
- **PostgreSQL User**: `<username>`
- **PostgreSQL Password**: `<password>`

---

## 🛠️ **Connection Examples**

### **From Your Laptop (External Access)**

#### **Web Interfaces**
```bash
# Main Application
curl https://52.230.252.48:8443/

# Admin Interface
curl https://52.230.252.48:8443/admin/

# API Documentation
curl https://52.230.252.48:8443/docs/

# Vault Management
curl https://52.182.154.41:8200

# RabbitMQ Management
curl http://52.182.154.41:15672

# Redis Admin
curl http://52.182.154.41:8083

# HAProxy Stats
curl http://52.182.154.41:8404
```

#### **Database Connections**
```bash
# PostgreSQL Primary
psql -h 52.182.154.41 -p 5432 -U <username> -d postgres

# PostgreSQL Replica
psql -h 52.182.154.41 -p 5433 -U <username> -d postgres

# Redis Primary
redis-cli -h 52.182.154.41 -p 6379

# Redis Replica
redis-cli -h 52.182.154.41 -p 6380
```

#### **SSH Access**
```bash
# Data VM
ssh <username>@52.182.154.41

# Apps VM
ssh <username>@52.230.252.48
```

### **From Within Infrastructure (Internal Access)**

#### **Service-to-Service Communication**
```bash
# From Apps VM to Data VM services
curl http://scsm-vault.dats-beeux-dev.internal:8200
curl http://sccm-config-server.dats-beeux-dev.internal:8888
curl http://wdat-postgresql.dats-beeux-dev.internal:5432
curl http://wcac-redis.dats-beeux-dev.internal:6379

# Within Kubernetes cluster
curl http://weui-end-user-interface-service.dats-beeux-dev.svc.cluster.local:8080
curl http://nglb-nginx-service.dats-beeux-dev.svc.cluster.local:80
```

---

## 📊 **Architecture Overview**

### **Production-Grade Design**
```
Internet → Azure Load Balancer → NSG → VMs
    ↓
[Apps VM] → [NGLB Gateway] → [Internal Services]
    ↓                           ↓
[Kubernetes Platform]    [External References]
    ↓                           ↓
[Application Services]   [Data VM Infrastructure]
```

### **Key Features**
- ✅ **Security**: No direct backend exposure
- ✅ **Scalability**: Multi-replica ready architecture
- ✅ **Performance**: Connection pooling, load balancing
- ✅ **Monitoring**: Health checks, metrics collection
- ✅ **SSL**: End-to-end encryption
- ✅ **High Availability**: Multi-zone deployment in Zone 1
- ✅ **Service Discovery**: Private DNS + Kubernetes DNS
- ✅ **Shared Storage**: Azure Files for persistent data

---

## 🚨 **Troubleshooting**

### **Common Issues**
1. **Cannot access services**: Check NSG rules and UFW status
2. **DNS resolution fails**: Verify private DNS zone configuration
3. **Kubernetes services not accessible**: Check port-forward status
4. **Database connection refused**: Verify PostgreSQL is running and accepting connections

### **Useful Commands**
```bash
# Check service status on Data VM
ssh <username>@52.182.154.41 "ss -tlnp | grep LISTEN"

# Check Kubernetes services
ssh <username>@52.230.252.48 "kubectl get services --all-namespaces"

# Check port-forward status
ssh <username>@52.230.252.48 "ps aux | grep port-forward"

# Test internal connectivity
ssh <username>@52.230.252.48 "curl -I http://192.168.49.2:31765"
```

### **Port Forward Management**
The current external access uses kubectl port-forward:
```bash
# Running port-forward processes
kubectl port-forward --address 0.0.0.0 -n dats-beeux-dev svc/nglb-nginx-service 8080:80 8443:443
```

---

## 📝 **Maintenance Notes**

### **Infrastructure State**
- All VMs deployed in **Zone 1** (migrated from Zone 2)
- Security vulnerabilities fixed (no hardcoded credentials)
- UFW firewall disabled for external access
- IP forwarding enabled for NodePort access
- Shared storage properly mounted

### **Recent Changes**
- ✅ Migrated VMs from Zone 2 to Zone 1
- ✅ Fixed Azure Files security (removed hardcoded access key)
- ✅ Configured comprehensive NSG rules for laptop access
- ✅ Set up production-grade NGLB with multi-replica support
- ✅ Enabled external access via kubectl port-forward
- ✅ **Upgraded Apps VM to Standard_B4ms (4 vCPU, 16GB RAM)** - September 28, 2025

### **Backup & Recovery**
- VM snapshots taken before zone migration
- Azure Files provides persistent storage across VM restarts
- Private DNS zone configuration backed up in Bicep templates

---

**🎯 All services are operational and accessible from external laptop via the configured access points!**