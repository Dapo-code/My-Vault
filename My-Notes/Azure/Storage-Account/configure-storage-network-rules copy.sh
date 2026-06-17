#!/bin/bash
# Configure storage account network rules for selected networks with IP allowlist

STORAGE_ACCOUNT="ablprodmanagementrgdiag"
RESOURCE_GROUP="abl-prod-management-rg"

# Define IP addresses and CIDR ranges
IPS=(
  "20.58.68.62"
  "20.58.68.63"
  "20.90.32.180"
  "20.90.132.144"
  "20.90.132.145"
  "51.104.30.169"
  "172.187.0.26"
  "172.187.65.53"
  "4.210.131.60"
  "20.105.209.72"
  "20.105.209.73"
  "40.113.178.49"
  "52.146.137.65"
  "52.146.139.220"
  "52.146.139.221"
  "98.71.107.78"
  "162.10.0.0/17"
  "163.116.128.0/17"
)

echo "Configuring storage account: $STORAGE_ACCOUNT"
echo "================================================"

# Set default action to Deny and allow trusted Microsoft services
echo "Setting network default action to Deny and bypassing Azure Services..."
az storage account update \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --default-action Deny \
  --bypass AzureServices

if [ $? -eq 0 ]; then
  echo "✓ Network default action configured successfully"
else
  echo "✗ Failed to configure network default action"
  exit 1
fi

# Add IP rules
echo ""
echo "Adding IP address rules..."
for ip in "${IPS[@]}"; do
  echo "  Adding: $ip"
  az storage account network-rule add \
    --account-name "$STORAGE_ACCOUNT" \
    --ip-address "$ip" \
    --output none
  
  if [ $? -eq 0 ]; then
    echo "    ✓ Added successfully"
  else
    echo "    ✗ Failed to add"
  fi
done

# Add VNet rules
echo ""
echo "Adding VNet rules for subnets with service endpoints..."
VNET_NAME="abl-prod-management-vnet"
SUBNETS=(
  "default"
  "abl-prod-mgmt-cicd-sn"
  "abl-prod-mgmt-ts-sn"
  "abl-prod-management-cicd-windows"
)

for subnet in "${SUBNETS[@]}"; do
  echo "  Adding VNet rule: $VNET_NAME/$subnet"
  az storage account network-rule add \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --subnet "$subnet" \
    --output none
  
  if [ $? -eq 0 ]; then
    echo "    ✓ Added successfully"
  else
    echo "    ✗ Failed to add (may already exist)"
  fi
done

echo ""
echo "================================================"
echo "Configuration complete!"
echo ""
echo "To verify the rules, run:"
echo "az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query networkRuleSet"
