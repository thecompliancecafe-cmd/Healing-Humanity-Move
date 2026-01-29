#!/bin/bash
set -e
source .env

echo "Initializing Access Control..."

sui client call \
  --package $PACKAGE_ID \
  --module access_control \
  --function init \
  --gas-budget 50000000 \
  --json > access_control.json

# Extract shared Roles object
ROLES_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::access_control::Roles")
    )
  | .objectId
' access_control.json)

# Extract Access Control Admin Cap
ACCESS_ADMIN_CAP=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::access_control::AdminCap")
    )
  | .objectId
' access_control.json)

# Safety checks
if [ -z "$ROLES_ID" ] || [ -z "$ACCESS_ADMIN_CAP" ]; then
  echo "❌ Failed to extract Access Control objects"
  exit 1
fi

# Persist to .env safely
touch .env

if ! grep -q "^ROLES_ID=" .env; then
  echo "ROLES_ID=$ROLES_ID" >> .env
fi

if ! grep -q "^ACCESS_ADMIN_CAP=" .env; then
  echo "ACCESS_ADMIN_CAP=$ACCESS_ADMIN_CAP" >> .env
fi

echo "✅ Access Control initialized"
echo "   Roles (shared): $ROLES_ID"
echo "   AdminCap: $ACCESS_ADMIN_CAP"
