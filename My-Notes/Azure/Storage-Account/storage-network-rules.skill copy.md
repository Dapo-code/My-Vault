---
title: Storage Account Network Rules Configuration
tags:
  - azure
  - storage-account
  - networking
  - security
  - az-cli
created: 2026-05-14
updated: 2026-06-17
---

# Storage Account Network Rules Configuration

## Linked Notes

- [[My-Notes/Azure/Storage-Account/privateendpoint copy|Private Endpoint Creation Plan]]
- [[My-Notes/Azure/Storage-Account/vm-connectivity-test copy|VM Storage Connectivity Testing Guide]]
- [[My-Notes/Azure/Storage-Account/ablprodsqlwitness3-dns-link-instructions copy|DNS Zone Link Instructions]]
- [[My-Notes/Azure/Storage-Account/configure-storage-network-rules copy.sh|Companion Script: Configure Storage Network Rules]]

## Purpose

Configure Azure Storage Accounts to use **selected networks** (deny public access by default) while:
- Allowing trusted Microsoft services to access the account
- Whitelisting specific IP addresses and CIDR ranges

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Appropriate permissions to modify storage account network rules
- Storage account must exist

## Quick Usage

### Using the Script

```bash
# Make the script executable
chmod +x scripts/configure-storage-network-rules.sh

# Run the script
./scripts/configure-storage-network-rules.sh
```

### Manual Commands

```bash
# 1. Set storage account to selected networks with Microsoft services bypass
az storage account update \
  --name <STORAGE_ACCOUNT_NAME> \
  --default-action Deny \
  --bypass AzureServices

# 2. Add individual IP addresses
az storage account network-rule add \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --ip-address <IP_ADDRESS>

# 3. Add CIDR ranges
az storage account network-rule add \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --ip-address <CIDR_RANGE>
```

## Parameters Explained

- `--default-action Deny`: Sets the storage account to **selected networks** mode (blocks all public access by default)
- `--bypass AzureServices`: Allows trusted Microsoft services to access the storage account
- `--ip-address`: Individual IP address or CIDR range to whitelist

## Example Configurations

### Example 1: Storage Account with IP Allowlist Only

**Storage Account:** `ablprodancillary02rgdiag`  
**Resource Group:** `abl-prod-ancillary02-rg`  
**Use Case:** Diagnostic storage with external monitoring systems

**Whitelisted IPs:**
```
20.58.68.62
20.58.68.63
20.90.32.180
20.90.132.144
20.90.132.145
51.104.30.169
172.187.0.26
172.187.65.53
4.210.131.60
20.105.209.72
20.105.209.73
40.113.178.49
52.146.137.65
52.146.139.220
52.146.139.221
98.71.107.78
```

**Whitelisted CIDR Ranges:**
```
162.10.0.0/17
163.116.128.0/17
```

**Configuration:**
```bash
# Set to selected networks
az storage account update \
  --name ablprodancillary02rgdiag \
  --resource-group abl-prod-ancillary02-rg \
  --default-action Deny \
  --bypass AzureServices

# Add IP rules (use loop in script)
az storage account network-rule add \
  --account-name ablprodancillary02rgdiag \
  --ip-address 20.58.68.62
# ... repeat for all IPs
```

### Example 2: Storage Account with VNet Rules + IP Allowlist

**Storage Account:** `ablprodmanagementrgdiag`  
**Resource Group:** `abl-prod-management-rg`  
**Use Case:** Management storage with VM diagnostics and external access

**Network Configuration:**
- **Private Endpoints:** 4 (Blob x2, Table x2)
- **VNet:** abl-prod-management-vnet (192.168.18.0/24)
- **Subnets with VNet Rules:**
  - default (192.168.18.0/26)
  - abl-prod-mgmt-cicd-sn (192.168.18.144/28)
  - abl-prod-mgmt-ts-sn (192.168.18.96/28)
  - abl-prod-management-cicd-windows (192.168.18.176/28)

**Configuration:**
```bash
# Set to selected networks
az storage account update \
  --name ablprodmanagementrgdiag \
  --resource-group abl-prod-management-rg \
  --default-action Deny \
  --bypass AzureServices

# Add VNet rules for VM subnets
az storage account network-rule add \
  --account-name ablprodmanagementrgdiag \
  --resource-group abl-prod-management-rg \
  --vnet-name abl-prod-management-vnet \
  --subnet default

# Add IP allowlist for external access
az storage account network-rule add \
  --account-name ablprodmanagementrgdiag \
  --ip-address 20.58.68.62
# ... repeat for all IPs
```

