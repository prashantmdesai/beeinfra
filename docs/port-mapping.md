# Port Mapping Reference

This document provides a comprehensive reference of all ports accessible on the Azure infrastructure from your laptop and WiFi network.

## Overview

All 5 VMs are configured with Network Security Group (NSG) rules that allow **full access** from:
- **Your Laptop IP**: Complete access to all ports
- **Your WiFi Network**: Complete access to all ports

This configuration is designed for development and testing purposes. **Production environments should implement more restrictive firewall rules.**

## Access Configuration

### Source IPs Allowed

The NSG is configured to allow traffic from:
1. **Your specific laptop IP address** (configured in tfvars)
2. **Your WiFi network range** (derived from your laptop IP)

### Security Notes

⚠️ **Important Security Considerations**:
- This is a **development** configuration with permissive access
- All ports are accessible from your laptop and WiFi network
- **Not recommended for production use**
- Consider implementing least-privilege access for production
- Monitor access logs regularly

## Port Categories

### 1. System Management Ports

| Port | Protocol | Service | Purpose | Access Level |
|------|----------|---------|---------|--------------|
| 22 | TCP | SSH | Remote shell access | Your IPs only |
| 3389 | TCP | RDP | Remote Desktop (if needed) | Your IPs only |

**Usage**:
```bash
# SSH to any VM
ssh beeuser@<vm-public-ip>

# SSH to master node
ssh beeuser@<master-public-ip>

# SSH to specific worker
ssh beeuser@<worker-public-ip>
```

---

### 2. Kubernetes Control Plane Ports

| Port | Protocol | Service | Purpose | Access Level |
|------|----------|---------|---------|--------------|
| 6443 | TCP | Kubernetes API | API server access | Your IPs only |
| 2379-2380 | TCP | etcd | Cluster datastore | Your IPs only |
| 10250 | TCP | Kubelet API | Node management | Your IPs only |
| 10251 | TCP | kube-scheduler | Scheduler health | Your IPs only |
| 10252 | TCP | kube-controller-manager | Controller health | Your IPs only |
| 10257 | TCP | kube-controller-manager (secure) | Controller metrics | Your IPs only |
| 10259 | TCP | kube-scheduler (secure) | Scheduler metrics | Your IPs only |

**Usage**:
```bash
# Access Kubernetes API (from master node or with kubeconfig)
kubectl get nodes

# Check API server health
curl -k https://<master-ip>:6443/healthz

# Check component status
kubectl get componentstatuses
```

---

### 3. Kubernetes Worker Node Ports

| Port | Protocol | Service | Purpose | Access Level |
|------|----------|---------|---------|--------------|
| 10250 | TCP | Kubelet API | Node management | Your IPs only |
| 30000-32767 | TCP | NodePort Services | External access to services | Your IPs only |

**Usage**:
```bash
# Access NodePort service
curl http://<any-node-ip>:30080

# List NodePort services
kubectl get services --all-namespaces | grep NodePort
```

---

### 4. Calico CNI Ports

| Port | Protocol | Service | Purpose | Access Level |
|------|----------|---------|---------|--------------|
| 179 | TCP | BGP | Calico routing | Your IPs only |
| 5473 | TCP | Typha | Calico dataplane | Your IPs only |
| 4789 | UDP | VXLAN | Overlay networking | Your IPs only |

**Usage**:
- These ports are used internally by Calico
- No direct user interaction required
- Monitor with `calicoctl` commands

---

### 5. Container Runtime Ports

| Port | Protocol | Service | Purpose | Access Level |
|------|----------|---------|---------|--------------|
| 2375 | TCP | Docker API (insecure) | Container management | Your IPs only |
| 2376 | TCP | Docker API (secure) | Container management | Your IPs only |

**Note**: Using containerd, Docker ports may not be active.

---

### 6. Common Application Ports

These ports are available for your applications:

| Port | Protocol | Service | Typical Use | Access Level |
|------|----------|---------|-------------|--------------|
| 80 | TCP | HTTP | Web applications | Your IPs only |
| 443 | TCP | HTTPS | Secure web applications | Your IPs only |
| 8080 | TCP | HTTP | Alternative web port | Your IPs only |
| 8443 | TCP | HTTPS | Alternative secure port | Your IPs only |
| 3000 | TCP | HTTP | Development servers | Your IPs only |
| 4200 | TCP | HTTP | Angular dev server | Your IPs only |
| 5000 | TCP | HTTP | Flask/Python apps | Your IPs only |
| 8000 | TCP | HTTP | Django apps | Your IPs only |
| 9000 | TCP | HTTP | Various apps | Your IPs only |

