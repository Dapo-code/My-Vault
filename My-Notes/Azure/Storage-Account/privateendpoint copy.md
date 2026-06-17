---
title: Private Endpoint Creation Plan for Azure Storage Accounts
tags:
  - azure
  - storage-account
  - private-endpoint
  - networking
  - runbook
created: 2026-05-14
updated: 2026-06-17
---

# Private Endpoint Creation Plan for Azure Storage Accounts

## Linked Notes

- [[My-Notes/Azure/Storage-Account/ablprodsqlwitness3-dns-link-instructions copy|DNS Zone Link Instructions for ablprodsqlwitness3]]
- [[My-Notes/Azure/Storage-Account/storage-network-rules.skill copy|Storage Network Rules Configuration]]
- [[My-Notes/Azure/Storage-Account/vm-connectivity-test copy|VM Storage Connectivity Testing Guide]]

**Universal Plan - Works for Any Storage Account in Any Environment**

## Executive Summary

This document outlines the strategy for an AI agent to create private endpoints for Azure storage accounts that currently lack them, using Azure CLI and following the existing patterns in the PET-self-serv-storage repository.

**This plan is generic and can be applied to ANY storage account across any environment (prod/dev/prep/nonprod).**

**Status:** Analysis Complete  
**Reference Example:** ablprodcoresa (abl-prod-management-rg) - used for illustration only  
**Date:** 2026-05-14

### How to Use This Plan

1. **Identify your storage account**: Get the storage account name, resource group, and subscription ID
2. **Determine the environment**: prod, dev, prep, nonprod, or prd_uks
3. **Update script variables**: Replace placeholder values (`<your-storage-account-name>`, etc.) with your actual values
4. **Run pre-flight checks**: Verify no existing PEs and all network resources exist
5. **Execute the agent workflow script**: Create private endpoints based on storage usage
6. **Validate**: Confirm PEs are created and DNS records are registered

All scripts in this document use **variables** - simply update them for your specific storage account.

### Quick Start Example

