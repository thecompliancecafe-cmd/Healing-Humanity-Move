#!/bin/bash
set -e
source .env

# Amount to release (in MIST, 1 SUI = 1_000_000_000)
AMOUNT=100000000
CHARITY_ADDRESS="0xCHARITY_ADDRESS"

# Safety checks
if [ -z "$ESCROW_ADMIN_CAP" ] || [ -z "$PROTOCOL_CONFIG_ID" ] || [ -z "$VAULT_ID" ]; then
  echo "❌ Missing required environment variables"
  exit 1
fi

echo "Releasing funds from escrow..."

sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function release \
  --args \
    $ESCROW_ADMIN_CAP \
    $PROTOCOL_CONFIG_ID \
    $VAULT_ID \
    $AMOUNT \
    $CHARITY_ADDRESS \
  --gas-budget 100000000

echo "✅ Funds released"
echo "   Amount: $AMOUNT"
echo "   Recipient: $CHARITY_ADDRESS"