**Usage**:
```bash
# Access application via NodePort
kubectl expose deployment myapp --type=NodePort --port=80

# Get NodePort assigned
kubectl get service myapp

# Access from laptop
curl http://<any-node-ip>:<nodeport>
```

---

### 7. Database Ports

| Port | Protocol | Service | Database | Access Level |
|------|----------|---------|----------|--------------|
| 3306 | TCP | MySQL/MariaDB | MySQL database | Your IPs only |
| 5432 | TCP | PostgreSQL | PostgreSQL database | Your IPs only |
| 6379 | TCP | Redis | Redis cache | Your IPs only |
| 27017 | TCP | MongoDB | MongoDB database | Your IPs only |
| 9042 | TCP | Cassandra | Cassandra database | Your IPs only |
| 1433 | TCP | SQL Server | Microsoft SQL Server | Your IPs only |

**Usage**:
```bash
# Connect to MySQL
mysql -h <vm-ip> -u user -p

# Connect to PostgreSQL
psql -h <vm-ip> -U user -d database

# Connect to Redis
redis-cli -h <vm-ip>

# Connect to MongoDB
mongo <vm-ip>:27017
```

---

### 8. Monitoring and Metrics Ports

| Port | Protocol | Service | Purpose | Access Level |
|------|----------|---------|---------|--------------|
| 9090 | TCP | Prometheus | Metrics collection | Your IPs only |
| 3000 | TCP | Grafana | Metrics visualization | Your IPs only |
| 9100 | TCP | Node Exporter | Node metrics | Your IPs only |
| 9093 | TCP | Alertmanager | Alert management | Your IPs only |
| 9115 | TCP | Blackbox Exporter | Endpoint monitoring | Your IPs only |

**Usage**:
```bash
# Access Prometheus
open http://<vm-ip>:9090

# Access Grafana
open http://<vm-ip>:3000
```

---

### 9. Logging Ports

| Port | Protocol | Service | Purpose | Access Level |
|------|----------|---------|---------|--------------|
| 5601 | TCP | Kibana | Log visualization | Your IPs only |
| 9200 | TCP | Elasticsearch | Log storage | Your IPs only |
| 5044 | TCP | Logstash | Log processing | Your IPs only |
| 24224 | TCP | Fluentd | Log forwarding | Your IPs only |

**Usage**:
```bash
# Access Kibana
open http://<vm-ip>:5601

# Query Elasticsearch
curl http://<vm-ip>:9200/_cluster/health
```

---

### 10. Message Queue Ports

| Port | Protocol | Service | Purpose | Access Level |
|------|----------|---------|---------|--------------|
| 5672 | TCP | RabbitMQ | AMQP protocol | Your IPs only |
| 15672 | TCP | RabbitMQ Management | Web UI | Your IPs only |
| 9092 | TCP | Kafka | Message broker | Your IPs only |
| 2181 | TCP | Zookeeper | Kafka coordination | Your IPs only |

**Usage**:
```bash
# Access RabbitMQ Management UI
open http://<vm-ip>:15672
```

---

### 11. Development Tools Ports

| Port | Protocol | Service | Purpose | Access Level |
|------|----------|---------|---------|--------------|
| 8888 | TCP | Jupyter | Notebooks | Your IPs only |
| 9000 | TCP | SonarQube | Code quality | Your IPs only |
| 8081 | TCP | Nexus | Artifact repository | Your IPs only |
| 5000 | TCP | Docker Registry | Image registry | Your IPs only |

---

### 12. Custom Application Ports

All other ports (1-65535) are accessible from your IPs. You can use any available port for your custom applications.

**Available Port Ranges**:
- **1-1023**: Well-known ports (requires root)
- **1024-49151**: Registered ports
- **49152-65535**: Dynamic/private ports

---

## NSG Rules Summary

The Network Security Group contains approximately **32 rules** allowing access from your IPs:

### Inbound Rules (Your IPs → VMs)

1. **AllowSSH**: Port 22 (Priority 100)
2. **AllowKubernetesAPI**: Port 6443 (Priority 110)
3. **AllowKubelet**: Port 10250 (Priority 120)
4. **AllowEtcd**: Ports 2379-2380 (Priority 130)
5. **AllowNodePort**: Ports 30000-32767 (Priority 140)
6. **AllowHTTP**: Port 80 (Priority 150)
7. **AllowHTTPS**: Port 443 (Priority 160)
8. **AllowCalicoBGP**: Port 179 (Priority 170)
9. **AllowCalicoTypha**: Port 5473 (Priority 180)
10. **AllowVXLAN**: Port 4789 UDP (Priority 190)
11-32. **AllowCustomPorts**: Various application ports

