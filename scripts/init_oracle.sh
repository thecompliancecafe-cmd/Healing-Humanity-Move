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

ORACLE_REGISTRY_ID=$(jq -r '.objectChanges[] | select(.objectType | contains("OracleRegistry")) | .objectId' oracle.json)
ORACLE_ADMIN_CAP=$(jq -r '.objectChanges[] | select(.objectType | contains("OracleAdminCap")) | .objectId' oracle.json)

echo "ORACLE_REGISTRY_ID=$ORACLE_REGISTRY_ID" >> .env
echo "ORACLE_ADMIN_CAP=$ORACLE_ADMIN_CAP" >> .env
