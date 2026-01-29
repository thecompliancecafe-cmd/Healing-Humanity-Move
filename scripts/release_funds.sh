#!/bin/bash
set -e
source .env

# Amount to release (in MIST, 1 SUI = 1_000_000_000)
AMOUNT=100000000
CHARITY_ADDRESS="0xCHARITY_ADDRESS"

echo "Releasing funds from escrow..."

sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function release \
  --args \
    $ESCROW_ADMIN_CAP_ID \
    $GOV_CONFIG_ID \
    $VAULT_ID \
    $AMOUNT \
    $CHARITY_ADDRESS \
  --gas-budget 100000000

echo "✅ Funds released"
echo "   Amount: $AMOUNT"
echo "   Recipient: $CHARITY_ADDRESS"
