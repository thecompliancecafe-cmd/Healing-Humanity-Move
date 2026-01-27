#!/bin/bash
set -e
source .env

echo "Initializing Access Control..."

sui client call \
  --package $PACKAGE_ID \
  --module access_control \
  --function init \
  --gas-budget 50000000 \
  --json > access.json

ROLES_ID=$(jq -r '.objectChanges[] | select(.objectType | contains("Roles")) | .objectId' access.json)
ACCESS_ADMIN_CAP=$(jq -r '.objectChanges[] | select(.objectType | contains("AdminCap")) | .objectId' access.json)

echo "ROLES_ID=$ROLES_ID" >> .env
echo "ACCESS_ADMIN_CAP=$ACCESS_ADMIN_CAP" >> .env