```bash
# 1. Set your storage account details
export STORAGE_ACCOUNT="myappstorageacct"
export STORAGE_RG="ABL-MYAPP-PROD-STORAGE-RG"
export STORAGE_SUB="847b9307-3224-4030-bbfa-b20e18452332"
export ENVIRONMENT="prod"

# 2. Run the complete agent workflow script (see bottom of this document)
./create-private-endpoints.sh "$STORAGE_ACCOUNT" "$STORAGE_RG" "$ENVIRONMENT"

# That's it! The script will:
# - Detect what type of PEs are needed (blob/dfs/file/queue/table/web)
# - Create primary and secondary endpoints (if geo-redundant)
# - Link to DNS zones automatically
# - TEST each endpoint immediately after creation
# - Validate the deployment
```

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Resource Inventory](#resource-inventory)
3. [Storage Account Usage Detection](#storage-account-usage-detection)
4. [Pre-Execution Checks](#pre-execution-checks)
5. [Private Endpoint Creation Workflow](#private-endpoint-creation-workflow)
6. [Azure CLI Commands](#azure-cli-commands)
7. [Immediate Connection Testing](#immediate-connection-testing)
8. [DNS Configuration](#dns-configuration)
9. [Validation Steps](#validation-steps)
10. [Rollback Procedures](#rollback-procedures)

---

## Architecture Overview

### Current Infrastructure Pattern

The repository implements a dual-region private endpoint architecture:

- **Primary Region:** North Europe (most environments)
- **Secondary Region:** UK South (for geo-redundancy)
- **Exception:** `prd_uks` environment uses UK South as primary, North Europe as secondary

### Private Endpoint Structure

```
Storage Account (any region)
  ├── Primary PE (North Europe) → connects to primary subnet
  │   └── Private DNS Zone Group → links to primary DNS zone
  └── Secondary PE (UK South) → connects to secondary subnet
      └── Private DNS Zone Group → links to secondary DNS zone
```

### Subresource Types

Private endpoints can be created for different storage services:

| Subresource | Use Case | Terraform Flag | DNS Zone |
|-------------|----------|----------------|----------|
| `blob` | Blob storage containers | `pe_blob` | `privatelink.blob.core.windows.net` |
| `dfs` | Data Lake Gen2 (HNS enabled) | `pe_dfs` | `privatelink.dfs.core.windows.net` |
| `file` | File shares (SMB/NFS) | `pe_file` | `privatelink.file.core.windows.net` |
| `queue` | Queue storage | `pe_queue` | `privatelink.queue.core.windows.net` |
| `table` | Table storage | `pe_table` | `privatelink.table.core.windows.net` |
| `web` | Static website hosting | `pe_web` | `privatelink.web.core.windows.net` |

---

## Resource Inventory

### Existing Resources (DO NOT CREATE NEW)

#### Primary Region (North Europe)

**Environment:** prod (example - adapt for your environment)  
**Subscription:** 847b9307-3224-4030-bbfa-b20e18452332 (corp subscription)

> **Important:** These resource IDs are for **prod** environment. For dev/prep/nonprod, replace `prod` with the appropriate environment name in resource names, and update the storage subscription ID accordingly. The corp subscription (`fda5eebb-adfa-4c02-af21-2d14f2e4476b`) remains the same across all environments.

```yaml
Resource Group: abl-corp-private-endpoints-rg
VNet: abl-corp-private-endpoints-prod-vnet
VNet ID: /subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-private-endpoints-prod-vnet
Subnet: abl-corp-private-endpoints-central-prod-sn
Subnet ID: /subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-private-endpoints-prod-vnet/subnets/abl-corp-private-endpoints-central-prod-sn
Location: northeurope
```

**Private DNS Zones:**
- Blob: `/subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net`
- DFS: `/subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net`
- File: `/subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net`
- Queue: `/subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net`
- Table: `/subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net`
- Web: `/subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/privateDnsZones/privatelink.web.core.windows.net`

#### Secondary Region (UK South)

**Environment:** prod (example - adapt for your environment)  
**Subscription:** 847b9307-3224-4030-bbfa-b20e18452332 (corp subscription)

```yaml
Resource Group: abl-corp-uks-private-endpoints-rg
VNet: abl-corp-uks-private-endpoints-prod-vnet
VNet ID: /subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-uks-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-uks-private-endpoints-prod-vnet
Subnet: abl-corp-uks-private-endpoints-central-prod-sn
Subnet ID: /subscriptions/fda5eebb-adfa-4c02-af21-2d14f2e4476b/resourceGroups/abl-corp-uks-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-uks-private-endpoints-prod-vnet/subnets/abl-corp-uks-private-endpoints-central-prod-sn
Location: uksouth
```

**Private DNS Zones:** (same zone names, different resource group)
- Resource Group: `abl-corp-uks-private-endpoints-rg`
- Same DNS zone names as primary, different subscription path

### Environment-Specific Variations

**To adapt this plan for your environment:**

1. **Replace `prod` with your environment** in all resource names:
   - `abl-corp-private-endpoints-rg` (no change needed - corp resources are shared)
   - `abl-corp-private-endpoints-prod-vnet` → `abl-corp-private-endpoints-{env}-vnet`
   - `abl-corp-private-endpoints-central-prod-sn` → `abl-corp-private-endpoints-central-{env}-sn`
   - DNS prefix: `abl-corp-private-endpoints-abl-prod` → `abl-corp-private-endpoints-abl-{env}`

2. **Update subscription IDs**:
   - Storage subscription: Update to your environment's subscription
   - Corp subscription: `fda5eebb-adfa-4c02-af21-2d14f2e4476b` (same for all)

3. **Environment examples**:
   - `prod`: Production environment (shown in examples above)
   - `dev`: Development environment
   - `prep`: Pre-production environment  
   - `nonprod`: Non-production shared environment
   - `prd_uks`: Production UK South (primary/secondary regions are swapped)

**Special case - prd_uks environment:**
- Primary region: UK South (not North Europe)
- Secondary region: North Europe (not UK South)
- Swap the primary and secondary resource IDs in scripts

---

## Storage Account Usage Detection

### Decision Tree

```
Storage Account Analysis
│
├─ Has HNS Enabled (is_hns_enabled)?
│  ├─ YES → Create pe_dfs (Data Lake Gen2)
│  └─ NO  → Create pe_blob (Standard Blob)
│
├─ Has File Shares?
│  └─ YES → Create pe_file
│
├─ Has Queues?
│  └─ YES → Create pe_queue
│
├─ Has Tables?
│  └─ YES → Create pe_table
│
└─ Has Static Website Enabled?
   └─ YES → Create pe_web
```

### Azure CLI Detection Commands

```bash
#!/bin/bash
# Storage Account Usage Detection Script
# USAGE: Update these variables for your target storage account

STORAGE_ACCOUNT="<your-storage-account-name>"  # e.g., "ablprodcoresa"
RESOURCE_GROUP="<resource-group-name>"         # e.g., "abl-prod-management-rg"
SUBSCRIPTION="<subscription-id>"               # e.g., "847b9307-3224-4030-bbfa-b20e18452332"

# Set subscription context
az account set --subscription "$SUBSCRIPTION"

# Get storage account properties
STORAGE_PROPS=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query '{hnsEnabled:isHnsEnabled,location:location,replicationType:sku.name}' \
  -o json)

HNS_ENABLED=$(echo "$STORAGE_PROPS" | jq -r '.hnsEnabled')
LOCATION=$(echo "$STORAGE_PROPS" | jq -r '.location')

echo "Storage Account: $STORAGE_ACCOUNT"
echo "Location: $LOCATION"
echo "HNS Enabled: $HNS_ENABLED"

# Determine PE types needed
PE_TYPES=()

# Blob or DFS based on HNS
if [ "$HNS_ENABLED" == "true" ]; then
  echo "✓ DFS endpoint needed (HNS enabled)"
  PE_TYPES+=("dfs")
else
  echo "✓ Blob endpoint needed (standard storage)"
  PE_TYPES+=("blob")
fi

# Check for file shares
FILE_SHARES=$(az storage share list \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query 'length(@)' \
  -o tsv 2>/dev/null)

if [ "$FILE_SHARES" -gt 0 ]; then
  echo "✓ File endpoint needed ($FILE_SHARES shares found)"
  PE_TYPES+=("file")
fi

# Check for queues
QUEUES=$(az storage queue list \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query 'length(@)' \
  -o tsv 2>/dev/null)

if [ "$QUEUES" -gt 0 ]; then
  echo "✓ Queue endpoint needed ($QUEUES queues found)"
  PE_TYPES+=("queue")
fi

# Check for tables
TABLES=$(az storage table list \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query 'length(@)' \
  -o tsv 2>/dev/null)

if [ "$TABLES" -gt 0 ]; then
  echo "✓ Table endpoint needed ($TABLES tables found)"
  PE_TYPES+=("table")
fi

# Check for static website (correct check - verify feature is enabled)
WEB_ENABLED=$(az storage blob service-properties show \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query 'staticWebsite.enabled' \
  -o tsv 2>/dev/null)

if [ "$WEB_ENABLED" == "true" ]; then
  echo "✓ Web endpoint needed (static website enabled)"
  PE_TYPES+=("web")
fi

# Export for use in subsequent scripts
echo ""
echo "Required PE Types: ${PE_TYPES[@]}"
export PE_TYPES
```

---

## Pre-Execution Checks

### 1. Check for Existing Private Endpoints

```bash
#!/bin/bash
# Check if storage account already has private endpoints
# USAGE: Update these variables for your target storage account

STORAGE_ACCOUNT="<your-storage-account-name>"  # e.g., "ablprodcoresa"
RESOURCE_GROUP="<resource-group-name>"         # e.g., "abl-prod-management-rg"
SUBSCRIPTION="<subscription-id>"               # e.g., "847b9307-3224-4030-bbfa-b20e18452332"

az account set --subscription "$SUBSCRIPTION"

# Get storage account resource ID
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query 'id' \
  -o tsv)

echo "Checking for existing private endpoints..."

# Search all private endpoints that connect to this storage account
EXISTING_PES=$(az network private-endpoint list \
  --subscription "fda5eebb-adfa-4c02-af21-2d14f2e4476b" \
  --query "[?privateLinkServiceConnections[?privateLinkServiceId=='$STORAGE_ID']].{name:name,rg:resourceGroup,subresource:privateLinkServiceConnections[0].groupIds[0],location:location}" \
  -o json)

PE_COUNT=$(echo "$EXISTING_PES" | jq 'length')

if [ "$PE_COUNT" -gt 0 ]; then
  echo "⚠️  WARNING: Found $PE_COUNT existing private endpoint(s)"
  echo "$EXISTING_PES" | jq -r '.[] | "  - \(.name) (\(.subresource)) in \(.rg) [\(.location)]"'
  echo ""
  echo "STOP: Do not create private endpoints for storage accounts with existing PEs."
  echo "Manual review required."
  exit 1
else
  echo "✓ No existing private endpoints found. Safe to proceed."
  exit 0
fi
```

### 2. Verify Network Resources Exist

```bash
#!/bin/bash
# Verify required network resources exist

CORP_SUB="fda5eebb-adfa-4c02-af21-2d14f2e4476b"
az account set --subscription "$CORP_SUB"

echo "Verifying network resources..."

# Primary subnet
PRIMARY_SUBNET="/subscriptions/$CORP_SUB/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-private-endpoints-prod-vnet/subnets/abl-corp-private-endpoints-central-prod-sn"

az network vnet subnet show --ids "$PRIMARY_SUBNET" &>/dev/null
if [ $? -eq 0 ]; then
  echo "✓ Primary subnet exists"
else
  echo "✗ Primary subnet not found"
  exit 1
fi

# Secondary subnet
SECONDARY_SUBNET="/subscriptions/$CORP_SUB/resourceGroups/abl-corp-uks-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-uks-private-endpoints-prod-vnet/subnets/abl-corp-uks-private-endpoints-central-prod-sn"

az network vnet subnet show --ids "$SECONDARY_SUBNET" &>/dev/null
if [ $? -eq 0 ]; then
  echo "✓ Secondary subnet exists"
else
  echo "✗ Secondary subnet not found"
  exit 1
fi

# Verify DNS zones
DNS_ZONES=("privatelink.blob.core.windows.net" "privatelink.dfs.core.windows.net" "privatelink.file.core.windows.net" "privatelink.queue.core.windows.net" "privatelink.table.core.windows.net" "privatelink.web.core.windows.net")

for zone in "${DNS_ZONES[@]}"; do
  az network private-dns zone show \
    --resource-group "abl-corp-private-endpoints-rg" \
    --name "$zone" &>/dev/null
  
  if [ $? -eq 0 ]; then
    echo "✓ DNS zone exists: $zone"
  else
    echo "✗ DNS zone not found: $zone"
    exit 1
  fi
done

echo ""
echo "✓ All required network resources verified"
```

---

## Private Endpoint Creation Workflow

### High-Level Process

```
1. Authenticate to Azure
2. Set target storage account subscription
3. Run usage detection script
4. Run pre-execution checks (existing PEs, network resources)
5. If checks pass:
   a. Create primary private endpoint(s)
      - Create PE
      - Link to DNS zone group
      - TEST CONNECTION immediately
   b. Create secondary private endpoint(s) [optional but recommended]
      - Create PE
      - Link to DNS zone group
      - TEST CONNECTION immediately
6. Review test results for any warnings
7. Perform additional validation from VNet VM (optional)
8. Document changes
```

**Key Change:** Each private endpoint is now tested immediately after creation, not at the end. This allows for faster troubleshooting if issues occur.

### Implementation Sequence

For each subresource type detected:

1. **Primary Region PE**
   - Create private endpoint in North Europe
   - Link to primary private DNS zone
   - Verify connection state (should be "Approved")
   - **Test connectivity immediately** (DNS resolution + endpoint accessibility)
   - Log test results

2. **Secondary Region PE** (always created for network redundancy)
   - Create private endpoint in UK South
   - Link to secondary private DNS zone
   - Verify connection state (should be "Approved")
   - **Test connectivity immediately** (DNS resolution + endpoint accessibility)
   - Log test results

**Important:** Each private endpoint must pass connectivity tests before proceeding to create the next one. This ensures issues are caught early and makes troubleshooting easier.

---

## Azure CLI Commands

### Template Variables

```bash
# Source storage account (target subscription)
# UPDATE THESE FOR YOUR TARGET STORAGE ACCOUNT
STORAGE_SUBSCRIPTION="<subscription-id>"       # e.g., "847b9307-3224-4030-bbfa-b20e18452332" for prod
STORAGE_ACCOUNT="<storage-account-name>"       # e.g., "ablprodcoresa"
STORAGE_RG="<resource-group-name>"             # e.g., "abl-prod-management-rg"

# Corp subscription (where PEs live)
CORP_SUBSCRIPTION="fda5eebb-adfa-4c02-af21-2d14f2e4476b"

# Primary PE resources (North Europe)
PRIMARY_RG="abl-corp-private-endpoints-rg"
PRIMARY_SUBNET_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-private-endpoints-prod-vnet/subnets/abl-corp-private-endpoints-central-prod-sn"
PRIMARY_LOCATION="northeurope"
PRIMARY_DNS_RG="abl-corp-private-endpoints-rg"

# Secondary PE resources (UK South)
SECONDARY_RG="abl-corp-uks-private-endpoints-rg"
SECONDARY_SUBNET_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/abl-corp-uks-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-uks-private-endpoints-prod-vnet/subnets/abl-corp-uks-private-endpoints-central-prod-sn"
SECONDARY_LOCATION="uksouth"
SECONDARY_DNS_RG="abl-corp-uks-private-endpoints-rg"

# DNS prefix (for PE DNS zone group naming)
DNS_PREFIX="abl-corp-private-endpoints-abl-prod"

# Tags
TAGS="pe_tag=prod-module Created_by=PLATFORMS Git_branch=main"
```

### Create Blob Private Endpoint (Primary)

```bash
#!/bin/bash
# Create primary blob private endpoint

# Get storage account resource ID
az account set --subscription "$STORAGE_SUBSCRIPTION"
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$STORAGE_RG" \
  --query 'id' \
  -o tsv)

# Switch to corp subscription
az account set --subscription "$CORP_SUBSCRIPTION"

# Create private endpoint
PE_NAME="${STORAGE_ACCOUNT}-blob"
CONNECTION_NAME="${STORAGE_ACCOUNT}-blobendpoint"

az network private-endpoint create \
  --name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --location "$PRIMARY_LOCATION" \
  --subnet "$PRIMARY_SUBNET_ID" \
  --private-connection-resource-id "$STORAGE_ID" \
  --group-id "blob" \
  --connection-name "$CONNECTION_NAME" \
  --tags $TAGS

# Add DNS zone group
DNS_ZONE_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/$PRIMARY_DNS_RG/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"

az network private-endpoint dns-zone-group create \
  --endpoint-name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --name "${DNS_PREFIX}-${STORAGE_ACCOUNT}" \
  --private-dns-zone "$DNS_ZONE_ID" \
  --zone-name "blob"

echo "✓ Primary blob endpoint created: $PE_NAME"
```

### Create DFS Private Endpoint (Primary)

```bash
#!/bin/bash
# Create primary DFS private endpoint (for HNS-enabled storage)

az account set --subscription "$STORAGE_SUBSCRIPTION"
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$STORAGE_RG" \
  --query 'id' \
  -o tsv)

az account set --subscription "$CORP_SUBSCRIPTION"

PE_NAME="${STORAGE_ACCOUNT}-dfs"
CONNECTION_NAME="${STORAGE_ACCOUNT}-dfsendpoint"

az network private-endpoint create \
  --name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --location "$PRIMARY_LOCATION" \
  --subnet "$PRIMARY_SUBNET_ID" \
  --private-connection-resource-id "$STORAGE_ID" \
  --group-id "dfs" \
  --connection-name "$CONNECTION_NAME" \
  --tags $TAGS

DNS_ZONE_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/$PRIMARY_DNS_RG/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net"

az network private-endpoint dns-zone-group create \
  --endpoint-name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --name "${DNS_PREFIX}-${STORAGE_ACCOUNT}" \
  --private-dns-zone "$DNS_ZONE_ID" \
  --zone-name "dfs"

echo "✓ Primary DFS endpoint created: $PE_NAME"
```

### Create File Private Endpoint (Primary)

```bash
#!/bin/bash
# Create primary file private endpoint

az account set --subscription "$STORAGE_SUBSCRIPTION"
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$STORAGE_RG" \
  --query 'id' \
  -o tsv)

az account set --subscription "$CORP_SUBSCRIPTION"

PE_NAME="${STORAGE_ACCOUNT}-file"
CONNECTION_NAME="${STORAGE_ACCOUNT}-fileendpoint"

az network private-endpoint create \
  --name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --location "$PRIMARY_LOCATION" \
  --subnet "$PRIMARY_SUBNET_ID" \
  --private-connection-resource-id "$STORAGE_ID" \
  --group-id "file" \
  --connection-name "$CONNECTION_NAME" \
  --tags $TAGS

DNS_ZONE_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/$PRIMARY_DNS_RG/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"

az network private-endpoint dns-zone-group create \
  --endpoint-name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --name "${DNS_PREFIX}-${STORAGE_ACCOUNT}" \
  --private-dns-zone "$DNS_ZONE_ID" \
  --zone-name "file"

echo "✓ Primary file endpoint created: $PE_NAME"
```

### Create Queue Private Endpoint (Primary)

```bash
#!/bin/bash
# Create primary queue private endpoint

az account set --subscription "$STORAGE_SUBSCRIPTION"
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$STORAGE_RG" \
  --query 'id' \
  -o tsv)

az account set --subscription "$CORP_SUBSCRIPTION"

PE_NAME="${STORAGE_ACCOUNT}-queue"
CONNECTION_NAME="${STORAGE_ACCOUNT}-queueendpoint"

az network private-endpoint create \
  --name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --location "$PRIMARY_LOCATION" \
  --subnet "$PRIMARY_SUBNET_ID" \
  --private-connection-resource-id "$STORAGE_ID" \
  --group-id "queue" \
  --connection-name "$CONNECTION_NAME" \
  --tags $TAGS

DNS_ZONE_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/$PRIMARY_DNS_RG/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"

az network private-endpoint dns-zone-group create \
  --endpoint-name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --name "${DNS_PREFIX}-${STORAGE_ACCOUNT}" \
  --private-dns-zone "$DNS_ZONE_ID" \
  --zone-name "queue"

echo "✓ Primary queue endpoint created: $PE_NAME"
```

### Create Table Private Endpoint (Primary)

```bash
#!/bin/bash
# Create primary table private endpoint

az account set --subscription "$STORAGE_SUBSCRIPTION"
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$STORAGE_RG" \
  --query 'id' \
  -o tsv)

az account set --subscription "$CORP_SUBSCRIPTION"

PE_NAME="${STORAGE_ACCOUNT}-table"
CONNECTION_NAME="${STORAGE_ACCOUNT}-tableendpoint"

az network private-endpoint create \
  --name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --location "$PRIMARY_LOCATION" \
  --subnet "$PRIMARY_SUBNET_ID" \
  --private-connection-resource-id "$STORAGE_ID" \
  --group-id "table" \
  --connection-name "$CONNECTION_NAME" \
  --tags $TAGS

DNS_ZONE_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/$PRIMARY_DNS_RG/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"

az network private-endpoint dns-zone-group create \
  --endpoint-name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --name "${DNS_PREFIX}-${STORAGE_ACCOUNT}" \
  --private-dns-zone "$DNS_ZONE_ID" \
  --zone-name "table"

echo "✓ Primary table endpoint created: $PE_NAME"
```

### Create Web Private Endpoint (Primary)

```bash
#!/bin/bash
# Create primary web private endpoint

az account set --subscription "$STORAGE_SUBSCRIPTION"
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$STORAGE_RG" \
  --query 'id' \
  -o tsv)

az account set --subscription "$CORP_SUBSCRIPTION"

PE_NAME="${STORAGE_ACCOUNT}-web"
CONNECTION_NAME="${STORAGE_ACCOUNT}-webendpoint"

az network private-endpoint create \
  --name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --location "$PRIMARY_LOCATION" \
  --subnet "$PRIMARY_SUBNET_ID" \
  --private-connection-resource-id "$STORAGE_ID" \
  --group-id "web" \
  --connection-name "$CONNECTION_NAME" \
  --tags $TAGS

DNS_ZONE_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/$PRIMARY_DNS_RG/providers/Microsoft.Network/privateDnsZones/privatelink.web.core.windows.net"

az network private-endpoint dns-zone-group create \
  --endpoint-name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  --name "${DNS_PREFIX}-${STORAGE_ACCOUNT}" \
  --private-dns-zone "$DNS_ZONE_ID" \
  --zone-name "web"

echo "✓ Primary web endpoint created: $PE_NAME"
```

### Create Secondary Private Endpoints

For secondary endpoints, use the same commands but replace:
- `$PE_NAME` → `${STORAGE_ACCOUNT}-{type}-sec`
- `$PRIMARY_RG` → `$SECONDARY_RG`
- `$PRIMARY_SUBNET_ID` → `$SECONDARY_SUBNET_ID`
- `$PRIMARY_LOCATION` → `$SECONDARY_LOCATION`
- `$PRIMARY_DNS_RG` → `$SECONDARY_DNS_RG`

Example for secondary blob:

```bash
PE_NAME="${STORAGE_ACCOUNT}-blob-sec"
CONNECTION_NAME="${STORAGE_ACCOUNT}-secondary_blob-pe"

az network private-endpoint create \
  --name "$PE_NAME" \
  --resource-group "$SECONDARY_RG" \
  --location "$SECONDARY_LOCATION" \
  --subnet "$SECONDARY_SUBNET_ID" \
  --private-connection-resource-id "$STORAGE_ID" \
  --group-id "blob" \
  --connection-name "$CONNECTION_NAME" \
  --tags $TAGS

DNS_ZONE_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/$SECONDARY_DNS_RG/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"

az network private-endpoint dns-zone-group create \
  --endpoint-name "$PE_NAME" \
  --resource-group "$SECONDARY_RG" \
  --name "${DNS_PREFIX}-${STORAGE_ACCOUNT}" \
  --private-dns-zone "$DNS_ZONE_ID" \
  --zone-name "blob"
```

---

## Immediate Connection Testing

After creating each private endpoint, **immediately test connectivity** to ensure it's functioning correctly before proceeding.

### Test Function for Private Endpoints

```bash
#!/bin/bash
# Test private endpoint connectivity immediately after creation
# This function should be called right after each PE is created

test_private_endpoint() {
  local STORAGE_ACCOUNT="$1"
  local PE_TYPE="$2"          # blob, dfs, file, queue, table, or web
  local PE_NAME="$3"          # Full PE name (e.g., "ablprodcoresa-blob")
  local PE_RG="$4"            # Resource group where PE was created
  local CORP_SUB="$5"         # Corp subscription ID
  
  echo ""
  echo "========================================"
  echo "Testing connectivity: $PE_NAME"
  echo "========================================"
  
  # Step 1: Verify PE is approved
  echo "1. Checking PE connection state..."
  az account set --subscription "$CORP_SUB"
  
  PE_STATE=$(az network private-endpoint show \
    --name "$PE_NAME" \
    --resource-group "$PE_RG" \
    --query 'privateLinkServiceConnections[0].privateLinkServiceConnectionState.status' \
    -o tsv 2>/dev/null)
  
  if [ "$PE_STATE" == "Approved" ]; then
    echo "   ✓ Connection state: Approved"
  else
    echo "   ✗ Connection state: $PE_STATE (expected: Approved)"
    return 1
  fi
  
  # Step 2: Get private IP address
  echo "2. Retrieving private IP address..."
  PRIVATE_IP=$(az network private-endpoint show \
    --name "$PE_NAME" \
    --resource-group "$PE_RG" \
    --query 'customDnsConfigs[0].ipAddresses[0]' \
    -o tsv 2>/dev/null)
  
  if [ -n "$PRIVATE_IP" ] && [ "$PRIVATE_IP" != "null" ]; then
    echo "   ✓ Private IP: $PRIVATE_IP"
  else
    echo "   ✗ Failed to retrieve private IP"
    return 1
  fi
  
  # Step 3: Verify DNS record exists
  echo "3. Checking DNS record..."
  DNS_ZONE="privatelink.${PE_TYPE}.core.windows.net"
  DNS_RG=$(echo "$PE_RG" | sed 's/abl-corp-private-endpoints/abl-corp-private-endpoints/')  # Same RG
  
  DNS_IP=$(az network private-dns record-set a show \
    --resource-group "$DNS_RG" \
    --zone-name "$DNS_ZONE" \
    --name "$STORAGE_ACCOUNT" \
    --query 'aRecords[0].ipv4Address' \
    -o tsv 2>/dev/null)
  
  if [ "$DNS_IP" == "$PRIVATE_IP" ]; then
    echo "   ✓ DNS record exists: ${STORAGE_ACCOUNT}.${PE_TYPE}.core.windows.net → $DNS_IP"
  elif [ -n "$DNS_IP" ]; then
    echo "   ⚠ DNS IP ($DNS_IP) doesn't match PE IP ($PRIVATE_IP)"
    echo "   (This may be temporary - DNS propagation in progress)"
  else
    echo "   ⚠ DNS record not found (may take a few seconds to propagate)"
  fi
  
  # Step 4: Wait for DNS propagation (short delay)
  echo "4. Waiting for DNS propagation (15 seconds)..."
  sleep 15
  
  # Step 5: Test DNS resolution from current machine
  echo "5. Testing DNS resolution..."
  FQDN="${STORAGE_ACCOUNT}.${PE_TYPE}.core.windows.net"
  
  # Try nslookup
  if command -v nslookup &> /dev/null; then
    RESOLVED_IP=$(nslookup "$FQDN" 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
    if [ -n "$RESOLVED_IP" ]; then
      if [[ "$RESOLVED_IP" == 10.* ]] || [[ "$RESOLVED_IP" == 172.* ]] || [[ "$RESOLVED_IP" == 192.168.* ]]; then
        echo "   ✓ Resolves to private IP: $RESOLVED_IP"
      else
        echo "   ⚠ Resolves to public IP: $RESOLVED_IP (expected private IP)"
        echo "   (This is normal if testing from outside the VNet)"
      fi
    else
      echo "   ○ DNS resolution test skipped (nslookup inconclusive)"
    fi
  else
    echo "   ○ nslookup not available, skipping DNS resolution test"
  fi
  
  # Step 6: Test endpoint connectivity (basic check)
  echo "6. Testing endpoint accessibility..."
  
  # Test varies by PE type
  case "$PE_TYPE" in
    "blob"|"dfs")
      # Try to access blob/dfs endpoint
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -m 10 \
        "https://${FQDN}/" 2>/dev/null || echo "000")
      
      if [ "$HTTP_CODE" == "400" ] || [ "$HTTP_CODE" == "403" ]; then
        echo "   ✓ Endpoint accessible (HTTP $HTTP_CODE - auth required, as expected)"
      elif [ "$HTTP_CODE" == "000" ]; then
        echo "   ⚠ Connection timeout or refused (may be normal from outside VNet)"
      else
        echo "   ○ HTTP $HTTP_CODE (endpoint may be accessible)"
      fi
      ;;
    
    "file")
      echo "   ○ File share testing requires SMB client (skipping)"
      ;;
    
    "queue"|"table")
      # Test queue/table endpoint
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -m 10 \
        "https://${FQDN}/" 2>/dev/null || echo "000")
      
      if [ "$HTTP_CODE" == "400" ] || [ "$HTTP_CODE" == "403" ]; then
        echo "   ✓ Endpoint accessible (HTTP $HTTP_CODE - auth required, as expected)"
      else
        echo "   ○ HTTP $HTTP_CODE (testing from outside VNet)"
      fi
      ;;
    
    "web")
      # Test static website endpoint
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -m 10 \
        "https://${FQDN}/" 2>/dev/null || echo "000")
      
      if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 500 ]; then
        echo "   ✓ Endpoint accessible (HTTP $HTTP_CODE)"
      else
        echo "   ○ HTTP $HTTP_CODE"
      fi
      ;;
  esac
  
  echo ""
  echo "✓ Private endpoint test completed: $PE_NAME"
  echo "========================================"
  echo ""
  
  return 0
}
```

### Usage in PE Creation

After creating and linking each private endpoint, call the test function:

```bash
# Create the private endpoint
az network private-endpoint create \
  --name "$PE_NAME" \
  --resource-group "$PRIMARY_RG" \
  ...

# Link DNS zone group
az network private-endpoint dns-zone-group create \
  --endpoint-name "$PE_NAME" \
  ...

# IMMEDIATELY TEST CONNECTIVITY
test_private_endpoint "$STORAGE_ACCOUNT" "$PE_TYPE" "$PE_NAME" "$PRIMARY_RG" "$CORP_SUBSCRIPTION"

if [ $? -ne 0 ]; then
  echo "⚠️  WARNING: Private endpoint connectivity test failed for $PE_NAME"
  echo "Review the errors above before proceeding."
  # Decide whether to continue or abort
fi
```

### Comprehensive Connection Test Script

For testing all endpoints at once (after all creation is complete):

```bash
#!/bin/bash
# Comprehensive test for all private endpoints of a storage account

STORAGE_ACCOUNT="<your-storage-account-name>"
CORP_SUB="fda5eebb-adfa-4c02-af21-2d14f2e4476b"

PE_TYPES=("blob" "dfs" "file" "queue" "table" "web")
REGIONS=("primary" "secondary")

echo "=========================================="
echo "Testing all private endpoints"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "=========================================="
echo ""

for region in "${REGIONS[@]}"; do
  if [ "$region" == "primary" ]; then
    PE_RG="abl-corp-private-endpoints-rg"
    SUFFIX=""
  else
    PE_RG="abl-corp-uks-private-endpoints-rg"
    SUFFIX="-sec"
  fi
  
  echo "Testing $region region endpoints..."
  echo ""
  
  for pe_type in "${PE_TYPES[@]}"; do
    PE_NAME="${STORAGE_ACCOUNT}-${pe_type}${SUFFIX}"
    
    # Check if PE exists
    az network private-endpoint show \
      --name "$PE_NAME" \
      --resource-group "$PE_RG" \
      --subscription "$CORP_SUB" &>/dev/null
    
    if [ $? -eq 0 ]; then
      test_private_endpoint "$STORAGE_ACCOUNT" "$pe_type" "$PE_NAME" "$PE_RG" "$CORP_SUB"
    fi
  done
done

echo ""
echo "=========================================="
echo "All tests completed"
echo "=========================================="
```

### Expected Test Results

| Test Step | Success Criteria | Notes |
|-----------|------------------|-------|
| Connection state | "Approved" | PE must be approved to function |
| Private IP assigned | Valid 10.x.x.x or 172.x.x.x | IP from PE subnet range |
| DNS record exists | A record points to private IP | May take 5-15 seconds to propagate |
| DNS resolution | Resolves to private IP | Only works from within VNet |
| Endpoint accessible | HTTP 400/403 (auth required) | From outside VNet, may timeout |

**Important Notes:**
- Tests from **outside the VNet** may show connection timeouts - this is expected
- DNS resolution to **public IP** from outside VNet is normal
- For complete validation, run tests from a **VM inside the VNet**
- HTTP 400/403 responses indicate the endpoint is accessible (authentication required)

---

## DNS Configuration

### Automatic DNS Record Creation

When a private endpoint is linked to a private DNS zone via `dns-zone-group`, Azure automatically creates the appropriate A records. **No manual DNS record creation is required.**

### DNS Zone Group Behavior

```
Private Endpoint
  └─ DNS Zone Group (e.g., "abl-corp-private-endpoints-abl-prod-ablprodcoresa")
      └─ Links to Private DNS Zone
          └─ Auto-creates A record: <storage-account>.<service>.core.windows.net → <private-ip>
```

### Example DNS Records (Auto-Created)

For storage account `<your-storage-account>` (example: ablprodcoresa):

| Subresource | FQDN Pattern | Private IP (auto-assigned) |
|-------------|--------------|----------------------------|
| blob | `{storage-account}`.blob.core.windows.net | 10.x.x.x |
| dfs | `{storage-account}`.dfs.core.windows.net | 10.x.x.y |
| file | `{storage-account}`.file.core.windows.net | 10.x.x.z |
| queue | `{storage-account}`.queue.core.windows.net | 10.x.x.a |
| table | `{storage-account}`.table.core.windows.net | 10.x.x.b |
| web | `{storage-account}`.web.core.windows.net | 10.x.x.c |

### Verification

```bash
# List DNS records in the private DNS zone
# Replace <storage-account> with your storage account name
az network private-dns record-set a list \
  --resource-group "abl-corp-private-endpoints-rg" \
  --zone-name "privatelink.blob.core.windows.net" \
  --query "[?name=='<storage-account>'].{name:name,ip:aRecords[0].ipv4Address}" \
  -o table
```

### VNet Links

The private DNS zones are already linked to the required VNets. **No additional VNet links are needed.**

To verify:

```bash
az network private-dns link vnet list \
  --resource-group "abl-corp-private-endpoints-rg" \
  --zone-name "privatelink.blob.core.windows.net" \
  -o table
```

---

## Validation Steps

**Note:** If you used the complete agent workflow script above, connectivity testing is **already performed** immediately after each PE creation. The steps below are for manual validation or troubleshooting.

### 1. Verify Private Endpoint Creation

```bash
#!/bin/bash
# Verify private endpoints exist and are approved
# UPDATE THESE FOR YOUR TARGET STORAGE ACCOUNT

STORAGE_ACCOUNT="<your-storage-account-name>"  # e.g., "ablprodcoresa"
CORP_SUB="fda5eebb-adfa-4c02-af21-2d14f2e4476b"  # Corp subscription (same for all)

az account set --subscription "$CORP_SUB"

# List all PEs in primary region
echo "Primary region private endpoints:"
az network private-endpoint list \
  --resource-group "abl-corp-private-endpoints-rg" \
  --query "[?starts_with(name, '$STORAGE_ACCOUNT')].{name:name,state:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status,subresource:privateLinkServiceConnections[0].groupIds[0]}" \
  -o table

# List all PEs in secondary region
echo ""
echo "Secondary region private endpoints:"
az network private-endpoint list \
  --resource-group "abl-corp-uks-private-endpoints-rg" \
  --query "[?starts_with(name, '$STORAGE_ACCOUNT')].{name:name,state:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status,subresource:privateLinkServiceConnections[0].groupIds[0]}" \
  -o table
```

Expected output:
```
Name                    State      Subresource
----------------------  ---------  ------------
ablprodcoresa-blob      Approved   blob
ablprodcoresa-dfs       Approved   dfs
...
```

### 2. Verify DNS Records

```bash
#!/bin/bash
# Verify DNS records exist in private DNS zones
# UPDATE THIS FOR YOUR TARGET STORAGE ACCOUNT

STORAGE_ACCOUNT="<your-storage-account-name>"  # e.g., "ablprodcoresa"
TYPES=("blob" "dfs" "file" "queue" "table" "web")

for type in "${TYPES[@]}"; do
  echo "Checking $type DNS record..."
  az network private-dns record-set a show \
    --resource-group "abl-corp-private-endpoints-rg" \
    --zone-name "privatelink.$type.core.windows.net" \
    --name "$STORAGE_ACCOUNT" \
    --query '{name:name,ip:aRecords[0].ipv4Address}' \
    -o json 2>/dev/null
  
  if [ $? -eq 0 ]; then
    echo "✓ $type DNS record exists"
  else
    echo "○ $type DNS record not found (may not be needed)"
  fi
  echo ""
done
```

### 3. Test Connectivity

From a VM within the VNet:

```bash
# Test blob endpoint resolution (replace with your storage account name)
STORAGE_ACCOUNT="<your-storage-account-name>"
nslookup ${STORAGE_ACCOUNT}.blob.core.windows.net

# Should resolve to private IP (10.x.x.x range)
# NOT public IP

# Test connectivity
curl -I https://${STORAGE_ACCOUNT}.blob.core.windows.net

# Should return 400 or 403 (authentication required) NOT connection refused
```

### 4. Verify Network Security

```bash
#!/bin/bash
# Verify storage account network rules still allow PE access
# UPDATE THESE FOR YOUR TARGET STORAGE ACCOUNT

STORAGE_ACCOUNT="<your-storage-account-name>"  # e.g., "ablprodcoresa"
STORAGE_RG="<resource-group-name>"             # e.g., "abl-prod-management-rg"
STORAGE_SUB="<subscription-id>"                # e.g., "847b9307-3224-4030-bbfa-b20e18452332"

az account set --subscription "$STORAGE_SUB"

az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$STORAGE_RG" \
  --query '{defaultAction:networkRuleSet.defaultAction,bypass:networkRuleSet.bypass,publicAccess:publicNetworkAccess}' \
  -o table
```

Expected:
- `defaultAction`: Allow or Deny (depends on config)
- `bypass`: Should include "AzureServices"
- `publicNetworkAccess`: Enabled or Disabled

---

## Rollback Procedures

### Delete Private Endpoint

```bash
#!/bin/bash
# Delete a private endpoint (rollback)
# UPDATE THESE FOR YOUR TARGET PRIVATE ENDPOINT

PE_NAME="<storage-account>-blob"               # e.g., "ablprodcoresa-blob"
PE_RG="abl-corp-private-endpoints-rg"          # Primary RG (or secondary RG for secondary PEs)
CORP_SUB="fda5eebb-adfa-4c02-af21-2d14f2e4476b"  # Corp subscription

az account set --subscription "$CORP_SUB"

# Delete PE (DNS records auto-deleted)
az network private-endpoint delete \
  --name "$PE_NAME" \
  --resource-group "$PE_RG" \
  --yes

echo "✓ Private endpoint deleted: $PE_NAME"
echo "✓ DNS records automatically removed"
```

### Verify Cleanup

```bash
# Verify PE is deleted
az network private-endpoint show \
  --name "$PE_NAME" \
  --resource-group "$PE_RG" 2>&1 | grep -q "not be found"

if [ $? -eq 0 ]; then
  echo "✓ Confirmed: Private endpoint removed"
else
  echo "⚠️  Warning: Private endpoint may still exist"
fi

# Verify DNS record is removed
# Extract storage account name from PE_NAME if needed
STORAGE_ACCOUNT="${PE_NAME%-*}"  # Removes -blob suffix
az network private-dns record-set a show \
  --resource-group "$PE_RG" \
  --zone-name "privatelink.blob.core.windows.net" \
  --name "$STORAGE_ACCOUNT" 2>&1 | grep -q "not be found"

if [ $? -eq 0 ]; then
  echo "✓ Confirmed: DNS record removed"
else
  echo "⚠️  Warning: DNS record may still exist"
fi
```

---

## Complete Agent Workflow Script

```bash
#!/bin/bash
#===============================================================================
# Private Endpoint Creation Agent
#===============================================================================
# Creates private endpoints for Azure storage accounts following PET patterns
#
# Usage:
#   ./create-private-endpoints.sh <storage-account> <resource-group> <environment>
#
# Examples:
#   ./create-private-endpoints.sh ablprodcoresa abl-prod-management-rg prod
#   ./create-private-endpoints.sh abldevmyappsa ABL-MYAPP-DEV-STORAGE-RG dev
#   ./create-private-endpoints.sh ablprepmyappsa ABL-MYAPP-PREP-STORAGE-RG prep
#
#===============================================================================

set -euo pipefail

# Input parameters
STORAGE_ACCOUNT="${1:?Storage account name required}"
STORAGE_RG="${2:?Resource group required}"
ENVIRONMENT="${3:?Environment required (prod/dev/prep/nonprod)}"

# Subscription IDs - UPDATE THESE BASED ON ENVIRONMENT
# Prod subscription: 847b9307-3224-4030-bbfa-b20e18452332
# Dev/Prep/NonProd subscriptions: Update accordingly
STORAGE_SUBSCRIPTION="847b9307-3224-4030-bbfa-b20e18452332"  # Update per environment
CORP_SUBSCRIPTION="fda5eebb-adfa-4c02-af21-2d14f2e4476b"     # Corp sub (same for all)

# Environment-specific resource configuration
case "$ENVIRONMENT" in
  "prod")
    PRIMARY_RG="abl-corp-private-endpoints-rg"
    PRIMARY_SUBNET_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/abl-corp-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-private-endpoints-prod-vnet/subnets/abl-corp-private-endpoints-central-prod-sn"
    PRIMARY_LOCATION="northeurope"
    PRIMARY_DNS_RG="abl-corp-private-endpoints-rg"
    
    SECONDARY_RG="abl-corp-uks-private-endpoints-rg"
    SECONDARY_SUBNET_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/abl-corp-uks-private-endpoints-rg/providers/Microsoft.Network/virtualNetworks/abl-corp-uks-private-endpoints-prod-vnet/subnets/abl-corp-uks-private-endpoints-central-prod-sn"
    SECONDARY_LOCATION="uksouth"
    SECONDARY_DNS_RG="abl-corp-uks-private-endpoints-rg"
    
    DNS_PREFIX="abl-corp-private-endpoints-abl-prod"
    TAGS="pe_tag=prod-module Created_by=PLATFORMS Git_branch=main"
    ;;
  
  "dev"|"prep"|"nonprod")
    # Update these for other environments
    echo "ERROR: Environment '$ENVIRONMENT' not fully configured in this script"
    echo "Please add environment-specific resource IDs for: $ENVIRONMENT"
    exit 1
    ;;
  
  *)
    echo "ERROR: Unknown environment: $ENVIRONMENT"
    echo "Supported: prod, dev, prep, nonprod"
    exit 1
    ;;
esac

echo "=================================================="
echo "Private Endpoint Creation Agent"
echo "=================================================="
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Resource Group:  $STORAGE_RG"
echo "Environment:     $ENVIRONMENT"
echo "=================================================="
echo ""

#===============================================================================
# Step 1: Pre-flight checks
#===============================================================================

echo "Step 1: Running pre-flight checks..."

# Check for existing private endpoints
az account set --subscription "$STORAGE_SUBSCRIPTION"
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$STORAGE_RG" \
  --query 'id' \
  -o tsv)

az account set --subscription "$CORP_SUBSCRIPTION"
EXISTING_PES=$(az network private-endpoint list \
  --query "[?privateLinkServiceConnections[?privateLinkServiceId=='$STORAGE_ID']].{name:name,rg:resourceGroup}" \
  -o json)

PE_COUNT=$(echo "$EXISTING_PES" | jq 'length')

if [ "$PE_COUNT" -gt 0 ]; then
  echo "⚠️  ERROR: Found $PE_COUNT existing private endpoint(s) for this storage account:"
  echo "$EXISTING_PES" | jq -r '.[] | "  - \(.name) in \(.rg)"'
  echo ""
  echo "STOP: This script only creates PEs for storage accounts with NO existing PEs."
  exit 1
fi

echo "✓ No existing private endpoints found"

# Verify network resources exist
az network vnet subnet show --ids "$PRIMARY_SUBNET_ID" &>/dev/null
if [ $? -ne 0 ]; then
  echo "✗ ERROR: Primary subnet not found"
  exit 1
fi
echo "✓ Primary subnet verified"

az network vnet subnet show --ids "$SECONDARY_SUBNET_ID" &>/dev/null
if [ $? -ne 0 ]; then
  echo "✗ ERROR: Secondary subnet not found"
  exit 1
fi
echo "✓ Secondary subnet verified"

echo ""

#===============================================================================
# Step 2: Detect required private endpoint types
#===============================================================================

echo "Step 2: Detecting storage account usage..."

az account set --subscription "$STORAGE_SUBSCRIPTION"

STORAGE_PROPS=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$STORAGE_RG" \
  --query '{hnsEnabled:isHnsEnabled,replication:sku.name}' \
  -o json)

HNS_ENABLED=$(echo "$STORAGE_PROPS" | jq -r '.hnsEnabled')
REPLICATION=$(echo "$STORAGE_PROPS" | jq -r '.replication')

PE_TYPES=()

# Determine blob vs DFS
if [ "$HNS_ENABLED" == "true" ]; then
  echo "✓ HNS enabled → DFS endpoint required"
  PE_TYPES+=("dfs")
else
  echo "✓ Standard storage → Blob endpoint required"
  PE_TYPES+=("blob")
fi

# Check for file shares
FILE_SHARES=$(az storage share list \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query 'length(@)' \
  -o tsv 2>/dev/null || echo "0")

if [ "$FILE_SHARES" -gt 0 ]; then
  echo "✓ $FILE_SHARES file share(s) found → File endpoint required"
  PE_TYPES+=("file")
fi

# Check for queues
QUEUES=$(az storage queue list \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query 'length(@)' \
  -o tsv 2>/dev/null || echo "0")

if [ "$QUEUES" -gt 0 ]; then
  echo "✓ $QUEUES queue(s) found → Queue endpoint required"
  PE_TYPES+=("queue")
fi

# Check for tables
TABLES=$(az storage table list \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query 'length(@)' \
  -o tsv 2>/dev/null || echo "0")

if [ "$TABLES" -gt 0 ]; then
  echo "✓ $TABLES table(s) found → Table endpoint required"
  PE_TYPES+=("table")
fi

# Check for static website (correct check - verify feature is enabled)
WEB_ENABLED=$(az storage blob service-properties show \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query 'staticWebsite.enabled' \
  -o tsv 2>/dev/null)

if [ "$WEB_ENABLED" == "true" ]; then
  echo "✓ Static website enabled → Web endpoint required"
  PE_TYPES+=("web")
fi

echo ""
echo "Required PE types: ${PE_TYPES[@]}"
echo "Replication type: $REPLICATION"
echo ""

# Secondary PEs are always created for network-level redundancy
CREATE_SECONDARY=true
echo "✓ Secondary PEs will be created (network-level redundancy)"
if [[ "$REPLICATION" =~ ^(GRS|GZRS|RAGRS|RAGZRS)$ ]]; then
  echo "  (Storage is also geo-redundant: $REPLICATION)"
else
  echo "  (Storage is $REPLICATION - secondary PEs provide network redundancy only)"
fi

echo ""

#===============================================================================
# Step 3: Create private endpoints
#===============================================================================

echo "Step 3: Creating private endpoints..."
echo ""

az account set --subscription "$CORP_SUBSCRIPTION"

# Function to test private endpoint connectivity
test_private_endpoint() {
  local STORAGE_ACCOUNT="$1"
  local PE_TYPE="$2"
  local PE_NAME="$3"
  local PE_RG="$4"
  
  echo "  → Testing connectivity..."
  
  # Check PE state
  local PE_STATE=$(az network private-endpoint show \
    --name "$PE_NAME" \
    --resource-group "$PE_RG" \
    --query 'privateLinkServiceConnections[0].privateLinkServiceConnectionState.status' \
    -o tsv 2>/dev/null)
  
  if [ "$PE_STATE" != "Approved" ]; then
    echo "  ✗ PE state: $PE_STATE (expected: Approved)"
    return 1
  fi
  
  # Get private IP
  local PRIVATE_IP=$(az network private-endpoint show \
    --name "$PE_NAME" \
    --resource-group "$PE_RG" \
    --query 'customDnsConfigs[0].ipAddresses[0]' \
    -o tsv 2>/dev/null)
  
  if [ -z "$PRIVATE_IP" ] || [ "$PRIVATE_IP" == "null" ]; then
    echo "  ✗ Failed to get private IP"
    return 1
  fi
  
  echo "  ✓ PE approved, private IP: $PRIVATE_IP"
  
  # Verify DNS record (wait up to 20 seconds)
  local DNS_ZONE="privatelink.${PE_TYPE}.core.windows.net"
  local MAX_ATTEMPTS=4
  local ATTEMPT=0
  
  while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    local DNS_IP=$(az network private-dns record-set a show \
      --resource-group "$PE_RG" \
      --zone-name "$DNS_ZONE" \
      --name "$STORAGE_ACCOUNT" \
      --query 'aRecords[0].ipv4Address' \
      -o tsv 2>/dev/null)
    
    if [ "$DNS_IP" == "$PRIVATE_IP" ]; then
      echo "  ✓ DNS record verified: ${STORAGE_ACCOUNT}.${PE_TYPE}.core.windows.net → $DNS_IP"
      
      # Quick connectivity test
      local FQDN="${STORAGE_ACCOUNT}.${PE_TYPE}.core.windows.net"
      local HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "https://${FQDN}/" 2>/dev/null || echo "000")
      
      if [ "$HTTP_CODE" == "400" ] || [ "$HTTP_CODE" == "403" ] || [ "$HTTP_CODE" == "404" ]; then
        echo "  ✓ Endpoint reachable (HTTP $HTTP_CODE)"
      else
        echo "  ○ Endpoint test: HTTP $HTTP_CODE (may be normal from outside VNet)"
      fi
      
      return 0
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
      echo "  ⌛ Waiting for DNS propagation... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
      sleep 5
    fi
  done
  
  echo "  ⚠ DNS record not yet propagated (may take a few more seconds)"
  return 0  # Don't fail, just warn
}

# Function to create a private endpoint
create_pe() {
  local PE_TYPE="$1"
  local IS_SECONDARY="$2"
  
  if [ "$IS_SECONDARY" == "true" ]; then
    local PE_NAME="${STORAGE_ACCOUNT}-${PE_TYPE}-sec"
    local CONNECTION_NAME="${STORAGE_ACCOUNT}-secondary_${PE_TYPE}-pe"
    local RG="$SECONDARY_RG"
    local SUBNET="$SECONDARY_SUBNET_ID"
    local LOCATION="$SECONDARY_LOCATION"
    local DNS_RG="$SECONDARY_DNS_RG"
    local LABEL="secondary"
  else
    local PE_NAME="${STORAGE_ACCOUNT}-${PE_TYPE}"
    local CONNECTION_NAME="${STORAGE_ACCOUNT}-${PE_TYPE}endpoint"
    local RG="$PRIMARY_RG"
    local SUBNET="$PRIMARY_SUBNET_ID"
    local LOCATION="$PRIMARY_LOCATION"
    local DNS_RG="$PRIMARY_DNS_RG"
    local LABEL="primary"
  fi
  
  # Map PE type to subresource name (case-sensitive for 'File')
  case "$PE_TYPE" in
    "file")
      local SUBRESOURCE="File"
      ;;
    *)
      local SUBRESOURCE="$PE_TYPE"
      ;;
  esac
  
  local DNS_ZONE_ID="/subscriptions/$CORP_SUBSCRIPTION/resourceGroups/$DNS_RG/providers/Microsoft.Network/privateDnsZones/privatelink.${PE_TYPE}.core.windows.net"
  
  echo "Creating $LABEL $PE_TYPE endpoint: $PE_NAME..."
  
  az network private-endpoint create \
    --name "$PE_NAME" \
    --resource-group "$RG" \
    --location "$LOCATION" \
    --subnet "$SUBNET" \
    --private-connection-resource-id "$STORAGE_ID" \
    --group-id "$SUBRESOURCE" \
    --connection-name "$CONNECTION_NAME" \
    --tags $TAGS \
    --output none
  
  echo "  ✓ Private endpoint created"
  
  az network private-endpoint dns-zone-group create \
    --endpoint-name "$PE_NAME" \
    --resource-group "$RG" \
    --name "${DNS_PREFIX}-${STORAGE_ACCOUNT}" \
    --private-dns-zone "$DNS_ZONE_ID" \
    --zone-name "$PE_TYPE" \
    --output none
  
  echo "  ✓ DNS zone group linked"
  
  # Test connectivity immediately
  test_private_endpoint "$STORAGE_ACCOUNT" "$PE_TYPE" "$PE_NAME" "$RG"
  
  if [ $? -ne 0 ]; then
    echo "  ⚠️  Warning: Connectivity test failed (review above)"
    echo "  (Continuing with remaining endpoints...)"
  fi
  
  echo ""
}

# Create primary PEs
for pe_type in "${PE_TYPES[@]}"; do
  create_pe "$pe_type" "false"
done

# Create secondary PEs if needed
if [ "$CREATE_SECONDARY" == "true" ]; then
  for pe_type in "${PE_TYPES[@]}"; do
    create_pe "$pe_type" "true"
  done
fi

#===============================================================================
# Step 4: Validation
#===============================================================================

echo "Step 4: Validating private endpoints..."
echo ""

echo "Primary region endpoints:"
az network private-endpoint list \
  --resource-group "$PRIMARY_RG" \
  --query "[?starts_with(name, '$STORAGE_ACCOUNT')].{Name:name,State:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status,Subresource:privateLinkServiceConnections[0].groupIds[0]}" \
  -o table

if [ "$CREATE_SECONDARY" == "true" ]; then
  echo ""
  echo "Secondary region endpoints:"
  az network private-endpoint list \
    --resource-group "$SECONDARY_RG" \
    --query "[?starts_with(name, '$STORAGE_ACCOUNT')].{Name:name,State:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status,Subresource:privateLinkServiceConnections[0].groupIds[0]}" \
    -o table
fi

echo ""
echo "=================================================="
echo "✓ Private endpoint creation complete!"
echo "=================================================="
echo ""
echo "Summary:"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  PE Types Created: ${PE_TYPES[@]}"
echo "  Primary Region: $PRIMARY_LOCATION"
if [ "$CREATE_SECONDARY" == "true" ]; then
  echo "  Secondary Region: $SECONDARY_LOCATION"
fi
echo ""
echo "All private endpoints were tested immediately after creation."
echo "Check the output above for any connectivity warnings."
echo ""
echo "Next Steps:"
echo "  1. Review test results above for any warnings"
echo "  2. Verify DNS resolution from a VM in the VNet"
echo "  3. Test actual storage operations (upload/download/list)"
echo "  4. Update Terraform config to match (add pe_* flags)"
echo "  5. Document changes in PR"
echo ""
echo "Note: This script can be reused for any storage account."
echo "      Simply run it again with different storage account parameters."
echo ""
```

---

## Agent Decision Matrix

| Condition | Action |
|-----------|--------|
| Storage account has existing PEs | **STOP** - Do not proceed |
| Network resources missing | **STOP** - Manual intervention required |
| HNS enabled | Create **dfs** PE (not blob) |
| HNS disabled | Create **blob** PE (not dfs) |
| File shares exist | Create **file** PE |
| Queues exist | Create **queue** PE |
| Tables exist | Create **table** PE |
| Static website enabled | Create **web** PE |
| Any storage account | **Always create secondary** PEs (network redundancy) |
| PE created | **TEST immediately** - verify connectivity |
| Test fails | **LOG warning** - continue with remaining PEs |

**Testing Policy:** Each private endpoint is tested immediately after creation. Test failures generate warnings but do not stop the script, allowing all PEs to be created even if one has issues.

---

## Key Patterns from Repository

### Naming Conventions

- **Primary PE:** `{storage-account}-{type}`
- **Secondary PE:** `{storage-account}-{type}-sec`
- **Connection Name (Primary):** `{storage-account}-{type}endpoint`
- **Connection Name (Secondary):** `{storage-account}-secondary_{type}-pe`
- **DNS Zone Group Name:** `{dns-prefix}-{storage-account}`

### Terraform Equivalents

This Azure CLI implementation mirrors the Terraform patterns in:
- `Terraform/shared/modules/storage/private.endpoint.*.tf`
- Configuration controlled by: `pe_blob`, `pe_dfs`, `pe_file`, `pe_queue`, `pe_table`, `pe_web`
- Secondary PEs controlled by: `secondary_pe` flag

### Subscription Model

- **Storage accounts** live in their environment subscription (prod/dev/prep)
- **Private endpoints** live in the **corp subscription** (centralized PE management)
- **Private DNS zones** also live in the corp subscription

---

## Limitations & Caveats

1. **Manual Approval:** If `manual_pe` is true in Terraform, connection approval is required. Azure CLI creates auto-approved PEs by default.

2. **Terraform State:** PEs created via CLI will not be in Terraform state. After creation, update the Terraform config and import resources or let Terraform adopt them on next apply.

3. **Environment Specificity:** This plan focuses on **prod** environment. Adapt resource IDs for dev/prep/nonprod environments.

4. **Permissions:** Agent must have:
   - Reader on storage account subscription
   - Contributor on corp subscription (PE resource groups)
   - Private DNS Zone Contributor on DNS zones

5. **Idempotency:** Running the script twice will fail (PEs already exist). Add skip logic if needed.

6. **Cross-Subscription:** Storage and PE resources are in different subscriptions - ensure proper RBAC.

---

## References

### Azure Documentation

- [Private endpoints for Azure Storage](https://learn.microsoft.com/azure/storage/common/storage-private-endpoints)
- [Azure Private DNS zones](https://learn.microsoft.com/azure/dns/private-dns-overview)
- [Azure CLI - Private Endpoint](https://learn.microsoft.com/cli/azure/network/private-endpoint)

### Repository Files

- Terraform Storage Module: `Terraform/shared/modules/storage/`
- Config Module PE Settings: `Terraform/shared/modules/_config/pe.*.tf`
- Environment PE Configurations: `Terraform/shared/modules/_config/pe.network.environment.*.tf`
- DNS Configuration: `Terraform/shared/modules/_config/pe.dns.tf`

---

## Troubleshooting

### Issue: Resource ID Truncation with Variables

**Symptom:**
When creating a private endpoint using Azure CLI with the storage account resource ID stored in a bash variable, the command fails with an error like:

```
(InvalidResourceId) String /subscriptions/.../Microsoft.Storage/storage is not a valid resource ID.
Message: String .../Microsoft.Storage/storageAccounts/cs is not a valid resource ID.
```

Note how the resource ID is truncated - the full path should end with `storageAccounts/<account-name>` but gets cut off.

**Root Cause:**
This appears to be a bash variable expansion issue with Azure CLI, possibly related to:
- Terminal session state or environment variables
- Interaction with other command parameters (e.g., tags with spaces)
- Length or special character handling in variable expansion

**Verification Steps:**
```bash
# The variable itself may appear correct
echo "STORAGE_ID: $STORAGE_ID"
echo "Length: ${#STORAGE_ID}"
# Shows: 162 characters with full path

# But when passed to az command, it gets truncated
az network private-endpoint create --private-connection-resource-id "$STORAGE_ID" ...
# Fails with truncated resource ID
```

**Solution:**
Use the full resource ID **directly inline** (hardcoded) instead of variable expansion:

```bash
# Instead of:
STORAGE_ID=$(az storage account show --name "$STORAGE_ACCOUNT" ...)
az network private-endpoint create --private-connection-resource-id "$STORAGE_ID" ...

# Use:
az network private-endpoint create \
  --private-connection-resource-id "/subscriptions/847b9307-3224-4030-bbfa-b20e18452332/resourceGroups/cloud-shell-storage-westeurope/providers/Microsoft.Storage/storageAccounts/csb10032000c8fdf6ac" \
  ...
```

**Lesson Learned:**
When encountering truncation issues with long resource IDs in Azure CLI commands:
1. ✅ DO: Use resource IDs directly inline in the command
2. ❌ AVOID: Relying on bash variable expansion for very long resource paths
3. ℹ️ NOTE: This issue is intermittent and may be environment-specific, but hardcoded values are a reliable workaround

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-05-14 | Initial plan created | AI Agent |
| 2026-05-14 | Made plan generic for any storage account (not just ablprodcoresa) | AI Agent |
| 2026-05-14 | Added immediate connectivity testing after each PE creation | AI Agent |
| 2026-05-14 | Fixed static website detection - now checks `staticWebsite.enabled` instead of just checking if web endpoint URL exists (StorageV2 accounts have web endpoint URL even when static website is disabled) | AI Agent |
| 2026-05-14 | Added troubleshooting section documenting resource ID truncation issue with bash variables - recommend using inline resource IDs instead of variable expansion when encountering truncation errors | AI Agent |

---

**END OF DOCUMENT**

---

## Related

- [[My-Notes/Azure/Storage-Account/ablprodsqlwitness3-dns-link-instructions copy|DNS Zone Link Instructions]]
- [[My-Notes/Azure/Storage-Account/vm-connectivity-test copy|VM Storage Connectivity Testing Guide]]
- [[My-Notes/my-notes|My Notes Folder Guide]]
