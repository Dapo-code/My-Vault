---
title: VM Storage Connectivity Testing Guide
tags:
    - azure
    - storage-account
    - connectivity
    - vm
    - runbook
created: 2026-05-14
updated: 2026-06-17
---

# VM Storage Connectivity Testing Guide

## Linked Notes

- [[My-Notes/Azure/Storage-Account/privateendpoint copy|Private Endpoint Creation Plan]]
- [[My-Notes/Azure/Storage-Account/storage-network-rules.skill copy|Storage Network Rules Configuration]]
- [[My-Notes/Azure/Storage-Account/ablprodsqlwitness3-dns-link-instructions copy|DNS Zone Link Instructions]]

**Purpose:** Test VM connectivity to Azure Storage Account before disabling public access

**Target Storage Account:** `ablprodbanklayerrg892`  
**Resource Group:** `abl-prod-banklayer-rg`  
**Test VMs:** prd-bl-dfs-01, prd-bl-dfs-02, prd-bl-fts-01, prd-ifrs9-01

---

## Why Test First?

Before disabling public access to a production storage account, you must verify that:
1. VMs can resolve the storage account's private DNS name
2. VMs can reach the storage account via private endpoints
3. Diagnostic agents can write data after network changes
4. No service disruption will occur

---

## Pre-Requisites

- [x] RDP/SSH access to test VMs
- [x] Administrator/root privileges on VMs
- [x] Azure CLI or PowerShell installed on your workstation
- [x] Storage account access keys or Azure AD permissions

---

## Phase 1: Pre-Change Baseline Tests

Run these tests **before** making any network changes to establish a baseline.

### Step 1.1: Choose a Test VM

**Recommendation:** Test VM **without** Microsoft.Storage service endpoint first:
- `prd-bl-dfs-01` (abl-prod-banklayer-dfs-sn) - NO service endpoint
- Alternative: `prd-bl-fts-01` or `prd-ifrs9-01`

**Why?** These VMs are most at risk and will rely on private endpoints after the change.

### Step 1.2: Connect to the VM

```powershell
# Option A: From Azure Portal
# 1. Navigate to VM in Azure Portal
# 2. Click "Connect" → "RDP" or "Bastion"
# 3. Download RDP file and connect

# Option B: Using Azure CLI (get RDP file)
az vm show --resource-group abl-prod-banklayer-rg --name prd-bl-dfs-01 --show-details --query "publicIps" -o tsv
```

### Step 1.3: DNS Resolution Test (Current Public DNS)

**On the VM, open PowerShell as Administrator:**

```powershell
# Test 1: Resolve storage account FQDN
$storageFQDN = "ablprodbanklayerrg892.blob.core.windows.net"
Write-Host "=== DNS Resolution Test ===" -ForegroundColor Cyan
Resolve-DnsName $storageFQDN | Format-Table -AutoSize

# Expected: Should resolve to PUBLIC IP address (e.g., 20.x.x.x or similar)
# Save this output for comparison

# Test 2: Check if private DNS is already working
Resolve-DnsName $storageFQDN -Type A | Where-Object { $_.IP4Address -match "^10\." }
# If this returns 10.x.x.x, private endpoint DNS is already configured
```

**Save the output:**
```powershell
# Save to file for comparison
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputFile = "C:\Temp\storage-dns-before-$timestamp.txt"
New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null

Resolve-DnsName $storageFQDN | Out-File $outputFile
Write-Host "DNS results saved to: $outputFile" -ForegroundColor Green
```

### Step 1.4: HTTP Connectivity Test

```powershell
# Test 3: HTTP/HTTPS connectivity to blob endpoint
Write-Host "`n=== HTTP Connectivity Test ===" -ForegroundColor Cyan

$blobUrl = "https://ablprodbanklayerrg892.blob.core.windows.net/"
$tableUrl = "https://ablprodbanklayerrg892.table.core.windows.net/"

