# VM1 Resize Plan: Standard_B4ms → Standard_B2ms

## 🎯 Resize Overview

**Current Configuration:**
- VM: dats-beeux-dev
- Size: Standard_B4ms (4 vCPU, 16GB RAM)
- Status: Running with active services

**Target Configuration:**
- Size: Standard_B2ms (2 vCPU, 8GB RAM)
- **Monthly Savings:** $59.53 ($119.20 → $59.67)

## ⚠️ Important Considerations

### Memory Impact
- **Current:** 16GB RAM
- **After Resize:** 8GB RAM
- **Risk:** Services may struggle with reduced memory

### CPU Impact  
- **Current:** 4 vCPU
- **After Resize:** 2 vCPU
- **Risk:** Performance degradation for CPU-intensive tasks

### Service Assessment Needed
Before resizing, we should check current resource usage:
```bash
# Check current memory usage
ssh dats-beeux-dev "free -h"

# Check current CPU usage
ssh dats-beeux-dev "top -bn1 | head -20"

# Check running services
ssh dats-beeux-dev "docker ps"
ssh dats-beeux-dev "systemctl list-units --type=service --state=running"
```

## 🚀 Resize Process

### Option 1: Direct Resize (Fastest)
```bash
# Stop VM
az vm stop --resource-group rg-dev-eastus --name dats-beeux-dev

# Resize VM
az vm resize --resource-group rg-dev-eastus --name dats-beeux-dev --size Standard_B2ms

# Start VM
az vm start --resource-group rg-dev-eastus --name dats-beeux-dev
```

**Downtime:** ~5-10 minutes

### Option 2: Infrastructure Update
Update Bicep templates and redeploy (preserves configuration as code)

## 📊 Service Impact Assessment

### High Memory Services (Potential Issues)
- **PostgreSQL databases** (multiple instances)
- **Redis caching** (memory-intensive)
- **Kubernetes cluster** (minikube + pods)
- **Development applications**

### Recommendation
**Test with current services first:**
1. Check current resource usage
2. Identify high-usage services  
3. Consider scaling down services if needed
4. Perform resize during low-usage period

## 💰 Cost Impact

### Before Resize
- VM1: $119.20/month
- VM2: $59.67/month  
- **Total:** $178.87/month

### After Resize
- VM1: $59.67/month
- VM2: $59.67/month
- **Total:** $119.34/month
- **Monthly Savings:** $59.53

## 🎯 Recommended Approach

**Phase 1: Assessment (Do Now)**
```bash
# Check current resource usage
ssh dats-beeux-dev "htop -n 1"
ssh dats-beeux-dev "df -h"
ssh dats-beeux-dev "docker stats --no-stream"
```

**Phase 2: Resize (Schedule)**
- Plan during low-usage period
- Backup critical data first
- Resize VM1 to Standard_B2ms
- Monitor performance after resize

**Phase 3: Optimization (If Needed)**
- Optimize services for lower memory
- Consider moving some services to VM2
- Scale services based on actual usage

This approach ensures we don't break your running development environment while achieving cost savings.