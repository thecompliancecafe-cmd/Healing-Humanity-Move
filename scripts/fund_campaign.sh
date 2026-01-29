#!/bin/bash
set -e
source .env

echo "Funding campaign escrow vault..."

# Select a SUI coin to deposit (this becomes the donation)
SUI_COIN=$(sui client gas --json | jq -r '.[0].id')

if [ -z "$SUI_COIN" ]; then
  echo "❌ No SUI coin available to fund campaign"
  exit 1
fi

echo "Using coin: $SUI_COIN"

sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function deposit \
  --args $VAULT_ID $SUI_COIN \
  --gas-budget 50000000

echo "✅ Campaign funded successfully"