# Test blob endpoint
try {
    $response = Invoke-WebRequest -Uri $blobUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✓ Blob endpoint reachable - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Blob response: $($_.Exception.Message)" -ForegroundColor Yellow
    # Note: 400 or 403 is OK - it means connection succeeded but auth failed
    # Connection timeout or DNS failure is BAD
}

# Test table endpoint
try {
    $response = Invoke-WebRequest -Uri $tableUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✓ Table endpoint reachable - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Table response: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Expected: HTTP 400 or 403 (authentication required) - this is GOOD
# Connection timeout or DNS failure - this is BAD
```

### Step 1.5: Test Current WAD Agent Status

```powershell
# Test 4: Check Windows Azure Diagnostics agent
Write-Host "`n=== WAD Agent Status ===" -ForegroundColor Cyan

# Check if WAD service is running
$wadService = Get-Service | Where-Object { $_.Name -like "*Diagnostic*" -or $_.Name -like "*Monitoring*" }
if ($wadService) {
    $wadService | Format-Table Name, Status, DisplayName -AutoSize
} else {
    Write-Host "No diagnostic services found" -ForegroundColor Yellow
}

# Check recent WAD logs
$wadLogPath = "C:\WindowsAzure\Logs\Plugins\Microsoft.Azure.Diagnostics.IaaSDiagnostics"
if (Test-Path $wadLogPath) {
    Write-Host "`nRecent WAD logs:"
    Get-ChildItem $wadLogPath -Recurse -Filter "*.log" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 3 | 
        ForEach-Object {
            Write-Host "  $($_.FullName) - Modified: $($_.LastWriteTime)"
        }
} else {
    Write-Host "WAD log path not found" -ForegroundColor Yellow
}

# Check OMS/MMA agent
$mmaService = Get-Service "HealthService" -ErrorAction SilentlyContinue
if ($mmaService) {
    Write-Host "`nMicrosoft Monitoring Agent (MMA):"
    Write-Host "  Status: $($mmaService.Status)" -ForegroundColor Green
}
```

### Step 1.6: Network Route Test

```powershell
# Test 5: Check network route to storage account
Write-Host "`n=== Network Route Test ===" -ForegroundColor Cyan

# Get IP address of storage account
$storageIP = (Resolve-DnsName $storageFQDN -Type A).IP4Address | Select-Object -First 1
Write-Host "Storage Account IP: $storageIP"

# Test network path
if ($storageIP) {
    Write-Host "`nTesting connectivity..."
    Test-NetConnection -ComputerName $storageFQDN -Port 443 -InformationLevel Detailed
    
    # Check if going through public internet or private network
    if ($storageIP -match "^10\." -or $storageIP -match "^172\." -or $storageIP -match "^192\.168\.") {
        Write-Host "✓ Using PRIVATE endpoint" -ForegroundColor Green
    } else {
        Write-Host "→ Using PUBLIC endpoint (expected before change)" -ForegroundColor Yellow
    }
}
```

### Step 1.7: Baseline Summary Report

```powershell
# Create summary report
Write-Host "`n=== BASELINE TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "VM Name: $env:COMPUTERNAME"
Write-Host "Timestamp: $(Get-Date)"
Write-Host "Storage Account: ablprodbanklayerrg892"
Write-Host ""
Write-Host "DNS Resolution: $(if ((Resolve-DnsName $storageFQDN -ErrorAction SilentlyContinue)) { '✓ SUCCESS' } else { '✗ FAILED' })"
Write-Host "Blob Endpoint: $(if ((Test-NetConnection ablprodbanklayerrg892.blob.core.windows.net -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded) { '✓ REACHABLE' } else { '✗ UNREACHABLE' })"
Write-Host "Table Endpoint: $(if ((Test-NetConnection ablprodbanklayerrg892.table.core.windows.net -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded) { '✓ REACHABLE' } else { '✗ UNREACHABLE' })"
Write-Host ""
Write-Host "Save this output for comparison after network changes!" -ForegroundColor Yellow
```

---

## Phase 2: Enable Service Endpoints (Preparation)

**Before disabling public access**, enable Microsoft.Storage service endpoint on the VM's subnet.

### Step 2.1: Enable Service Endpoint (From Workstation)

**Run from your workstation (not the VM):**

```bash
# Get VM's subnet name
VM_NAME="prd-bl-dfs-01"
RESOURCE_GROUP="abl-prod-banklayer-rg"
VNET_NAME="abl-prod-banklayer-vnet"

# Get current subnet
SUBNET_ID=$(az vm show --name $VM_NAME --resource-group $RESOURCE_GROUP \
  --query "networkProfile.networkInterfaces[0].id" -o tsv | \
  xargs az network nic show --ids | \
  jq -r '.ipConfigurations[0].subnet.id')

SUBNET_NAME=$(echo $SUBNET_ID | awk -F'/' '{print $NF}')

echo "VM: $VM_NAME"
echo "Subnet: $SUBNET_NAME"

# Check current service endpoints
echo ""
echo "Current service endpoints:"
az network vnet subnet show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --query "serviceEndpoints[].service" -o table

# Enable Microsoft.Storage service endpoint
echo ""
echo "Enabling Microsoft.Storage service endpoint..."
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --service-endpoints Microsoft.Storage

# Verify
echo ""
echo "Updated service endpoints:"
az network vnet subnet show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --query "serviceEndpoints[].service" -o table
```

### Step 2.2: Verify Service Endpoint (No Restart Required)

Service endpoints are effective immediately - no VM restart needed!

**From the VM:**

```powershell
# Verify subnet configuration changed
Write-Host "Service endpoint enabled - no restart required!" -ForegroundColor Green
Write-Host "You can proceed with testing immediately." -ForegroundColor Green
```

---

## Phase 3: Configure Selected Networks with VNet Rules

### Step 3.1: Add VNet Rule for VM's Subnet

**Run from your workstation:**

```bash
STORAGE_ACCOUNT="ablprodbanklayerrg892"
RESOURCE_GROUP="abl-prod-banklayer-rg"
VNET_NAME="abl-prod-banklayer-vnet"
SUBNET_NAME="abl-prod-banklayer-dfs-sn"  # or the subnet your test VM is on

# Add VNet rule BEFORE disabling public access
echo "Adding VNet rule for subnet: $SUBNET_NAME"
az storage account network-rule add \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME

# Verify rule added
echo ""
echo "Current VNet rules:"
az storage account show \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --query "networkRuleSet.virtualNetworkRules" -o table
```

### Step 3.2: Disable Public Access (TEST with ONE VM first)

```bash
# NOW disable public access
echo ""
echo "⚠ CRITICAL: Disabling public access..."
echo "Only VNet rules and private endpoints will work after this!"
read -p "Continue? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
  az storage account update \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --default-action Deny \
    --bypass AzureServices
    
  echo "✓ Public access disabled"
  echo "Testing connectivity from VM..."
fi
```

---

## Phase 4: Post-Change Validation Tests

Run these tests **immediately after** disabling public access.

### Step 4.1: DNS Resolution Test (Should Use Private IP)

**On the VM:**

```powershell
# Test 6: DNS resolution after change
Write-Host "`n=== POST-CHANGE DNS Test ===" -ForegroundColor Cyan
$storageFQDN = "ablprodbanklayerrg892.blob.core.windows.net"

$dnsResult = Resolve-DnsName $storageFQDN -Type A
$dnsResult | Format-Table -AutoSize

# Check if private IP
$privateIPs = $dnsResult | Where-Object { $_.IP4Address -match "^10\." }
if ($privateIPs) {
    Write-Host "✓ Using PRIVATE endpoint (10.x.x.x)" -ForegroundColor Green
} else {
    Write-Host "→ Still using public IP (may rely on service endpoint or public access)" -ForegroundColor Yellow
}
```

### Step 4.2: Storage Access Test

```powershell
# Test 7: Verify storage access still works
Write-Host "`n=== Storage Access Test ===" -ForegroundColor Cyan

$blobUrl = "https://ablprodbanklayerrg892.blob.core.windows.net/"
$tableUrl = "https://ablprodbanklayerrg892.table.core.windows.net/"

# Test blob endpoint
try {
    $response = Invoke-WebRequest -Uri $blobUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✓ Blob endpoint REACHABLE - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400 -or $statusCode -eq 403) {
        Write-Host "✓ Blob endpoint REACHABLE (auth required) - Status: $statusCode" -ForegroundColor Green
    } else {
        Write-Host "✗ Blob endpoint FAILED - Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  This indicates network connectivity is BROKEN!" -ForegroundColor Red
    }
}

