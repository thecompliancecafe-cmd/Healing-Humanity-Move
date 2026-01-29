#!/bin/bash
set -e
source .env

echo "Initializing Oracle Registry..."

sui client call \
  --package $PACKAGE_ID \
  --module ai_oracle \
  --function init \
  --gas-budget 50000000 \
  --json > oracle.json

# Extract Oracle Registry (shared)
ORACLE_REGISTRY_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::ai_oracle::OracleRegistry")
    )
  | .objectId
' oracle.json)

# Extract Oracle Admin Cap
ORACLE_ADMIN_CAP=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::ai_oracle::OracleAdminCap")
    )
  | .objectId
' oracle.json)

# Safety checks
if [ -z "$ORACLE_REGISTRY_ID" ] || [ -z "$ORACLE_ADMIN_CAP" ]; then
  echo "❌ Failed to extract Oracle objects"
  exit 1
fi

# Persist to .env safely
touch .env

if ! grep -q "^ORACLE_REGISTRY_ID=" .env; then
  echo "ORACLE_REGISTRY_ID=$ORACLE_REGISTRY_ID" >> .env
fi

if ! grep -q "^ORACLE_ADMIN_CAP=" .env; then
  echo "ORACLE_ADMIN_CAP=$ORACLE_ADMIN_CAP" >> .env
fi

echo "✅ Oracle initialized"
echo "   OracleRegistry: $ORACLE_REGISTRY_ID"
echo "   OracleAdminCap: $ORACLE_ADMIN_CAP"
