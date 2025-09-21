# dats-beeux-dev VM Service Access Guide

## VM Details
- **Name**: dats-beeux-dev
- **Public IP**: 172.191.147.143
- **Private IP**: 10.0.1.4
- **Size**: Standard_B4ms (16GB RAM, 4 vCPUs)
- **SSH Access**: `ssh dats-beeux-dev`

## Database Services

### PostgreSQL
Multiple instances running:
- **Primary**: `172.191.147.143:5432`
- **Secondary**: `172.191.147.143:5433`
- **Tertiary**: `172.191.147.143:5434`

**Connection Examples:**
```bash
# Using psql
psql -h 172.191.147.143 -p 5432 -U username -d database_name

# Using connection string
postgresql://username:password@172.191.147.143:5432/database_name
```

### MySQL
- **Port**: `172.191.147.143:3306`

**Connection Example:**
```bash
mysql -h 172.191.147.143 -P 3306 -u username -p
```

## Caching Services

### Redis
- **Primary**: `172.191.147.143:6379`
- **Secondary**: `172.191.147.143:6380`

### Redis Sentinel (High Availability)
- **Sentinel 1**: `172.191.147.143:26379`
- **Sentinel 2**: `172.191.147.143:26380`
- **Sentinel 3**: `172.191.147.143:26381`

**Connection Examples:**
```bash
# Redis CLI
redis-cli -h 172.191.147.143 -p 6379

# With authentication
redis-cli -h 172.191.147.143 -p 6379 -a your_password
```

## Message Queue Services

### RabbitMQ
**AMQP Ports:**
- `172.191.147.143:5670`
- `172.191.147.143:5671`
- `172.191.147.143:5672`
- `172.191.147.143:5673`
- `172.191.147.143:5674`

**Management UI Ports:**
- **Primary Management**: `http://172.191.147.143:15672`
- **Additional Management**: `172.191.147.143:15670`, `172.191.147.143:15673`, `172.191.147.143:15674`

**Access Management UI:**
Open in browser: `http://172.191.147.143:15672`

## Security & Secrets

### HashiCorp Vault
- **UI/API**: `http://172.191.147.143:8200`

**Access Vault UI:**
Open in browser: `http://172.191.147.143:8200`

## Development Applications

### Application Services
- **Service 1**: `172.191.147.143:8083`
- **Service 2**: `172.191.147.143:8404`
- **Service 3**: `172.191.147.143:9121`
- **Service 4**: `172.191.147.143:9419`
- **Service 5**: `172.191.147.143:9999`

### Common Development Ports
The following ports are also available for development use:
- `172.191.147.143:4000` / `172.191.147.143:4001` (Phoenix/Elixir apps)
- `172.191.147.143:8000` / `172.191.147.143:8001` (Django/FastAPI apps)

## Monitoring & Observability Services

### Prometheus & Monitoring Stack
- **Prometheus**: `http://172.191.147.143:9090`
- **Prometheus Pushgateway**: `http://172.191.147.143:9091`
- **Alertmanager**: `http://172.191.147.143:9093`
- **Node Exporter**: `http://172.191.147.143:9100`
- **Blackbox Exporter**: `http://172.191.147.143:9115`
- **Postgres Exporter**: `http://172.191.147.143:9187`
- **Grafana Loki**: `http://172.191.147.143:3100`

### Dashboard Services
- **Grafana**: `http://172.191.147.143:3000`
- **Secondary Grafana**: `http://172.191.147.143:3001`
- **Dashboard Services**: `172.191.147.143:8080`, `172.191.147.143:8081`
- **Alternative Dashboards**: `172.191.147.143:9000`, `172.191.147.143:9001`

## Kubernetes Services

### Kubernetes Web Applications (Internet Accessible)
**Direct Internet Access via Port 8080:**
- **WEUI Frontend**: `http://172.191.147.143:8080`
- **API Gateway**: `http://172.191.147.143:8080/api`  
- **Health Check**: `http://172.191.147.143:8080/health`

**Service Details:**
- **BeEux Word Learning Platform** - End User Interface (WEUI)
- **Phase 5 Deployment** - Connected to SCGC API Gateway
- **Real-time Health Monitoring** via `/health` endpoint

### Kubernetes Infrastructure
- **Kubernetes Dashboard**: `http://172.191.147.143:8090`
- **NodePort Services**: 
  - `172.191.147.143:30000`
  - `172.191.147.143:30001`
  - `172.191.147.143:30080`
  - `172.191.147.143:30443`
