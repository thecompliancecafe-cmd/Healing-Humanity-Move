#!/bin/bash
set -e
source .env

echo "Initializing Protocol Governance..."

sui client call \
  --package $PACKAGE_ID \
  --module protocol_governance \
  --function init \
  --gas-budget 50000000 \
  --json > governance.json

# Extract ProtocolConfig ID (Sui 2024 format)
GOV_CONFIG_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::protocol_governance::ProtocolConfig")
    )
  | .objectId
' governance.json)

# Extract Governance Admin Cap
GOV_ADMIN_CAP=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::protocol_governance::GovAdminCap")
    )
  | .objectId
' governance.json)

# Safety checks
if [ -z "$GOV_CONFIG_ID" ] || [ -z "$GOV_ADMIN_CAP" ]; then
  echo "❌ Failed to extract governance objects"
  exit 1
fi

# Persist to .env safely
touch .env

if ! grep -q "^GOV_CONFIG_ID=" .env; then
  echo "GOV_CONFIG_ID=$GOV_CONFIG_ID" >> .env
fi

if ! grep -q "^GOV_ADMIN_CAP=" .env; then
  echo "GOV_ADMIN_CAP=$GOV_ADMIN_CAP" >> .env
fi

echo "✅ Governance initialized"
echo "GOV_CONFIG_ID=$GOV_CONFIG_ID"
echo "GOV_ADMIN_CAP=$GOV_ADMIN_CAP"