### Outbound Rules (VMs → Internet)

- **AllowAllOutbound**: All traffic allowed (default)

---

## VM-Specific Port Access

### Master Node (vm1-infr1-dev - 10.0.1.4)

**Required Ports**:
- SSH (22): Remote access
- Kubernetes API (6443): Cluster management
- etcd (2379-2380): Cluster state
- kubelet (10250): Node management
- Scheduler (10251, 10259): Scheduling
- Controller Manager (10252, 10257): Controllers

**Usage**:
```bash
# SSH to master
ssh beeuser@<master-public-ip>

# Access Kubernetes API
kubectl --server=https://<master-public-ip>:6443 get nodes

# Port forward to pod
kubectl port-forward pod/mypod 8080:80
```

### Worker Nodes (vm2-5)

**Required Ports**:
- SSH (22): Remote access
- kubelet (10250): Node management
- NodePort (30000-32767): Service access
- Application ports: As configured

**Usage**:
```bash
# SSH to worker
ssh beeuser@<worker-public-ip>

# Access NodePort service
curl http://<worker-public-ip>:30080
```

---

## Port Testing

### Test Connectivity from Laptop

```bash
# Test SSH
ssh -v beeuser@<vm-ip>

# Test specific port
nc -zv <vm-ip> 6443

# Test port with telnet
telnet <vm-ip> 6443

# Test HTTP port
curl http://<vm-ip>:80

# Scan ports (use responsibly)
nmap -p 22,6443,10250 <vm-ip>
```

### Test from Within Cluster

```bash
# SSH to master
ssh beeuser@<master-ip>

# Test connectivity to worker
nc -zv 10.0.1.5 10250

# Test pod network
kubectl run test --image=busybox -it --rm -- wget -O- http://service-name
```

---

## Security Hardening (Production)

For production deployments, implement these restrictions:

### 1. Limit SSH Access

```hcl
# Only allow SSH from specific IPs
security_rule {
  name                       = "AllowSSH"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "YOUR_SPECIFIC_IP/32"
  destination_address_prefix = "*"
}
```

### 2. Restrict API Access

```hcl
# Limit Kubernetes API to VPN or specific IPs
security_rule {
  name                       = "AllowKubernetesAPI"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "6443"
  source_address_prefix      = "VPN_IP_RANGE"
  destination_address_prefix = "*"
}
```

### 3. Use Private Cluster

- Place master node behind load balancer
- Use Azure Bastion for SSH access
- Implement VPN for cluster access
- Remove public IPs from worker nodes

### 4. Application-Level Security

- Use network policies in Kubernetes
- Implement service mesh (Istio, Linkerd)
- Enable TLS for all services
- Use certificate management (cert-manager)

---

## Troubleshooting Port Access

### Cannot Connect to Port

**Check NSG Rules**:
```bash
az network nsg rule list \
  --resource-group dats-beeux-dev-rg \
  --nsg-name dats-beeux-dev-nsg \
  --output table
```

**Check VM Firewall**:
```bash
# SSH to VM
ssh beeuser@<vm-ip>

# Check firewall status (if enabled)
sudo ufw status

# Check listening ports
sudo netstat -tlnp
sudo ss -tlnp
```

**Check Service Status**:
```bash
# Check if service is running
sudo systemctl status <service-name>

# Check Kubernetes service
kubectl get service <service-name>
```

### Port Already in Use

```bash
# Find process using port
sudo lsof -i :8080
sudo netstat -tlnp | grep 8080

# Kill process
sudo kill <PID>
```

### Kubernetes Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints <service-name>

# Check pod status
kubectl get pods -l app=<app-name>

# Check service type
kubectl get service <service-name> -o yaml
```

---

## Related Documentation

- [Architecture](./architecture.md) - Infrastructure architecture
- [Deployment Guide](./deployment-guide.md) - Deployment instructions
- [Troubleshooting](./troubleshooting.md) - Common issues
- [Best Practices](./best-practices.md) - Security and standards

---

**Last Updated**: 2025-10-08  
**Version**: 1.0.0  
**Maintainer**: Infrastructure Team