**Result:**
- ✅ VMs on management VNet access via service endpoints
- ✅ Private endpoint connectivity for peered VNets
- ✅ External systems access via whitelisted IPs
- ✅ Azure services (monitoring, backup) access via bypass
- ✅ WAD and Linux syslog continue functioning
- ✅ Boot diagnostics continue working

## Verification

```bash
# View current network rules
az storage account show \
  --name <STORAGE_ACCOUNT_NAME> \
  --query networkRuleSet

# View only IP rules
az storage account show \
  --name <STORAGE_ACCOUNT_NAME> \
  --query networkRuleSet.ipRules
```

## Troubleshooting

### Rule Already Exists
If you see an error that a rule already exists, you can:
1. List existing rules first to check
2. Remove the rule before re-adding: `az storage account network-rule remove --account-name <NAME> --ip-address <IP>`

### Access Denied
Ensure you have the appropriate RBAC role:
- `Storage Account Contributor` or higher
- `Owner` at the storage account or resource group level

### Resource Group Required
Some Azure CLI versions require the `--resource-group` parameter:
```bash
az storage account update \
  --name <STORAGE_ACCOUNT_NAME> \
  --resource-group <RESOURCE_GROUP_NAME> \
  --default-action Deny \
  --bypass AzureServices
```

## Related Files

- Script: [`scripts/configure-storage-network-rules.sh`](configure-storage-network-rules.sh)
- Config examples: `config/*/prod/*.yaml`

## Impact Analysis Before Configuration

**CRITICAL:** Always perform impact analysis before disabling public access to production storage accounts.

### Step 1: Identify Storage Account Usage

```bash
# Check current network configuration
az storage account show \
  --name <STORAGE_ACCOUNT_NAME> \
  --resource-group <RESOURCE_GROUP_NAME> \
  --query "{network:networkRuleSet, privateEndpoints:privateEndpointConnections}" \
  -o json

# List all containers (boot diagnostics, logs, etc.)
az storage container list \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --auth-mode login \
  --query "[].{name:name, lastModified:properties.lastModified}" \
  -o table

# List all tables (WAD metrics, syslogs)
az storage table list \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --auth-mode login \
  -o table
```

### Step 2: Check Private Endpoint Configuration

```bash
# Verify private endpoints exist
az storage account show \
  --name <STORAGE_ACCOUNT_NAME> \
  --query "privateEndpointConnections[].{name:name, state:privateLinkServiceConnectionState.status}" \
  -o table
```

### Step 3: Analyze VNet Connectivity

```bash
# Get resource group name first
RESOURCE_GROUP=$(az storage account show --name <STORAGE_ACCOUNT_NAME> --query resourceGroup -o tsv)

# List VMs that might be using the storage account
az vm list --resource-group $RESOURCE_GROUP --query "[].name" -o table

# Check VNet peering
az network vnet list \
  --resource-group $RESOURCE_GROUP \
  --query "[].{name:name, subnets:subnets[].{name:name, serviceEndpoints:serviceEndpoints[].service}}" \
  -o json
```

### Step 4: Identify Services Using the Storage

**Common Services to Check:**
- ✅ **VM Boot Diagnostics** - Check bootdiagnostics-* containers
- ✅ **Windows Azure Diagnostics (WAD)** - Check WADMetrics* tables
- ✅ **Linux Syslog Collection** - Check LinuxSyslog* tables
- ✅ **NSG Flow Logs** - Check insights-logs-* containers
- ✅ **Azure Site Recovery** - Check ASR-* containers
- ✅ **Log Analytics** - Check workspace connections

---

## VNet Rules and Service Endpoints

### Why VNet Rules Matter

VNet rules allow VMs and services **within your Azure VNets** to access the storage account even when public access is denied. This is essential for:
- VM diagnostic agents (WAD, OMSAgent)
- Boot diagnostics
- Applications running on VMs
- CI/CD agents

### Prerequisites for VNet Rules

**Service Endpoints MUST be enabled** on the subnet before adding VNet rules:

```bash
# Enable Microsoft.Storage service endpoint on subnet
az network vnet subnet update \
  --resource-group <RESOURCE_GROUP> \
  --vnet-name <VNET_NAME> \
  --name <SUBNET_NAME> \
  --service-endpoints Microsoft.Storage
```

