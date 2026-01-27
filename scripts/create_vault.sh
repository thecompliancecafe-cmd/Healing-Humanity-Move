#!/bin/bash
set -e
source .env

echo "Creating Escrow Vault..."

GAS_COIN=$(sui client gas --json | jq -r '.[0].id')

sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function create \
  --type-args 0x2::sui::SUI \
  --args $CAMPAIGN_ID $GAS_COIN \
  --gas-budget 50000000 \
  --json > vault.json

VAULT_ID=$(jq -r '.objectChanges[] | select(.objectType | contains("Vault")) | .objectId' vault.json)

echo "VAULT_ID=$VAULT_ID" >> .env
