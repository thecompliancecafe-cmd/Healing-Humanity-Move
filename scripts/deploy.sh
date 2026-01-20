#!/bin/bash

echo "Publishing Healing Humanity protocol..."

sui client publish \
  --gas-budget 300000000 \
  --json > deployment.json

PACKAGE_ID=$(cat deployment.json | jq -r '.objectChanges[] | select(.type=="published") | .packageId')

echo "Package published at: $PACKAGE_ID"

echo "PACKAGE_ID=$PACKAGE_ID" > .env
