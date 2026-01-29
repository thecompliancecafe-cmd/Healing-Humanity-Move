#!/bin/bash
set -e

echo "Publishing Healing Humanity package (Sui 2024)..."

# Publish the package
sui move publish \
  --gas-budget 300000000 \
  --json > deployment.json

# Extract the PACKAGE_ID from JSON
PACKAGE_ID=$(jq -r '.effects.effects.changes[] | select(.type=="published") | .packageId' deployment.json)

# Store in .env for other scripts
echo "PACKAGE_ID=$PACKAGE_ID" > .env

echo "Package published successfully:"
echo $PACKAGE_ID
