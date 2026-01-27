#!/bin/bash
set -e
source .env

echo "Funding campaign..."

GAS_COIN=$(sui client gas --json | jq -r '.[0].id')

sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function deposit \
  --type-args 0x2::sui::SUI \
  --args $VAULT_ID $GAS_COIN \
  --gas-budget 50000000
