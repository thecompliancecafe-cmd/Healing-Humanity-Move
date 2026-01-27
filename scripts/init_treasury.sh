#!/bin/bash
set -e
source .env

echo "Creating Treasury..."

GAS_COIN=$(sui client gas --json | jq -r '.[0].id')

sui client call \
  --package $PACKAGE_ID \
  --module treasury \
  --function create \
  --type-args 0x2::sui::SUI \
  --args $GAS_COIN \
  --gas-budget 50000000 \
  --json > treasury.json

TREASURY_ID=$(jq -r '.objectChanges[] | select(.objectType | contains("Treasury")) | .objectId' treasury.json)

echo "TREASURY_ID=$TREASURY_ID" >> .env
