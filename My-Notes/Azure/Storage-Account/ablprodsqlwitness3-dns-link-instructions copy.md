---
title: DNS Zone Link Instructions for ablprodsqlwitness3
tags:
  - azure
  - storage-account
  - private-dns
  - sql-witness
created: 2026-05-14
updated: 2026-06-17
---

# DNS Zone Link Instructions for ablprodsqlwitness3

## Linked Notes

- [[My-Notes/Azure/Storage-Account/privateendpoint copy|Private Endpoint Creation Plan]]
- [[My-Notes/Azure/Storage-Account/storage-network-rules.skill copy|Storage Network Rules Configuration]]
- [[My-Notes/Azure/Storage-Account/vm-connectivity-test copy|VM Storage Connectivity Testing Guide]]

**Created:** 2026-05-14  
**Storage Account:** ablprodsqlwitness3  
**Purpose:** Enable private routing for SQL Cloud Witness

---

## Current Status

✅ **Private endpoints created** for ablprodsqlwitness3  
✅ **SQL Cloud Witness working** via public access  
⚠️  **Traffic still going over public internet** (DNS not configured)

---

## What This Does

Linking the `abl-prod-banklayer-vnet` to the private DNS zones will:
- Make SQL VMs resolve `ablprodsqlwitness3.blob.core.windows.net` to **private IPs**
- Route traffic through **VNet peering** instead of public internet
- Enable **secure private connectivity** to the storage account

---

## Prerequisites

✅ VNet peering exists (already configured)  
✅ Private endpoints exist (just created)  
✅ DNS zones exist (already exist in corp subscription)

---

## Commands to Add DNS Zone Links

### Link to Primary DNS Zone (North Europe)

```bash
# Set subscription to corp subscription
az account set --subscription "fda5eebb-adfa-4c02-af21-2d14f2e4476b"

# Create VNet link for North Europe DNS zone
az network private-dns link vnet create \
  --resource-group "abl-corp-private-endpoints-rg" \
  --zone-name "privatelink.blob.core.windows.net" \
  --name "abl-prod-banklayer-vnet-link" \
  --virtual-network "/subscriptions/847b9307-3224-4030-bbfa-b20e18452332/resourceGroups/abl-prod-banklayer-rg/providers/Microsoft.Network/virtualNetworks/abl-prod-banklayer-vnet" \
  --registration-enabled false
```

**Expected output:** Link created with provisioningState: Succeeded

---

### Link to Secondary DNS Zone (UK South)

```bash
# Create VNet link for UK South DNS zone
az network private-dns link vnet create \
  --resource-group "abl-corp-uks-private-endpoints-rg" \
  --zone-name "privatelink.blob.core.windows.net" \
  --name "abl-prod-banklayer-vnet-link" \
  --virtual-network "/subscriptions/847b9307-3224-4030-bbfa-b20e18452332/resourceGroups/abl-prod-banklayer-rg/providers/Microsoft.Network/virtualNetworks/abl-prod-banklayer-vnet" \
  --registration-enabled false
```

**Expected output:** Link created with provisioningState: Succeeded

---

## Verification

### Step 1: Check DNS Links Were Created

```bash
# Check primary region
az network private-dns link vnet list \
  --resource-group "abl-corp-private-endpoints-rg" \
  --zone-name "privatelink.blob.core.windows.net" \
  --query "[?contains(name, 'banklayer')]" \
  -o table

# Check secondary region
az network private-dns link vnet list \
  --resource-group "abl-corp-uks-private-endpoints-rg" \
  --zone-name "privatelink.blob.core.windows.net" \
  --query "[?contains(name, 'banklayer')]" \
  -o table
```

**Expected output:** Should see `abl-prod-banklayer-vnet-link` in both regions

---

### Step 2: Test DNS Resolution from SQL VMs

From one of the SQL VMs (prd-bl-db-01, prd-bl-db-02, or prd-bl-db-03):

```powershell
# Should resolve to private IP (192.168.177.25 or 10.64.8.231)
nslookup ablprodsqlwitness3.blob.core.windows.net

# Test connectivity
Test-NetConnection ablprodsqlwitness3.blob.core.windows.net -Port 443
```

**Expected Results:**
- **Before DNS link:** Resolves to public IP (20.x.x.x or similar)
- **After DNS link:** Resolves to private IP (192.168.177.25)

---

## Private Endpoint Details

### Primary Endpoint (North Europe)
- **Name:** ablprodsqlwitness3-blob
- **Private IP:** 192.168.177.25
- **Resource Group:** abl-corp-private-endpoints-rg
- **Location:** northeurope

### Secondary Endpoint (UK South)
- **Name:** ablprodsqlwitness3-blob-sec
- **Private IP:** 10.64.8.231
- **Resource Group:** abl-corp-uks-private-endpoints-rg
- **Location:** uksouth

---

## Timeline

**No urgency** - This can be done anytime:
- SQL Witness is currently working via public access
- Adding DNS links is **non-disruptive**
- Traffic will automatically switch to private routing once links are added
- No downtime expected

---

## Rollback (if needed)

If you need to revert to public routing:

```bash
# Remove the primary DNS link
az network private-dns link vnet delete \
  --resource-group "abl-corp-private-endpoints-rg" \
  --zone-name "privatelink.blob.core.windows.net" \
  --name "abl-prod-banklayer-vnet-link" \
  --yes

# Remove the secondary DNS link
az network private-dns link vnet delete \
  --resource-group "abl-corp-uks-private-endpoints-rg" \
  --zone-name "privatelink.blob.core.windows.net" \
  --name "abl-prod-banklayer-vnet-link" \
  --yes
```

Traffic will immediately revert to public routing via public endpoints.

---

## Important Notes

- **DNS propagation:** Typically instant (few seconds)
- **No restart required:** SQL VMs will automatically use new DNS resolution
- **No downtime expected:** Witness continues working during transition
- **Public access:** Can remain enabled as fallback if desired
- **Impact:** Zero-downtime transition from public to private routing

---

## SQL Cloud Witness Details

- **SQL Cluster:** prd-bl-db-01, prd-bl-db-02, prd-bl-db-03
- **VNet:** abl-prod-banklayer-vnet
- **Container:** msft-cloud-witness
- **Peering:** Already connected to corp private endpoint network

---

## Questions?

If DNS resolution doesn't work after adding links:
1. Verify VNet peering is in "Connected" state
2. Check SQL VM's DNS server settings (should use VNet DNS or custom DNS that forwards to Azure DNS)
3. Clear DNS cache on SQL VMs: `ipconfig /flushdns`
4. Verify private endpoint connection status is "Approved"

---

## Related

- [[My-Notes/Azure/Storage-Account/privateendpoint copy|Private Endpoint Creation Plan]]
- [[My-Notes/Azure/Storage-Account/vm-connectivity-test copy|VM Storage Connectivity Testing Guide]]
- [[My-Notes/my-notes|My Notes Folder Guide]]