### Adding VNet Rules

```bash
# Add VNet rule for a specific subnet
az storage account network-rule add \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --resource-group <RESOURCE_GROUP_NAME> \
  --vnet-name <VNET_NAME> \
  --subnet <SUBNET_NAME>
```

### Multiple Subnets Configuration

For storage accounts used by VMs across multiple subnets (recommended):

```bash
STORAGE_ACCOUNT="<STORAGE_ACCOUNT_NAME>"
RESOURCE_GROUP="<RESOURCE_GROUP_NAME>"
VNET_NAME="<VNET_NAME>"
SUBNETS=("default" "cicd-subnet" "app-subnet" "management-subnet")

for subnet in "${SUBNETS[@]}"; do
  az storage account network-rule add \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --subnet "$subnet"
done
```

---

## Private Endpoints Integration

### How Private Endpoints Work

Private endpoints provide **private IP addresses** in your VNet for storage account services:
- **Blob storage:** `<storage-account>.blob.core.windows.net` → Private IP (e.g., 10.1.2.3)
- **Table storage:** `<storage-account>.table.core.windows.net` → Private IP
- **File storage:** `<storage-account>.file.core.windows.net` → Private IP

### Private Endpoints + Selected Networks = Best Security

When you combine:
1. **Private endpoints** (for internal access)
2. **defaultAction: Deny** (block public internet)
3. **IP allowlist** (specific public IPs only)
4. **VNet rules** (subnet access)
5. **AzureServices bypass** (Azure platform services)

You achieve **defense-in-depth**:
- Internal VMs use private endpoints (Azure backbone, never leaves Azure)
- External systems use whitelisted IPs only
- Azure services (monitoring, backup) continue working

### Checking Private Endpoint Connectivity

```bash
# Verify VNet peering to private endpoint network
az network vnet peering list \
  --resource-group <RESOURCE_GROUP> \
  --vnet-name <VNET_NAME> \
  --query "[].{name:name, state:peeringState, remoteVnet:remoteVirtualNetwork.id}" \
  -o table
```

**Key requirement:** VMs must be able to reach the VNet where private endpoints are deployed (via peering or same VNet).

---

## Diagnostic Agents Considerations

### Windows Azure Diagnostics (WAD)

**How WAD Connects to Storage:**
1. **Primary:** Service Endpoints (if enabled on VM subnet)
   - Traffic stays on Azure backbone
   - No public internet routing
   - Authenticated via SAS token or managed identity

2. **Fallback:** Private Endpoints (if VNet peered)
   - Private IP resolution
   - Requires Private DNS zones

3. **Last Resort:** AzureServices Bypass
   - Works even with defaultAction: Deny

**WAD Tables to Monitor:**
- `WADMetricsPT1HP10DV2S*` - Performance metrics
- `WADDiagnosticInfrastructureLogsTable` - Agent logs

**Verification After Configuration:**
```bash
# Check if WAD tables still receiving data
az storage table list \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --auth-mode login \
  --query "[?contains(name, 'WADMetrics')].name" \
  -o table

# Check last modified time
az storage entity query \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --table-name <WAD_TABLE_NAME> \
  --auth-mode login \
  --num-results 1
```

### Linux Syslog Collection (OMSAgent)

**How OMSAgent Connects:**
- Same connectivity paths as WAD
- Uses Log Analytics workspace configuration
- Writes to `LinuxSyslogVer2v0` table

**Verification:**
```bash
# Check syslog table exists and is accessible
az storage table list \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --auth-mode login \
  --query "[?contains(name, 'Syslog')]" \
  -o table
```

### Boot Diagnostics

**Impact Assessment:**
- ⚠️ **Portal Access:** May not display screenshots if accessing from non-whitelisted IP
- ✅ **VM Boot:** Not affected - boot diagnostics is non-blocking
- ✅ **Agent Upload:** Works via service endpoints or AzureServices bypass

**Best Practice:** Add VNet rules for all VM subnets that use this storage account for boot diagnostics.

---

## Testing Procedures

### Pre-Configuration Testing

**1. Document Current State:**
```bash
# Save current configuration
az storage account show \
  --name <STORAGE_ACCOUNT_NAME> \
  --query networkRuleSet \
  -o json > storage-network-before.json
```

