#!/bin/bash
set -e
source .env

CAMPAIGN_NAME="Vaccines for Children"
TARGET=1000000000

echo "Creating Campaign..."

sui client call \
  --package $PACKAGE_ID \
  --module campaign_registry \
  --function create \
  --args "$CAMPAIGN_NAME" $TARGET \
  --gas-budget 50000000 \
  --json > campaign.json

# Extract Campaign object
CAMPAIGN_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::campaign_registry::Campaign")
    )
  | .objectId
' campaign.json)

# Safety check
if [ -z "$CAMPAIGN_ID" ]; then
  echo "❌ Failed to create campaign"
  exit 1
fi

# Persist to .env safely
touch .env

if ! grep -q "^CAMPAIGN_ID=" .env; then
  echo "CAMPAIGN_ID=$CAMPAIGN_ID" >> .env
fi

echo "✅ Campaign created"
echo "   Campaign ID: $CAMPAIGN_ID"
