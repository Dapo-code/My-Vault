---
title: Monitor Runbook Notes (Converted)
tags:
  - monitoring
  - runbook
  - azure
  - paloalto
created: 2026-06-08
updated: 2026-06-08
source: "/mnt/c/Users/OladapoAde-Ogun/OneDrive - Allica/Desktop/Monitor.txt"
---

# Monitor Runbook Notes (Converted)

## Purpose
This note converts the raw `Monitor.txt` content into an operational runbook-style reference for monitoring, escalation, and query usage.

## High-Level Workflow
1. Start with Checkly when an OLB issue is suspected.
2. Continue with monitoring checks and log analytics queries.
3. If OLB synthetic write fails or pings fail, notify Jason on chat.
4. Validate fire alarm pipeline every Tuesday after Checkly alarm:
   - https://dev.azure.com/AllicaBankLtd/Allica-Infra/_build?definitionId=2111&_a=summary

## Ownership / Context Notes
- Context mentioned: PET Prod Support, Escalations and Incidents.
- Firewall monitoring reference: `abl-prod-fw-[01-03]` for PALO monitoring.

## Query: Alert Rules IP Block Candidate
```kusto
AzureDiagnostics
| where TimeGenerated > ago(5m)
| where requestUri_s contains "auth.allica.bank"
| where isnotempty(clientIp_s)
| where clientIp_s !in ("52.155.221.129", "13.74.241.99", "52.155.216.60", "52.158.32.84", "20.123.82.10")
| summarize Requests = count(), ExampleUris = make_list(requestUri_s, 5) by clientIp_s
| where Requests > 2000
| order by Requests desc
```

## Query: Top Suspicious IP Trend (8h)
```kusto
let lookback=8h;
let threshold=2000;
let bucket=5m;
let topN=10;
let BadIps =
AzureDiagnostics
| where TimeGenerated > ago(lookback)
| where requestUri_s has "auth.allica.bank"
| where isnotempty(clientIp_s)
| summarize TotalRequests=count() by clientIp_s
| where TotalRequests > threshold
| top topN by TotalRequests desc
| project clientIp_s;

AzureDiagnostics
| where TimeGenerated > ago(lookback)
| where requestUri_s has "auth.allica.bank"
| where isnotempty(clientIp_s)
| join kind=inner (BadIps) on clientIp_s
| summarize Requests=count() by bin(TimeGenerated, bucket), clientIp_s
| render timechart
```

## Query: Filtered Timechart with Exclusion Lists
Use the raw source list as maintained. This query focuses on non-whitelisted IPs and charts request volume over 5-minute bins.

## PALO / Network Filters (Raw)
```text
( action eq 'drop' ) and ( addr.src in '10.252.6.0/24' )
```

```text
( addr.dst in '13.74.203.17' ) and ( addr.dst in '20.50.74.177' ) and ( addr.dst in '52.138.226.95' ) and ( addr.dst in '20.50.65.84' )
```

## Referenced Asset
- `abl-prod-data-aks-vnet`

## Suggested Next Improvements
- Split this into separate notes: `Incident Workflow`, `Kusto Queries`, and `PALO Filters`.
- Replace hard-coded IP lists with named watchlists where possible.
- Add explicit severity thresholds and escalation contacts.

## Cross-Links
- [[Oladapo]]
- [[changelog]]
- [[My-Notes/my-notes|My Notes Folder Guide]]
