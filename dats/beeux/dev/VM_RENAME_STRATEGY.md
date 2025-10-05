# VM Renaming Strategy: dats-beeux-dev-* → dats-beeux-*-dev

## 🎯 Objective
Rename existing VMs to follow the new naming convention:
- `dats-beeux-dev-data` → `dats-beeux-data-dev`  
- `dats-beeux-dev-apps` → `dats-beeux-apps-dev`

## 🔍 Current State Analysis

### Current VMs (Central US)
| VM Name | Current Public IP | Current Private IP | Role | Zone |
|---------|-------------------|--------------------|----- |------|
| `dats-beeux-dev-data` | 52.182.154.41 | 10.0.1.4 | Data Services | 1 |
| `dats-beeux-dev-apps` | 52.230.252.48 | 10.0.1.5 | Kubernetes Apps | 1 |

### Target State
| VM Name | Target Public IP | Target Private IP | Role | Zone |
|---------|------------------|--------------------|----- |------|
| `dats-beeux-data-dev` | 52.182.154.41 | 10.0.1.4 | Data Services | 1 |
| `dats-beeux-apps-dev` | 52.230.252.48 | 10.0.1.5 | Kubernetes Apps | 1 |
| `dats-beeux-infr-dev` | TBD | 10.0.1.6 | Kubernetes Master | 3 |

## 🛠️ Renaming Approaches

### Option 1: Azure Resource Renaming (Complex)
**Pros**: Complete resource name change
**Cons**: Complex, risky, involves recreating resources
**Timeline**: 2-3 hours with downtime

### Option 2: Computer Name Only (Simple) ⭐ RECOMMENDED
**Pros**: No resource recreation, minimal risk, no IP changes
**Cons**: Azure resource names remain the same
**Timeline**: 30 minutes with minimal downtime

### Option 3: DNS Alias Approach (Alternative)
**Pros**: No VM changes, flexible naming
**Cons**: Doesn't change actual VM names
**Timeline**: 15 minutes, no downtime

## ✅ Recommended Approach: Option 2 (Computer Name Change)

### Why This Approach?
1. **Minimal Risk**: No resource recreation required
2. **IP Preservation**: All IP addresses remain the same
3. **Service Continuity**: Minimal impact on running services
4. **Quick Execution**: Can be done during maintenance window

### Implementation Steps

#### Step 1: Backup Current State
```bash
# Document current configuration
az vm show --resource-group rg-dev-centralus --name dats-beeux-dev-data
az vm show --resource-group rg-dev-centralus --name dats-beeux-dev-apps

# Create VM snapshots (optional but recommended)
az snapshot create --resource-group rg-dev-centralus \
  --name dats-beeux-dev-data-snapshot-$(date +%Y%m%d) \
  --source dats-beeux-dev-data-osdisk

az snapshot create --resource-group rg-dev-centralus \
  --name dats-beeux-dev-apps-snapshot-$(date +%Y%m%d) \
  --source dats-beeux-dev-apps-osdisk
```

#### Step 2: Change Computer Names (SSH to each VM)

**For Data VM (dats-beeux-dev-data → dats-beeux-data-dev):**
```bash
# SSH to data VM
ssh beeuser@52.182.154.41

# Change hostname
sudo hostnamectl set-hostname dats-beeux-data-dev

# Update /etc/hosts
sudo sed -i 's/dats-beeux-dev-data/dats-beeux-data-dev/g' /etc/hosts

# Update /etc/hostname (if needed)
echo "dats-beeux-data-dev" | sudo tee /etc/hostname

# Reboot to apply changes
sudo reboot
```

**For Apps VM (dats-beeux-dev-apps → dats-beeux-apps-dev):**
```bash  
# SSH to apps VM
ssh beeuser@52.230.252.48

# Change hostname
sudo hostnamectl set-hostname dats-beeux-apps-dev

# Update /etc/hosts
sudo sed -i 's/dats-beeux-dev-apps/dats-beeux-apps-dev/g' /etc/hosts

# Update /etc/hostname (if needed)
echo "dats-beeux-apps-dev" | sudo tee /etc/hostname

# Reboot to apply changes
sudo reboot
```

#### Step 3: Update DNS Records
```bash
# Update private DNS zone records
az network private-dns record-set a add-record \
  --resource-group rg-dev-centralus \
  --zone-name dats-beeux-dev.internal \
  --record-set-name dats-beeux-data-dev \
  --ipv4-address 10.0.1.4

az network private-dns record-set a add-record \
  --resource-group rg-dev-centralus \
  --zone-name dats-beeux-dev.internal \
  --record-set-name dats-beeux-apps-dev \
  --ipv4-address 10.0.1.5

# Keep old records for compatibility (optional)
# Can be removed after verifying all services work
```

#### Step 4: Update Documentation
- Update ALL_INFRA_DETAILS.md with new hostnames
- Update any scripts or configuration files referencing old names
- Update SSH config files

#### Step 5: Verify Services
```bash
# Test SSH with new hostnames
ssh beeuser@52.182.154.41 'hostname'  # Should show: dats-beeux-data-dev
ssh beeuser@52.230.252.48 'hostname'  # Should show: dats-beeux-apps-dev

# Test service connectivity
# Verify databases, Kubernetes, etc. are working
```

## 🚨 Risk Mitigation

### Pre-Change Checklist
- [ ] Create VM snapshots
- [ ] Document current services and ports
- [ ] Notify team of maintenance window
- [ ] Prepare rollback plan

### Rollback Plan
If issues occur:
```bash
# Revert hostname changes
sudo hostnamectl set-hostname <old-hostname>
sudo sed -i 's/<new-hostname>/<old-hostname>/g' /etc/hosts
sudo reboot
```

### Service Dependencies to Check
- SSH connections and saved configurations
- Internal service discovery (if using hostnames)
- Monitoring systems
- Backup systems
- Any hardcoded hostname references

## 📋 Impact Assessment

### Minimal Impact
- SSH access (IP addresses unchanged)
- Service connectivity (IP-based connections)
- Network communication (private IPs same)
- External access (public IPs same)

### Requires Updates
- SSH config files with hostname references
- Documentation and runbooks
- Monitoring systems using hostnames
- Any scripts with hardcoded hostnames

## ⏰ Maintenance Window

**Recommended Schedule**: Off-peak hours (e.g., 6:00 AM UTC)
**Estimated Downtime**: 
- Data VM: ~5 minutes (reboot time)
- Apps VM: ~5 minutes (reboot time)
- Total: ~15 minutes including verification

## 🔄 Alternative: Full Resource Rename (Not Recommended)

If full Azure resource renaming is required:

### Steps (High Risk - Not Recommended)
1. Stop VMs
2. Create new VMs with new names
3. Attach existing disks to new VMs
4. Update network configurations
5. Delete old VM resources

### Risks
- Data loss if misconfigured
- Extended downtime (1-2 hours)
- Potential IP address changes
- Complex rollback procedure

## 📝 Final Recommendation

**Proceed with Option 2 (Computer Name Change)** because:
1. ✅ Preserves all IP addresses and network configuration
2. ✅ Minimal risk and downtime
3. ✅ Easy rollback if needed
4. ✅ Maintains service continuity
5. ✅ Quick implementation

The Azure resource names will remain as `dats-beeux-dev-data` and `dats-beeux-dev-apps`, but the actual computer hostnames will be `dats-beeux-data-dev` and `dats-beeux-apps-dev`, which is what matters for most operational purposes.