- **Custom Services**: `172.191.147.143:32000`

## Additional Development Tools

### pgAdmin & Database Tools
- **pgAdmin**: `http://172.191.147.143:5050`
- **Database Tools**: `172.191.147.143:5555`

### Development Servers
- **Flask/Django Dev**: `172.191.147.143:5000`, `172.191.147.143:5001`
- **Alternative Dev Servers**: `172.191.147.143:7000`, `172.191.147.143:7001`
- **Jupyter/Notebook**: `172.191.147.143:8888`, `172.191.147.143:8889`
- **Custom Services**: `172.191.147.143:9900`

## Web Services
- **HTTP**: `http://172.191.147.143:80`
- **HTTPS**: `https://172.191.147.143:443`

## Security Configuration

All ports are configured with Network Security Group rules that:
- **Restrict access** to your WiFi network: `192.168.86.0/24` (entire WiFi network)
- **Block** all other internet traffic to these services
- **Allow** SSH access from anywhere (port 22)

### Port Categories Configured:
1. **Database Services**: PostgreSQL (5432-5434), MySQL (3306), Redis (6379-6380), Redis Sentinel (26379-26381)
2. **Message Queue**: RabbitMQ (5670-5674), RabbitMQ Management (15670-15674)
3. **Security**: HashiCorp Vault (8200)
4. **Development Apps**: Various applications (8083, 8404, 9121, 9419, 9999)
5. **Common Development**: Phoenix/Elixir (4000-4001), Django/FastAPI (8000-8001)
6. **Monitoring Stack**: Prometheus (9090-9093), Exporters (9100, 9115, 9187), Loki (3100)
7. **Dashboard Services**: Grafana (3000-3001), Web UIs (8080-8081, 9000-9001)
8. **Kubernetes**: Dashboard (8090), NodePort range (30000-30443), Custom (32000)
9. **Additional Tools**: pgAdmin (5050), Flask/Django dev (5000-5001), Dev servers (7000-7001), Jupyter (8888-8889), Custom (9900)
10. **DNS Services**: Port 53 for development DNS queries

### WiFi Network Access
**Any device on your WiFi network (192.168.86.x) can now access all services!**
- Smartphones, tablets, laptops on the same WiFi
- Testing from different devices on your network
- Collaborative development access for team members on your WiFi

## Quick Test Commands

### Test Connectivity (PowerShell)
```powershell
# Test PostgreSQL
Test-NetConnection 172.191.147.143 -Port 5432

# Test RabbitMQ Management
Test-NetConnection 172.191.147.143 -Port 15672

# Test Vault
Test-NetConnection 172.191.147.143 -Port 8200

# Test Redis
Test-NetConnection 172.191.147.143 -Port 6379

# Test Kubernetes Ingress (requires SSH tunnel)
Test-NetConnection localhost -Port 30214
```

### Test Web Services
```bash
# Test basic HTTP connectivity
curl http://172.191.147.143:8200/v1/sys/health

# Test RabbitMQ Management (requires credentials)
curl http://172.191.147.143:15672/api/overview

# Test Kubernetes services (via SSH tunnel)
curl http://localhost:30214
curl http://localhost:30214/health
curl http://localhost:30214/api
```

### SSH Tunnel Setup for Kubernetes Services
```bash
# Create tunnels for all Kubernetes web applications
ssh -L 30214:192.168.49.2:30214 -L 30500:192.168.49.2:30500 dats-beeux-dev

# Keep tunnel open and access from browser:
# http://localhost:30214 - WEUI Frontend
# http://localhost:30214/api - API Gateway  
# http://localhost:30214/health - Health Check
```

## Monthly Cost Estimate
- **Total**: $128.91/month (if running 24/7)
  - VM Compute (Standard_B4ms): $119.20/month
  - Storage (30GB Premium SSD): $6.14/month
  - Public IP (Static): $3.65/month

## Network Architecture
- **Resource Group**: rg-dev-eastus
- **Virtual Network**: vnet-dev-eastus
- **Subnet**: 10.0.1.0/24
- **Network Security Group**: nsg-dev-ubuntu-vm
- **Availability Zone**: 2

---

**Note**: This VM contains your complete development environment with all data preserved from the previous instance. All services are now accessible from your local machine through the configured security rules.