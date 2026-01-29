#!/bin/bash
set -e
source .env

echo "Creating Treasury..."

sui client call \
  --package $PACKAGE_ID \
  --module treasury \
  --function create \
  --gas-budget 50000000 \
  --json > treasury.json

# Extract Treasury object
TREASURY_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::treasury::Treasury")
    )
  | .objectId
' treasury.json)

# Safety check
if [ -z "$TREASURY_ID" ]; then
  echo "❌ Failed to extract Treasury object"
  exit 1
fi

# Persist to .env safely
touch .env

if ! grep -q "^TREASURY_ID=" .env; then
  echo "TREASURY_ID=$TREASURY_ID" >> .env
fi

echo "✅ Treasury created"
echo "   Treasury: $TREASURY_ID"
