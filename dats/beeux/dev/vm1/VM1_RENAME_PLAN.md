# VM1 Rename Plan: dats-beeux-dev → dats-beeux-dev-data

## ⚠️ Critical Considerations

**Current State:**
- VM1 is **running** with active services and data
- SSH access configured as `dats-beeux-dev`
- Public IP: 172.191.147.143
- Contains all your development data and services

**Rename Impact:**
- SSH connection name will change
- Internal hostname changes
- Configuration files need updates
- Potential service disruption

## 🔄 Rename Options

### Option 1: In-Place Rename (Recommended)
**Pros:** Preserves all data, minimal downtime
**Cons:** More complex process

**Steps:**
1. Update Azure VM name in portal/CLI
2. Update internal hostname 
3. Update SSH config
4. Update documentation

### Option 2: Deploy New VM with Correct Name
**Pros:** Clean deployment with correct name
**Cons:** Requires data migration, more complex

## 📋 Detailed Rename Process (Option 1)

### Phase 1: Preparation
- [ ] Backup current VM configuration
- [ ] Document current SSH setup
- [ ] Test current services status
- [ ] Schedule maintenance window

### Phase 2: Azure Resource Rename
```bash
# Stop VM safely
az vm stop --resource-group rg-dev-eastus --name dats-beeux-dev

# Note: Azure doesn't support direct VM name changes
# We need to create new VM with correct name and swap disks
```

### Phase 3: Internal System Updates
```bash
# Update hostname inside VM
sudo hostnamectl set-hostname dats-beeux-dev-data

# Update /etc/hosts
sudo sed -i 's/dats-beeux-dev/dats-beeux-dev-data/g' /etc/hosts

# Update SSH host key identification
```

### Phase 4: Configuration Updates
- [ ] Update SSH config entries
- [ ] Update documentation references
- [ ] Update monitoring configurations
- [ ] Update backup scripts

## ⚠️ Recommended Approach

**Given the complexity and current running state, I recommend:**

1. **Keep VM1 as-is for now** - It's working and has your data
2. **Deploy VM2 as `dats-beeux-dev-apps`** - Clean deployment
3. **Plan VM1 rename for later** when we have time for proper maintenance

This allows you to:
- ✅ Get VM2 running immediately  
- ✅ Avoid disrupting current development work
- ✅ Plan VM1 rename during scheduled downtime

## 🎯 Immediate Action Plan

**For Now:**
- VM1: Keep as `dats-beeux-dev` (rename later)
- VM2: Deploy as `dats-beeux-dev-apps` (ready now)

**Later (Scheduled Maintenance):**
- Plan proper VM1 rename to `dats-beeux-dev-data`
- Consider creating new infrastructure with correct names
- Migrate data if needed

This approach minimizes risk and allows immediate progress on VM2.