**2. Test DNS Resolution (from a VM):**
```bash
# Should resolve to public IP before configuration
nslookup <storage-account>.blob.core.windows.net

# After private endpoint setup, should resolve to private IP
# Example: 10.1.2.3
```

**3. Test Connectivity (from a VM):**
```bash
# Should return HTTP 400 (auth required), not connection refused
curl -I https://<storage-account>.blob.core.windows.net
```

### Post-Configuration Testing

**Immediate Tests (within 5 minutes):**

```bash
# 1. Verify rules applied
az storage account show \
  --name <STORAGE_ACCOUNT_NAME> \
  --query "networkRuleSet" \
  -o json

# 2. Test access from your current IP (should work if whitelisted)
az storage container list \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --auth-mode login

# 3. Test access to tables
az storage table list \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --auth-mode login
```

**Short-term Monitoring (15-30 minutes):**

```bash
# Check if diagnostic data still flowing
# Last modified should be recent
az storage table list \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --auth-mode login \
  --query "[].{name:name, lastModified:properties.lastModified}" \
  -o table

# Check if boot diagnostics containers still updating
az storage container list \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --auth-mode login \
  --query "[?contains(name, 'bootdiagnostics')].{name:name, lastModified:properties.lastModified}" \
  -o table
```

**Medium-term Monitoring (24-48 hours):**

- Monitor Log Analytics workspace for gaps in:
  - VM performance metrics
  - Syslog entries  
  - Security logs
  - Application logs

- Check Azure Monitor alerts for any storage access errors

- Review Application Insights for any connection failures

---

## Security Best Practices

### 1. **Defense in Depth**

**Layer 1: Default Deny**
```bash
--default-action Deny
```
Block all public access by default.

**Layer 2: IP Allowlisting**
Only allow specific known IP addresses:
- Office IP ranges
- VPN egress IPs
- Partner/vendor IPs (time-limited)
- CI/CD pipeline IPs

**Layer 3: VNet Rules**
Allow internal Azure VNets with service endpoints.

**Layer 4: Private Endpoints**
Provide private connectivity for VNet resources.

**Layer 5: Azure Services Bypass**
Allow trusted Microsoft services (monitoring, backup, etc.).

### 2. **Principle of Least Privilege**

**Avoid wildcard ranges:**
❌ Bad: `0.0.0.0/0` (allows everything)
✅ Good: Specific IP addresses or small CIDR ranges

**Example:**
```bash
# Too broad - DON'T DO THIS
162.0.0.0/8  # Entire /8 range

# Better - specific /17
162.10.0.0/17  # Only 32,768 addresses
```

### 3. **Regular Audit and Cleanup**

```bash
# List all IP rules
az storage account show \
  --name <STORAGE_ACCOUNT_NAME> \
  --query "networkRuleSet.ipRules" \
  -o table

# Remove unused rules
az storage account network-rule remove \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --ip-address <OLD_IP>
```

### 4. **Document All Changes**

Maintain documentation for each IP address:
- **Purpose:** What system uses this IP?
- **Owner:** Who requested it?
- **Expiry:** When should it be reviewed/removed?
- **Approval:** Who approved the access?

### 5. **Use Resource Group Tags**

```bash
# Tag storage account with security classification
az storage account update \
  --name <STORAGE_ACCOUNT_NAME> \
  --resource-group <RESOURCE_GROUP_NAME> \
  --tags SecurityLevel=Restricted NetworkAccess=SelectedNetworks LastReviewed=2026-05-26
```

---

## Lessons Learned

### 1. **Always Analyze Impact Before Configuration**

**Lesson:** Disabling public access to production storage accounts can break critical services if not properly planned.

**Action:** 
- Document all services using the storage account
- Check for private endpoints
- Verify VNet peering and service endpoints
- Test connectivity paths

### 2. **Service Endpoints Are Essential for VNet Rules**

**Lesson:** VNet rules won't work if Microsoft.Storage service endpoint isn't enabled on the subnet.

**Action:**
- Always check subnet service endpoints first
- Enable Microsoft.Storage before adding VNet rules
- Document which subnets have service endpoints

### 3. **Private Endpoints + VNet Rules = Redundancy**

**Lesson:** Having both private endpoints AND VNet rules provides redundancy and better performance.

**Why Both:**
- Private endpoints: Direct private IP connectivity
- VNet rules with service endpoints: Azure backbone routing
- If one fails, the other works

