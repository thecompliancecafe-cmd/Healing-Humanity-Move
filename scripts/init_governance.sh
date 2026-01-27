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

GOV_CONFIG_ID=$(jq -r '.objectChanges[] | select(.objectType | contains("ProtocolConfig")) | .objectId' governance.json)
GOV_ADMIN_CAP=$(jq -r '.objectChanges[] | select(.objectType | contains("GovAdminCap")) | .objectId' governance.json)

echo "GOV_CONFIG_ID=$GOV_CONFIG_ID" >> .env
echo "GOV_ADMIN_CAP=$GOV_ADMIN_CAP" >> .env
