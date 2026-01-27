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

CAMPAIGN_ID=$(jq -r '.objectChanges[] | select(.objectType | contains("Campaign")) | .objectId' campaign.json)

echo "CAMPAIGN_ID=$CAMPAIGN_ID" >> .env
