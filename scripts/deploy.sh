#!/bin/bash
set -e

echo "Publishing Healing Humanity package (Sui 2024)..."

# Publish the package
sui move publish \
  --gas-budget 300000000 \
  --json > deployment.json

# Extract PACKAGE_ID (Sui 2024 format)
PACKAGE_ID=$(jq -r '
  .effects.changes[]
  | select(.type=="published")
  | .packageId
' deployment.json)

if [ -z "$PACKAGE_ID" ]; then
  echo "❌ Failed to extract PACKAGE_ID"
  exit 1
fi

# Persist environment variables (append-safe)
touch .env

if ! grep -q "^PACKAGE_ID=" .env; then
  echo "PACKAGE_ID=$PACKAGE_ID" >> .env
fi

echo "✅ Package published successfully"
echo "PACKAGE_ID=$PACKAGE_ID"