# Test table endpoint
try {
    $response = Invoke-WebRequest -Uri $tableUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✓ Table endpoint REACHABLE - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400 -or $statusCode -eq 403) {
        Write-Host "✓ Table endpoint REACHABLE (auth required) - Status: $statusCode" -ForegroundColor Green
    } else {
        Write-Host "✗ Table endpoint FAILED - Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

### Step 4.3: WAD Agent Verification (15-30 min wait)

```powershell
# Test 8: Check if WAD agent can still write metrics
Write-Host "`n=== WAD Agent Test (requires 15-30 min wait) ===" -ForegroundColor Cyan

Write-Host "Diagnostic agents cache data and retry on failure."
Write-Host "Wait 15-30 minutes, then check if new data is being written."
Write-Host ""

# Check WAD log for recent activity
$wadLogPath = "C:\WindowsAzure\Logs\Plugins\Microsoft.Azure.Diagnostics.IaaSDiagnostics"
if (Test-Path $wadLogPath) {
    Write-Host "Most recent WAD activity:"
    Get-ChildItem $wadLogPath -Recurse -Filter "*.log" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1 | 
        ForEach-Object {
            Write-Host "  $($_.FullName)"
            Write-Host "  Last Modified: $($_.LastWriteTime)"
            Write-Host ""
            Write-Host "  Last 10 lines:"
            Get-Content $_.FullName -Tail 10 | ForEach-Object { Write-Host "    $_" }
        }
}

# Look for errors
Write-Host "`nSearching for recent errors..."
Get-EventLog -LogName Application -Source "Azure*" -After (Get-Date).AddMinutes(-30) -ErrorAction SilentlyContinue |
    Where-Object { $_.EntryType -eq "Error" } |
    Select-Object -First 5 |
    Format-List TimeGenerated, Source, Message
```

### Step 4.4: Compare Before/After

```powershell
# Test 9: Side-by-side comparison
Write-Host "`n=== BEFORE vs AFTER Comparison ===" -ForegroundColor Cyan

$comparison = @"
╔═══════════════════════════════════════════════════════════════════════════╗
║                    CONNECTIVITY TEST COMPARISON                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

Metric                   BEFORE (Public)    AFTER (Selected Networks)
────────────────────────────────────────────────────────────────────────────
DNS Resolution           Public IP          Private IP (10.x.x.x)
Blob Endpoint            ✓ Reachable        ✓ Reachable
Table Endpoint           ✓ Reachable        ✓ Reachable
WAD Agent Status         Running            Running (check logs)
Network Path             Public Internet    VNet/Private Endpoint

Expected After Change:
  - DNS should resolve to 10.x.x.x (private IP)
  - HTTP 400/403 response (auth required) = GOOD
  - Connection timeout = BAD (rollback needed)
  - WAD logs show successful uploads = GOOD
  - WAD logs show storage errors = BAD (rollback needed)

"@

Write-Host $comparison
```

---

## Phase 5: Monitor for 24-48 Hours

### Step 5.1: Automated Monitoring Script

Create this script and schedule it to run every 15 minutes:

```powershell
# Save as: C:\Scripts\Monitor-StorageConnectivity.ps1

$storageFQDN = "ablprodbanklayerrg892.blob.core.windows.net"
$logFile = "C:\Logs\storage-connectivity-$(Get-Date -Format 'yyyyMMdd').log"

# Create log directory
New-Item -ItemType Directory -Path "C:\Logs" -Force | Out-Null

# Test connectivity
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$testResult = Test-NetConnection -ComputerName $storageFQDN -Port 443 -WarningAction SilentlyContinue

$logEntry = @"
[$timestamp]
DNS: $($testResult.ResolvedAddresses -join ', ')
TCP 443: $($testResult.TcpTestSucceeded)
Ping: $($testResult.PingSucceeded)
---
"@

Add-Content -Path $logFile -Value $logEntry

# Alert on failure
if (-not $testResult.TcpTestSucceeded) {
    Write-EventLog -LogName Application -Source "StorageMonitor" -EventId 1001 -EntryType Error `
        -Message "Storage connectivity FAILED to $storageFQDN" -ErrorAction SilentlyContinue
}
```

**Schedule the monitoring:**

```powershell
# Run from Administrator PowerShell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Monitor-StorageConnectivity.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "MonitorStorageConnectivity" -Action $action -Trigger $trigger -Principal $principal
```

### Step 5.2: Check Azure Monitor for Gaps

**From Azure Portal:**

1. Navigate to **Storage Account** → **Insights**
2. Check **Transactions** graph
3. Look for:
   - ✓ Steady transaction rate = GOOD
   - ✗ Sharp drop after change time = BAD
   - ✗ Increase in errors = BAD

### Step 5.3: Review WAD Metrics in Log Analytics

**From workstation:**

```bash
# Query Log Analytics for recent metrics
az monitor log-analytics query \
  --workspace <WORKSPACE_ID> \
  --analytics-query "Perf | where Computer == 'prd-bl-dfs-01' | where TimeGenerated > ago(2h) | summarize count() by bin(TimeGenerated, 5m)" \
  --output table
```

---

## Rollback Procedure

If connectivity fails after disabling public access:

### Emergency Rollback

```bash
# IMMEDIATE: Re-enable public access
az storage account update \
  --name ablprodbanklayerrg892 \
  --resource-group abl-prod-banklayer-rg \
  --default-action Allow

echo "✓ Public access restored"
echo "Verify VMs can connect again"
```

### Rollback Verification

```powershell
# On the VM - verify access restored
Test-NetConnection ablprodbanklayerrg892.blob.core.windows.net -Port 443
```

---

## Success Criteria

✅ **PROCEED to remaining VMs if:**
- DNS resolves to private IP (10.x.x.x) OR public IP with service endpoint
- HTTP 400/403 response (authentication required)
- No connection timeouts
- WAD logs show successful uploads after 30 minutes
- No errors in Application Event Log

❌ **ROLLBACK if:**
- Connection timeout to storage account
- DNS resolution fails
- WAD logs show persistent storage errors after 30 minutes
- Performance metrics stop flowing to Log Analytics
- Application errors related to storage access

---

## Testing Checklist

- [ ] Choose test VM (one without service endpoint preferred)
- [ ] Run Phase 1 baseline tests
- [ ] Save baseline output
- [ ] Enable service endpoint on VM's subnet
- [ ] Add VNet rule for VM's subnet
- [ ] Disable public access
- [ ] Run Phase 4 post-change tests immediately
- [ ] Compare before/after results
- [ ] Wait 15-30 minutes and check WAD logs
- [ ] Monitor for 24-48 hours
- [ ] If successful, repeat for remaining subnets

---

## Summary

This guide provides a systematic approach to testing storage account network changes:

1. **Baseline** - Understand current connectivity
2. **Prepare** - Enable service endpoints
3. **Test** - One VM at a time
4. **Validate** - Confirm connectivity works
5. **Monitor** - Watch for issues over 24-48 hours
6. **Rollback** - Immediate restoration if problems occur

**Always test with ONE VM first before rolling out to all VMs!**

---

## Related

- [[My-Notes/Azure/Storage-Account/storage-network-rules.skill copy|Storage Network Rules Configuration]]
- [[My-Notes/Azure/Storage-Account/privateendpoint copy|Private Endpoint Creation Plan]]
- [[My-Notes/my-notes|My Notes Folder Guide]]
