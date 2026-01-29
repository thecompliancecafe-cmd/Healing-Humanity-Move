#!/bin/bash
set -e
source .env

echo "Initializing Compliance Registry..."

sui client call \
  --package $PACKAGE_ID \
  --module compliance \
  --function init \
  --gas-budget 50000000 \
  --json > compliance.json

COMPLIANCE_ID=$(jq -r '.objectChanges[] | select(.objectType | contains("ComplianceRegistry")) | .objectId' compliance.json)
COMPLIANCE_ADMIN_CAP=$(jq -r '.objectChanges[] | select(.objectType | contains("ComplianceAdminCap")) | .objectId' compliance.json)

if [ -z "$COMPLIANCE_ID" ] || [ -z "$COMPLIANCE_ADMIN_CAP" ]; then
  echo "❌ Compliance init failed"
  exit 1
fi

echo "COMPLIANCE_ID=$COMPLIANCE_ID" >> .env
echo "COMPLIANCE_ADMIN_CAP=$COMPLIANCE_ADMIN_CAP" >> .env

echo "✅ Compliance initialized"
