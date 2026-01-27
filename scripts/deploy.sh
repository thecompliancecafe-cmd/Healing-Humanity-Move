#!/bin/bash
set -e

echo "Publishing Healing Humanity package..."

sui client publish \
  --gas-budget 300000000 \
  --json > deployment.json

PACKAGE_ID=$(jq -r '.objectChanges[] | select(.type=="published") | .packageId' deployment.json)

echo "PACKAGE_ID=$PACKAGE_ID" > .env

echo "Package published:"
echo $PACKAGE_ID
