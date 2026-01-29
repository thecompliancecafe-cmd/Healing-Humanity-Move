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

# Extract Compliance Registry (shared)
COMPLIANCE_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::compliance::ComplianceRegistry")
    )
  | .objectId
' compliance.json)

# Extract Compliance Admin Cap
COMPLIANCE_ADMIN_CAP=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::compliance::ComplianceAdminCap")
    )
  | .objectId
' compliance.json)

# Safety checks
if [ -z "$COMPLIANCE_ID" ] || [ -z "$COMPLIANCE_ADMIN_CAP" ]; then
  echo "❌ Failed to extract Compliance objects"
  exit 1
fi

# Persist to .env safely
touch .env

if ! grep -q "^COMPLIANCE_ID=" .env; then
  echo "COMPLIANCE_ID=$COMPLIANCE_ID" >> .env
fi

if ! grep -q "^COMPLIANCE_ADMIN_CAP=" .env; then
  echo "COMPLIANCE_ADMIN_CAP=$COMPLIANCE_ADMIN_CAP" >> .env
fi

echo "✅ Compliance initialized"
echo "   ComplianceRegistry: $COMPLIANCE_ID"
echo "   ComplianceAdminCap: $COMPLIANCE_ADMIN_CAP"