### 4. **AzureServices Bypass is Critical**

**Lesson:** Many Azure platform services (monitoring, backup, Site Recovery) need the AzureServices bypass.

**Services that rely on bypass:**
- NSG Flow Logs
- Azure Site Recovery
- Azure Backup
- Azure Monitor
- SQL Auditing to storage
- Azure Sentinel data connectors

**Always include:**
```bash
--bypass AzureServices
```

### 5. **Boot Diagnostics Uses Different Storage**

**Lesson:** Not all boot diagnostics containers are in the "diag" storage account.

**Discovery:** Check each VM's diagnostics configuration:
```bash
az vm show \
  --name <VM_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --query "diagnosticsProfile.bootDiagnostics.storageUri" \
  -o tsv
```

### 6. **IP Rules Need CIDR Notation for Ranges**

**Lesson:** Azure accepts both single IPs and CIDR ranges in the same parameter.

**Valid formats:**
- `20.58.68.62` - Single IP
- `162.10.0.0/17` - CIDR range
- ~~`162.10.0.0-162.10.127.255`~~ - Range notation NOT supported

### 7. **Test Access After Configuration**

**Lesson:** Configuration can succeed but access can still fail due to DNS, routing, or permissions issues.

**Always test:**
```bash
# From Azure CLI (your current IP)
az storage container list --account-name <NAME> --auth-mode login

# From a VM (VNet rules or private endpoints)
curl -I https://<storage-account>.blob.core.windows.net
```

### 8. **Monitor for 24-48 Hours**

**Lesson:** Some issues only appear after time:
- Diagnostic agents retry on failure (may take 15 minutes to detect)
- Log ingestion may be batched
- Backup jobs may run on schedules

**Action:** Set up monitoring alerts for:
- Storage access errors
- Missing diagnostic data
- Failed backup jobs
- Application errors related to storage

---

## Production Readiness Checklist

Before deploying to production, verify:

- [ ] Impact analysis completed and documented
- [ ] Private endpoints exist and are in "Succeeded" state
- [ ] VNet peering configured to private endpoint network
- [ ] Service endpoints enabled on all relevant subnets
- [ ] VNet rules added for all VM subnets
- [ ] IP allowlist documented with ownership and purpose
- [ ] AzureServices bypass enabled
- [ ] DNS resolution tested from VMs (should resolve to private IPs)
- [ ] Storage access tested from VMs
- [ ] Boot diagnostics containers identified
- [ ] WAD/syslog tables verified
- [ ] Change documented in change management system
- [ ] Rollback plan prepared
- [ ] Monitoring alerts configured
- [ ] Stakeholders notified
- [ ] Post-deployment testing scheduled (24-48 hours)

---

## Rollback Procedure

If issues occur after configuration:

```bash
# 1. Immediately restore public access
az storage account update \
  --name <STORAGE_ACCOUNT_NAME> \
  --resource-group <RESOURCE_GROUP_NAME> \
  --default-action Allow

# 2. Verify services restored
az storage container list --account-name <STORAGE_ACCOUNT_NAME> --auth-mode login

# 3. Document the issue and investigate root cause

# 4. After fixing, retry with corrected configuration
```

**Common Issues and Fixes:**

| Issue | Root Cause | Fix |
|-------|------------|-----|
| WAD stops logging | No service endpoint on VM subnet | Enable service endpoint + add VNet rule |
| Boot diagnostics fail | Wrong storage account | Check VM diagnostics profile |
| Access denied from VM | No VNet rule or private endpoint | Add VNet rule for VM's subnet |
| Portal can't view logs | Your IP not whitelisted | Add your public IP to allowlist |

---

## References

- [Azure Storage Network Security](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security)
- [Azure CLI Storage Account Network Rule](https://learn.microsoft.com/en-us/cli/azure/storage/account/network-rule)
- [Configure Azure Storage Firewalls and Virtual Networks](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security)
- [Use Private Endpoints for Azure Storage](https://learn.microsoft.com/en-us/azure/storage/common/storage-private-endpoints)
- [Azure Storage Service Endpoints](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview)

---

## Related

- [[My-Notes/Azure/Storage-Account/privateendpoint copy|Private Endpoint Creation Plan]]
- [[My-Notes/Azure/Storage-Account/vm-connectivity-test copy|VM Storage Connectivity Testing Guide]]
- [[My-Notes/my-notes|My Notes Folder Guide]]
