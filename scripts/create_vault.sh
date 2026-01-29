#!/bin/bash
set -e
source .env

echo "Creating Escrow Vault..."

# 1. Create vault + admin cap
sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function create \
  --args $CAMPAIGN_ID \
  --gas-budget 50000000 \
  --json > vault_create.json

# Extract Vault ID
VAULT_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::milestone_escrow::Vault")
    )
  | .objectId
' vault_create.json)

# Extract Escrow Admin Cap
ESCROW_ADMIN_CAP_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::milestone_escrow::EscrowAdminCap")
    )
  | .objectId
' vault_create.json)

# Safety check
if [ -z "$VAULT_ID" ] || [ -z "$ESCROW_ADMIN_CAP_ID" ]; then
  echo "❌ Failed to create escrow vault"
  exit 1
fi

echo "Sharing Vault..."

# 2. Share vault so anyone can deposit
sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function share \
  --args $VAULT_ID \
  --gas-budget 30000000

# Persist to .env safely
touch .env

if ! grep -q "^VAULT_ID=" .env; then
  echo "VAULT_ID=$VAULT_ID" >> .env
fi

if ! grep -q "^ESCROW_ADMIN_CAP_ID=" .env; then
  echo "ESCROW_ADMIN_CAP=$ESCROW_ADMIN_CAP_ID" >> .env
fi

echo "✅ Escrow Vault created"
echo "   Vault (shared): $VAULT_ID"
echo "   EscrowAdminCap: $ESCROW_ADMIN_CAP_ID"
